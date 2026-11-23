import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Шлёт сигнал "реестр ЖК изменился" всем, кто сейчас смотрит карту —
/// чтобы они перезапросили список.
///
/// Раньше карта слушала Postgres Changes прямо на таблице zhk, но
/// Supabase Realtime применяет RLS при доставке таких событий, а
/// после того как прямое чтение zhk закрыто для всех, кроме админа
/// (см. supabase/zhk_lock_table_access.sql), обычные пользователи
/// просто перестали бы получать эти события. Broadcast — отдельный
/// канал, не завязанный на RLS таблицы, поэтому сигнал доходит всем,
/// а данные они всё равно получают только через zhk_public.
class ZhkChangeNotifier {
  static const channelName = 'zhk-updates';
  static const event = 'changed';

  static Future<void> notifyChanged() async {
    final client = Supabase.instance.client;
    final channel = client.channel(channelName);
    final subscribed = Completer<void>();

    // subscribe() сам по себе синхронный (не Future) — ждём реального
    // статуса SUBSCRIBED через колбэк, иначе sendBroadcastMessage может
    // уйти раньше, чем сокет готов, и сообщение потеряется.
    channel.subscribe((status, error) {
      if (subscribed.isCompleted) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        subscribed.complete();
      } else if (error != null) {
        subscribed.completeError(error);
      }
    });

    try {
      await subscribed.future.timeout(const Duration(seconds: 5));
      await channel.sendBroadcastMessage(event: event, payload: const {});
    } catch (_) {
      // Сигнал вторичен (данные и так защищены через zhk_public) —
      // если сеть подвела, просто молча пропускаем, без ошибки у админа.
    } finally {
      await client.removeChannel(channel);
    }
  }
}
