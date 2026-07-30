# Configuracion operativa de Laropay

Este documento describe como configurar, desplegar y validar la integracion de
Laropay en `autolabCustomer` sin exponer credenciales en frontend, logs o
repositorio.

## Componentes

La integracion esta separada en tres Edge Functions:

- `laropay-generate-link`: genera el link de pago y registra la auditoria inicial.
- `laropay-check-status`: consulta el estado real del pago contra Laropay.
- `laropay-return`: recibe el retorno visual de Laropay y redirige al deep link de la app.

La confirmacion final del pago no se toma del retorno visual del usuario. La app
debe consultar `laropay-check-status`, que valida el resultado con Laropay desde
backend.

## Secrets requeridos

Configurar estos secrets en Supabase:

```powershell
npx supabase secrets set LAROPAY_BASE_URL=https://...
npx supabase secrets set LAROPAY_BASIC_USER=...
npx supabase secrets set LAROPAY_BASIC_PASSWORD=...
npx supabase secrets set LAROPAY_ID_USER=...
npx supabase secrets set LAROPAY_TOKEN=...
npx supabase secrets set LAROPAY_CALLBACK_URL=https://<project-ref>.functions.supabase.co/laropay-return
npx supabase secrets set LAROPAY_TRANSACTION_TYPE=1
```

Tambien deben existir los secrets propios de Supabase:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Para validar que existen sin revelar valores:

```powershell
npx supabase secrets list
```

## Seguridad de secretos

El token de Laropay no debe aparecer en:

- codigo fuente
- logs de Flutter
- respuestas de Edge Functions
- errores visibles al usuario
- capturas o evidencia compartida

Las Edge Functions redactan llaves sensibles antes de persistir auditoria. Los
campos sensibles como `idUser`, `token`, `newToken`, `authorization` y
`securityCode` se guardan como `<redacted>` cuando forman parte de payloads
tecnicos.

## Token runtime y renovacion

El token inicial vive en `LAROPAY_TOKEN`. Cuando Laropay responde `TE`
(`TOKEN EXPIRED`), el backend intenta renovar el token con:

```text
GET /api/UpdateSecureLinkToken
```

Si la renovacion es exitosa:

- el nuevo token se guarda en `public.laropay_runtime_config`
- se registra auditoria en `public.laropay_token_refresh_audit`
- la misma operacion reintenta automaticamente con el token nuevo
- el usuario no debe ver un error solo porque el token anterior vencio

La tabla `public.laropay_runtime_config` debe tener RLS habilitado y solo ser
manipulada por backend con service role.

## Despliegue

Desplegar las Edge Functions:

```powershell
npx supabase functions deploy laropay-generate-link
npx supabase functions deploy laropay-check-status
npx supabase functions deploy laropay-return
```

Si solo se cambian migraciones SQL, no hace falta desplegar Edge Functions. Si se
cambian archivos dentro de `supabase/functions`, si debe desplegarse la funcion
afectada.

## Validaciones antes de generar link

`laropay-generate-link` valida desde backend:

- usuario autenticado
- `internalTransactionId` valido
- orden existente
- orden perteneciente al usuario
- `payment_status = unpaid`
- monto solicitado contra el subtotal cobrable
- correo del cliente
- URL base y callback seguros
- tipo de transaccion permitido

El frontend no envia ni conoce `idUser` ni `token`.

## Reutilizacion de links

El backend reserva un registro interno antes de llamar a Laropay. Si ya existe
un link activo para la misma orden, se reutiliza cuando corresponde. Si hay una
generacion en curso, la funcion responde con error controlado para evitar dobles
generaciones accidentales.

Estados finales como `paid`, `rejected` o `expired` no deben reutilizarse como
links activos.

## Callback y deep link

`laropay-return` recibe `paymentLinkId`, valida que exista en
`public.laropay_payment_links` y que apunte a una orden real. Luego obtiene el
`workshop_id` desde la orden y redirige al deep link:

```text
autolab://laropay-callback/payment-return?workshopId=<workshop-id>&paymentLinkId=<payment-link-id>
```

El callback no marca pagos como aprobados. Solo devuelve al usuario a la app.
La confirmacion de pago se realiza con `laropay-check-status`.

