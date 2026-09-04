-- Fix: reschedule_customer_appointment only checked ownership, status, and
-- that the new time was in the future -- it never re-ran the
-- capacity/business-hours/slot-duration validation that
-- book_service_appointment performs when an appointment is first booked.
-- This let a reschedule land on an already-full slot, a closed day, or a
-- non-30-minute-aligned time, silently double-booking a workshop.
--
-- Rather than duplicating that ~90-line validation block a second time
-- (which is exactly how it drifted out of sync before), it's extracted into
-- a shared function, assert_appointment_slot_available(), and both
-- book_service_appointment and reschedule_customer_appointment now call it.
-- Behavior for booking is unchanged -- same checks, same exception
-- messages, same advisory-lock granularity -- just no longer inlined twice.

create or replace function public.assert_appointment_slot_available(
  p_workshop_id uuid,
  p_inventory_item_id uuid,
  p_scheduled_datetime timestamp with time zone,
  p_exclude_appointment_id uuid default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_service_name text;
  v_duration_hours numeric;
  v_is_inspection_service boolean;
  v_scheduled_end_datetime timestamp with time zone;
  v_open_datetime timestamp with time zone;
  v_close_datetime timestamp with time zone;
  v_employee_capacity integer := 0;
  v_is_closed boolean;
  v_open_time time;
  v_close_time time;
  v_scheduled_date date;
begin
  select ii.name, ii.estimated_duration_hours
  into v_service_name, v_duration_hours
  from public.inventory_items ii
  where ii.id = p_inventory_item_id
    and ii.workshop_id = p_workshop_id
    and ii.item_type = 'service'
    and ii.status = 'active'
    and ii.is_schedulable = true
    and ii.requires_appointment = true
  limit 1;

  if not found then
    raise exception using message = 'appointment_service_not_schedulable';
  end if;

  if v_duration_hours is null or v_duration_hours <= 0 then
    raise exception using message = 'appointment_service_duration_required';
  end if;

  -- book_service_appointment enforces this same 30-minute alignment on
  -- p_scheduled_time before it ever reaches here; reschedule_customer_appointment
  -- has no equivalent client-side picker constraint, so it must be
  -- re-checked here to keep both entry points aligned to the same slot grid.
  if extract(
       minute from (p_scheduled_datetime at time zone 'America/Costa_Rica')
     )::int not in (0, 30)
     or extract(
          second from (p_scheduled_datetime at time zone 'America/Costa_Rica')
        )::int <> 0 then
    raise exception using message = 'appointment_invalid_slot_interval';
  end if;

  v_is_inspection_service := public.is_inspection_service_name(v_service_name);

  v_scheduled_end_datetime :=
    p_scheduled_datetime
      + make_interval(secs => (v_duration_hours * 3600)::double precision);

  select count(*)
  into v_employee_capacity
  from public.employees e
  where e.workshop_id = p_workshop_id
    and e.is_active = true;

  if v_employee_capacity <= 0 then
    raise exception using message = 'appointment_no_active_employees';
  end if;

  v_scheduled_date :=
    (p_scheduled_datetime at time zone 'America/Costa_Rica')::date;

  select
    bh.is_closed,
    bh.open_time,
    bh.close_time
  into
    v_is_closed,
    v_open_time,
    v_close_time
  from public.business_hours bh
  where bh.workshop_id = p_workshop_id
    and bh.day_of_week = extract(isodow from v_scheduled_date)::integer - 1
  limit 1;

  if v_is_closed is null then
    raise exception using message = 'appointment_business_hours_unavailable';
  end if;

  if v_is_closed = true then
    raise exception using message = 'appointment_workshop_closed';
  end if;

  if v_open_time is null or v_close_time is null then
    raise exception using message = 'appointment_business_hours_unavailable';
  end if;

  v_open_datetime :=
    (v_scheduled_date + v_open_time) at time zone 'America/Costa_Rica';

  v_close_datetime :=
    (v_scheduled_date + v_close_time) at time zone 'America/Costa_Rica';

  if p_scheduled_datetime < v_open_datetime
     or p_scheduled_datetime >= v_close_datetime
     or v_scheduled_end_datetime > v_close_datetime then
    raise exception using message = 'appointment_outside_business_hours';
  end if;

  perform pg_advisory_xact_lock(
    hashtext('workshop_appointment_capacity|' || p_workshop_id::text)::bigint
  );

  if v_is_inspection_service then
    if (
      select count(*)
      from public.appointments a
      join public.order_services os on os.id = a.order_service_id
      join public.orders o on o.id = os.order_id
      join public.inventory_items ii on ii.id = os.inventory_item_id
      where o.workshop_id = p_workshop_id
        and a.appointment_status not in ('cancelled', 'no_show')
        and (
          p_exclude_appointment_id is null
          or a.id <> p_exclude_appointment_id
        )
        and public.is_inspection_service_name(ii.name)
        and a.scheduled_datetime >= date_trunc('hour', p_scheduled_datetime)
        and a.scheduled_datetime < date_trunc('hour', p_scheduled_datetime) + interval '1 hour'
    ) >= (v_employee_capacity * 2) then
      raise exception using message = 'appointment_slot_unavailable';
    end if;
  elsif exists (
    with candidate_segments as (
      select
        segment_start,
        least(
          segment_start + interval '30 minutes',
          v_scheduled_end_datetime
        ) as segment_end
      from generate_series(
        p_scheduled_datetime,
        v_scheduled_end_datetime - interval '1 microsecond',
        interval '30 minutes'
      ) as segments(segment_start)
    ),
    existing_appointments as (
      select
        a.id,
        a.scheduled_datetime as starts_at,
        a.scheduled_datetime
          + make_interval(
              secs => (
                coalesce(nullif(ii.estimated_duration_hours, 0), 0.5) * 3600
              )::double precision
            ) as ends_at
      from public.appointments a
      join public.order_services os on os.id = a.order_service_id
      join public.orders o on o.id = os.order_id
      join public.inventory_items ii on ii.id = os.inventory_item_id
      where o.workshop_id = p_workshop_id
        and a.appointment_status not in ('cancelled', 'no_show')
        and (
          p_exclude_appointment_id is null
          or a.id <> p_exclude_appointment_id
        )
        and not public.is_inspection_service_name(ii.name)
        and a.scheduled_datetime < v_scheduled_end_datetime
        and (
          a.scheduled_datetime
            + make_interval(
                secs => (
                  coalesce(nullif(ii.estimated_duration_hours, 0), 0.5) * 3600
                )::double precision
              )
        ) > p_scheduled_datetime
    ),
    segment_occupancy as (
      select
        cs.segment_start,
        count(ea.id) as overlapping_appointments
      from candidate_segments cs
      left join existing_appointments ea
        on ea.starts_at < cs.segment_end
       and ea.ends_at > cs.segment_start
      group by cs.segment_start
    )
    select 1
    from segment_occupancy
    where overlapping_appointments >= v_employee_capacity
  ) then
    raise exception using message = 'appointment_slot_unavailable';
  end if;
end;
$function$;

revoke all on function public.assert_appointment_slot_available(
  uuid, uuid, timestamp with time zone, uuid
) from public, anon, authenticated;

-- book_service_appointment: identical behavior, now delegating its
-- capacity/business-hours/overlap validation to the shared function above
-- instead of inlining it. Everything else (auth, product validation/stock
-- reservation from 202609030001, vehicle handling, order/appointment
-- creation) is unchanged.
create or replace function public.book_service_appointment(
  p_workshop_id uuid,
  p_inventory_item_id uuid,
  p_scheduled_date date,
  p_scheduled_time time without time zone,
  p_products jsonb default '[]'::jsonb,
  p_note text default null::text,
  p_vehicle_id uuid default null::uuid,
  p_garage_vehicle_id uuid default null::uuid,
  p_license_plate text default null::text,
  p_vehicle_brand text default null::text,
  p_vehicle_year integer default null::integer,
  p_vehicle_color text default null::text,
  p_fuel_type fuel_type default null::fuel_type,
  p_transmission_type transmission_type default null::transmission_type,
  p_vehicle_type text default null::text,
  p_vehicle_model text default null::text
)
returns uuid
language plpgsql
security definer
set search_path to 'public', 'auth'
as $function$
declare
  v_user_id uuid;
  v_profile_name text;
  v_profile_phone text;
  v_profile_email text;

  v_customer_id uuid;
  v_vehicle_id uuid;
  v_order_id uuid;
  v_order_service_id uuid;
  v_appointment_id uuid;
  v_unit_price numeric;
  v_products_total numeric := 0;
  v_order_number text;
  v_license_plate text;
  v_product record;
  v_validated_products jsonb := '[]'::jsonb;
  v_valid_product_count integer := 0;

  v_scheduled_datetime timestamp with time zone;

  v_existing_brand text;
  v_existing_year integer;
  v_existing_color text;
  v_existing_fuel_type fuel_type;
  v_existing_transmission_type transmission_type;
  v_existing_vehicle_type text;
  v_existing_vehicle_model text;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception using message = 'appointment_auth_required';
  end if;

  v_scheduled_datetime :=
    (p_scheduled_date + p_scheduled_time) at time zone 'America/Costa_Rica';

  if v_scheduled_datetime <= now() then
    raise exception using message = 'appointment_datetime_in_past';
  end if;

  if extract(minute from p_scheduled_time)::int not in (0, 30) then
    raise exception using message = 'appointment_invalid_slot_interval';
  end if;

  if p_products is null or jsonb_typeof(p_products) <> 'array' then
    raise exception using message = 'appointment_products_invalid';
  end if;

  select up.name, up.phone, up.email
  into v_profile_name, v_profile_phone, v_profile_email
  from public.user_profiles up
  where up.user_id = v_user_id
  limit 1;

  if coalesce(trim(v_profile_name), '') = '' then
    raise exception using message = 'appointment_customer_name_required';
  end if;

  if coalesce(trim(v_profile_phone), '') = '' then
    raise exception using message = 'appointment_customer_phone_required';
  end if;

  select ii.selling_price
  into v_unit_price
  from public.inventory_items ii
  where ii.id = p_inventory_item_id
    and ii.workshop_id = p_workshop_id
    and ii.item_type = 'service'
    and ii.status = 'active'
    and ii.is_schedulable = true
    and ii.requires_appointment = true
  limit 1;

  if not found then
    raise exception using message = 'appointment_service_not_schedulable';
  end if;

  perform public.assert_appointment_slot_available(
    p_workshop_id,
    p_inventory_item_id,
    v_scheduled_datetime,
    null
  );

  for v_product in
    select
      ii.id,
      ii.selling_price,
      coalesce(ii.current_stock, 0) as current_stock,
      agg.quantity,
      agg.raw_count
    from (
      select
        raw_id,
        sum(quantity)::integer as quantity,
        count(*)::integer as raw_count
      from (
        select
          coalesce(
            nullif(value ->> 'inventoryItemId', ''),
            nullif(value ->> 'inventory_item_id', ''),
            nullif(value ->> 'id', '')
          ) as raw_id,
          case
            when nullif(value ->> 'quantity', '') is null then 1
            when (value ->> 'quantity') ~ '^[0-9]{1,3}$'
              then (value ->> 'quantity')::integer
            else 0
          end as quantity
        from jsonb_array_elements(p_products) as input(value)
      ) as product_item
      group by raw_id
    ) as agg
    join public.inventory_items ii
      on ii.id = case
        when agg.raw_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          then agg.raw_id::uuid
        else null
      end
    where ii.workshop_id = p_workshop_id
      and ii.status = 'active'
      and ii.item_type <> 'service'
    order by ii.id
    for no key update of ii
  loop
    if v_product.quantity <= 0 or v_product.quantity > 999 then
      raise exception using message = 'appointment_products_invalid';
    end if;

    if v_product.selling_price is null or v_product.selling_price <= 0 then
      raise exception using message = 'appointment_product_price_required';
    end if;

    if v_product.current_stock < v_product.quantity then
      raise exception using message = 'appointment_product_stock_unavailable';
    end if;

    v_valid_product_count := v_valid_product_count + v_product.raw_count;
    v_validated_products :=
      v_validated_products ||
      jsonb_build_object(
        'id', v_product.id,
        'selling_price', v_product.selling_price,
        'quantity', v_product.quantity
      );

    v_products_total :=
      v_products_total + (v_product.selling_price * v_product.quantity);
  end loop;

  if v_valid_product_count <> jsonb_array_length(p_products) then
    raise exception using message = 'appointment_products_invalid';
  end if;

  if jsonb_array_length(p_products) > 0 and v_products_total <= 0 then
    raise exception using message = 'appointment_products_invalid';
  end if;

  v_customer_id := public.get_or_create_customer_for_workshop(
    p_workshop_id := p_workshop_id,
    p_name := v_profile_name,
    p_phone := v_profile_phone,
    p_email := v_profile_email,
    p_identification := null
  );

  if p_vehicle_id is not null then
    select v.id
    into v_vehicle_id
    from public.vehicles v
    where v.id = p_vehicle_id
      and v.customer_id = v_customer_id
      and v.is_active = true
    limit 1;

    if v_vehicle_id is null then
      raise exception using message = 'appointment_vehicle_not_owned_by_customer';
    end if;

  elsif p_garage_vehicle_id is not null then
    select
      gv.license_plate,
      gv.brand,
      gv.year,
      gv.color,
      gv.fuel_type,
      gv.transmission_type,
      gv.vehicle_type,
      gv.model
    into
      v_license_plate,
      v_existing_brand,
      v_existing_year,
      v_existing_color,
      v_existing_fuel_type,
      v_existing_transmission_type,
      v_existing_vehicle_type,
      v_existing_vehicle_model
    from public.garage_vehicles gv
    where gv.id = p_garage_vehicle_id
      and gv.user_id = v_user_id
      and gv.is_active = true
    limit 1;

    if v_license_plate is null then
      raise exception using message = 'appointment_vehicle_not_owned_by_customer';
    end if;

    v_license_plate := upper(trim(v_license_plate));

    perform pg_advisory_xact_lock(
      hashtext(v_customer_id::text || '|' || v_license_plate)::bigint
    );

    select v.id
    into v_vehicle_id
    from public.vehicles v
    where v.customer_id = v_customer_id
      and v.license_plate = v_license_plate
      and v.is_active = true
    limit 1;

    if v_vehicle_id is null then
      insert into public.vehicles (
        customer_id,
        license_plate,
        vehicle_type,
        brand,
        model,
        year,
        color,
        fuel_type,
        transmission_type,
        is_active
      )
      values (
        v_customer_id,
        v_license_plate,
        v_existing_vehicle_type,
        v_existing_brand,
        v_existing_vehicle_model,
        v_existing_year,
        v_existing_color,
        v_existing_fuel_type,
        v_existing_transmission_type,
        true
      )
      returning id into v_vehicle_id;
    end if;

  else
    v_license_plate := upper(trim(coalesce(p_license_plate, '')));

    if v_license_plate = '' then
      raise exception using message = 'appointment_vehicle_required';
    end if;

    perform pg_advisory_xact_lock(
      hashtext(v_customer_id::text || '|' || v_license_plate)::bigint
    );

    select
      v.id,
      v.brand,
      v.year,
      v.color,
      v.fuel_type,
      v.transmission_type,
      v.vehicle_type,
      v.model
    into
      v_vehicle_id,
      v_existing_brand,
      v_existing_year,
      v_existing_color,
      v_existing_fuel_type,
      v_existing_transmission_type,
      v_existing_vehicle_type,
      v_existing_vehicle_model
    from public.vehicles v
    where v.customer_id = v_customer_id
      and v.license_plate = v_license_plate
      and v.is_active = true
    limit 1;

    if v_vehicle_id is not null then
      if (
        nullif(trim(coalesce(p_vehicle_brand, '')), '') is not null
        and lower(trim(v_existing_brand)) is distinct from lower(trim(p_vehicle_brand))
      )
      or (
        p_vehicle_year is not null
        and v_existing_year is distinct from p_vehicle_year
      )
      or (
        nullif(trim(coalesce(p_vehicle_color, '')), '') is not null
        and lower(trim(v_existing_color)) is distinct from lower(trim(p_vehicle_color))
      )
      or (
        p_fuel_type is not null
        and v_existing_fuel_type is distinct from p_fuel_type
      )
      or (
        p_transmission_type is not null
        and v_existing_transmission_type is distinct from p_transmission_type
      )
      or (
        nullif(trim(coalesce(p_vehicle_type, '')), '') is not null
        and lower(trim(v_existing_vehicle_type)) is distinct from lower(trim(p_vehicle_type))
      )
      or (
        nullif(trim(coalesce(p_vehicle_model, '')), '') is not null
        and lower(trim(v_existing_vehicle_model)) is distinct from lower(trim(p_vehicle_model))
      )
      then
        raise exception using message = 'appointment_vehicle_plate_conflict';
      end if;
    else
      insert into public.vehicles (
        customer_id,
        license_plate,
        vehicle_type,
        brand,
        model,
        year,
        color,
        fuel_type,
        transmission_type,
        is_active
      )
      values (
        v_customer_id,
        v_license_plate,
        nullif(trim(coalesce(p_vehicle_type, '')), ''),
        nullif(trim(coalesce(p_vehicle_brand, '')), ''),
        nullif(trim(coalesce(p_vehicle_model, '')), ''),
        p_vehicle_year,
        nullif(trim(coalesce(p_vehicle_color, '')), ''),
        p_fuel_type,
        p_transmission_type,
        true
      )
      returning id into v_vehicle_id;
    end if;
  end if;

  v_order_number :=
    'APP-' ||
    to_char(now(), 'YYYYMMDD') ||
    '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  -- Customer-created orders keep the full commercial total for MiTaller.
  -- Laropay still charges only additional products from order_products;
  -- the service balance remains payable directly at the workshop.
  insert into public.orders (
    order_number,
    workshop_id,
    customer_id,
    order_status,
    payment_status,
    payment_expires_at,
    total_amount,
    paid_amount,
    remaining_amount
  )
  values (
    v_order_number,
    p_workshop_id,
    v_customer_id,
    'pending',
    'unpaid',
    null,
    v_unit_price + v_products_total,
    0,
    v_unit_price + v_products_total
  )
  returning id into v_order_id;

  insert into public.order_services (
    order_id,
    inventory_item_id,
    quantity,
    unit_price,
    service_status
  )
  values (
    v_order_id,
    p_inventory_item_id,
    1,
    v_unit_price,
    'scheduled'
  )
  returning id into v_order_service_id;

  -- Reserve stock atomically at insert time (mirrors create_cart_order),
  -- re-checking current_stock in the WHERE clause to guard against a race
  -- with another booking/checkout between the validation loop above and here.
  for v_product in
    select
      id,
      selling_price,
      quantity
    from jsonb_to_recordset(v_validated_products)
      as product_item(id uuid, selling_price numeric, quantity integer)
  loop
    update public.inventory_items
    set current_stock = coalesce(current_stock, 0) - v_product.quantity
    where id = v_product.id
      and coalesce(current_stock, 0) >= v_product.quantity;

    if not found then
      raise exception using message = 'appointment_product_stock_unavailable';
    end if;

    insert into public.order_products (
      order_id,
      inventory_item_id,
      quantity,
      unit_price,
      product_status
    )
    values (
      v_order_id,
      v_product.id,
      v_product.quantity,
      v_product.selling_price,
      'pending'
    );
  end loop;

  insert into public.appointments (
    order_service_id,
    vehicle_id,
    appointment_status,
    scheduled_datetime,
    note
  )
  values (
    v_order_service_id,
    v_vehicle_id,
    'scheduled',
    v_scheduled_datetime,
    p_note
  )
  returning id into v_appointment_id;

  return v_appointment_id;
end;
$function$;

revoke all on function public.book_service_appointment(
  uuid, uuid, date, time without time zone, jsonb, text, uuid, uuid,
  text, text, integer, text, fuel_type, transmission_type, text, text
) from public;

grant execute on function public.book_service_appointment(
  uuid, uuid, date, time without time zone, jsonb, text, uuid, uuid,
  text, text, integer, text, fuel_type, transmission_type, text, text
) to authenticated;

-- reschedule_customer_appointment: now derives the appointment's workshop
-- and service, then calls the same shared validation before moving it,
-- excluding the appointment being moved from its own overlap count.
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
  v_workshop_id uuid;
  v_inventory_item_id uuid;
begin
  if v_user_id is null then
    raise exception using message = 'appointment_auth_required';
  end if;

  if p_scheduled_datetime is null or p_scheduled_datetime <= now() then
    raise exception using message = 'appointment_datetime_in_past';
  end if;

  select o.workshop_id, os.inventory_item_id
  into v_workshop_id, v_inventory_item_id
  from public.appointments a
  join public.order_services os on os.id = a.order_service_id
  join public.orders o on o.id = os.order_id
  join public.customers c on c.id = o.customer_id
  where a.id = p_appointment_id
    and a.appointment_status = 'scheduled'
    and a.scheduled_datetime > now()
    and c.user_id = v_user_id
  limit 1;

  if v_workshop_id is null then
    raise exception using message = 'appointment_not_reschedulable';
  end if;

  perform public.assert_appointment_slot_available(
    v_workshop_id,
    v_inventory_item_id,
    p_scheduled_datetime,
    p_appointment_id
  );

  update public.appointments a
  set
    scheduled_datetime = p_scheduled_datetime,
    updated_by = v_user_id::text,
    updated_at = now()
  where a.id = p_appointment_id
    and a.appointment_status = 'scheduled'
    and a.scheduled_datetime > now();

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
