-- ============================================================
-- Закрывает прямой анонимный доступ к таблице zhk — ранее можно
-- было обойти zhk_public (представление с усечёнными платными
-- полями), просто обратившись напрямую к /rest/v1/zhk?select=*,
-- если знать/угадать имя таблицы. Теперь читать саму таблицу
-- напрямую может только админ; все остальные — через zhk_public.
--
-- Выполнить ПОСЛЕ zhk_public_view.sql, в Supabase -> SQL Editor.
-- ============================================================

-- Пересоздаём zhk_public БЕЗ security_invoker: представление должно
-- выполняться с правами владельца (видит все строки в обход RLS
-- таблицы, само решает, что обрезать по подписке) — иначе, как только
-- ниже мы запретим обычным пользователям читать zhk напрямую, то же
-- самое ограничение ударило бы и по self-invoking представлению,
-- и оно перестало бы отдавать вообще что-либо не-админам.
create or replace view public.zhk_public
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

-- Таблицу напрямую теперь может читать только админ.
drop policy if exists "zhk_read_all" on public.zhk;
create policy "zhk_read_admin_only"
  on public.zhk for select
  using (public.is_admin());

-- ============================================================
-- Важно: Supabase Realtime (Postgres Changes) учитывает RLS при
-- рассылке событий — после этой миграции обычные пользователи
-- больше не получат событий по изменениям в zhk через
-- onPostgresChanges(table: 'zhk', ...), даже если подписаны на канал
-- (RLS блокирует доставку, не только сам SELECT). Поэтому
-- lib/screens/map_screen.dart переключён на Realtime Broadcast
-- (отдельный канал 'zhk-updates', не завязан на RLS таблицы) —
-- админ отправляет сообщение "что-то изменилось" после своих правок
-- (см. lib/services/zhk_change_notifier.dart), все остальные слушают
-- и просто перезапрашивают zhk_public.
-- ============================================================
