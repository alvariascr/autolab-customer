create or replace function public.toggle_customer_favorite_inventory_item(
  p_inventory_item_id uuid,
  p_favorite_type text
)
returns boolean
language plpgsql
security invoker
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_favorite_id uuid;
  v_favorite_type text := lower(trim(p_favorite_type));
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if v_favorite_type not in ('product', 'service') then
    raise exception 'Invalid favorite type: %', p_favorite_type;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(v_user_id::text || ':' || p_inventory_item_id::text, 0)
  );

  select id
  into v_favorite_id
  from public.customer_favorites
  where user_id = v_user_id
    and inventory_item_id = p_inventory_item_id
    and favorite_type in ('product', 'service')
  limit 1
  for update;

  if v_favorite_id is not null then
    delete from public.customer_favorites
    where id = v_favorite_id;

    return false;
  end if;

  insert into public.customer_favorites (
    user_id,
    favorite_type,
    inventory_item_id,
    updated_by
  )
  values (
    v_user_id,
    v_favorite_type,
    p_inventory_item_id,
    v_user_id::text
  );

  return true;
end;
$function$;

revoke all on function public.toggle_customer_favorite_inventory_item(uuid, text)
from public;

grant execute on function public.toggle_customer_favorite_inventory_item(uuid, text)
to authenticated;
