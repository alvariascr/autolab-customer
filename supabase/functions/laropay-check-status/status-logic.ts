// Pure payment-status decision logic, split out from index.ts so it can be
// unit tested without pulling in the Deno.serve HTTP handler (importing
// index.ts directly binds a network listener as a side effect of module
// load, which fails outside the edge runtime).
import { stringValue } from "../_shared/laropay-common.ts";

export type PaymentLinkRow = {
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

export type LaropayStatusOutcome =
  | "paid"
  | "pending"
  | "rejected"
  | "expired"
  | "failed"
  | "cancelled";

// On this gateway (Cloud2Pay/Pay-me), the top-level `response` field is
// always "00" regardless of outcome -- the real result lives inside
// listOfAuthorizations[].autorizationResponseCode/Description. When the
// customer explicitly cancels, Laropay's own "Motivo de Cancelacion" dialog
// echoes back one of its fixed reasons in that description field. These are
// the exhaustive set of reasons offered by that dialog (confirmed against a
// live test), not a guess from the static response-code catalog.
const EXPLICIT_CANCELLATION_REASONS = [
  "no reconoce el cargo",
  "rechazo por monto invalido",
  "ya no requiere servicio",
];

const _combiningDiacriticsPattern = new RegExp("[\\u0300-\\u036f]", "g");
const _whitespacePattern = new RegExp("\\s+", "g");

export function isExplicitCancellationDescription(value: unknown) {
  const normalized = stringValue(value)
    .toLowerCase()
    .normalize("NFD")
    .replace(_combiningDiacriticsPattern, "")
    .replace(_whitespacePattern, " ")
    .trim();
  if (normalized === "") {
    return false;
  }
  return EXPLICIT_CANCELLATION_REASONS.some((reason) =>
    normalized.includes(reason)
  );
}

export function statusFromAuthorizations(
  value: unknown,
): LaropayStatusOutcome | null {
  if (!Array.isArray(value) || value.length === 0) {
    return null;
  }

  let hasPaidAuthorization = false;
  let hasDeclinedAuthorization = false;
  for (const item of value) {
    if (item === null || typeof item !== "object") {
      continue;
    }

    const authorization = item as Record<string, unknown>;

    // Checked before the "00" success code, and for every entry rather than
    // stopping at the first "00": a later authorization in the same array
    // can report a reversal/cancellation of an earlier successful one, and
    // that signal must win regardless of where it appears in the array.
    if (
      isExplicitCancellationDescription(
        authorization.autorizationResponseCodeDescription ??
          authorization.authorizationResponseCodeDescription,
      )
    ) {
      return "cancelled";
    }

    const code = stringValue(
      authorization.autorizationResponseCode ??
        authorization.authorizationResponseCode,
    );

    if (code === "00") {
      hasPaidAuthorization = true;
    } else if (code !== "") {
      hasDeclinedAuthorization = true;
    }
  }

  if (hasPaidAuthorization) {
    return "paid";
  }

  return hasDeclinedAuthorization ? "rejected" : null;
}

export function resolveFinalStatus(input: {
  paymentLink: PaymentLinkRow;
  verifyOutcome: LaropayStatusOutcome;
  certifierOutcome: LaropayStatusOutcome | null;
}): LaropayStatusOutcome {
  // An explicit cancellation is checked ahead of "paid": it's a stronger
  // business signal than an authorization code, and should win even if a
  // "paid" outcome was also present from the same or the other source.
  if (
    input.certifierOutcome === "cancelled" ||
    input.verifyOutcome === "cancelled"
  ) {
    return "cancelled";
  }

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

export function statusFromLocalExpiration(
  paymentLink: PaymentLinkRow,
): LaropayStatusOutcome | null {
  const expiresAt = Date.parse(stringValue(paymentLink.expires_at));
  if (!Number.isFinite(expiresAt)) {
    return null;
  }

  return expiresAt <= Date.now() ? "expired" : null;
}
