-- Статус стройки и год сдачи — видны всем пользователям бесплатно,
-- в отличие от документации/нарушений/суда, которые остаются за подпиской.
alter table public.zhk
  add column if not exists construction_status text
    check (construction_status in ('built', 'in_progress')),
  add column if not exists completion_year integer;
