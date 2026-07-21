// deno-lint-ignore-file no-import-prefix
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  isTokenExpiredResponse,
  loadLaropayRuntimeToken,
  refreshLaropayToken,
} from "../_shared/laropay-token.ts";

type LaropayLinkRequest = {
  internalTransactionId?: string;
  amount?: number;
  document?: string;
  detail?: string;
  customerFirstName?: string;
  customerLastName?: string;
  customerEmail?: string;
  customerPhone?: string;
  customerLocation?: string;
  expirationType?: string;
  expirationValue?: number;
  securityCode?: string;
};

type ExistingLaropayLink = {
  id: string;
  link_id: string | null;
  link_url: string | null;
  status: string | null;
  response_code: string | null;
  response_description: string | null;
  reject_reason: string | null;
  auth_response_code: string | null;
};

type OrderPaymentData = {
  amount: number;
  idTransaction: number;
  currencyCode: string;
  workshopId: string;
};

type AuthenticatedRequestUser = {
  id: string;
  authorization: string;
};

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const env = loadEnv();
    const user = await authenticatedUser(request, env);
    const input = await parseJson(request);
    const validationError = validate(input);

    if (validationError !== null) {
      return json({ error: validationError }, 400);
    }

    const orderPayment = await loadOrderPaymentData(env, user, input);
    const reservation = await reservePendingLink(
      env,
      user.id,
      input,
      orderPayment,
    );
    if ("existingLink" in reservation) {
      const existingLink = reservation.existingLink;
      return json({
        response: stringValue(existingLink.response_code),
        responseDescription: stringValue(existingLink.response_description),
        linkID: stringValue(existingLink.link_id),
        linkURL: stringValue(existingLink.link_url),
        status: stringValue(existingLink.status),
        rejectReason: stringValue(existingLink.reject_reason),
        authResponseCode: stringValue(existingLink.auth_response_code),
        reused: true,
      });
    }

    if ("inProgress" in reservation) {
      return json({ error: "laropay_link_generation_in_progress" }, 409);
    }

    const callbackUrl = buildCallbackUrl(
      env.laropayCallbackUrl,
      reservation.id,
      orderPayment.workshopId,
    );
    const laropayToken = await loadLaropayRuntimeToken(env);
    let laropayPayload = buildLaropayPayload(
      input,
      env,
      orderPayment,
      callbackUrl,
      laropayToken,
    );
    let laropayResponse = await callLaropay(laropayPayload, env).catch(
      async (error) => {
        if (error instanceof LaropayHttpError) {
          await persistAttempt(
            env,
            user.id,
            input,
            orderPayment,
            laropayPayload,
            {
              response: "HTTP_ERROR",
              responseDescription: "Laropay rejected the request",
              statusCode: error.status,
              body: error.body,
            },
            reservation.id,
            callbackUrl,
          );

          return null;
        }

        if (isAbortError(error)) {
          await persistAttempt(
            env,
            user.id,
            input,
            orderPayment,
            laropayPayload,
            {
              response: "TIMEOUT",
              responseDescription: "Laropay request timed out",
            },
            reservation.id,
            callbackUrl,
          );

          return null;
        }

        await persistAttempt(
          env,
          user.id,
          input,
          orderPayment,
          laropayPayload,
          {
            response: "NETWORK_ERROR",
            responseDescription: "Laropay request failed before response",
            error: safeError(error),
          },
          reservation.id,
          callbackUrl,
        );

        return null;
      },
    );

    if (laropayResponse === null) {
      return json({ error: "laropay_gateway_rejected" }, 502);
    }

    if (isTokenExpiredResponse(laropayResponse)) {
      const refreshedToken = await refreshLaropayToken(
        env,
        laropayToken,
        "generate_link",
      );

      if (refreshedToken !== null) {
        laropayPayload = buildLaropayPayload(
          input,
          env,
          orderPayment,
          callbackUrl,
          refreshedToken,
        );
        laropayResponse = await callLaropay(laropayPayload, env).catch(
          async (error) => {
            if (error instanceof LaropayHttpError) {
              await persistAttempt(
                env,
                user.id,
                input,
                orderPayment,
                laropayPayload,
                {
                  response: "HTTP_ERROR",
                  responseDescription: "Laropay rejected the retry request",
                  statusCode: error.status,
                  body: error.body,
                },
                reservation.id,
                callbackUrl,
              );

              return null;
            }

            await persistAttempt(
              env,
              user.id,
              input,
              orderPayment,
              laropayPayload,
              {
                response: isAbortError(error) ? "TIMEOUT" : "NETWORK_ERROR",
                responseDescription: isAbortError(error)
                  ? "Laropay retry request timed out"
                  : "Laropay retry request failed before response",
                error: safeError(error),
              },
              reservation.id,
              callbackUrl,
            );

            return null;
          },
        );

        if (laropayResponse === null) {
          return json({ error: "laropay_gateway_rejected" }, 502);
        }
      }
    }

    const linkID = stringValue(laropayResponse.linkID);
    const linkURL = stringValue(laropayResponse.linkURL);

    if (
      stringValue(laropayResponse.response) !== "00" || linkID === "" ||
      !isSecureUrl(linkURL)
    ) {
      await persistAttempt(
        env,
        user.id,
        input,
        orderPayment,
        laropayPayload,
        laropayResponse,
        reservation.id,
        callbackUrl,
      );
      return json({ error: "laropay_invalid_response" }, 502);
    }

    await persistAttempt(
      env,
      user.id,
      input,
      orderPayment,
      laropayPayload,
      laropayResponse,
      reservation.id,
      callbackUrl,
    );

    return json({
      response: stringValue(laropayResponse.response),
      responseDescription: stringValue(laropayResponse.responseDescription),
      linkID,
      linkURL,
      status: normalizedStatus(laropayResponse),
      rejectReason: stringValue(laropayResponse.rejectReason),
      authResponseCode: stringValue(laropayResponse.authResponseCode),
      reused: false,
    });
  } catch (error) {
    console.error("laropay_generate_link_failed", safeError(error));
    if (error instanceof Error && error.message.startsWith("auth_")) {
      return json({ error: error.message }, 401);
    }

    if (error instanceof Error && error.message.startsWith("invalid_")) {
      return json({ error: error.message }, 400);
    }

    if (error instanceof Error && error.message === "transaction_not_found") {
      return json({ error: error.message }, 403);
    }

    return json({ error: "laropay_generate_link_failed" }, 500);
  }
});

