-- ============================================================
-- Модерация объявлений «Купить дом»: новое объявление сначала
-- попадает на проверку админу (status = 'pending') и становится
-- видно всем только после одобрения. Выполнить после listings.sql,
-- в Supabase -> SQL Editor.
-- ============================================================

alter table public.listings
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected'));

-- Публично видны только одобренные; владелец и админ видят свои/все
-- объявления независимо от статуса (чтобы владелец видел, что его
-- объявление ещё на проверке или отклонено).
drop policy if exists "listings_read_all" on public.listings;
create policy "listings_read_all"
  on public.listings for select
  using (
    deleted_at is null
    and (status = 'approved' or auth.uid() = owner_id or public.is_admin())
  );
