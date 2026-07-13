-- ============================================================
-- Лог изменений статуса ЖК — на его основе строим уведомления
-- "статус вашего избранного ЖК изменился".
-- ============================================================

create table if not exists public.zhk_status_log (
  id uuid primary key default gen_random_uuid(),
  zhk_id text references public.zhk(id) on delete cascade,
  old_status text,
  new_status text,
  changed_at timestamptz default now()
);

alter table public.zhk_status_log enable row level security;

-- Лог не содержит личных данных — читать может любой авторизованный,
-- приложение само отфильтрует по избранному пользователя.
drop policy if exists "zhk_status_log_select_authenticated" on public.zhk_status_log;
create policy "zhk_status_log_select_authenticated"
  on public.zhk_status_log for select
  to authenticated
  using (true);

create or replace function public.log_zhk_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if OLD.status is distinct from NEW.status then
    insert into public.zhk_status_log (zhk_id, old_status, new_status)
    values (NEW.id, OLD.status, NEW.status);
  end if;
  return NEW;
end;
$$;

drop trigger if exists on_zhk_status_change on public.zhk;
create trigger on_zhk_status_change
  after update on public.zhk
  for each row execute function public.log_zhk_status_change();
