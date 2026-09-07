-- ============================================================
-- Заглушка оплаты подписки: пользователь сам активирует себе
-- is_subscribed через узкую функцию (RLS на profiles остаётся
-- admin-only, см. profiles_and_subscriptions.sql). Реальной оплаты
-- пока нет — когда подключите платёжный шлюз, вызывайте эту же
-- функцию из вебхука после подтверждения платежа, а не напрямую
-- с клиента по нажатию кнопки.
-- ============================================================
create or replace function public.activate_own_subscription()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set is_subscribed = true
  where id = auth.uid();
end;
$$;

grant execute on function public.activate_own_subscription() to authenticated;
