-- ============================================================
-- Представление zhk_public — закрывает реальную дыру в приватности:
-- политика "zhk_read_all" на таблице zhk разрешает читать ВСЁ (в том
-- числе платные поля documentation/tech_status/violations/measures/
-- court) кому угодно, включая анонимных пользователей без подписки —
-- Row Level Security управляет видимостью СТРОК, а не столбцов, так
-- что ограничение "подписка нужна для этих полей" до сих пор было
-- только в UI Flutter. Любой человек с публичным anon-ключом (он и
-- так виден всем в клиентском коде — это нормально для Supabase) мог
-- одним запросом к /rest/v1/zhk?select=* получить весь платный контент
-- бесплатно, в обход подписки.
--
-- Это представление отдаёт платные поля только тем, у кого
-- profiles.is_subscribed = true, остальным — null. Приложение теперь
-- читает именно его (см. ZhkRepository.fetchFromSupabase), а не
-- таблицу zhk напрямую. Запись (админка) как и раньше идёт прямо в
-- zhk — там отдельные политики "только админ", представление их не
-- затрагивает.
--
-- security_invoker = true (Postgres 15+, в Supabase по умолчанию) —
-- без этого представление выполнялось бы с правами ВЛАДЕЛЬЦА (обычно
-- с правами, которые видят вообще всё), а не с правами того, кто
-- сейчас делает запрос, и RLS таблицы zhk могло бы просто не
-- учитываться.
--
-- Выполнить в Supabase -> SQL Editor.
-- ============================================================

create or replace view public.zhk_public
with (security_invoker = true)
as
select
  z.id,
  z.name,
  z.city,
  z.district,
  z.address,
  z.developer,
  z.status,
  z.lat,
  z.lng,
  z.photo_url,
  z.construction_status,
  z.completion_year,
  z.created_at,
  z.deleted_at,
  case when s.subscribed then z.documentation else null end as documentation,
  case when s.subscribed then z.tech_status else null end as tech_status,
  case when s.subscribed then z.violations else null end as violations,
  case when s.subscribed then z.measures else null end as measures,
  case when s.subscribed then z.court else null end as court
from public.zhk z
cross join lateral (
  select exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.is_subscribed
  ) as subscribed
) s;

grant select on public.zhk_public to anon, authenticated;
