// deno-lint-ignore-file no-import-prefix
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  isTokenExpiredResponse,
  loadLaropayRuntimeToken,
  refreshLaropayToken,
} from "../_shared/laropay-token.ts";
import {
  laropayEventTypeFromResponse,
  recordLaropayPaymentEvent,
} from "../_shared/laropay-audit.ts";

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
      } else {
        await persistAttempt(
          env,
          user.id,
          input,
          orderPayment,
          laropayPayload,
          tokenRefreshFailurePayload(),
          reservation.id,
          callbackUrl,
        );
        return json({ error: "laropay_token_refresh_failed" }, 502);
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

    if (error instanceof Error && isBadRequestError(error.message)) {
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
      "id, workshop_id, order_number, order_status, payment_status, payment_expires_at, total_amount, customers!inner(user_id)",
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
  if (isCancelledOrderStatus(order.order_status)) {
    throw new Error("order_cancelled");
  }

  if (stringValue(order.payment_status).toLowerCase() !== "unpaid") {
    throw new Error("invalid_order_payment_status");
  }

  // Appointment orders' payment window is recalculated on every link
  // generation attempt (see ensureAppointmentOrderPaymentExpiration below),
  // so a stale/expired payment_expires_at from a previous attempt must not
  // block a retry before that recalculation runs -- otherwise a customer
  // whose order sat past its old deadline could never regenerate a link
  // even though the refreshed end-of-day window would still allow it.
  let effectivePaymentExpiresAt = order.payment_expires_at;
  if (stringValue(order.order_number).startsWith("APP-")) {
    const refreshedExpiresAt = await ensureAppointmentOrderPaymentExpiration(
      env,
      stringValue(input.internalTransactionId),
    );
    if (refreshedExpiresAt !== null) {
      effectivePaymentExpiresAt = refreshedExpiresAt.toISOString();
    }
  }

  if (isExpiredAt(effectivePaymentExpiresAt)) {
    throw new Error("order_payment_expired");
  }

  const orderTotal = numberValue(order.total_amount);
  if (!Number.isFinite(orderTotal) || orderTotal <= 0) {
    throw new Error("invalid_order_total");
  }

  const { data: products, error: productsError } = await adminSupabaseClient(
    env,
  )
    .from("order_products")
    .select("quantity, unit_price")
    .eq("order_id", stringValue(input.internalTransactionId));

  if (productsError !== null) {
    throw new Error("invalid_order_products");
  }

  const productsTotal = ((products ?? []) as Array<Record<string, unknown>>)
    .reduce((total, item) => {
      const quantity = numberValue(item.quantity);
      const unitPrice = numberValue(item.unit_price);
      if (!Number.isFinite(quantity) || !Number.isFinite(unitPrice)) {
        throw new Error("invalid_order_products");
      }

      return total + quantity * unitPrice;
    }, 0);

  if (!Number.isFinite(productsTotal) || productsTotal <= 0) {
    throw new Error("order_has_no_chargeable_products");
  }

  // Laropay only charges product lines. Workshop services and delivery fees are
  // settled directly with the workshop according to the business rule.
  const amount = productsTotal;

  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error("order_has_no_chargeable_products");
  }

  return {
    amount,
    idTransaction: env.laropayTransactionType,
    currencyCode: currencyCode(env.laropayTransactionType),
    workshopId: stringValue(order.workshop_id),
  };
}

