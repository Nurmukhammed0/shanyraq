-- ============================================================
-- Профили пользователей: роль (user/admin) и статус подписки.
-- Подписка пока без реального платёжного шлюза — is_subscribed
-- переключает вручную админ (например, после оплаты на Kaspi).
-- Выполнить в Supabase -> SQL Editor.
-- ============================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'user' check (role in ('user', 'admin')),
  is_subscribed boolean not null default false,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

-- security definer функция: проверяет роль без рекурсии в RLS
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- Автосоздание профиля при регистрации нового пользователя
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- RLS: пользователь видит свой профиль, админ видит все
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin());

-- RLS: менять роль/подписку может только админ
drop policy if exists "profiles_update_admin_only" on public.profiles;
create policy "profiles_update_admin_only"
  on public.profiles for update
  using (public.is_admin())
  with check (public.is_admin());

-- Разрешаем админу редактировать таблицу zhk (добавление/правки объектов)
drop policy if exists "zhk_write_admin_only" on public.zhk;
create policy "zhk_write_admin_only"
  on public.zhk for insert
  with check (public.is_admin());

drop policy if exists "zhk_update_admin_only" on public.zhk;
create policy "zhk_update_admin_only"
  on public.zhk for update
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "zhk_delete_admin_only" on public.zhk;
create policy "zhk_delete_admin_only"
  on public.zhk for delete
  using (public.is_admin());

-- ============================================================
-- Бэкафилл: создать профили для уже зарегистрированных
-- пользователей (на случай, если регистрация была до триггера).
-- ============================================================
insert into public.profiles (id, email)
select id, email from auth.users
on conflict (id) do nothing;

-- ============================================================
-- Сделать себя админом: замени email на свой и выполни отдельно.
-- ============================================================
-- update public.profiles set role = 'admin' where email = 'you@example.com';
