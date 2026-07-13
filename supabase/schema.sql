-- ============================================================
-- Схема для проекта "Проблемные ЖК Алматы"
-- Выполнить в Supabase -> SQL Editor
-- ============================================================

-- Таблица ЖК (и проблемных, и завершённых под гарантией)
create table if not exists public.zhk (
  id text primary key,
  name text not null,
  district text,
  address text,
  developer text,
  status text not null check (status in ('problematic', 'completed_guaranteed')),
  documentation text,
  tech_status text,
  violations text,
  measures text,
  court text,
  lat double precision,
  lng double precision,
  created_at timestamptz default now()
);

-- Таблица избранного (связь пользователь <-> ЖК)
create table if not exists public.favorites (
  user_id uuid references auth.users(id) on delete cascade,
  zhk_id text references public.zhk(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, zhk_id)
);

-- Включаем Row Level Security
alter table public.zhk enable row level security;
alter table public.favorites enable row level security;

-- ЖК может читать кто угодно (даже анонимный пользователь, без логина)
drop policy if exists "zhk_read_all" on public.zhk;
create policy "zhk_read_all"
  on public.zhk for select
  using (true);

-- Избранное видит только сам пользователь
drop policy if exists "favorites_select_own" on public.favorites;
create policy "favorites_select_own"
  on public.favorites for select
  using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own"
  on public.favorites for insert
  with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own"
  on public.favorites for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Дальше: залить данные из almaty_zhk_data.json в таблицу zhk.
-- Проще всего через Supabase Table Editor -> Import CSV/JSON,
-- либо через одноразовый скрипт (могу подготовить, когда
-- будут координаты lat/lng после геокодирования адресов).
-- ============================================================
