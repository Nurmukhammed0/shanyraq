-- ============================================================
-- Расширение профиля: имя и аватар. Плюс функция самостоятельного
-- удаления аккаунта (без сервисного ключа на клиенте).
-- ============================================================

alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists avatar_url text;

-- RLS на UPDATE у profiles остаётся admin-only (см. profiles_and_subscriptions.sql) —
-- НЕ добавляем сюда политику "update own row", иначе пользователь через неё
-- сможет менять role/is_subscribed самому себе (RLS не различает колонки).
-- Вместо этого — узкая security definer функция, трогающая только имя/аватар.
create or replace function public.update_own_profile(new_display_name text, new_avatar_url text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set display_name = new_display_name,
      avatar_url = new_avatar_url
  where id = auth.uid();
end;
$$;

grant execute on function public.update_own_profile(text, text) to authenticated;

-- Самостоятельное удаление аккаунта: удаляет строку из auth.users,
-- профиль/избранное удаляются каскадом по внешним ключам.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function public.delete_own_account() to authenticated;

-- ============================================================
-- Storage bucket для аватаров. Публичное чтение, пользователь
-- пишет только в свою папку (avatars/<user_id>/...).
-- ============================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars_own_write" on storage.objects;
create policy "avatars_own_write"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_own_update" on storage.objects;
create policy "avatars_own_update"
  on storage.objects for update
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
