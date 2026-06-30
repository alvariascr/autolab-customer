-- Service appointments are reservations, not payment attempts. The booking RPC
-- creates their order first, so clear its temporary payment expiration as soon
-- as the related appointment exists. Product checkout remains independent.
create or replace function public.keep_appointment_order_active()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.orders o
  set
    payment_expires_at = null,
    updated_at = now()
  from public.order_services os
  where os.id = new.order_service_id
    and o.id = os.order_id
    and o.payment_status = 'unpaid';

  return new;
end;
$$;

drop trigger if exists keep_appointment_order_active
on public.appointments;

create trigger keep_appointment_order_active
after insert on public.appointments
for each row
execute function public.keep_appointment_order_active();

-- Existing appointments must continue blocking their reserved time slots.
update public.orders o
set
  payment_expires_at = null,
  updated_at = now()
where o.payment_status = 'unpaid'
  and o.payment_expires_at is not null
  and exists (
    select 1
    from public.order_services os
    join public.appointments a on a.order_service_id = os.id
    where os.order_id = o.id
  );

notify pgrst, 'reload schema';
