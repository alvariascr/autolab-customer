create table if not exists public.laropay_response_code_catalog (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  code text not null,
  description text not null,
  category text not null default 'provider',
  is_success boolean not null default false,
  is_retryable boolean not null default false,
  created_at timestamptz not null default now(),
  constraint laropay_response_code_catalog_source_check check (
    source in ('generate_link', 'verify_secure_link', 'certifier')
  ),
  constraint laropay_response_code_catalog_category_check check (
    category in ('success', 'pending', 'declined', 'configuration', 'provider', 'security', 'network', 'unknown')
  ),
  constraint laropay_response_code_catalog_code_not_blank check (btrim(code) <> ''),
  constraint laropay_response_code_catalog_description_not_blank check (btrim(description) <> '')
);

alter table public.laropay_response_code_catalog enable row level security;

create unique index if not exists laropay_response_code_catalog_source_code_description_idx
  on public.laropay_response_code_catalog(source, code, description);

revoke all on public.laropay_response_code_catalog from public, anon, authenticated;
grant select, insert, update on public.laropay_response_code_catalog to service_role;

create policy laropay_response_code_catalog_service_role_all
  on public.laropay_response_code_catalog
  for all
  to service_role
  using (true)
  with check (true);

create table if not exists public.laropay_payment_events (
  id uuid primary key default gen_random_uuid(),
  payment_link_id uuid references public.laropay_payment_links(id) on delete cascade,
  order_id uuid references public.orders(id) on delete cascade,
  source text not null,
  event_type text not null,
  status text,
  response_code text,
  response_description text,
  reject_reason text,
  auth_response_code text,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint laropay_payment_events_source_check check (
    source in ('generate_link', 'verify_secure_link', 'certifier', 'token_refresh', 'checkout')
  ),
  constraint laropay_payment_events_event_type_check check (
    event_type in (
      'provider_response',
      'provider_rejected',
      'network_error',
      'timeout',
      'http_error',
      'invalid_response',
      'token_expired',
      'token_refresh_failed',
      'status_persisted',
      'status_persist_failed',
      'checkout_open_failed'
    )
  )
);

alter table public.laropay_payment_events enable row level security;

create index if not exists laropay_payment_events_payment_link_id_idx
  on public.laropay_payment_events(payment_link_id, created_at desc);

create index if not exists laropay_payment_events_order_id_idx
  on public.laropay_payment_events(order_id, created_at desc);

create index if not exists laropay_payment_events_source_code_idx
  on public.laropay_payment_events(source, response_code, created_at desc);

revoke all on public.laropay_payment_events from public, anon, authenticated;
grant insert, select on public.laropay_payment_events to service_role;

create policy laropay_payment_events_service_role_all
  on public.laropay_payment_events
  for all
  to service_role
  using (true)
  with check (true);

insert into public.laropay_response_code_catalog
  (source, code, description, category, is_success, is_retryable)