async function authenticatedUser(
  request: Request,
  env: Env,
): Promise<AuthenticatedRequestUser> {
  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.toLowerCase().startsWith("bearer ")) {
    throw new Error("auth_required");
  }

  const accessToken = authorization.replace(/^bearer\s+/i, "").trim();
  const supabase = authSupabaseClient(env);
  const { data, error } = await supabase.auth.getUser(accessToken);

  if (error !== null || data.user === null) {
    throw new Error("auth_invalid");
  }

  return { id: data.user.id, authorization };
}

async function parseJson(request: Request): Promise<LaropayLinkRequest> {
  let decoded: unknown;
  try {
    decoded = await request.json();
  } catch {
    throw new Error("invalid_json");
  }

  if (
    decoded === null || typeof decoded !== "object" || Array.isArray(decoded)
  ) {
    throw new Error("invalid_json");
  }

  return decoded as LaropayLinkRequest;
}

async function loadOrderPaymentData(
  env: Env,
  user: AuthenticatedRequestUser,
  input: LaropayLinkRequest,
): Promise<OrderPaymentData> {
  const supabase = userSupabaseClient(env, user.authorization);
  const { data, error } = await supabase
    .from("orders")
    .select(
      "id, workshop_id, remaining_amount, total_amount, payment_status, customers!inner(user_id)",
    )
    .eq("id", stringValue(input.internalTransactionId))
    .eq("customers.user_id", user.id)
    .maybeSingle();

  if (error !== null) {
    throw new Error("invalid_internal_transaction");
  }

  if (data === null) {
    throw new Error("transaction_not_found");
  }

  const order = data as Record<string, unknown>;
  if (stringValue(order.payment_status).toLowerCase() !== "unpaid") {
    throw new Error("invalid_order_payment_status");
  }

  const rawRemainingAmount = order.remaining_amount;
  const amount = hasStoredValue(rawRemainingAmount)
    ? numberValue(rawRemainingAmount)
    : numberValue(order.total_amount);

  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error("invalid_order_amount");
  }

  return {
    amount,
    idTransaction: env.laropayTransactionType,
    currencyCode: currencyCode(env.laropayTransactionType),
    workshopId: stringValue(order.workshop_id),
  };
}

