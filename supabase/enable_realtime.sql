-- Включаем Realtime-трансляцию изменений для карты (авто-обновление
-- при добавлении/редактировании/удалении ЖК другим пользователем/вкладкой)
-- и для лога статусов (живые уведомления).
alter publication supabase_realtime add table public.zhk;
alter publication supabase_realtime add table public.zhk_status_log;