values
  ('generate_link', '00', 'OK', 'success', true, false),
  ('generate_link', 'IR', 'INVALID REQUEST', 'configuration', false, false),
  ('generate_link', 'IU', 'INVALID USER', 'configuration', false, false),
  ('generate_link', 'II', 'INVALID IDUSER', 'configuration', false, false),
  ('generate_link', 'UT', 'USER TRIES', 'security', false, false),
  ('generate_link', 'IT', 'INVALID TOKEN', 'configuration', false, false),
  ('generate_link', 'IY', 'INVALID AMOUNT TYPE', 'configuration', false, false),
  ('generate_link', 'IA', 'INVALID AMOUNT', 'configuration', false, false),
  ('generate_link', 'TO', 'INVALID USER TOKEN', 'configuration', false, false),
  ('generate_link', 'TE', 'TOKEN EXPIRED', 'configuration', false, true),
  ('generate_link', 'IG', 'INVALID GROUP', 'configuration', false, false),
  ('generate_link', 'ID', 'INVALID DEVICE', 'configuration', false, false),
  ('generate_link', 'TT', 'INVALID TRANSACTION-TERMINAL', 'configuration', false, false),
  ('generate_link', '96', 'SYSTEM ERROR', 'provider', false, true),
  ('generate_link', 'IL', 'INVALID LINKID', 'provider', false, false),
  ('generate_link', 'LN', 'LINK NOT EXIST', 'provider', false, false),
  ('generate_link', 'ER', 'SECURITY ERROR', 'security', false, false),
  ('generate_link', 'FI', 'INVALID FIRST NAME', 'configuration', false, false),
  ('generate_link', 'LA', 'INVALID LAST NAME', 'configuration', false, false),
  ('generate_link', 'UK', 'INVALID UNIQUEKEY', 'configuration', false, false),
  ('generate_link', 'UN', 'UNIQUEKEY NOT EXIST', 'configuration', false, false),
  ('generate_link', 'HTTP_ERROR', 'Laropay rejected the HTTP request', 'network', false, true),
  ('generate_link', 'TIMEOUT', 'Laropay request timed out', 'network', false, true),
  ('generate_link', 'NETWORK_ERROR', 'Laropay request failed before response', 'network', false, true),
  ('generate_link', 'TOKEN_REFRESH_FAILED', 'Laropay token refresh failed', 'configuration', false, true),
  ('verify_secure_link', '00', 'APROBADO', 'success', true, false),
  ('verify_secure_link', '01', 'REFIERASE A EMISOR', 'declined', false, false),
  ('verify_secure_link', '02', 'REFIERASE A EMISOR ESPECIAL', 'declined', false, false),
  ('verify_secure_link', '03', 'COMERCIO INVALIDO', 'configuration', false, false),
  ('verify_secure_link', '05', 'DECLINAR LA OPERACION', 'declined', false, false),
  ('verify_secure_link', '06', 'ERROR', 'provider', false, true),
  ('verify_secure_link', '09', 'PETICION EN PROGRESO', 'pending', false, true),
  ('verify_secure_link', '12', 'TRANSACCION INVALIDA', 'declined', false, false),
  ('verify_secure_link', '13', 'CANTIDAD INVALIDA', 'configuration', false, false),
  ('verify_secure_link', '14', 'NUMERO DE TARJETA INVALIDO', 'declined', false, false),
  ('verify_secure_link', '15', 'BIN INVALIDO', 'declined', false, false),
  ('verify_secure_link', '17', 'CANCELACION DEL CLIENTE', 'declined', false, false),
  ('verify_secure_link', '30', 'ERROR DE FORMATO', 'configuration', false, false),
  ('verify_secure_link', '31', 'BANCO RECHAZO POR EL SWITCH', 'declined', false, false),
  ('verify_secure_link', '32', 'COMPLETADO PARCIALMENTE', 'pending', false, true),
  ('verify_secure_link', '51', 'FONDOS INSUFICIENTES', 'declined', false, false),
  ('verify_secure_link', '54', 'TARJETA EXPIRADA', 'declined', false, false),
  ('verify_secure_link', '55', 'PIN INVALIDO', 'declined', false, false),
  ('verify_secure_link', '57', 'TRANSACCION NO PERMITIDA', 'declined', false, false),
  ('verify_secure_link', '58', 'TRANSACCION NO PERMITIDA TERMINAL', 'declined', false, false),
  ('verify_secure_link', '63', 'VIOLACION DE SEGURIDAD', 'security', false, false),
  ('verify_secure_link', '82', 'DECLINADA', 'declined', false, false),
  ('verify_secure_link', '88', 'DECLINADA', 'declined', false, false),
  ('verify_secure_link', '89', 'INVALID TERMINALID', 'configuration', false, false),
  ('verify_secure_link', '90', 'CORTE EN PROCESO REINTENTE', 'provider', false, true),
  ('verify_secure_link', '91', 'EMISOR O SWITCH INOPERATIVO', 'provider', false, true),
  ('verify_secure_link', '92', 'NO SE PUEDE ENRUTAR', 'provider', false, true),
  ('verify_secure_link', '94', 'TRANSMISION DUPLICADA', 'provider', false, false),
  ('verify_secure_link', '96', 'ERROR DEL SISTEMA', 'provider', false, true),
  ('verify_secure_link', '97', 'DOCUMENTO INVALIDO', 'configuration', false, false),
  ('verify_secure_link', 'CV', 'INVALID CVV2', 'declined', false, false),
  ('verify_secure_link', 'ED', 'INVALID EXPIRATION DATE', 'declined', false, false),
  ('verify_secure_link', 'IK', 'INVALID KEY SENT', 'configuration', false, false),
  ('verify_secure_link', 'IM', 'MERCHANT NOT EXIST', 'configuration', false, false),
  ('verify_secure_link', 'IS', 'INVALID MERCHANT STATUS', 'configuration', false, false),
  ('verify_secure_link', 'KE', 'KEY EXPIRED', 'configuration', false, true),
  ('verify_secure_link', 'KN', 'MERCHANT NOT HAVE KEY', 'configuration', false, false),
  ('verify_secure_link', 'MA', 'INVALID MAXIMUN AMOUNT', 'configuration', false, false),
  ('verify_secure_link', 'MV', 'INVALID MACVALUE', 'security', false, false),
  ('verify_secure_link', 'PC', 'INVALID PROCESSING CODE', 'configuration', false, false),
  ('verify_secure_link', 'RT', 'REINTENTE OTRA VEZ', 'provider', false, true)
