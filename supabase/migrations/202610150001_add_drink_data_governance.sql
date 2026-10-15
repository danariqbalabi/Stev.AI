alter table public.drinks
  add column if not exists validation_status text not null default 'demo'
  check (validation_status in ('demo', 'verified'));

alter table public.drinks
  add column if not exists source_checked_at timestamptz;

comment on column public.drinks.verified is
  'Publication approval. True means the record may be served to clients; it does not validate the nutrition value.';
comment on column public.drinks.validation_status is
  'Nutrition validation status. Demo values must remain demo until checked against a cited source.';
comment on column public.drinks.source_url is
  'Public source for the nutrition value, required before validation_status can become verified.';

update public.drinks
set validation_status = 'demo',
    source_checked_at = null
where id in (
  'es-teh-manis',
  'es-kopi-susu-gula-aren',
  'boba-milk-tea',
  'es-jeruk',
  'matcha',
  'teh-melati-kotak',
  'kopi-susu-kaleng-nescafe',
  'susu-cokelat-kotak-ultra',
  'sprite-botol',
  'hydro-coco'
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'drinks_verified_source_check'
      and conrelid = 'public.drinks'::regclass
  ) then
    alter table public.drinks
      add constraint drinks_verified_source_check check (
        validation_status <> 'verified'
        or (source_url is not null and source_checked_at is not null)
      );
  end if;
end
$$;

create index if not exists drinks_validation_status_idx
  on public.drinks (validation_status, name);
