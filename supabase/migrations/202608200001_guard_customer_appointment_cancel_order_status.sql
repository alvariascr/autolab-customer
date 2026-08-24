-- MIT-143 follow-up: cancel_customer_appointment already blocks cancellation
-- once the appointment's own scheduled_datetime has passed, but it never
-- looked at the order's own order_status. That leaves a gap: if the
-- workshop marks the order in_progress *before* the scheduled time (the
-- customer dropped the vehicle off early and work already started), the
-- customer could still cancel from the app even though parts/labor are
-- already committed. Add the same order_status allow-list already used by
-- cancel_order_and_release_resources (202608190003) so both cancellation
-- paths -- explicit Laropay cancel / TTL sweep, and the customer's own
-- "Mis citas" cancel -- agree on when a repair is still safely cancelable.
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
begin
  if v_user_id is null then
    raise exception using message = 'appointment_auth_required';
  end if;

  v_reason := coalesce(nullif(trim(p_reason), ''), 'Sin motivo');

  v_note := 'Cancelada por cliente: ' || v_reason;

  if p_comments is not null and trim(p_comments) <> '' then
    v_note := v_note || E'\nComentarios: ' || trim(p_comments);
  end if;

  update public.appointments a
  set
    appointment_status = 'cancelled',
    cancelled_at = now(),
    cancelled_by = v_user_id,
    cancellation_reason = v_reason,
    note = case
      when coalesce(trim(a.note), '') = '' then v_note
      else a.note || E'\n' || v_note
    end,
    updated_by = v_user_id::text,
    updated_at = now()
  where a.id = p_appointment_id
    and a.appointment_status = 'scheduled'
    and a.scheduled_datetime > now()
    and exists (
      select 1
      from public.order_services os
      join public.orders o on os.order_id = o.id
      join public.customers c on o.customer_id = c.id
      where os.id = a.order_service_id
        and c.user_id = v_user_id
        and o.order_status::text in ('draft', 'pending', 'scheduled')
    );

  if not found then
    raise exception using message = 'appointment_not_cancelable';
  end if;

  return p_appointment_id;
end;
$function$;

-- No grant/revoke here: CREATE OR REPLACE FUNCTION preserves the existing
-- privileges on this function since the signature is unchanged.

notify pgrst, 'reload schema';
