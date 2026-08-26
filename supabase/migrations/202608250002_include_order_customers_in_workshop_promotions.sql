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
    and (
      p_workshop_id is null
      or c.workshop_id = p_workshop_id
      or exists (
        select 1
        from public.orders o
        where o.customer_id = c.id
          and o.workshop_id = p_workshop_id
      )
    );

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

revoke all on function public.notify_customers_of_promotion(text, text, uuid)
from public, anon, authenticated;

grant execute on function public.notify_customers_of_promotion(text, text, uuid)
to service_role;