// Appointment orders never get a TTL just from being booked (see migration
// 202606240001 keep_appointment_order_active) -- the service can be paid at
// the workshop. Once the customer actually opens a Laropay checkout for one,
// bound its payment window to the end of the appointment's own day (Costa
// Rica local time), per MIT-143. This gives the workshop room to check the
// vehicle in and record payment before the order is swept as abandoned --
// the sweep itself only ever touches orders still in draft/pending/scheduled
// (see 202608190003), so once work actually starts this window stops
// mattering regardless. Recalculated (and returned) on every call, including
// retries, so a stale expires_at from a previous attempt never gets checked
// instead of the refreshed one -- see loadOrderPaymentData. Best-effort:
// failures here must not block link generation.
async function ensureAppointmentOrderPaymentExpiration(
  env: Env,
  orderId: string,
): Promise<Date | null> {
  try {
    const supabase = adminSupabaseClient(env);
    const { data, error } = await supabase
      .from("appointments")
      .select("scheduled_datetime, appointment_status, order_services!inner(order_id)")
      .eq("order_services.order_id", orderId)
      .not("appointment_status", "in", "(cancelled,no_show)")
      .order("scheduled_datetime", { ascending: true })
      .limit(1)
      .maybeSingle();

    if (error !== null || data === null) {
      return null;
    }

    const scheduledAt = stringValue(
      (data as Record<string, unknown>).scheduled_datetime,
    );
    if (scheduledAt === "") {
      return null;
    }

    const expiresAt = endOfCostaRicaDayUtc(scheduledAt);
    if (expiresAt === null) {
      return null;
    }

    await supabase
      .from("orders")
      .update({ payment_expires_at: expiresAt.toISOString() })
      .eq("id", orderId)
      .eq("payment_status", "unpaid");

    return expiresAt;
  } catch (error) {
    console.warn(
      "[laropay.generate_link] appointment_payment_expiration_failed",
      safeError(error),
    );
    return null;
  }
}

// Costa Rica has no DST and is always UTC-6. Given a UTC timestamp, returns
// the UTC instant for 23:59:59.999 of that same day in Costa Rica local time.
function endOfCostaRicaDayUtc(value: string): Date | null {
  const utcDate = new Date(value);
  if (Number.isNaN(utcDate.getTime())) {
    return null;
  }

  const crShifted = new Date(utcDate.getTime() - 6 * 60 * 60 * 1000);
  return new Date(
    Date.UTC(
      crShifted.getUTCFullYear(),
      crShifted.getUTCMonth(),
      crShifted.getUTCDate(),
      29, // 23:59:59.999 CR (UTC-6) normalizes to next-day 05:59:59.999 UTC
      59,
      59,
      999,
    ),
  );
}

function isCancelledOrderStatus(value: unknown) {
  return ["cancelled", "canceled", "expired"].includes(
    stringValue(value).toLowerCase(),
  );
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

  await recordLaropayPaymentEvent(adminSupabaseClient(env), {
    paymentLinkId: reservationId,
    orderId: stringValue(input.internalTransactionId),
    source: "generate_link",
    eventType: eventTypeFromGenerateResponse(laropayResponse),
    status: normalizedStatus(laropayResponse),
    responseCode: stringValue(laropayResponse.response),
    responseDescription: stringValue(laropayResponse.responseDescription),
    rejectReason: stringValue(laropayResponse.rejectReason),
    authResponseCode: stringValue(laropayResponse.authResponseCode),
    payload: responsePayload,
  });
}

function eventTypeFromGenerateResponse(response: Record<string, unknown>) {
  if (
    stringValue(response.response) === "00" &&
    stringValue(response.linkID) === ""
  ) {
    return "invalid_response";
  }

  return laropayEventTypeFromResponse(response, "provider_response");
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

function tokenRefreshFailurePayload() {
  return {
    response: "TOKEN_REFRESH_FAILED",
    responseDescription: "Laropay token refresh failed before link retry",
  };
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

function isExpiredAt(value: unknown) {
  const text = stringValue(value);
  if (text === "") {
    return false;
  }

  const normalizedText = text.includes(" ") ? text.replace(" ", "T") : text;
  const timestamp = new Date(normalizedText).getTime();
  if (Number.isNaN(timestamp)) {
    console.warn("[laropay.generate_link] invalid_payment_expires_at");
    return false;
  }

  return Number.isFinite(timestamp) && timestamp <= Date.now();
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

function isBadRequestError(message: string) {
  return [
    "invalid_order_total",
    "order_payment_expired",
    "order_has_no_chargeable_products",
    "order_cancelled",
  ].includes(message);
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
    isBadRequestError(message) ||
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
