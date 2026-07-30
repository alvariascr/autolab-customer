alter type public.payment_status add value if not exists 'partial';

create unique index if not exists payments_order_reference_number_unique_idx
on public.payments (order_id, reference_number)
where reference_number is not null;

create or replace function public.persist_laropay_status_check(
  p_payment_link_id uuid,
  p_status text,
  p_response_code text,
  p_response_description text,
  p_reject_reason text,
  p_auth_response_code text,
  p_verify_payload jsonb,
  p_certifier_payload jsonb,
  p_status_checked_at timestamptz,
  p_status_check_error text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment_link public.laropay_payment_links%rowtype;
  v_effective_status text;
  v_order_id uuid;
  v_order_workshop_id uuid;
  v_updated_order_count integer;
  v_card_payment_method_id integer;
  v_payment_reference text;
  v_total_paid numeric;
begin
  if p_status not in ('paid', 'pending', 'rejected', 'expired', 'failed') then
    raise exception 'invalid_laropay_status';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_payment_link_id::text, 0));

  select *
  into v_payment_link
  from public.laropay_payment_links
  where id = p_payment_link_id
  for update;

  if not found then
    raise exception 'payment_link_not_found';
  end if;

  v_effective_status := lower(coalesce(v_payment_link.status, ''));

  if v_effective_status <> 'paid' then
    if p_status <> 'paid' and v_effective_status in ('rejected', 'expired') then
      return to_jsonb(v_payment_link);
    end if;

    v_effective_status := p_status;

    update public.laropay_payment_links
    set
      status = v_effective_status,
      response_code = p_response_code,
      response_description = p_response_description,
      reject_reason = p_reject_reason,
      auth_response_code = p_auth_response_code,
      response_payload = coalesce(p_verify_payload, '{}'::jsonb),
      verify_payload = coalesce(p_verify_payload, '{}'::jsonb),
      certifier_payload = coalesce(p_certifier_payload, '{}'::jsonb),
      status_checked_at = p_status_checked_at,
      status_check_error = p_status_check_error
    where id = p_payment_link_id
    returning * into v_payment_link;
  end if;

  if v_effective_status = 'paid' then
    begin
      v_order_id := v_payment_link.internal_transaction_id::uuid;
    exception
      when invalid_text_representation then
        raise exception 'invalid_internal_transaction_id';
    end;

    if v_payment_link.amount <= 0 then
      raise exception 'invalid_laropay_payment_amount';
    end if;

    v_payment_reference := 'LAROPAY:' || v_payment_link.id::text;

    select o.workshop_id
    into v_order_workshop_id
    from public.orders o
    where o.id = v_order_id
    for update;

    if not found then
      raise exception 'payment_order_not_found';
    end if;

    select pm.id
    into v_card_payment_method_id
    from public.workshop_payment_methods wpm
    join public.payment_methods pm on pm.id = wpm.payment_method_id
    where wpm.workshop_id = v_order_workshop_id
      and translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') in (
        'tarjeta',
        'tarjeta credito',
        'tarjeta de credito',
        'tarjeta debito',
        'tarjeta de debito'
      )
    order by
      case
        when translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') = 'tarjeta' then 0
        when translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') in (
          'tarjeta credito',
          'tarjeta de credito'
        ) then 1
        when translate(lower(coalesce(pm.name, '')), 'áéíóúü', 'aeiouu') in (
          'tarjeta debito',
          'tarjeta de debito'
        ) then 2
        else 4
      end,
      pm.id
    limit 1;

    if v_card_payment_method_id is null then
      raise exception 'laropay_card_payment_method_not_found';
    end if;

    insert into public.payments (
      id,
      order_id,
      amount,
      payment_method_id,
      payment_date,
      reference_number,
      notes,
      updated_at
    )
    select
      gen_random_uuid(),
      v_order_id,
      v_payment_link.amount,
      v_card_payment_method_id,
      coalesce(p_status_checked_at, v_payment_link.status_checked_at, now()),
      v_payment_reference,
      'Pago Laropay confirmado. link_id=' || coalesce(v_payment_link.link_id, ''),
      now()
    where not exists (
      select 1
      from public.payments p
      where p.order_id = v_order_id
        and p.reference_number = v_payment_reference
    )
    on conflict (order_id, reference_number)
      where reference_number is not null
      do nothing;

    select coalesce(sum(p.amount), 0)
    into v_total_paid
    from public.payments p
    where p.order_id = v_order_id;

    -- Customer-created orders can include service balances paid at the workshop.
    -- Laropay settles only product payments, so remaining service balance is partial.
    update public.orders o
    set
      payment_status = case
        when v_total_paid <= 0 then 'unpaid'
        when o.total_amount is null then 'partial'
        when v_total_paid >= o.total_amount then 'paid'
        else 'partial'
      end::public.payment_status,
      paid_amount = v_total_paid,
      remaining_amount = case
        when o.total_amount is null then null
        else greatest(o.total_amount - v_total_paid, 0)
      end,
      updated_at = now()
    where o.id = v_order_id;

    get diagnostics v_updated_order_count = row_count;
    if v_updated_order_count <> 1 then
      raise exception 'payment_order_not_found';
    end if;
  end if;

  return to_jsonb(v_payment_link);
end;
$$;

revoke all on function public.persist_laropay_status_check(
  uuid,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  timestamptz,
  text
) from public, anon, authenticated;

grant execute on function public.persist_laropay_status_check(
  uuid,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  timestamptz,
  text
) to service_role;

notify pgrst, 'reload schema';
