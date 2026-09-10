import { assertEquals } from "jsr:@std/assert";
import { numberValue, stringValue } from "./laropay-common.ts";

Deno.test("stringValue no lanza error con null o undefined", () => {
  assertEquals(stringValue(null), "");
  assertEquals(stringValue(undefined), "");
});

Deno.test("stringValue convierte numeros y booleanos a texto", () => {
  assertEquals(stringValue(123), "123");
  assertEquals(stringValue(true), "true");
});

Deno.test("stringValue recorta espacios", () => {
  assertEquals(stringValue("  00  "), "00");
});

Deno.test("numberValue retorna NaN para un string vacio o solo espacios", () => {
  assertEquals(Number.isNaN(numberValue("")), true);
  assertEquals(Number.isNaN(numberValue("   ")), true);
});

Deno.test("numberValue parsea numeros con espacios alrededor", () => {
  assertEquals(numberValue(" 123.45 "), 123.45);
});

Deno.test("numberValue retorna NaN para objetos, arreglos y booleanos", () => {
  assertEquals(Number.isNaN(numberValue({})), true);
  assertEquals(Number.isNaN(numberValue([])), true);
  assertEquals(Number.isNaN(numberValue(true)), true);
});
