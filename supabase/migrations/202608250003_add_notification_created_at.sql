alter table public.notifications
add column if not exists created_at timestamptz;

update public.notifications
set created_at = coalesce(updated_at, now())
where created_at is null;

alter table public.notifications
alter column created_at set default now();

alter table public.notifications
alter column created_at set not null;

create index if not exists notifications_user_created_at_idx
on public.notifications (user_id, created_at desc);
