-- Site24x7 "First Byte Time" already includes DNS and Connection, so the backend stage is Server Time.
-- Stages now add up to Overall Response Time: redirect + dns + connection + server + download + rendering.
alter table public.performance_data add column if not exists server_ms integer check (server_ms >= 0);
alter table public.performance_import add column if not exists server_ms text;

create or replace function public.upsert_performance_row(r public.performance_import)
returns void language plpgsql security definer set search_path = '' as $$
declare d date := public.parse_date(r.migrated_on);
begin
  insert into public.performance_data
    (year, month, region, market, brand, site, uptime_pct, apdex, lcp_s, inp_ms, cls, ttfb_ms, sessions,
     redirect_ms, dns_ms, connection_ms, server_ms, download_ms, rendering_ms, response_ms)
  values (
    public.parse_int(r.year), public.parse_month(r.month),
    trim(r.region), trim(r.market), trim(r.brand), trim(r.site),
    public.parse_num(r.uptime_pct), public.parse_num(r.apdex), public.parse_num(r.lcp_s),
    public.parse_int(r.inp_ms), public.parse_num(r.cls), public.parse_int(r.ttfb_ms),
    public.parse_int(r.sessions),
    public.parse_int(r.redirect_ms), public.parse_int(r.dns_ms), public.parse_int(r.connection_ms),
    public.parse_int(r.server_ms), public.parse_int(r.download_ms), public.parse_int(r.rendering_ms), public.parse_int(r.response_ms))
  on conflict (site, year, month) do update set
    region = excluded.region, market = excluded.market, brand = excluded.brand,
    uptime_pct = excluded.uptime_pct, apdex = excluded.apdex, lcp_s = excluded.lcp_s,
    inp_ms = excluded.inp_ms, cls = excluded.cls, ttfb_ms = excluded.ttfb_ms,
    sessions = excluded.sessions,
    redirect_ms = excluded.redirect_ms, dns_ms = excluded.dns_ms, connection_ms = excluded.connection_ms,
    server_ms = excluded.server_ms, download_ms = excluded.download_ms, rendering_ms = excluded.rendering_ms,
    response_ms = excluded.response_ms;
  if d is not null then
    insert into public.site_migrations (site, migrated_on) values (trim(r.site), d)
    on conflict (site) do update set migrated_on = excluded.migrated_on;
  end if;
end $$;
revoke execute on function public.upsert_performance_row(public.performance_import) from public, anon, authenticated;

drop view if exists public.performance_tracker;
create view public.performance_tracker with (security_invoker = true) as
select d.year, d.month, d.region, d.market, d.brand, d.site,
       d.uptime_pct, d.apdex, d.lcp_s, d.inp_ms, d.cls, d.ttfb_ms, d.sessions,
       d.redirect_ms, d.dns_ms, d.connection_ms, d.server_ms, d.download_ms, d.rendering_ms, d.response_ms,
       d.created_at, m.migrated_on
from public.performance_data d
left join public.site_migrations m on lower(m.site) = lower(trim(d.site));
grant select on public.performance_tracker to anon, authenticated;
