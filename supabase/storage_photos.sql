-- ============================================================
-- Storage bucket для фото ЖК. Публичное чтение, загрузка/удаление
-- только админом.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('zhk-photos', 'zhk-photos', true)
on conflict (id) do nothing;

drop policy if exists "zhk_photos_public_read" on storage.objects;
create policy "zhk_photos_public_read"
  on storage.objects for select
  using (bucket_id = 'zhk-photos');

drop policy if exists "zhk_photos_admin_insert" on storage.objects;
create policy "zhk_photos_admin_insert"
  on storage.objects for insert
  with check (bucket_id = 'zhk-photos' and public.is_admin());

drop policy if exists "zhk_photos_admin_update" on storage.objects;
create policy "zhk_photos_admin_update"
  on storage.objects for update
  using (bucket_id = 'zhk-photos' and public.is_admin());

drop policy if exists "zhk_photos_admin_delete" on storage.objects;
create policy "zhk_photos_admin_delete"
  on storage.objects for delete
  using (bucket_id = 'zhk-photos' and public.is_admin());
