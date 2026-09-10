// Small primitives shared by the Laropay edge functions (CORS headers and
// JSON-value coercion), previously redefined identically -- or, for
// stringValue, near-identically -- in each function's own index.ts.

export const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
};

export function stringValue(value: unknown) {
  return typeof value === "string"
    ? value.trim()
    : value?.toString().trim() ?? "";
}

export function numberValue(value: unknown) {
  if (typeof value === "number") {
    return value;
  }

  if (typeof value === "string") {
    // Number("") and Number("   ") are 0, not NaN -- without this guard an
    // empty/blank string would silently coerce to a "valid" 0 and slip past
    // the Number.isFinite() checks callers use to reject malformed data
    // (e.g. loadOrderPaymentData's quantity/unitPrice validation).
    const trimmed = value.trim();
    return trimmed === "" ? Number.NaN : Number(trimmed);
  }

  return Number.NaN;
}
