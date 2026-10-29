-- Store each site's DXP+ migration date once, instead of on monthly rows.

create table public.site_migrations (
  site        text primary key,
  migrated_on date not null,
  created_at  timestamptz not null default now()
);
alter table public.site_migrations enable row level security;
create policy "read site migrations" on public.site_migrations
  for select to anon, authenticated using (true);

-- Keep dates already entered on monthly rows (one per site)
insert into public.site_migrations (site, migrated_on)
select distinct on (trim(site)) trim(site), migrated_on
from public.performance_data where migrated_on is not null
order by trim(site), year desc, month desc
on conflict (site) do nothing;

-- Imports: metrics go to performance_data; an optional migrated_on is saved once per site
create or replace function public.upsert_performance_row(r public.performance_import)
returns void language plpgsql security definer set search_path = '' as $$
declare d date := public.parse_date(r.migrated_on);
begin
  insert into public.performance_data
    (year, month, region, market, brand, site, uptime_pct, apdex, lcp_s, inp_ms, cls, ttfb_ms, sessions)
  values (
    public.parse_int(r.year), public.parse_month(r.month),
    trim(r.region), trim(r.market), trim(r.brand), trim(r.site),
    public.parse_num(r.uptime_pct), public.parse_num(r.apdex), public.parse_num(r.lcp_s),
    public.parse_int(r.inp_ms), public.parse_num(r.cls), public.parse_int(r.ttfb_ms),
    public.parse_int(r.sessions))
  on conflict (site, year, month) do update set
    region = excluded.region, market = excluded.market, brand = excluded.brand,
    uptime_pct = excluded.uptime_pct, apdex = excluded.apdex, lcp_s = excluded.lcp_s,
    inp_ms = excluded.inp_ms, cls = excluded.cls, ttfb_ms = excluded.ttfb_ms,
    sessions = excluded.sessions;
  if d is not null then
    insert into public.site_migrations (site, migrated_on) values (trim(r.site), d)
    on conflict (site) do update set migrated_on = excluded.migrated_on;
  end if;
end $$;
revoke execute on function public.upsert_performance_row(public.performance_import) from public, anon, authenticated;

alter table public.performance_data drop column migrated_on;

-- What the tracker reads: monthly metrics plus each site's migration date
create view public.performance_tracker with (security_invoker = true) as
select d.year, d.month, d.region, d.market, d.brand, d.site,
       d.uptime_pct, d.apdex, d.lcp_s, d.inp_ms, d.cls, d.ttfb_ms, d.sessions, d.created_at,
       m.migrated_on
from public.performance_data d
left join public.site_migrations m on lower(m.site) = lower(trim(d.site));
grant select on public.performance_tracker to anon, authenticated;
