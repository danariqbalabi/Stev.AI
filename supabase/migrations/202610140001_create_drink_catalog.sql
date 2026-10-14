create table if not exists public.drinks (
  id text primary key,
  name text not null,
  brand text,
  category text not null check (
    category in ('packaged', 'coffee', 'tea', 'boba', 'juice', 'custom')
  ),
  kind text not null check (
    kind in ('tea', 'coffee', 'boba', 'juice', 'milk', 'soda', 'isotonic', 'custom')
  ),
  packaged boolean not null default false,
  barcode text unique,
  serving_ml integer check (serving_ml is null or serving_ml > 0),
  sugar_grams numeric(6, 2) not null check (sugar_grams >= 0),
  estimated boolean not null default true,
  data_type text not null check (
    data_type in ('label', 'official', 'estimated', 'community')
  ),
  photo_asset text,
  image_url text,
  source_url text,
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sugar_options (
  id bigint generated always as identity primary key,
  drink_id text not null references public.drinks(id) on delete cascade,
  level text not null check (level in ('normal', 'less', 'no_sugar')),
  sugar_grams numeric(6, 2) not null check (sugar_grams >= 0),
  unique (drink_id, level)
);

create table if not exists public.drink_aliases (
  id bigint generated always as identity primary key,
  drink_id text not null references public.drinks(id) on delete cascade,
  alias text not null,
  unique (drink_id, alias)
);

create table if not exists public.drink_images (
  id uuid primary key default gen_random_uuid(),
  drink_id text not null references public.drinks(id) on delete cascade,
  storage_path text not null,
  angle text,
  lighting text,
  background text,
  dataset_split text check (
    dataset_split is null or dataset_split in ('train', 'validation', 'test')
  ),
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists drinks_verified_name_idx
  on public.drinks (verified, name);
create index if not exists drink_aliases_alias_idx
  on public.drink_aliases (lower(alias));
create index if not exists drink_images_drink_id_idx
  on public.drink_images (drink_id);

alter table public.drinks enable row level security;
alter table public.sugar_options enable row level security;
alter table public.drink_aliases enable row level security;
alter table public.drink_images enable row level security;

revoke insert, update, delete, truncate, references, trigger
  on public.drinks, public.sugar_options, public.drink_aliases, public.drink_images
  from anon, authenticated;
grant select
  on public.drinks, public.sugar_options, public.drink_aliases
  to anon, authenticated;

drop policy if exists "verified drinks are publicly readable"
  on public.drinks;
create policy "verified drinks are publicly readable"
  on public.drinks for select
  to anon, authenticated
  using (verified = true);

drop policy if exists "options of verified drinks are publicly readable"
  on public.sugar_options;
create policy "options of verified drinks are publicly readable"
  on public.sugar_options for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.drinks
      where drinks.id = sugar_options.drink_id
        and drinks.verified = true
    )
  );

drop policy if exists "aliases of verified drinks are publicly readable"
  on public.drink_aliases;
create policy "aliases of verified drinks are publicly readable"
  on public.drink_aliases for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.drinks
      where drinks.id = drink_aliases.drink_id
        and drinks.verified = true
    )
  );

insert into public.drinks (
  id, name, brand, category, kind, packaged, sugar_grams, estimated,
  data_type, photo_asset, verified
) values
  ('es-teh-manis', 'Es teh manis', null, 'tea', 'tea', false, 24, true,
    'estimated', 'assets/drinks/es_teh_manis.png', true),
  ('es-kopi-susu-gula-aren', 'Es kopi susu gula aren', null, 'coffee', 'coffee', false, 36, true,
    'estimated', 'assets/drinks/es_kopi_susu_gula_aren.png', true),
  ('boba-milk-tea', 'Boba milk tea', null, 'boba', 'boba', false, 38, true,
    'estimated', 'assets/drinks/boba_milk_tea.png', true),
  ('es-jeruk', 'Es jeruk', null, 'juice', 'juice', false, 16, true,
    'estimated', 'assets/drinks/es_jeruk.png', true),
  ('matcha', 'Matcha', null, 'tea', 'tea', false, 20, true,
    'estimated', 'assets/drinks/matcha.png', true),
  ('teh-melati-kotak', 'Teh melati kotak', null, 'tea', 'tea', true, 18, false,
    'label', 'assets/drinks/teh_melati_kotak.png', true),
  ('kopi-susu-kaleng-nescafe', 'Kopi susu kaleng Nescafe', 'Nescafe', 'packaged', 'coffee', true, 30, false,
    'label', 'assets/drinks/kopi_susu_kaleng_nescafe.png', true),
  ('susu-cokelat-kotak-ultra', 'Susu cokelat kotak Ultra', 'Ultra', 'packaged', 'milk', true, 22, false,
    'label', 'assets/drinks/susu_cokelat_ultra.png', true),
  ('sprite-botol', 'Sprite botol', 'Sprite', 'packaged', 'soda', true, 25, false,
    'label', 'assets/drinks/sprite_botol.png', true),
  ('hydro-coco', 'Hydro Coco', 'Hydro Coco', 'packaged', 'isotonic', true, 9, false,
    'label', 'assets/drinks/hydro_coco.png', true)
on conflict (id) do update set
  name = excluded.name,
  brand = excluded.brand,
  category = excluded.category,
  kind = excluded.kind,
  packaged = excluded.packaged,
  sugar_grams = excluded.sugar_grams,
  estimated = excluded.estimated,
  data_type = excluded.data_type,
  photo_asset = excluded.photo_asset,
  verified = excluded.verified,
  updated_at = now();

insert into public.sugar_options (drink_id, level, sugar_grams) values
  ('es-teh-manis', 'normal', 24),
  ('es-teh-manis', 'less', 14),
  ('es-teh-manis', 'no_sugar', 0),
  ('es-kopi-susu-gula-aren', 'normal', 36),
  ('es-kopi-susu-gula-aren', 'less', 22),
  ('es-kopi-susu-gula-aren', 'no_sugar', 6),
  ('boba-milk-tea', 'normal', 38),
  ('boba-milk-tea', 'less', 25),
  ('boba-milk-tea', 'no_sugar', 12),
  ('matcha', 'normal', 20),
  ('matcha', 'less', 12),
  ('matcha', 'no_sugar', 4)
on conflict (drink_id, level) do update set
  sugar_grams = excluded.sugar_grams;

insert into public.drink_aliases (drink_id, alias) values
  ('kopi-susu-kaleng-nescafe', 'nescafe can'),
  ('kopi-susu-kaleng-nescafe', 'kopi nescafe kaleng'),
  ('teh-melati-kotak', 'teh kotak melati'),
  ('susu-cokelat-kotak-ultra', 'ultra milk cokelat'),
  ('boba-milk-tea', 'boba tea')
on conflict (drink_id, alias) do nothing;
