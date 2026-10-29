-- Mark the date a site moved to DXP+. Rows whose month contains that date are partial months.
alter table public.performance_data add column if not exists migrated_on date;
alter table public.performance_import add column if not exists migrated_on text;

-- Date as 2026-10-14, 14/10/2026, 14-10-2026 or 14.10.2026 (day first)
create or replace function public.parse_date(v text)
returns date language plpgsql immutable set search_path = '' as $$
declare s text; x text[];
begin
  if v is null or trim(v) = '' then return null; end if;
  s := trim(v);
  x := regexp_match(s, '^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})');
  if x is not null then return make_date(x[1]::int, x[2]::int, x[3]::int); end if;
  x := regexp_match(s, '^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})');
  if x is not null then return make_date(x[3]::int, x[2]::int, x[1]::int); end if;
  raise exception 'Could not read "%" as a date (use 2026-10-14 or 14/10/2026)', v;
exception when others then
  raise exception 'Could not read "%" as a date (use 2026-10-14 or 14/10/2026)', v;
end $$;

create or replace function public.apply_performance_import()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.performance_data
    (year, month, region, market, brand, site, uptime_pct, apdex, lcp_s, inp_ms, cls, ttfb_ms, sessions, migrated_on)
  values (
    public.parse_int(new.year), public.parse_month(new.month),
    trim(new.region), trim(new.market), trim(new.brand), trim(new.site),
    public.parse_num(new.uptime_pct), public.parse_num(new.apdex), public.parse_num(new.lcp_s),
    public.parse_int(new.inp_ms), public.parse_num(new.cls), public.parse_int(new.ttfb_ms),
    public.parse_int(new.sessions), public.parse_date(new.migrated_on))
  on conflict (site, year, month) do update set
    region = excluded.region, market = excluded.market, brand = excluded.brand,
    uptime_pct = excluded.uptime_pct, apdex = excluded.apdex, lcp_s = excluded.lcp_s,
    inp_ms = excluded.inp_ms, cls = excluded.cls, ttfb_ms = excluded.ttfb_ms,
    sessions = excluded.sessions, migrated_on = excluded.migrated_on;
  return new;
end $$;
