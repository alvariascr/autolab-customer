import { assertEquals } from "jsr:@std/assert";
import {
  type LaropayLinkRequest,
  normalizedExpirationType,
  normalizedExpirationValue,
  validate,
} from "./validation.ts";

function validRequest(
  overrides: Partial<LaropayLinkRequest> = {},
): LaropayLinkRequest {
  return {
    internalTransactionId: "order-1",
    amount: 1000,
    customerFirstName: "Juan",
    customerLastName: "Perez",
    customerEmail: "juan@example.com",
    ...overrides,
  };
}

Deno.test("validate acepta un request completo y valido", () => {
  assertEquals(validate(validRequest()), null);
});

Deno.test("validate rechaza cuando falta internalTransactionId", () => {
  assertEquals(
    validate(validRequest({ internalTransactionId: "" })),
    "internal_transaction_required",
  );
});

Deno.test("validate rechaza un monto invalido, cero o negativo", () => {
  assertEquals(
    validate(validRequest({ amount: undefined })),
    "amount_invalid",
  );
  assertEquals(validate(validRequest({ amount: 0 })), "amount_invalid");
  assertEquals(validate(validRequest({ amount: -5 })), "amount_invalid");
  assertEquals(
    validate(validRequest({ amount: Number.NaN })),
    "amount_invalid",
  );
});

Deno.test("validate rechaza cuando falta el nombre o apellido del cliente", () => {
  assertEquals(
    validate(validRequest({ customerFirstName: "" })),
    "customer_first_name_required",
  );
  assertEquals(
    validate(validRequest({ customerLastName: "" })),
    "customer_last_name_required",
  );
});

Deno.test("validate rechaza un correo con formato invalido", () => {
  assertEquals(
    validate(validRequest({ customerEmail: "no-es-un-correo" })),
    "customer_email_invalid",
  );
});

Deno.test("validate rechaza un expirationType que no sea D, H o M", () => {
  assertEquals(
    validate(validRequest({ expirationType: "X" })),
    "expiration_type_invalid",
  );
});

Deno.test("validate rechaza un expirationValue no entero o no positivo", () => {
  assertEquals(
    validate(validRequest({ expirationValue: 0 })),
    "expiration_value_invalid",
  );
  assertEquals(
    validate(validRequest({ expirationValue: 1.5 })),
    "expiration_value_invalid",
  );
});

Deno.test("normalizedExpirationType usa D por defecto y pasa a mayusculas", () => {
  assertEquals(normalizedExpirationType(validRequest()), "D");
  assertEquals(
    normalizedExpirationType(validRequest({ expirationType: "h" })),
    "H",
  );
});

Deno.test("normalizedExpirationValue usa 1 por defecto", () => {
  assertEquals(normalizedExpirationValue(validRequest()), 1);
  assertEquals(
    normalizedExpirationValue(validRequest({ expirationValue: 5 })),
    5,
  );
});
