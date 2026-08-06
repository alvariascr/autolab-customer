create or replace function public.create_customer_profile_on_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_metadata_role text := coalesce(new.raw_user_meta_data ->> 'role', '');
  v_name text := nullif(
    trim(
      coalesce(
        new.raw_user_meta_data ->> 'name',
        new.raw_user_meta_data ->> 'full_name',
        ''
      )
    ),
    ''
  );
  v_phone text := nullif(trim(coalesce(new.raw_user_meta_data ->> 'phone', '')), '');
  v_email text := coalesce(new.email, '');
begin
  if v_metadata_role <> 'customer' then
    return new;
  end if;

  if v_name is null then
    v_name := nullif(split_part(v_email, '@', 1), '');
  end if;

  insert into public.user_profiles (
    user_id,
    name,
    role,
    email,
    phone,
    workshop_id,
    force_password_change,
    updated_at
  )
  values (
    new.id,
    coalesce(v_name, 'Cliente Autolab'),
    'customer'::public.app_role,
    v_email,
    v_phone,
    null,
    false,
    now()
  )
  on conflict (user_id) do update
  set
    name = excluded.name,
    role = excluded.role,
    email = excluded.email,
    phone = excluded.phone,
    workshop_id = excluded.workshop_id,
    force_password_change = excluded.force_password_change,
    updated_at = excluded.updated_at;

  return new;
end;
$$;

drop function if exists public.ensure_customer_profile(uuid, text, text, text);

drop trigger if exists create_customer_profile_on_signup on auth.users;

-- Replaces the legacy signup trigger that duplicated customer profile creation
-- and caused auth signup failures when both triggers ran for the same user.
drop trigger if exists on_auth_user_created on auth.users;

create trigger create_customer_profile_on_signup
after insert on auth.users
for each row
execute function public.create_customer_profile_on_signup();
