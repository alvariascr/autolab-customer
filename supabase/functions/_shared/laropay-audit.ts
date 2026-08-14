// deno-lint-ignore-file no-import-prefix
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export type LaropayPaymentEventInput = {
  paymentLinkId?: string;
  orderId?: string;
  source: string;
  eventType: string;
  status?: string;
  responseCode?: string;
  responseDescription?: string;
  rejectReason?: string;
  authResponseCode?: string;
  payload?: unknown;
};

export async function recordLaropayPaymentEvent(
  supabase: SupabaseClient,
  input: LaropayPaymentEventInput,
) {
  const { error } = await supabase
    .from("laropay_payment_events")
    .insert({
      payment_link_id: uuidOrNull(input.paymentLinkId),
      order_id: uuidOrNull(input.orderId),
      source: input.source,
      event_type: input.eventType,
      status: nullableString(input.status),
      response_code: nullableString(input.responseCode),
      response_description: nullableString(input.responseDescription),
      reject_reason: nullableString(input.rejectReason),
      auth_response_code: nullableString(input.authResponseCode),
      provider_payload: sanitizeJson(input.payload ?? {}),
    });

  if (error !== null) {
    console.error("laropay_payment_event_audit_failed", {
      source: input.source,
      eventType: input.eventType,
      code: safeErrorCode(error.message),
    });
  }
}

export function laropayEventTypeFromResponse(
  response: Record<string, unknown>,
  successEventType: string,
) {
  const code = stringValue(response.response);
  if (code === "TIMEOUT") {
    return "timeout";
  }

  if (code === "NETWORK_ERROR") {
    return "network_error";
  }

  if (code === "HTTP_ERROR") {
    return "http_error";
  }

  if (code === "TOKEN_REFRESH_FAILED") {
    return "token_refresh_failed";
  }

  if (code === "TE") {
    return "token_expired";
  }

  if (code !== "" && code !== "00") {
    return "provider_rejected";
  }

  return successEventType;
}

export function sanitizeJson(value: unknown): unknown {
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

function uuidOrNull(value: unknown) {
  const text = stringValue(value);
  return isUuid(text) ? text : null;
}

function nullableString(value: unknown) {
  const text = stringValue(value);
  return text === "" ? null : text;
}

function stringValue(value: unknown) {
  return typeof value === "string" ? value.trim() : value?.toString().trim() ??
    "";
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
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

function safeErrorCode(message: string) {
  const normalized = message
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_|_$/g, "");

  return normalized.slice(0, 64) || "unknown_error";
}
