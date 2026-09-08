-- ============================================================
-- Управление пользователями из админки: блокировка и удаление.
-- Создание новых пользователей — через Edge Function
-- (supabase/functions/admin-create-user), т.к. требует service_role
-- ключ, который нельзя держать в клиентском Flutter-приложении.
-- Выполнить в Supabase -> SQL Editor.
-- ============================================================

alter table public.profiles add column if not exists blocked boolean not null default false;

-- Заблокировать/разблокировать пользователя. Только админ, и нельзя
-- заблокировать самого себя (иначе можно случайно остаться без доступа).
create or replace function public.admin_set_blocked(target_id uuid, blocked_value boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Только администратор может блокировать пользователей';
  end if;
  if target_id = auth.uid() then
    raise exception 'Нельзя заблокировать самого себя';
  end if;
  update public.profiles set blocked = blocked_value where id = target_id;
end;
$$;

grant execute on function public.admin_set_blocked(uuid, boolean) to authenticated;

-- Удалить пользователя (каскадом удалятся профиль, избранное и т.д.
-- через внешние ключи с on delete cascade). Только админ, нельзя
-- удалить самого себя.
create or replace function public.admin_delete_user(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Только администратор может удалять пользователей';
  end if;
  if target_id = auth.uid() then
    raise exception 'Нельзя удалить самого себя';
  end if;
  delete from auth.users where id = target_id;
end;
$$;

grant execute on function public.admin_delete_user(uuid) to authenticated;
