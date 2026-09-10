// Pure request-validation logic, split out from index.ts so it can be unit
// tested without pulling in the Deno.serve HTTP handler (importing index.ts
// directly binds a network listener as a side effect of module load, which
// fails outside the edge runtime).
import { stringValue } from "../_shared/laropay-common.ts";

export type LaropayLinkRequest = {
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

export function validate(input: LaropayLinkRequest): string | null {
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

export function normalizedExpirationType(input: LaropayLinkRequest) {
  return stringValue(input.expirationType || "D").toUpperCase();
}

export function normalizedExpirationValue(input: LaropayLinkRequest) {
  return input.expirationValue ?? 1;
}
