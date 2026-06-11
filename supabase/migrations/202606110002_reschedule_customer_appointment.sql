create or replace function public.reschedule_customer_appointment(
  p_appointment_id uuid,
  p_scheduled_datetime timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using message = 'appointment_auth_required';
  end if;

  if p_scheduled_datetime is null or p_scheduled_datetime <= now() then
    raise exception using message = 'appointment_datetime_in_past';
  end if;

  update public.appointments a
  set
    scheduled_datetime = p_scheduled_datetime,
    updated_by = v_user_id::text,
    updated_at = now()
  where a.id = p_appointment_id
    and a.appointment_status = 'scheduled'
    and a.scheduled_datetime > now()
    and exists (
      select 1
      from public.order_services os
      join public.orders o on o.id = os.order_id
      join public.customers c on c.id = o.customer_id
      where os.id = a.order_service_id
        and c.user_id = v_user_id
    );

  if not found then
    raise exception using message = 'appointment_not_reschedulable';
  end if;

  return p_appointment_id;
end;
$$;

revoke all on function public.reschedule_customer_appointment(
  uuid,
  timestamptz
) from public;

grant execute on function public.reschedule_customer_appointment(
  uuid,
  timestamptz
) to authenticated;

notify pgrst, 'reload schema';
