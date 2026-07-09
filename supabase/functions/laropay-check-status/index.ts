import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type AuthenticatedRequestUser = {
  id: string;
  authorization: string;
};

type PaymentLinkRow = {
  id: string;
  user_id: string;
  internal_transaction_id: string;
  amount: number | string;
  currency_code: string | null;
  detail: string | null;
  link_id: string | null;
  link_url: string | null;
  status: string | null;
  response_code: string | null;
  response_description: string | null;
  reject_reason: string | null;
  auth_response_code: string | null;
  expires_at: string | null;
  created_at: string | null;
};

type LaropayStatusInput = {
  paymentLinkId?: string;
};

type LaropayStatusOutcome =
  | "paid"
  | "pending"
  | "rejected"
  | "expired"
  | "failed";

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
    const paymentLinkId = stringValue(input.paymentLinkId);

    if (!isUuid(paymentLinkId)) {
      return json({ error: "invalid_payment_link" }, 400);
    }

    const paymentLink = await loadPaymentLink(env, user, paymentLinkId);
    if (paymentLink === null) {
      return json({ error: "payment_link_not_found" }, 404);
    }

    if (isFinalStatus(paymentLink.status)) {
      return json(responseFromPaymentLink(paymentLink, true));
    }

    const linkID = stringValue(paymentLink.link_id);
    if (linkID === "") {
      return json({ error: "payment_link_missing_laropay_id" }, 409);
    }

    const verifyResponse = await callLaropayStatus(
      "VerifySecureLink",
      linkID,
      env,
    ).catch(async (error) => {
      await persistStatusError(
        env,
        paymentLink,
        "verify_secure_link_failed",
        error,
      );
      return null;
    });

    if (verifyResponse === null) {
      return json({ error: "laropay_status_unavailable" }, 502);
    }

    if (!isSuccessfulLaropayResponse(verifyResponse)) {
      await persistStatusCheck(env, paymentLink, {
        status: statusFromLocalExpiration(paymentLink) ?? "pending",
        verifyResponse,
        certifierResponse: null,
        statusCheckError: providerErrorCode("verify", verifyResponse),
      });
      return json({ error: "laropay_verify_rejected" }, 502);
    }

    const verifyOutcome = statusFromVerifyResponse(verifyResponse, paymentLink);
    let certifierResponse: Record<string, unknown> | null = null;
    let certifierOutcome: LaropayStatusOutcome | null = null;

    if (verifyOutcome !== "rejected" && verifyOutcome !== "expired") {
      certifierResponse = await callLaropayStatus(
        "ConsultTransactionInCertifier",
        linkID,
        env,
      ).catch(async (error) => {
        await persistStatusCheck(env, paymentLink, {
          status: statusFromLocalExpiration(paymentLink) ?? "pending",
          verifyResponse,
          certifierResponse: {
            response: "NETWORK_ERROR",
            responseDescription: "Laropay certifier request failed",
            error: safeError(error),
          },
          statusCheckError: "certifier_unavailable",
        });
        return null;
      });

      if (certifierResponse === null) {
        return json({ error: "laropay_certifier_unavailable" }, 502);
      }

      if (!isSuccessfulLaropayResponse(certifierResponse)) {
        await persistStatusCheck(env, paymentLink, {
          status: statusFromLocalExpiration(paymentLink) ?? "pending",
          verifyResponse,
          certifierResponse,
          statusCheckError: providerErrorCode(
            "certifier",
            certifierResponse,
          ),
        });
        return json({ error: "laropay_certifier_rejected" }, 502);
      }

      certifierOutcome = statusFromCertifierResponse(certifierResponse);
    }

    const finalStatus = resolveFinalStatus({
      paymentLink,
      verifyOutcome,
      certifierOutcome,
    });

    const updatedPayment = await persistStatusCheck(env, paymentLink, {
      status: finalStatus,
      verifyResponse,
      certifierResponse,
      statusCheckError: null,
    });

    return json({
      ...responseFromPaymentLink(updatedPayment, false),
      verifyResponse: stringValue(verifyResponse.response),
      certifierResponse: certifierResponse === null
        ? ""
        : stringValue(certifierResponse.response),
    });
  } catch (error) {
    console.error("laropay_check_status_failed", safeError(error));

    if (error instanceof Error && error.message.startsWith("auth_")) {
      return json({ error: error.message }, 401);
    }

    if (error instanceof Error && error.message.startsWith("invalid_")) {
      return json({ error: error.message }, 400);
    }

    return json({ error: "laropay_check_status_failed" }, 500);
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

async function parseJson(request: Request): Promise<LaropayStatusInput> {
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

  return decoded as LaropayStatusInput;
}

async function loadPaymentLink(
  env: Env,
  user: AuthenticatedRequestUser,
  paymentLinkId: string,
): Promise<PaymentLinkRow | null> {
  const supabase = userSupabaseClient(env, user.authorization);
  const { data, error } = await supabase
    .from("laropay_payment_links")
    .select(
      [
        "id",
        "user_id",
        "internal_transaction_id",
        "amount",
        "currency_code",
        "detail",
        "link_id",
        "link_url",
        "status",
        "response_code",
        "response_description",
        "reject_reason",
        "auth_response_code",
        "expires_at",
        "created_at",
      ].join(", "),
    )
    .eq("id", paymentLinkId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (error !== null) {
    throw new Error("invalid_payment_link_query");
  }

  return data as PaymentLinkRow | null;
}

async function callLaropayStatus(
  endpoint: "VerifySecureLink" | "ConsultTransactionInCertifier",
  linkID: string,
  env: Env,
) {
  const url = new URL(`${env.laropayBaseUrl}/api/${endpoint}`);
  url.searchParams.set("IDUser", env.laropayIdUser);
  url.searchParams.set("Token", env.laropayToken);
  url.searchParams.set("LinkID", linkID);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20000);

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "accept": "application/json",
        "authorization": `Basic ${
          btoa(
            `${env.laropayBasicUser}:${env.laropayBasicPassword}`,
          )
        }`,
      },
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

async function persistStatusError(
  env: Env,
  paymentLink: PaymentLinkRow,
  code: string,
  error: unknown,
) {
  await persistStatusCheck(env, paymentLink, {
    status: statusFromLocalExpiration(paymentLink) ?? "pending",
    verifyResponse: {
      response: "NETWORK_ERROR",
      responseDescription: code,
      error: safeError(error),
    },
    certifierResponse: null,
    statusCheckError: code,
  });
}

async function persistStatusCheck(
  env: Env,
  paymentLink: PaymentLinkRow,
  input: {
    status: LaropayStatusOutcome;
    verifyResponse: Record<string, unknown>;
    certifierResponse: Record<string, unknown> | null;
    statusCheckError: string | null;
  },
): Promise<PaymentLinkRow> {
  const supabase = adminSupabaseClient(env);
  const verifyResponse = sanitizeJson(input.verifyResponse);
  const certifierResponse = sanitizeJson(input.certifierResponse ?? {});
  const { data, error } = await supabase.rpc("persist_laropay_status_check", {
    p_payment_link_id: paymentLink.id,
    p_status: input.status,
    p_response_code: stringValue(input.verifyResponse.response),
    p_response_description: responseDescription(input.verifyResponse),
    p_reject_reason: rejectReason(
      input.verifyResponse,
      input.certifierResponse,
    ),
    p_auth_response_code: authResponseCode(input.verifyResponse),
    p_verify_payload: verifyResponse,
    p_certifier_payload: certifierResponse,
    p_status_checked_at: new Date().toISOString(),
    p_status_check_error: input.statusCheckError,
  });

  if (error !== null) {
    throw error;
  }

  if (data === null || typeof data !== "object" || Array.isArray(data)) {
    throw new Error("invalid_status_persistence_response");
  }

  return data as PaymentLinkRow;
}

function statusFromVerifyResponse(
  response: Record<string, unknown>,
  paymentLink: PaymentLinkRow,
): LaropayStatusOutcome {
  const authorizationOutcome = statusFromAuthorizations(
    response.listOfAuthorizations,
  );
  if (authorizationOutcome !== null) {
    return authorizationOutcome;
  }

  const status = stringValue(response.status).toLowerCase();
  const reject = stringValue(response.rejectReason).toLowerCase();
  const authCode = stringValue(response.authResponseCode);
  const description = stringValue(response.responseDescription).toLowerCase();

  if (statusIncludes(status, ["paid", "approved", "completed"])) {
    return "paid";
  }

  if (
    statusIncludes(status, ["reject", "cancel", "failed", "error"]) ||
    reject !== "" ||
    description.includes("rechaz") ||
    (authCode !== "" && authCode !== "00")
  ) {
    return "rejected";
  }

  const localExpiration = statusFromLocalExpiration(paymentLink);
  if (localExpiration !== null) {
    return localExpiration;
  }

  return "pending";
}

function isSuccessfulLaropayResponse(response: Record<string, unknown>) {
  return stringValue(response.response) === "00";
}

function providerErrorCode(
  source: "verify" | "certifier",
  response: Record<string, unknown>,
) {
  const code = stringValue(response.response)
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, "")
    .slice(0, 32);
  return `${source}_${code === "" ? "invalid_response" : code}`;
}

