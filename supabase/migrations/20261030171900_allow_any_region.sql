-- Regions are no longer limited to Europe / APAC / Americas (e.g. Africa); only require a value
alter table public.performance_data drop constraint if exists performance_data_region_check;
alter table public.performance_data add constraint performance_data_region_check check (length(trim(region)) > 0);
