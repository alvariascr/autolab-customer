create or replace function public.toggle_customer_favorite_workshop(
  p_workshop_id uuid
)
returns boolean
language plpgsql
security invoker
set search_path to 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_favorite_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(v_user_id::text || ':' || p_workshop_id::text, 0)
  );

  select id
  into v_favorite_id
  from public.customer_favorites
  where user_id = v_user_id
    and workshop_id = p_workshop_id
    and favorite_type = 'workshop'
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
    workshop_id,
    updated_by
  )
  values (
    v_user_id,
    'workshop',
    p_workshop_id,
    v_user_id::text
  );

  return true;
end;
$function$;

revoke all on function public.toggle_customer_favorite_workshop(uuid)
from public;

grant execute on function public.toggle_customer_favorite_workshop(uuid)
to authenticated;
