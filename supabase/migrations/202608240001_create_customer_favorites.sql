create table if not exists public.customer_favorites (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  favorite_type text not null,
  workshop_id uuid,
  inventory_item_id uuid,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  updated_by text,
  constraint customer_favorites_pkey primary key (id),
  constraint customer_favorites_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete cascade,
  constraint customer_favorites_workshop_id_fkey
    foreign key (workshop_id) references public.workshops(id) on delete cascade,
  constraint customer_favorites_inventory_item_id_fkey
    foreign key (inventory_item_id) references public.inventory_items(id) on delete cascade,
  constraint customer_favorites_type_check
    check (favorite_type in ('workshop', 'product', 'service')),
  constraint customer_favorites_target_check
    check (
      (
        favorite_type = 'workshop'
        and workshop_id is not null
        and inventory_item_id is null
      )
      or
      (
        favorite_type in ('product', 'service')
        and inventory_item_id is not null
        and workshop_id is null
      )
    )
);

create unique index if not exists customer_favorites_user_workshop_key
on public.customer_favorites(user_id, workshop_id)
where favorite_type = 'workshop';

create unique index if not exists customer_favorites_user_inventory_item_key
on public.customer_favorites(user_id, inventory_item_id)
where favorite_type in ('product', 'service');

create index if not exists customer_favorites_user_id_idx
on public.customer_favorites(user_id);

create index if not exists customer_favorites_workshop_id_idx
on public.customer_favorites(workshop_id);

create index if not exists customer_favorites_inventory_item_id_idx
on public.customer_favorites(inventory_item_id);

alter table public.customer_favorites enable row level security;

drop policy if exists "Users can view their favorites"
on public.customer_favorites;

create policy "Users can view their favorites"
on public.customer_favorites
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can create their favorites"
on public.customer_favorites;

create policy "Users can create their favorites"
on public.customer_favorites
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can update their favorites"
on public.customer_favorites;

create policy "Users can update their favorites"
on public.customer_favorites
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Users can delete their favorites"
on public.customer_favorites;

create policy "Users can delete their favorites"
on public.customer_favorites
for delete
to authenticated
using (user_id = auth.uid());

create or replace function public.set_customer_favorites_updated_at()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

drop trigger if exists set_customer_favorites_updated_at
on public.customer_favorites;

create trigger set_customer_favorites_updated_at
before update on public.customer_favorites
for each row
execute function public.set_customer_favorites_updated_at();
