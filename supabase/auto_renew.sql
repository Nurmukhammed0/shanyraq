-- Автопродление подписки — тот же паттерн, что и activate_own_subscription
-- (fake_subscription.sql): узкая security definer функция вместо открытой
-- RLS-политики на UPDATE, чтобы пользователь не смог задеть другие колонки.
alter table public.profiles add column if not exists auto_renew boolean not null default true;

create or replace function public.set_own_auto_renew(enabled boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set auto_renew = enabled
  where id = auth.uid();
end;
$$;

grant execute on function public.set_own_auto_renew(boolean) to authenticated;
