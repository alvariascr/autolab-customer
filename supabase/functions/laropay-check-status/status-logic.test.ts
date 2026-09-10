import { assertEquals } from "jsr:@std/assert";
import {
  isExplicitCancellationDescription,
  type LaropayStatusOutcome,
  type PaymentLinkRow,
  resolveFinalStatus,
  statusFromAuthorizations,
} from "./status-logic.ts";

function paymentLink(overrides: Partial<PaymentLinkRow> = {}): PaymentLinkRow {
  return {
    id: "link-1",
    user_id: "user-1",
    internal_transaction_id: "order-1",
    amount: 1000,
    currency_code: "CRC",
    detail: null,
    link_id: "abc",
    link_url: "https://pay.test/abc",
    status: "pending",
    response_code: null,
    response_description: null,
    reject_reason: null,
    auth_response_code: null,
    expires_at: null,
    created_at: null,
    ...overrides,
  };
}

Deno.test("statusFromAuthorizations retorna null para un arreglo vacio o invalido", () => {
  assertEquals(statusFromAuthorizations(null), null);
  assertEquals(statusFromAuthorizations([]), null);
  assertEquals(statusFromAuthorizations("not an array"), null);
});

Deno.test("statusFromAuthorizations retorna paid cuando una autorizacion tiene codigo 00", () => {
  const result = statusFromAuthorizations([
    { autorizationResponseCode: "00" },
  ]);
  assertEquals(result, "paid");
});

Deno.test("statusFromAuthorizations detecta la cancelacion aunque venga despues de un 00 (finding #15)", () => {
  const result = statusFromAuthorizations([
    { autorizationResponseCode: "00" },
    {
      autorizationResponseCodeDescription: "No reconoce el cargo",
    },
  ]);
  assertEquals(result, "cancelled");
});

Deno.test("statusFromAuthorizations detecta la cancelacion cuando viene antes de un 00", () => {
  const result = statusFromAuthorizations([
    {
      autorizationResponseCodeDescription: "Ya no requiere servicio",
    },
    { autorizationResponseCode: "00" },
  ]);
  assertEquals(result, "cancelled");
});

Deno.test("statusFromAuthorizations retorna rejected cuando hay codigos declinados sin pago ni cancelacion", () => {
  const result = statusFromAuthorizations([
    { autorizationResponseCode: "05" },
  ]);
  assertEquals(result, "rejected");
});

Deno.test("statusFromAuthorizations tambien reconoce autorizationResponseCode bien escrito", () => {
  const result = statusFromAuthorizations([
    { authorizationResponseCode: "00" },
  ]);
  assertEquals(result, "paid");
});

Deno.test("statusFromAuthorizations ignora espacios accidentales en el codigo de respuesta", () => {
  const result = statusFromAuthorizations([
    { autorizationResponseCode: "00 " },
  ]);
  assertEquals(result, "paid");
});

Deno.test("statusFromAuthorizations retorna null cuando ninguna entrada trae codigo ni descripcion", () => {
  const result = statusFromAuthorizations([{}]);
  assertEquals(result, null);
});

Deno.test("isExplicitCancellationDescription reconoce las razones conocidas sin importar mayusculas/acentos", () => {
  assertEquals(
    isExplicitCancellationDescription("RECHAZO POR MONTO INVÁLIDO"),
    true,
  );
  assertEquals(
    isExplicitCancellationDescription("ya NO requiere servicio"),
    true,
  );
});

Deno.test("isExplicitCancellationDescription retorna false para texto vacio o sin relacion", () => {
  assertEquals(isExplicitCancellationDescription(""), false);
  assertEquals(isExplicitCancellationDescription(null), false);
  assertEquals(isExplicitCancellationDescription("aprobada"), false);
});

Deno.test("resolveFinalStatus prioriza cancelled sobre paid (finding #15)", () => {
  const result = resolveFinalStatus({
    paymentLink: paymentLink(),
    verifyOutcome: "cancelled",
    certifierOutcome: "paid",
  });
  assertEquals(result, "cancelled");
});

Deno.test("resolveFinalStatus prioriza paid sobre rejected/expired", () => {
  const result = resolveFinalStatus({
    paymentLink: paymentLink(),
    verifyOutcome: "paid",
    certifierOutcome: "rejected",
  });
  assertEquals(result, "paid");
});

Deno.test("resolveFinalStatus prioriza rejected sobre expired", () => {
  const result = resolveFinalStatus({
    paymentLink: paymentLink(),
    verifyOutcome: "rejected",
    certifierOutcome: "expired",
  });
  assertEquals(result, "rejected");
});

Deno.test("resolveFinalStatus cae en expired cuando el link ya vencio localmente", () => {
  const result = resolveFinalStatus({
    paymentLink: paymentLink({ expires_at: "2000-01-01T00:00:00.000Z" }),
    verifyOutcome: "pending",
    certifierOutcome: null,
  });
  assertEquals(result, "expired");
});

Deno.test("resolveFinalStatus cae en pending cuando nada mas aplica", () => {
  const outcome: LaropayStatusOutcome = "pending";
  const result = resolveFinalStatus({
    paymentLink: paymentLink({ expires_at: null }),
    verifyOutcome: outcome,
    certifierOutcome: null,
  });
  assertEquals(result, "pending");
});
