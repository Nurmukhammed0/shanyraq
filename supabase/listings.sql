-- ============================================================
-- Раздел «Купить дом»: объявления от собственников, добавляют
-- сами пользователи (только с активной подпиской). Мы не проверяем
-- документы/договорённости — это отражено в интерфейсе и здесь же
-- в комментариях как явная граница ответственности.
-- Выполнить в Supabase -> SQL Editor.
-- ============================================================

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  price numeric,
  city text not null default 'Алматы',
  district text,
  address text,
  rooms int,
  area_sqm numeric,
  phone text not null,
  contact_name text,
  photo_url text,
  created_at timestamptz default now(),
  deleted_at timestamptz
);

alter table public.listings enable row level security;

-- Объявления видит кто угодно, кроме удалённых
drop policy if exists "listings_read_all" on public.listings;
create policy "listings_read_all"
  on public.listings for select
  using (deleted_at is null);

-- Добавлять объявление может только сам владелец аккаунта, и только
-- если у него активна подписка (платный доступ к размещению).
drop policy if exists "listings_insert_subscribed_own" on public.listings;
create policy "listings_insert_subscribed_own"
  on public.listings for insert
  with check (
    auth.uid() = owner_id
    and exists (select 1 from public.profiles where id = auth.uid() and is_subscribed = true)
  );

-- Редактировать/удалять (мягко, через deleted_at) — только свои
-- объявления или админ.
drop policy if exists "listings_update_own_or_admin" on public.listings;
create policy "listings_update_own_or_admin"
  on public.listings for update
  using (auth.uid() = owner_id or public.is_admin())
  with check (auth.uid() = owner_id or public.is_admin());

drop policy if exists "listings_delete_own_or_admin" on public.listings;
create policy "listings_delete_own_or_admin"
  on public.listings for delete
  using (auth.uid() = owner_id or public.is_admin());

-- Storage: фото объявлений. Публичное чтение; загружать может только
-- подписанный пользователь; менять/удалять — владелец файла или админ.
insert into storage.buckets (id, name, public)
values ('listing-photos', 'listing-photos', true)
on conflict (id) do nothing;

drop policy if exists "listing_photos_public_read" on storage.objects;
create policy "listing_photos_public_read"
  on storage.objects for select
  using (bucket_id = 'listing-photos');

drop policy if exists "listing_photos_subscribed_insert" on storage.objects;
create policy "listing_photos_subscribed_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'listing-photos'
    and exists (select 1 from public.profiles where id = auth.uid() and is_subscribed = true)
  );

drop policy if exists "listing_photos_own_update" on storage.objects;
create policy "listing_photos_own_update"
  on storage.objects for update
  using (bucket_id = 'listing-photos' and (owner = auth.uid() or public.is_admin()));

drop policy if exists "listing_photos_own_delete" on storage.objects;
create policy "listing_photos_own_delete"
  on storage.objects for delete
  using (bucket_id = 'listing-photos' and (owner = auth.uid() or public.is_admin()));