function statusFromAuthorizations(value: unknown): LaropayStatusOutcome | null {
  if (!Array.isArray(value) || value.length === 0) {
    return null;
  }

  let hasDeclinedAuthorization = false;
  for (const item of value) {
    if (item === null || typeof item !== "object") {
      continue;
    }

    const authorization = item as Record<string, unknown>;
    const code = stringValue(
      authorization.autorizationResponseCode ??
        authorization.authorizationResponseCode,
    );

    if (code === "00") {
      return "paid";
    }

    if (code !== "") {
      hasDeclinedAuthorization = true;
    }
  }

  return hasDeclinedAuthorization ? "rejected" : null;
}

function statusFromCertifierResponse(
  response: Record<string, unknown>,
): LaropayStatusOutcome | null {
  const errorCode = stringValue(response.errorCode);
  const errorMessage = stringValue(response.errorMessage).toLowerCase();
  const result = stringValue(response.result).toLowerCase();
  const resultDescription = stringValue(response.resultDescription)
    .toLowerCase();
  const authorizationCode = stringValue(response.authorizationCode);

  if (
    (errorCode !== "" && errorCode !== "00") ||
    errorMessage !== "" ||
    resultDescription.includes("rechaz") ||
    resultDescription.includes("deneg") ||
    resultDescription.includes("failed") ||
    resultDescription.includes("declin") ||
    result === "rejected" ||
    result === "failed" ||
    result === "denied"
  ) {
    return "rejected";
  }

  if (
    authorizationCode !== "" ||
    result === "approved" ||
    result === "paid" ||
    result === "00" ||
    resultDescription.includes("aprob")
  ) {
    return "paid";
  }

  return null;
}

