-- MIT-143 follow-up: when a customer cancels their own appointment from
-- "Mis citas", the whole associated order must be cancelled and its
-- resources released (product stock restored, order_products/appointments
-- marked cancelled, any pending Laropay link cancelled) -- exactly like the
-- Laropay-explicit-cancel and TTL-sweep paths already do via
-- cancel_order_and_release_resources (202608190001/202608190003). Until now
-- cancel_customer_appointment only flipped the appointment row itself,
-- leaving the order/products/stock untouched.
--
-- The eligibility guard (order still in draft/pending/scheduled, appointment
-- still scheduled and in the future, belongs to the caller) is unchanged
-- from 202608200001 -- it's re-checked here before calling the shared
-- function, and cancel_order_and_release_resources re-validates order_status
-- again internally under its own advisory lock, so this stays safe even if
-- the order's state changes concurrently.
create or replace function public.cancel_customer_appointment(
  p_appointment_id uuid,
  p_reason text,
  p_comments text default null::text
)
returns uuid
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_note text;
  v_reason text;
  v_order_id uuid;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception using message = 'appointment_auth_required';
  end if;

  v_reason := coalesce(nullif(trim(p_reason), ''), 'Sin motivo');

  v_note := 'Cancelada por cliente: ' || v_reason;

  if p_comments is not null and trim(p_comments) <> '' then
    v_note := v_note || E'\nComentarios: ' || trim(p_comments);
  end if;

  select o.id
  into v_order_id
  from public.appointments a
  join public.order_services os on os.id = a.order_service_id
  join public.orders o on o.id = os.order_id
  join public.customers c on c.id = o.customer_id
  where a.id = p_appointment_id
    and a.appointment_status = 'scheduled'
    and a.scheduled_datetime > now()
    and c.user_id = v_user_id
    and o.order_status::text in ('draft', 'pending', 'scheduled');

  if v_order_id is null then
    raise exception using message = 'appointment_not_cancelable';
  end if;

  v_result := public.cancel_order_and_release_resources(
    v_order_id,
    'customer_cancelled_appointment',
    v_user_id
  );

  if coalesce((v_result ->> 'skipped')::boolean, false)
    or coalesce((v_result ->> 'alreadyCancelled')::boolean, false)
  then
    raise exception using message = 'appointment_not_cancelable';
  end if;

  update public.appointments a
  set
    note = case
      when coalesce(trim(a.note), '') = '' then v_note
      else a.note || E'\n' || v_note
    end,
    updated_by = v_user_id::text,
    updated_at = now()
  where a.id = p_appointment_id;

  return p_appointment_id;
end;
$function$;

-- No grant/revoke here: CREATE OR REPLACE FUNCTION preserves the existing
-- privileges on this function since the signature is unchanged.

notify pgrst, 'reload schema';
