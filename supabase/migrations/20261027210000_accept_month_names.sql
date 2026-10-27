-- Month as a number (9, 09) or a name in English or Spanish (sep, September, sept, septiembre, set)
create or replace function public.parse_month(v text)
returns smallint language plpgsql immutable set search_path = '' as $$
declare s text; m smallint;
begin
  if v is null or trim(v) = '' then return null; end if;
  s := lower(trim(v));
  if s ~ '^\d{1,2}$' then return s::smallint; end if;
  s := regexp_replace(translate(s, 'áéíóú', 'aeiou'), '[^a-z]', '', 'g');
  m := case
    when s like 'jan%' or s like 'ene%' then 1
    when s like 'feb%' then 2
    when s like 'mar%' then 3
    when s like 'apr%' or s like 'abr%' then 4
    when s like 'may%' then 5
    when s like 'jun%' then 6
    when s like 'jul%' then 7
    when s like 'aug%' or s like 'ago%' then 8
    when s like 'sep%' or s like 'set%' then 9
    when s like 'oct%' then 10
    when s like 'nov%' then 11
    when s like 'dec%' or s like 'dic%' then 12
  end;
  if m is null then raise exception 'Could not read "%" as a month', v; end if;
  return m;
end $$;

create or replace function public.apply_performance_import()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.performance_data
    (year, month, region, market, brand, site, uptime_pct, apdex, lcp_s, inp_ms, cls, ttfb_ms, sessions)
  values (
    public.parse_int(new.year), public.parse_month(new.month),
    trim(new.region), trim(new.market), trim(new.brand), trim(new.site),
    public.parse_num(new.uptime_pct), public.parse_num(new.apdex), public.parse_num(new.lcp_s),
    public.parse_int(new.inp_ms), public.parse_num(new.cls), public.parse_int(new.ttfb_ms),
    public.parse_int(new.sessions))
  on conflict (site, year, month) do update set
    region = excluded.region, market = excluded.market, brand = excluded.brand,
    uptime_pct = excluded.uptime_pct, apdex = excluded.apdex, lcp_s = excluded.lcp_s,
    inp_ms = excluded.inp_ms, cls = excluded.cls, ttfb_ms = excluded.ttfb_ms,
    sessions = excluded.sessions;
  return new;
end $$;
