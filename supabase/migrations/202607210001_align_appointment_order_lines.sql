-- Align customer-created order lines with MiTaller Business:
-- services stay in order_services, additional products go to order_products.
CREATE OR REPLACE FUNCTION public.is_inspection_service_name(p_name text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $function$
  select position(
      'inspeccion' in lower(
        translate(coalesce(p_name, ''), 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU')
      )
    ) > 0
    or position('inspection' in lower(coalesce(p_name, ''))) > 0
    or position(
      'revision' in lower(
        translate(coalesce(p_name, ''), 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU')
      )
    ) > 0;
$function$;

REVOKE ALL ON FUNCTION public.is_inspection_service_name(text)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.book_service_appointment(
  p_workshop_id uuid,
  p_inventory_item_id uuid,
  p_scheduled_date date,
  p_scheduled_time time without time zone,
  p_products jsonb DEFAULT '[]'::jsonb,
  p_note text DEFAULT NULL::text,
  p_vehicle_id uuid DEFAULT NULL::uuid,
  p_garage_vehicle_id uuid DEFAULT NULL::uuid,
  p_license_plate text DEFAULT NULL::text,
  p_vehicle_brand text DEFAULT NULL::text,
  p_vehicle_year integer DEFAULT NULL::integer,
  p_vehicle_color text DEFAULT NULL::text,
  p_fuel_type fuel_type DEFAULT NULL::fuel_type,
  p_transmission_type transmission_type DEFAULT NULL::transmission_type,
  p_vehicle_type text DEFAULT NULL::text,
  p_vehicle_model text DEFAULT NULL::text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth'
AS $function$
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
  v_service_name text;
  v_is_inspection_service boolean := false;

  v_scheduled_datetime timestamp with time zone;
  v_scheduled_end_datetime timestamp with time zone;
  v_open_datetime timestamp with time zone;
  v_close_datetime timestamp with time zone;

  v_duration_hours numeric;
  v_duration_interval interval;

  v_existing_brand text;
  v_existing_year integer;
  v_existing_color text;
  v_existing_fuel_type fuel_type;
  v_existing_transmission_type transmission_type;
  v_existing_vehicle_type text;
  v_existing_vehicle_model text;

  v_employee_capacity integer := 0;
  v_is_closed boolean;
  v_open_time time;
  v_close_time time;
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

  select
    ii.name,
    ii.selling_price,
    ii.estimated_duration_hours
  into
    v_service_name,
    v_unit_price,
    v_duration_hours
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

  v_is_inspection_service :=
    public.is_inspection_service_name(v_service_name);

  v_duration_interval :=
    make_interval(secs => (v_duration_hours * 3600)::double precision);
  v_scheduled_end_datetime := v_scheduled_datetime + v_duration_interval;

  select count(*)
  into v_employee_capacity
  from public.employees e
  where e.workshop_id = p_workshop_id
    and e.is_active = true;

  if v_employee_capacity <= 0 then
    raise exception using message = 'appointment_no_active_employees';
  end if;

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
    and bh.day_of_week = extract(isodow from p_scheduled_date)::integer - 1
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
    (p_scheduled_date + v_open_time) at time zone 'America/Costa_Rica';

  v_close_datetime :=
    (p_scheduled_date + v_close_time) at time zone 'America/Costa_Rica';

  if v_scheduled_datetime < v_open_datetime
     or v_scheduled_datetime >= v_close_datetime
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
        and public.is_inspection_service_name(ii.name)
        and a.scheduled_datetime >= date_trunc('hour', v_scheduled_datetime)
        and a.scheduled_datetime < date_trunc('hour', v_scheduled_datetime) + interval '1 hour'
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
        v_scheduled_datetime,
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
        and not public.is_inspection_service_name(ii.name)
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

  for v_product in
    select
      ii.id,
      ii.selling_price,
      product_item.quantity
    from (
      select
        coalesce(
          nullif(value ->> 'inventoryItemId', ''),
          nullif(value ->> 'inventory_item_id', ''),
          nullif(value ->> 'id', '')
        ) as raw_id,
        case
          when nullif(value ->> 'quantity', '') is null then 1
          when (value ->> 'quantity') ~ '^-?[0-9]+$'
            then (value ->> 'quantity')::integer
          else 0
        end as quantity
      from jsonb_array_elements(p_products) as input(value)
    ) as product_item
    join public.inventory_items ii
      on ii.id = case
        when product_item.raw_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
          then product_item.raw_id::uuid
        else null
      end
    where ii.workshop_id = p_workshop_id
      and ii.status = 'active'
      and ii.item_type <> 'service'
  loop
    if v_product.quantity <= 0 then
      raise exception using message = 'appointment_products_invalid';
    end if;

    if v_product.selling_price is null or v_product.selling_price <= 0 then
      raise exception using message = 'appointment_product_price_required';
    end if;

    v_valid_product_count := v_valid_product_count + 1;
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

  -- Customer checkout only collects additional products online. The service
  -- price is kept on order_services for MiTaller, but Laropay totals stay
  -- product-only because the service is paid directly at the workshop.
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
    v_products_total,
    0,
    v_products_total
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

  for v_product in
    select
      id,
      selling_price,
      quantity
    from jsonb_to_recordset(v_validated_products)
      as product_item(id uuid, selling_price numeric, quantity integer)
  loop
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

REVOKE ALL ON FUNCTION public.book_service_appointment(
  uuid,
  uuid,
  date,
  time without time zone,
  jsonb,
  text,
  uuid,
  uuid,
  text,
  text,
  integer,
  text,
  fuel_type,
  transmission_type,
  text,
  text
)
FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.book_service_appointment(
  uuid,
  uuid,
  date,
  time without time zone,
  jsonb,
  text,
  uuid,
  uuid,
  text,
  text,
  integer,
  text,
  fuel_type,
  transmission_type,
  text,
  text
)
TO authenticated;

notify pgrst, 'reload schema';
