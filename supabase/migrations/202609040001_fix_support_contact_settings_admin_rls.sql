-- Fix: "Admins can manage support contact settings" compared user_profiles.id
-- (the row's own primary key) against auth.uid() instead of user_profiles.user_id
-- (the column that actually holds the auth user id), which every other admin/
-- ownership check in this codebase uses (see e.g. book_service_appointment,
-- reschedule_customer_appointment, create_cart_order: `where up.user_id = v_user_id`).
-- Because id never equals auth.uid(), the EXISTS subquery never matched, so no
-- admin could ever pass this policy -- fails closed (no data leak), but the
-- "admins manage support contact settings" feature was completely broken.

drop policy if exists "Admins can manage support contact settings"
  on public.support_contact_settings;

create policy "Admins can manage support contact settings"
on public.support_contact_settings
for all
to authenticated
using (
  exists (
    select 1
    from public.user_profiles
    where user_id = auth.uid()
      and role = 'admin'
  )
)
with check (
  exists (
    select 1
    from public.user_profiles
    where user_id = auth.uid()
      and role = 'admin'
  )
);