function resolveFinalStatus(input: {
  paymentLink: PaymentLinkRow;
  verifyOutcome: LaropayStatusOutcome;
  certifierOutcome: LaropayStatusOutcome | null;
}): LaropayStatusOutcome {
  if (input.certifierOutcome === "paid" || input.verifyOutcome === "paid") {
    return "paid";
  }

  if (
    input.certifierOutcome === "rejected" ||
    input.verifyOutcome === "rejected"
  ) {
    return "rejected";
  }

  if (
    input.certifierOutcome === "expired" ||
    input.verifyOutcome === "expired" ||
    statusFromLocalExpiration(input.paymentLink) === "expired"
  ) {
    return "expired";
  }

  return "pending";
}

function statusFromLocalExpiration(
  paymentLink: PaymentLinkRow,
): LaropayStatusOutcome | null {
  const expiresAt = Date.parse(stringValue(paymentLink.expires_at));
  if (!Number.isFinite(expiresAt)) {
    return null;
  }

  return expiresAt <= Date.now() ? "expired" : null;
}

function responseDescription(response: Record<string, unknown>) {
  return stringValue(
    response.responseDescription ??
      response.resultDescription ??
      response.errorMessage,
  );
}

function rejectReason(
  verifyResponse: Record<string, unknown>,
  certifierResponse: Record<string, unknown> | null,
) {
  return stringValue(
    verifyResponse.rejectReason ??
      certifierResponse?.errorMessage ??
      certifierResponse?.resultDescription,
  );
}

