// deno-lint-ignore-file no-import-prefix
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export type LaropayTokenEnv = {
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  laropayBaseUrl: string;
  laropayBasicUser: string;
  laropayBasicPassword: string;
  laropayIdUser: string;
  laropayToken: string;
};

export async function loadLaropayRuntimeToken(env: LaropayTokenEnv) {
  const supabase = adminSupabaseClient(env);
  const { data, error } = await supabase
    .from("laropay_runtime_config")
    .select("value")
    .eq("key", "token")
    .maybeSingle();

  if (error !== null) {
    throw error;
  }

  const token = stringValue((data as Record<string, unknown> | null)?.value);
  return token === "" ? env.laropayToken : token;
}

export async function refreshLaropayToken(
  env: LaropayTokenEnv,
  expiredToken: string,
  source: string,
) {
  const currentToken = await loadLaropayRuntimeToken(env);
  if (currentToken !== "" && currentToken !== expiredToken) {
    return currentToken;
  }

  const response = await callLaropayTokenRefresh(env, expiredToken).catch(
    async (error) => {
      const latestToken = await loadLaropayRuntimeToken(env).catch(() => "");
      if (latestToken !== "" && latestToken !== expiredToken) {
        return { response: "00", newToken: latestToken } as Record<
          string,
          unknown
        >;
      }

      await persistTokenRefreshAudit(env, {
        source,
        status: "failed",
        responseCode: "NETWORK_ERROR",
        responseDescription: "Laropay token refresh request failed",
        errorCode: safeErrorCode(error instanceof Error ? error.message : ""),
      });
      return null;
    },
  );

  if (response === null) {
    return null;
  }

  const responseCode = stringValue(response.response);
  const newToken = stringValue(response.newToken);
  const succeeded = responseCode === "00" && newToken !== "";

  if (!succeeded) {
    const latestToken = await loadLaropayRuntimeToken(env).catch(() => "");
    if (latestToken !== "" && latestToken !== expiredToken) {
      return latestToken;
    }

    await persistTokenRefreshAudit(env, {
      source,
      status: "failed",
      responseCode,
      responseDescription: stringValue(response.responseDescription),
      errorCode: tokenRefreshErrorCode(response),
    });
    return null;
  }

  try {
    await persistLaropayRuntimeToken(env, newToken);
  } catch (error) {
    await persistTokenRefreshAudit(env, {
      source,
      status: "failed",
      responseCode,
      responseDescription:
        "Laropay token refresh succeeded but persistence failed",
      errorCode: safeErrorCode(error instanceof Error ? error.message : ""),
    });
    throw error;
  }

  await persistTokenRefreshAudit(env, {
    source,
    status: "succeeded",
    responseCode,
    responseDescription: stringValue(response.responseDescription),
    errorCode: null,
  }).catch(() => undefined);

  return newToken;
}

export function isTokenExpiredResponse(response: Record<string, unknown>) {
  return stringValue(response.response).toUpperCase() === "TE";
}

async function callLaropayTokenRefresh(
  env: LaropayTokenEnv,
  expiredToken: string,
) {
  const url = new URL(`${env.laropayBaseUrl}/api/UpdateSecureLinkToken`);
  url.searchParams.set("IDUser", env.laropayIdUser);
  url.searchParams.set("Token", expiredToken);

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
      throw new LaropayTokenRefreshHttpError(response.status, body);
    }

    return body as Record<string, unknown>;
  } finally {
    clearTimeout(timeout);
  }
}

async function persistLaropayRuntimeToken(
  env: LaropayTokenEnv,
  token: string,
) {
  const supabase = adminSupabaseClient(env);
  const { error } = await supabase
    .from("laropay_runtime_config")
    .upsert({
      key: "token",
      value: token,
      updated_at: new Date().toISOString(),
    });

  if (error !== null) {
    throw error;
  }
}

async function persistTokenRefreshAudit(
  env: LaropayTokenEnv,
  input: {
    source: string;
    status: "succeeded" | "failed";
    responseCode: string;
    responseDescription: string;
    errorCode: string | null;
  },
) {
  const supabase = adminSupabaseClient(env);
  const { error } = await supabase
    .from("laropay_token_refresh_audit")
    .insert({
      source: input.source,
      status: input.status,
      response_code: input.responseCode,
      response_description: input.responseDescription,
      error_code: input.errorCode,
    });

  if (error !== null) {
    throw error;
  }
}

function adminSupabaseClient(env: LaropayTokenEnv) {
  return createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function tokenRefreshErrorCode(response: Record<string, unknown>) {
  const code = stringValue(response.response)
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, "")
    .slice(0, 32);
  return code === "" ? "invalid_token_refresh_response" : `laropay_${code}`;
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

function stringValue(value: unknown) {
  return typeof value === "string" ? value.trim() : value?.toString().trim() ??
    "";
}

class LaropayTokenRefreshHttpError extends Error {
  constructor(public readonly status: number, public readonly body: unknown) {
    super("laropay_token_refresh_http_error");
  }
}
