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
    return Number(value);
  }

  return Number.NaN;
}