## Consulta de estado

`laropay-check-status` consume:

- `GET /api/VerifySecureLink`
- `GET /api/ConsultTransactionInCertifier`

El estado interno se persiste con la RPC:

```text
public.persist_laropay_status_check
```

Cuando Laropay confirma pago aprobado:

- `laropay_payment_links.status` queda en `paid`
- la orden se actualiza segun los pagos registrados
- se inserta un registro en `public.payments`
- se guarda respuesta tecnica para auditoria

Si Laropay responde pendiente, rechazo, vencido, error o no responde, el sistema
no marca la orden como pagada.

## Timeouts y retry

Las llamadas a Laropay tienen timeout controlado de 20 segundos. Los reintentos
estan limitados a los casos donde Laropay indica token vencido (`TE`) y el
backend logra obtener un token nuevo.

Errores de red, HTTP o timeout se registran como respuestas controladas y no
exponen secretos.

## Queries de evidencia

Ultimos links generados:

```sql
select
  id,
  internal_transaction_id,
  link_id,
  amount,
  currency_code,
  status,
  response_code,
  response_description,
  created_at,
  status_checked_at
from public.laropay_payment_links
order by created_at desc
limit 10;
```

Auditoria de payloads tecnicos:

```sql
select
  id,
  link_id,
  status,
  request_payload,
  response_payload,
  verify_payload,
  certifier_payload,
  status_check_error,
  created_at,
  status_checked_at
from public.laropay_payment_links
order by created_at desc
limit 5;
```

Pagos Laropay registrados en la tabla de pagos:

```sql
select
  p.id,
  p.order_id,
  o.order_number,
  p.amount,
  pm.name as payment_method,
  p.payment_date,
  p.reference_number,
  p.notes
from public.payments p
join public.orders o on o.id = p.order_id
join public.payment_methods pm on pm.id = p.payment_method_id
where p.reference_number like 'LAROPAY:%'
order by p.payment_date desc
limit 10;
```

Estado de orden contra link Laropay:

```sql
select
  lpl.id as payment_link_id,
  lpl.link_id,
  lpl.status as laropay_status,
  lpl.amount as laropay_amount,
  o.id as order_id,
  o.order_number,
  o.payment_status,
  o.total_amount,
  o.paid_amount,
  o.remaining_amount
from public.laropay_payment_links lpl
join public.orders o on o.id = lpl.internal_transaction_id::uuid
order by lpl.created_at desc
limit 10;
```

Auditoria de refresh de token:

```sql
select
  source,
  status,
  response_code,
  response_description,
  error_code,
  created_at
from public.laropay_token_refresh_audit
order by created_at desc
limit 10;
```

Token runtime vigente sin revelar el valor:

```sql
select
  key,
  updated_at,
  length(value) as token_length
from public.laropay_runtime_config
where key = 'token';
```

## Checklist para cierre de tarea

- Secrets configurados en Supabase.
- Edge Functions desplegadas.
- Migraciones aplicadas.
- Generacion de link exitosa en ambiente de pruebas.
- Retorno visual redirige a la app.
- Consulta de estado confirma `paid`, `pending`, `rejected`, `expired` o `failed`.
- Pago aprobado se refleja en `orders`, `laropay_payment_links` y `payments`.
- Token vencido se refresca automaticamente y queda auditado.
- Evidencia no contiene token, Basic Auth, service role ni datos sensibles sin redaccion.

## Cambio de ambiente

Para cambiar entre pruebas, staging y produccion:

1. Actualizar `LAROPAY_BASE_URL`.
2. Actualizar `LAROPAY_BASIC_USER` y `LAROPAY_BASIC_PASSWORD`.
3. Actualizar `LAROPAY_ID_USER`.
4. Actualizar `LAROPAY_TOKEN`.
5. Actualizar `LAROPAY_CALLBACK_URL` con la URL del proyecto Supabase correcto.
6. Confirmar `LAROPAY_TRANSACTION_TYPE`.
7. Desplegar las Edge Functions si el proyecto Supabase es distinto.
8. Ejecutar prueba de generacion y consulta de estado.

No se debe cambiar ninguna credencial desde Flutter ni desde el repositorio.
