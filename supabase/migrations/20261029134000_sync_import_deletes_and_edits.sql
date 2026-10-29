-- Keep performance_data in step with performance_import:
-- insert or edit an import row -> upsert; change its site/month -> move; delete it -> remove.

create or replace function public.upsert_performance_row(r public.performance_import)
returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.performance_data
    (year, month, region, market, brand, site, uptime_pct, apdex, lcp_s, inp_ms, cls, ttfb_ms, sessions, migrated_on)
  values (
    public.parse_int(r.year), public.parse_month(r.month),
    trim(r.region), trim(r.market), trim(r.brand), trim(r.site),
    public.parse_num(r.uptime_pct), public.parse_num(r.apdex), public.parse_num(r.lcp_s),
    public.parse_int(r.inp_ms), public.parse_num(r.cls), public.parse_int(r.ttfb_ms),
    public.parse_int(r.sessions), public.parse_date(r.migrated_on))
  on conflict (site, year, month) do update set
    region = excluded.region, market = excluded.market, brand = excluded.brand,
    uptime_pct = excluded.uptime_pct, apdex = excluded.apdex, lcp_s = excluded.lcp_s,
    inp_ms = excluded.inp_ms, cls = excluded.cls, ttfb_ms = excluded.ttfb_ms,
    sessions = excluded.sessions, migrated_on = excluded.migrated_on;
end $$;

-- Remove the performance_data row for an import row's site + month,
-- unless another import row still provides that same site + month
create or replace function public.remove_performance_row(r public.performance_import)
returns void language plpgsql security definer set search_path = '' as $$
declare k_site text := trim(r.site); k_year int := public.parse_int(r.year); k_month int := public.parse_month(r.month);
begin
  if not exists (
    select 1 from public.performance_import i
    where i.id <> r.id and trim(i.site) = k_site
      and public.parse_int(i.year) = k_year and public.parse_month(i.month) = k_month
  ) then
    delete from public.performance_data where site = k_site and year = k_year and month = k_month;
  end if;
end $$;

create or replace function public.apply_performance_import()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    perform public.remove_performance_row(old);
    return old;
  end if;
  if tg_op = 'UPDATE' and (trim(old.site), public.parse_int(old.year), public.parse_month(old.month))
       is distinct from (trim(new.site), public.parse_int(new.year), public.parse_month(new.month)) then
    perform public.remove_performance_row(old);
  end if;
  perform public.upsert_performance_row(new);
  return new;
end $$;

drop trigger if exists performance_import_apply on public.performance_import;
create trigger performance_import_apply
  after insert or update or delete on public.performance_import
  for each row execute function public.apply_performance_import();

-- These functions are only for the trigger, not for the public API
revoke execute on function public.upsert_performance_row(public.performance_import) from public, anon, authenticated;
revoke execute on function public.remove_performance_row(public.performance_import) from public, anon, authenticated;
revoke execute on function public.apply_performance_import() from public, anon, authenticated;
