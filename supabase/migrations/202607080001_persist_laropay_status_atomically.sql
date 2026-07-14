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
  v_updated_order_count integer;
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

  if v_effective_status = 'paid' then
    return to_jsonb(v_payment_link);
  end if;

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

  if v_effective_status = 'paid' then
    if v_payment_link.internal_transaction_id !~
      '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
    then
      raise exception 'invalid_internal_transaction_id';
    end if;

    v_order_id := v_payment_link.internal_transaction_id::uuid;

    update public.orders
    set
      payment_status = 'paid',
      paid_amount = v_payment_link.amount,
      remaining_amount = 0,
      updated_at = now()
    where id = v_order_id;

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
