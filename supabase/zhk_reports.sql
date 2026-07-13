-- ============================================================
-- Обращения пользователей: "сообщить об ошибке / уточнить данные"
-- по конкретному ЖК.
-- ============================================================

create table if not exists public.zhk_reports (
  id uuid primary key default gen_random_uuid(),
  zhk_id text references public.zhk(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  message text not null,
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_at timestamptz default now()
);

alter table public.zhk_reports enable row level security;

drop policy if exists "zhk_reports_insert_own" on public.zhk_reports;
create policy "zhk_reports_insert_own"
  on public.zhk_reports for insert
  with check (auth.uid() = user_id);

drop policy if exists "zhk_reports_select_own_or_admin" on public.zhk_reports;
create policy "zhk_reports_select_own_or_admin"
  on public.zhk_reports for select
  using (auth.uid() = user_id or public.is_admin());

drop policy if exists "zhk_reports_update_admin_only" on public.zhk_reports;
create policy "zhk_reports_update_admin_only"
  on public.zhk_reports for update
  using (public.is_admin())
  with check (public.is_admin());
