-- The customer app now books services through public.book_service_appointment.
-- Revoke the legacy appointment/payment simulation RPC from client roles so the
-- old order schema cannot be reactivated accidentally from Flutter.
do $$
declare
  v_function_signature text;
begin
  for v_function_signature in
    select p.oid::regprocedure::text
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'create_appointment_with_products'
  loop
    execute format(
      'revoke all on function %s from public, anon, authenticated',
      v_function_signature
    );
  end loop;
end $$;
