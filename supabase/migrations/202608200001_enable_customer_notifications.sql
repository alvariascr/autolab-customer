alter table public.notifications enable row level security;

drop policy if exists "customers can read own notifications"
on public.notifications;

create policy "customers can read own notifications"
on public.notifications
for select
to authenticated
using (auth.uid() = user_id);

revoke update on table public.notifications from authenticated;
grant select on table public.notifications to authenticated;

create or replace function public.mark_customer_notification_read(
  p_notification_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  update public.notifications
  set
    is_read = true,
    read_at = coalesce(read_at, now()),
    updated_at = now()
  where id = p_notification_id
    and user_id = auth.uid();

  if not found then
    raise exception 'notification not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all
on function public.mark_customer_notification_read(uuid)
from public, anon;

grant execute
on function public.mark_customer_notification_read(uuid)
to authenticated;
