create table if not exists public.user_data_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  client_updated_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_data_snapshots_payload_object
    check (jsonb_typeof(payload) = 'object')
);

alter table public.user_data_snapshots enable row level security;

create or replace function public.set_user_data_snapshot_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_data_snapshot_updated_at
  on public.user_data_snapshots;
create trigger set_user_data_snapshot_updated_at
before update on public.user_data_snapshots
for each row execute function public.set_user_data_snapshot_updated_at();

revoke all on public.user_data_snapshots from anon;
grant select, insert, update, delete on public.user_data_snapshots
  to authenticated;

drop policy if exists "users read their own snapshot"
  on public.user_data_snapshots;
create policy "users read their own snapshot"
  on public.user_data_snapshots for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "users create their own snapshot"
  on public.user_data_snapshots;
create policy "users create their own snapshot"
  on public.user_data_snapshots for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "users update their own snapshot"
  on public.user_data_snapshots;
create policy "users update their own snapshot"
  on public.user_data_snapshots for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "users delete their own snapshot"
  on public.user_data_snapshots;
create policy "users delete their own snapshot"
  on public.user_data_snapshots for delete
  to authenticated
  using ((select auth.uid()) = user_id);
