do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'home_service_click_counts'
  ) then
    alter publication supabase_realtime
    add table public.home_service_click_counts;
  end if;
end;
$$;