on conflict (source, code, description) do update
set
  category = excluded.category,
  is_success = excluded.is_success,
  is_retryable = excluded.is_retryable;

insert into public.laropay_response_code_catalog
  (source, code, description, category, is_success, is_retryable)
values
  ('generate_link', 'ID', 'INVALID USER DOMAIN', 'configuration', false, false),
  ('generate_link', '96', 'SYSTEM ERROR 1', 'provider', false, true),
  ('generate_link', '96', 'SYSTEM ERROR 2', 'provider', false, true),
  ('generate_link', '96', 'SYSTEM ERROR 3', 'provider', false, true),
  ('generate_link', '96', 'SYSTEM ERROR 4', 'provider', false, true),
  ('verify_secure_link', '04', 'RETENGA LA TARJETA', 'declined', false, false),
  ('verify_secure_link', '07', 'RETENGA LA TARJETA ESPECIAL', 'declined', false, false),
  ('verify_secure_link', '08', 'ACEPTE CON IDENTIFICACION', 'pending', false, false),
  ('verify_secure_link', '16', 'APROBADO ACTUALIZE PISTA 3', 'success', true, false),
  ('verify_secure_link', '18', 'DISPUTA DEL CLIENTE', 'declined', false, false),
  ('verify_secure_link', '19', 'REINGRESE LA TRANSACCION', 'provider', false, true),
  ('verify_secure_link', '20', 'RESPUESTA INVALIDA', 'provider', false, true),
  ('verify_secure_link', '21', 'NO SE TOMO ACCION', 'provider', false, true),
  ('verify_secure_link', '22', 'MAL FUNCIONAMIENTO SOSPECHOSO', 'security', false, false),
  ('verify_secure_link', '23', 'CANTIDAD INACEPTABLE', 'configuration', false, false),
  ('verify_secure_link', '24', 'MANTENIMIENTO DE ARCHIVO', 'provider', false, true),
  ('verify_secure_link', '25', 'MANTENIMIENTO DE ARCHIVO', 'provider', false, true),
  ('verify_secure_link', '26', 'MANTENIMIENTO DE ARCHIVO', 'provider', false, true),
  ('verify_secure_link', '27', 'MANTENIMIENTO DE ARCHIVO', 'provider', false, true),
  ('verify_secure_link', '28', 'MANTENIMIENTO DE ARCHIVO', 'provider', false, true),
  ('verify_secure_link', '29', 'MANTENIMIENTO DE ARCHIVO', 'provider', false, true),
  ('verify_secure_link', '33', 'TARJETA EXPIRADA RETENGALA', 'declined', false, false),
  ('verify_secure_link', '34', 'SOSPECHO DE FRAUDE RETENGA', 'security', false, false),
  ('verify_secure_link', '35', 'CONTACTE ADQUIRENTE RETENGA', 'declined', false, false),
  ('verify_secure_link', '36', 'TARJETA RESTRINGIDA RETENGA', 'declined', false, false),
  ('verify_secure_link', '37', 'LLAME AL ADQUIRENTE RETENGA', 'declined', false, false),
  ('verify_secure_link', '38', 'INTENTOS DE PIN PERMITOS', 'declined', false, false),
  ('verify_secure_link', '39', 'NO TIENE CUENTA DE CREDITO', 'declined', false, false),
  ('verify_secure_link', '40', 'FUNCION NO SOPORTADA', 'configuration', false, false),
  ('verify_secure_link', '41', 'TARJETA EXTRAVIA RETENGA', 'declined', false, false),
  ('verify_secure_link', '42', 'NO HAY CUENTA UNIVERSAL', 'declined', false, false),
  ('verify_secure_link', '43', 'TARJETA ROBADA RETENGA', 'security', false, false),
  ('verify_secure_link', '44', 'NO HAY CUENTA DE INVERSION', 'declined', false, false),
  ('verify_secure_link', '45', 'REVERSADO', 'declined', false, false),
  ('verify_secure_link', '46', 'REVERSADO', 'declined', false, false),
  ('verify_secure_link', '47', 'REVERSADO', 'declined', false, false),
  ('verify_secure_link', '48', 'REVERSADO', 'declined', false, false),
  ('verify_secure_link', '49', 'REVERSADO', 'declined', false, false),
  ('verify_secure_link', '50', 'REVERSADO', 'declined', false, false),
  ('verify_secure_link', '52', 'NO HAY CUENTA CORRIENTE', 'declined', false, false),
  ('verify_secure_link', '53', 'NO HAY CUENTA DE AHORRO', 'declined', false, false),
  ('verify_secure_link', '56', 'NO HAY REGISTRO DE LA TARJETA', 'declined', false, false),
  ('verify_secure_link', '59', 'FRAUDE SOSPECHADO', 'security', false, false),
  ('verify_secure_link', '60', 'CONTACTE AL ADQUIRENTE', 'declined', false, false),
  ('verify_secure_link', '61', 'EXCEDE EL LIMITE DE LA CUENTA', 'declined', false, false),
  ('verify_secure_link', '62', 'TARJETA RESTRINGIDA', 'declined', false, false),
  ('verify_secure_link', '64', 'CANTIDAD ORIGINAL INCORRECTA', 'configuration', false, false),
  ('verify_secure_link', '65', 'EXCEDE LA FRECUENCIA DE RETIRO', 'declined', false, false),
  ('verify_secure_link', '66', 'LLAME LA SEGURIDAD DEL ADQUIRENTE', 'declined', false, false),
  ('verify_secure_link', '67', 'RETENER LA TARJETA EN EL ATM', 'declined', false, false),
  ('verify_secure_link', '68', 'RESERVADO', 'unknown', false, false),
  ('verify_secure_link', '69', 'RESERVADO', 'unknown', false, false),
  ('verify_secure_link', '70', 'RESERVADO', 'unknown', false, false),
  ('verify_secure_link', '71', 'RESERVADO', 'unknown', false, false),
  ('verify_secure_link', '72', 'RESERVADO', 'unknown', false, false),
  ('verify_secure_link', '73', 'RESERVADO', 'unknown', false, false),
  ('verify_secure_link', '74', 'RESERVADO', 'unknown', false, false),
  ('verify_secure_link', '75', 'INTENTOS DE PIN EXCEDIDOS', 'declined', false, false),
  ('verify_secure_link', '76', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '77', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '78', 'REFIERASE AL EMISOR', 'declined', false, false),
  ('verify_secure_link', '79', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '80', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '81', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '83', 'DECLINADA', 'declined', false, false),
  ('verify_secure_link', '84', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '85', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '86', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '87', 'PRIVADO', 'unknown', false, false),
  ('verify_secure_link', '93', 'VIOLACION DE LA LEY', 'security', false, false),
  ('verify_secure_link', '95', 'ERROR DE RECONCILIACION', 'provider', false, true),
  ('verify_secure_link', '98', 'NACIONAL', 'unknown', false, false),
  ('verify_secure_link', '99', 'NACIONAL', 'unknown', false, false),
  ('verify_secure_link', 'A1', 'VER LIMITES ESPECIALES', 'declined', false, false),
  ('verify_secure_link', 'A2', 'VER LIMITES ESPECIALES', 'declined', false, false),
  ('verify_secure_link', 'A3', 'VER LIMITES ESPECIALES', 'declined', false, false),
  ('verify_secure_link', 'A4', 'VER LIMITES ESPECIALES', 'declined', false, false),
  ('verify_secure_link', 'A5', 'VER LIMITES ESPECIALES', 'declined', false, false),
  ('verify_secure_link', 'A6', 'VER LIMITES ESPECIALES', 'declined', false, false),
  ('verify_secure_link', 'A7', 'VER LIMITES ESPECIALES', 'declined', false, false),
  ('verify_secure_link', 'A8', 'VER LIMITES ESPECIALES', 'declined', false, false)
on conflict (source, code, description) do update
set
  category = excluded.category,
  is_success = excluded.is_success,
  is_retryable = excluded.is_retryable;

insert into public.laropay_response_code_catalog
  (source, code, description, category, is_success, is_retryable)
select
  'certifier',
  code,
  description,
  category,
  is_success,
  is_retryable
from public.laropay_response_code_catalog
where source = 'verify_secure_link'
on conflict (source, code, description) do update
set
  category = excluded.category,
  is_success = excluded.is_success,
  is_retryable = excluded.is_retryable;

notify pgrst, 'reload schema';