function authResponseCode(response: Record<string, unknown>) {
  const explicitCode = stringValue(response.authResponseCode);
  if (explicitCode !== "") {
    return explicitCode;
  }

  const authorizations = response.listOfAuthorizations;
  if (!Array.isArray(authorizations)) {
    return "";
  }

  for (const item of authorizations) {
    if (item === null || typeof item !== "object") {
      continue;
    }

    const code = stringValue(
      (item as Record<string, unknown>).autorizationResponseCode ??
        (item as Record<string, unknown>).authorizationResponseCode,
    );
    if (code !== "") {
      return code;
    }
  }

  return "";
}

function responseFromPaymentLink(paymentLink: PaymentLinkRow, cached: boolean) {
  return {
    id: paymentLink.id,
    amount: numberValue(paymentLink.amount),
    currencyCode: stringValue(paymentLink.currency_code) || "CRC",
    detail: stringValue(paymentLink.detail),
    linkID: stringValue(paymentLink.link_id),
    linkURL: stringValue(paymentLink.link_url),
    status: stringValue(paymentLink.status),
    response: stringValue(paymentLink.response_code),
    responseDescription: stringValue(paymentLink.response_description),
    rejectReason: stringValue(paymentLink.reject_reason),
    authResponseCode: stringValue(paymentLink.auth_response_code),
    expiresAt: stringValue(paymentLink.expires_at),
    createdAt: stringValue(paymentLink.created_at),
    cached,
  };
}

function isFinalStatus(status: unknown) {
  return ["paid", "approved", "completed", "rejected", "expired"].includes(
    stringValue(status).toLowerCase(),
  );
}

function statusIncludes(value: string, patterns: string[]) {
  return patterns.some((pattern) => value.includes(pattern));
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
  return [
    "iduser",
    "token",
    "newtoken",
    "authorization",
    "securitycode",
    "cardnumber",
    "autorizationcardnumbermask",
    "authorizationcardnumbermask",
  ].includes(key.toLowerCase());
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
  return createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function stringValue(value: unknown) {
  return typeof value === "string" ? value.trim() : value?.toString().trim() ??
    "";
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

function isSecureUrl(value: string) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname.trim() !== "";
  } catch {
    return false;
  }
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
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

function safeError(error: unknown) {
  if (error instanceof LaropayHttpError) {
    return { status: error.status, body: sanitizeJson(error.body) };
  }

  if (error instanceof DOMException && error.name === "AbortError") {
    return { name: "AbortError" };
  }

  if (error instanceof Error) {
    return { name: error.name, code: safeErrorCode(error.message) };
  }

  return { name: "NonError" };
}

function safeErrorCode(message: string) {
  if (
    message.startsWith("auth_") ||
    message.startsWith("invalid_") ||
    message.startsWith("missing_env_") ||
    message === "payment_link_not_found"
  ) {
    return message;
  }

  return "unexpected_error";
}

function loadEnv(): Env {
  const laropayBaseUrl = requiredEnv("LAROPAY_BASE_URL").replace(/\/+$/, "");

  if (!isSecureUrl(laropayBaseUrl)) {
    throw new Error("missing_env_LAROPAY_BASE_URL");
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
};

class LaropayHttpError extends Error {
  constructor(public readonly status: number, public readonly body: unknown) {
    super("laropay_http_error");
  }
}
