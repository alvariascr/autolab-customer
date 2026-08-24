alter table public.notifications
add column if not exists event_key text;

create unique index if not exists notifications_event_key_unique
on public.notifications (event_key)
where event_key is not null;

create or replace function public.notify_customer_appointment_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_workshop_id uuid;
  v_title text;
  v_body text;
  v_event_key text;
begin
  select c.user_id, o.workshop_id
  into v_user_id, v_workshop_id
  from public.order_services os
  join public.orders o on o.id = os.order_id
  join public.customers c on c.id = o.customer_id
  where os.id = new.order_service_id;

  if v_user_id is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    v_title := 'Cita confirmada';
    v_body := 'Tu cita fue programada para el ' ||
      to_char(new.scheduled_datetime at time zone 'America/Costa_Rica', 'DD/MM/YYYY HH24:MI') || '.';
    v_event_key := 'appointment_confirmed:' || new.id::text;
  elsif new.appointment_status::text in ('cancelled', 'canceled')
    and old.appointment_status::text not in ('cancelled', 'canceled') then
    v_title := 'Cita cancelada';
    v_body := 'Tu cita fue cancelada. Revisa Mis citas para consultar los detalles.';
    v_event_key := 'appointment_cancelled:' || new.id::text;
  elsif new.scheduled_datetime is distinct from old.scheduled_datetime then
    v_title := 'Cita reprogramada';
    v_body := 'Tu cita fue reprogramada para el ' ||
      to_char(new.scheduled_datetime at time zone 'America/Costa_Rica', 'DD/MM/YYYY HH24:MI') || '.';
    v_event_key := 'appointment_rescheduled:' || new.id::text || ':' ||
      extract(epoch from new.scheduled_datetime)::bigint::text;
  else
    return new;
  end if;

  insert into public.notifications (
    user_id, workshop_id, title, body, type, event_key
  ) values (
    v_user_id, v_workshop_id, v_title, v_body, 'appointment', v_event_key
  ) on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists notify_customer_appointment_change
on public.appointments;

create trigger notify_customer_appointment_change
after insert or update of appointment_status, scheduled_datetime
on public.appointments
for each row execute function public.notify_customer_appointment_change();

create or replace function public.notify_customer_payment_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  if new.payment_status is not distinct from old.payment_status then
    return new;
  end if;

  select c.user_id into v_user_id
  from public.customers c
  where c.id = new.customer_id;

  if v_user_id is null then
    return new;
  end if;

  insert into public.notifications (
    user_id, workshop_id, title, body, type, event_key
  ) values (
    v_user_id,
    new.workshop_id,
    'Estado de pago actualizado',
    'El pago de la orden ' || coalesce(new.order_number, 'sin número') ||
      ' ahora está: ' || coalesce(new.payment_status::text, 'desconocido') || '.',
    'payment',
    'order_payment:' || new.id::text || ':' ||
      coalesce(new.payment_status::text, 'unknown')
  ) on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists notify_customer_payment_change
on public.orders;

create trigger notify_customer_payment_change
after update of payment_status
on public.orders
for each row execute function public.notify_customer_payment_change();

create or replace function public.notify_customer_vehicle_ready()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_workshop_id uuid;
begin
  select c.user_id, o.workshop_id
  into v_user_id, v_workshop_id
  from public.appointments a
  join public.order_services os on os.id = a.order_service_id
  join public.orders o on o.id = os.order_id
  join public.customers c on c.id = o.customer_id
  where a.id = new.appointment_id;

  if v_user_id is null then
    return new;
  end if;

  insert into public.notifications (
    user_id, workshop_id, title, body, type, event_key
  ) values (
    v_user_id,
    v_workshop_id,
    'Tu vehículo está listo',
    'El taller finalizó el servicio. Tu vehículo está listo para ser retirado.',
    'vehicle',
    'vehicle_ready:' || new.appointment_id::text
  ) on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists notify_customer_vehicle_ready
on public.appointment_check_outs;

create trigger notify_customer_vehicle_ready
after insert on public.appointment_check_outs
for each row execute function public.notify_customer_vehicle_ready();

create or replace function public.notify_message_recipient()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient_id uuid;
begin
  select case
    when new.is_from_sender then c.receiver_id
    else c.sender_id
  end
  into v_recipient_id
  from public.conversations c
  where c.id = new.conversation_id;

  if v_recipient_id is null then
    return new;
  end if;

  insert into public.notifications (
    user_id, title, body, type, event_key
  ) values (
    v_recipient_id,
    'Nuevo mensaje de ' || coalesce(new.sender_name, 'Autolab'),
    left(coalesce(new.content, 'Tienes un nuevo mensaje.'), 180),
    'message',
    'message:' || new.id::text
  ) on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists notify_message_recipient
on public.messages;

create trigger notify_message_recipient
after insert on public.messages
for each row execute function public.notify_message_recipient();

create or replace function public.create_upcoming_appointment_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer;
begin
  insert into public.notifications (
    user_id, workshop_id, title, body, type, event_key
  )
  select
    c.user_id,
    o.workshop_id,
    'Tu cita se acerca',
    'Recuerda que tienes una cita el ' ||
      to_char(a.scheduled_datetime at time zone 'America/Costa_Rica', 'DD/MM/YYYY HH24:MI') || '.',
    'appointment',
    'appointment_reminder:' || a.id::text
  from public.appointments a
  join public.order_services os on os.id = a.order_service_id
  join public.orders o on o.id = os.order_id
  join public.customers c on c.id = o.customer_id
  where c.user_id is not null
    and a.appointment_status::text not in ('cancelled', 'canceled', 'completed', 'no_show')
    and a.scheduled_datetime > now()
    and a.scheduled_datetime <= now() + interval '24 hours'
  on conflict do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

revoke all on function public.create_upcoming_appointment_reminders()
from public, anon, authenticated;

grant execute on function public.create_upcoming_appointment_reminders()
to service_role;

create or replace function public.notify_customers_of_promotion(
  p_title text,
  p_body text,
  p_workshop_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer;
  v_campaign_key text := gen_random_uuid()::text;
begin
  if nullif(trim(p_title), '') is null or nullif(trim(p_body), '') is null then
    raise exception 'promotion title and body are required' using errcode = '22023';
  end if;

  insert into public.notifications (
    user_id, workshop_id, title, body, type, event_key
  )
  select distinct
    c.user_id,
    p_workshop_id,
    trim(p_title),
    trim(p_body),
    'promotion',
    'promotion:' || v_campaign_key || ':' || c.user_id::text
  from public.customers c
  where c.user_id is not null
    and (p_workshop_id is null or c.workshop_id = p_workshop_id);

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

revoke all on function public.notify_customers_of_promotion(text, text, uuid)
from public, anon, authenticated;

grant execute on function public.notify_customers_of_promotion(text, text, uuid)
to service_role;

create extension if not exists pg_cron;

do $$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id
  from cron.job
  where jobname = 'create-upcoming-appointment-reminders';

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;

  perform cron.schedule(
    'create-upcoming-appointment-reminders',
    '*/15 * * * *',
    'select public.create_upcoming_appointment_reminders();'
  );
end;
$$;