async function reservePendingLink(
  env: Env,
  userId: string,
  input: LaropayLinkRequest,
  orderPayment: OrderPaymentData,
): Promise<
  | { id: string }
  | { existingLink: ExistingLaropayLink }
  | { inProgress: true }
> {
  const supabase = adminSupabaseClient(env);
  const { data, error } = await supabase.rpc("reserve_laropay_payment_link", {
    p_user_id: userId,
    p_internal_transaction_id: stringValue(input.internalTransactionId),
    p_id_transaction: orderPayment.idTransaction,
    p_amount: orderPayment.amount,
    p_currency_code: orderPayment.currencyCode,
    p_document: trimOrNull(input.document),
    p_detail: trimOrNull(input.detail),
    p_customer_email: stringValue(input.customerEmail),
    p_expiration_type: normalizedExpirationType(input),
    p_expiration_value: normalizedExpirationValue(input),
    p_expires_at: calculateExpiresAt(input).toISOString(),
    p_url_callback: env.laropayCallbackUrl,
    p_request_payload: sanitizeJson({
      ...input,
      urlCallback: env.laropayCallbackUrl,
    }),
  });

  if (error !== null) {
    throw error;
  }

  const result = data as Record<string, unknown>;
  const kind = stringValue(result.kind);

  if (kind === "reserved") {
    return { id: stringValue(result.id) };
  }

  if (kind === "existing") {
    return { existingLink: result.link as ExistingLaropayLink };
  }

  if (kind === "in_progress") {
    return { inProgress: true };
  }

  throw new Error("invalid_reservation_response");
}

function validate(input: LaropayLinkRequest): string | null {
  if (stringValue(input.internalTransactionId) === "") {
    return "internal_transaction_required";
  }

  if (
    typeof input.amount !== "number" ||
    !Number.isFinite(input.amount) ||
    input.amount <= 0
  ) {
    return "amount_invalid";
  }

  if (stringValue(input.customerFirstName) === "") {
    return "customer_first_name_required";
  }

  if (stringValue(input.customerLastName) === "") {
    return "customer_last_name_required";
  }

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(stringValue(input.customerEmail))) {
    return "customer_email_invalid";
  }

  const expirationType = normalizedExpirationType(input);
  if (!["D", "H", "M"].includes(expirationType)) {
    return "expiration_type_invalid";
  }

  const expirationValue = normalizedExpirationValue(input);
  if (!Number.isInteger(expirationValue) || expirationValue <= 0) {
    return "expiration_value_invalid";
  }

  return null;
}

function buildLaropayPayload(
  input: LaropayLinkRequest,
  env: Env,
  orderPayment: OrderPaymentData,
  callbackUrl: string,
  laropayToken = env.laropayToken,
) {
  return {
    idUser: env.laropayIdUser,
    token: laropayToken,
    idTransaction: orderPayment.idTransaction,
    amount: orderPayment.amount,
    document: trimOrNull(input.document),
    detail: trimOrNull(input.detail),
    customerFirstName: stringValue(input.customerFirstName),
    customerLastName: stringValue(input.customerLastName),
    customerEmail: stringValue(input.customerEmail),
    customerPhone: trimOrNull(input.customerPhone),
    customerLocation: trimOrNull(input.customerLocation),
    expirationType: normalizedExpirationType(input),
    expirationValue: normalizedExpirationValue(input),
    urlCallback: callbackUrl,
    securityCode: trimOrNull(input.securityCode),
  };
}

