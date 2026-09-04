-- Fix: reserve_laropay_payment_link reused any existing 'created'/'pending'
-- link for the same (user, order) pair as-is, without comparing its stored
-- amount against the amount just recomputed from the order's current
-- contents (loadOrderPaymentData in laropay-generate-link/index.ts
-- recalculates the total from live order + product data on every call).
--
-- If the order's contents changed after a link was generated but before the
-- customer paid (a product added/removed, quantity changed), the customer
-- would still be handed the old linkURL -- which Laropay's gateway serves
-- at the amount baked in when that link was originally created -- and end
-- up paying the wrong amount.
--
-- Fix: when an active link is found, compare its stored amount to the
-- freshly computed p_amount. If they match, behavior is unchanged (reuse
-- it). If they don't, expire the stale link and fall through to reserve a
-- new one at the current amount, exactly as if no active link existed.

create or replace function public.reserve_laropay_payment_link(
  p_user_id uuid,
  p_internal_transaction_id text,
  p_id_transaction integer,
  p_amount numeric,
  p_currency_code text,
  p_document text,
  p_detail text,
  p_customer_email text,
  p_expiration_type text,
  p_expiration_value integer,
  p_expires_at timestamptz,
  p_url_callback text,
  p_request_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing record;
  v_reserved_id uuid;
begin
  perform pg_advisory_xact_lock(
    hashtextextended(p_user_id::text || ':' || p_internal_transaction_id, 0)
  );

  update public.laropay_payment_links
  set status = 'expired'
  where user_id = p_user_id
    and internal_transaction_id = p_internal_transaction_id
    and status in ('created', 'pending')
    and expires_at <= now();

  select id,
         link_id,
         link_url,
         status,
         response_code,
         response_description,
         reject_reason,
         auth_response_code,
         amount
  into v_existing
  from public.laropay_payment_links
  where user_id = p_user_id
    and internal_transaction_id = p_internal_transaction_id
    and status in ('created', 'pending')
    and expires_at > now()
  order by created_at desc
  limit 1;

  if found then
    if v_existing.amount is distinct from p_amount then
      -- The order's total changed since this link was generated (e.g. a
      -- product was added/removed while the link sat unpaid). It no longer
      -- reflects what the customer should pay, so it can't be reused.
      update public.laropay_payment_links
      set status = 'expired'
      where id = v_existing.id;
    elsif coalesce(v_existing.link_id, '') <> ''
       and coalesce(v_existing.link_url, '') <> '' then
      return jsonb_build_object(
        'kind', 'existing',
        'link', to_jsonb(v_existing)
      );
    else
      return jsonb_build_object('kind', 'in_progress');
    end if;
  end if;

  insert into public.laropay_payment_links (
    user_id,
    internal_transaction_id,
    id_transaction,
    amount,
    currency_code,
    document,
    detail,
    customer_email,
    expiration_type,
    expiration_value,
    expires_at,
    url_callback,
    status,
    request_payload
  )
  values (
    p_user_id,
    p_internal_transaction_id,
    p_id_transaction,
    p_amount,
    p_currency_code,
    p_document,
    p_detail,
    p_customer_email,
    p_expiration_type,
    p_expiration_value,
    p_expires_at,
    p_url_callback,
    'pending',
    p_request_payload
  )
  returning id into v_reserved_id;

  return jsonb_build_object('kind', 'reserved', 'id', v_reserved_id);
end;
$$;