async function callLaropay(payload: Record<string, unknown>, env: Env) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20000);

  try {
    const response = await fetch(`${env.laropayBaseUrl}/api/GetNewSecureLink`, {
      method: "POST",
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": `Basic ${
          btoa(
            `${env.laropayBasicUser}:${env.laropayBasicPassword}`,
          )
        }`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new LaropayHttpError(response.status, body);
    }

    return body as Record<string, unknown>;
  } finally {
    clearTimeout(timeout);
  }
}

async function persistAttempt(
  env: Env,
  userId: string,
  input: LaropayLinkRequest,
  orderPayment: OrderPaymentData,
  laropayPayload: Record<string, unknown>,
  laropayResponse: Record<string, unknown>,
  reservationId?: string,
  callbackUrl = env.laropayCallbackUrl,
) {
  const linkID = trimOrNull(laropayResponse.linkID);
  const linkURL = trimOrNull(laropayResponse.linkURL);
  const supabase = adminSupabaseClient(env);
  const requestPayload = sanitizeJson({
    ...laropayPayload,
    idUser: "<redacted>",
    token: "<redacted>",
  });
  const responsePayload = sanitizeJson(laropayResponse);
  const values = {
    user_id: userId,
    internal_transaction_id: stringValue(input.internalTransactionId),
    id_transaction: orderPayment.idTransaction,
    amount: orderPayment.amount,
    currency_code: orderPayment.currencyCode,
    document: trimOrNull(input.document),
    detail: trimOrNull(input.detail),
    customer_email: stringValue(input.customerEmail),
    expiration_type: normalizedExpirationType(input),
    expiration_value: normalizedExpirationValue(input),
    expires_at: calculateExpiresAt(input).toISOString(),
    url_callback: callbackUrl,
    link_id: linkID,
    link_url: linkURL,
    status: normalizedStatus(laropayResponse),
    response_code: stringValue(laropayResponse.response),
    response_description: stringValue(laropayResponse.responseDescription),
    reject_reason: stringValue(laropayResponse.rejectReason),
    auth_response_code: stringValue(laropayResponse.authResponseCode),
    request_payload: requestPayload,
    response_payload: responsePayload,
  };

  const { error } = reservationId === undefined
    ? await supabase.from("laropay_payment_links").insert(values)
    : await supabase
      .from("laropay_payment_links")
      .update(values)
      .eq("id", reservationId);

  if (error !== null) {
    throw error;
  }
}

function buildCallbackUrl(
  callbackBaseUrl: string,
  paymentLinkId: string,
  workshopId: string,
) {
  const callbackUrl = new URL(callbackBaseUrl);
  callbackUrl.searchParams.set("paymentLinkId", paymentLinkId);
  callbackUrl.searchParams.set("workshopId", workshopId);
  return callbackUrl.toString();
}

function sanitizeJson(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(sanitizeJson);
  }

  if (value !== null && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, item]) => {
        if (isSensitiveKey(key)) {
          return [key, stringValue(item) === "" ? "" : "<redacted>"];
        }

        return [key, sanitizeJson(item)];
      }),
    );
  }

  return value;
}

function isSensitiveKey(key: string) {
  return ["iduser", "token", "newtoken", "authorization", "securitycode"]
    .includes(
      key.toLowerCase(),
    );
}

function authSupabaseClient(env: Env) {
  return createClient(env.supabaseUrl, env.supabaseAnonKey);
}

function userSupabaseClient(env: Env, authorization: string) {
  return createClient(env.supabaseUrl, env.supabaseAnonKey, {
    global: { headers: { authorization } },
  });
}

function adminSupabaseClient(env: Env) {
  return createClient(env.supabaseUrl, env.supabaseServiceRoleKey);
}

function currencyCode(idTransaction?: number) {
  return idTransaction === 2 ? "USD" : "CRC";
}

function normalizedStatus(response: Record<string, unknown>) {
  if (stringValue(response.response) !== "00") {
    return "failed";
  }

  const explicitStatus = stringValue(response.status).toLowerCase();
  if (explicitStatus !== "") {
    return explicitStatus;
  }

  return stringValue(response.linkID) === "" ? "failed" : "created";
}

function stringValue(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function numberValue(value: unknown) {
  if (typeof value === "number") {
    return value;
  }

  if (typeof value === "string") {
    return Number(value);
  }

  return Number.NaN;
}

function hasStoredValue(value: unknown) {
  if (value === null || value === undefined) {
    return false;
  }

  if (typeof value === "string") {
    return value.trim() !== "";
  }

  return typeof value === "number";
}

function trimOrNull(value: unknown) {
  const text = stringValue(value);
  return text === "" ? null : text;
}

function normalizedExpirationType(input: LaropayLinkRequest) {
  return stringValue(input.expirationType || "D").toUpperCase();
}

function normalizedExpirationValue(input: LaropayLinkRequest) {
  return input.expirationValue ?? 1;
}

function calculateExpiresAt(input: LaropayLinkRequest) {
  const expirationValue = normalizedExpirationValue(input);
  const millisecondsByType: Record<string, number> = {
    D: 24 * 60 * 60 * 1000,
    H: 60 * 60 * 1000,
    M: 60 * 1000,
  };
  const unit = millisecondsByType[normalizedExpirationType(input)] ??
    millisecondsByType.D;

  return new Date(Date.now() + expirationValue * unit);
}

function isSecureUrl(value: string) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname.trim() !== "";
  } catch {
    return false;
  }
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "content-type": "application/json",
    },
  });
}

function isAbortError(error: unknown) {
  return error instanceof DOMException && error.name === "AbortError";
}

function safeError(error: unknown) {
  if (error instanceof LaropayHttpError) {
    return { status: error.status, body: sanitizeJson(error.body) };
  }

  if (error instanceof Error) {
    return {
      name: error.name,
      code: safeErrorCode(error.message),
    };
  }

  return { name: "NonError" };
}

function safeErrorCode(message: string) {
  if (
    message.startsWith("auth_") ||
    message.startsWith("invalid_") ||
    message.startsWith("missing_env_") ||
    message === "transaction_not_found"
  ) {
    return message;
  }

  return "unexpected_error";
}

function loadEnv(): Env {
  const laropayBaseUrl = requiredEnv("LAROPAY_BASE_URL").replace(/\/+$/, "");
  const laropayCallbackUrl = requiredEnv("LAROPAY_CALLBACK_URL");

  if (!isSecureUrl(laropayBaseUrl)) {
    throw new Error("missing_env_LAROPAY_BASE_URL");
  }

  if (!isSecureUrl(laropayCallbackUrl)) {
    throw new Error("missing_env_LAROPAY_CALLBACK_URL");
  }

  const laropayTransactionType = Number(
    requiredEnv("LAROPAY_TRANSACTION_TYPE"),
  );
  if (![1, 2].includes(laropayTransactionType)) {
    throw new Error("missing_env_LAROPAY_TRANSACTION_TYPE");
  }

  return {
    supabaseUrl: requiredEnv("SUPABASE_URL"),
    supabaseAnonKey: requiredEnv("SUPABASE_ANON_KEY"),
    supabaseServiceRoleKey: requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    laropayBaseUrl,
    laropayBasicUser: requiredEnv("LAROPAY_BASIC_USER"),
    laropayBasicPassword: requiredEnv("LAROPAY_BASIC_PASSWORD"),
    laropayIdUser: requiredEnv("LAROPAY_ID_USER"),
    laropayToken: requiredEnv("LAROPAY_TOKEN"),
    laropayCallbackUrl,
    laropayTransactionType,
  };
}

function requiredEnv(key: string) {
  const value = Deno.env.get(key)?.trim() ?? "";
  if (value === "") {
    throw new Error(`missing_env_${key}`);
  }

  return value;
}

type Env = {
  supabaseUrl: string;
  supabaseAnonKey: string;
  supabaseServiceRoleKey: string;
  laropayBaseUrl: string;
  laropayBasicUser: string;
  laropayBasicPassword: string;
  laropayIdUser: string;
  laropayToken: string;
  laropayCallbackUrl: string;
  laropayTransactionType: number;
};

class LaropayHttpError extends Error {
  constructor(public readonly status: number, public readonly body: unknown) {
    super("laropay_http_error");
  }
}
