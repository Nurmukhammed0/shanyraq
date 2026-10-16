import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';

/// Источник данных объявлений «Купить дом» — таблица listings в Supabase.
/// Новое объявление создаётся со статусом pending и становится видно
/// всем только после одобрения админом (approved) — см. listings_moderation.sql.
class ListingRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Публичная лента — только одобренные объявления. RLS и так это
  /// гарантирует для чужих запросов, фильтр здесь — чтобы админ видел
  /// тот же вид ленты, что и обычный пользователь.
  Future<List<Listing>> fetchApproved() async {
    final rows = await _client
        .from('listings')
        .select()
        .filter('deleted_at', 'is', null)
        .eq('status', 'approved')
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Listing.fromJson(row as Map<String, dynamic>)).toList();
  }

  /// Объявления текущего пользователя — любого статуса (видно только
  /// самому владельцу по RLS).
  Future<List<Listing>> fetchOwn() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('listings')
        .select()
        .filter('deleted_at', 'is', null)
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Listing.fromJson(row as Map<String, dynamic>)).toList();
  }

  /// Для админа — все объявления (опционально отфильтрованные по статусу).
  Future<List<Listing>> fetchForModeration({String? status}) async {
    var query = _client.from('listings').select().filter('deleted_at', 'is', null);
    if (status != null) query = query.eq('status', status);
    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((row) => Listing.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<void> create(Listing listing) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('listings').insert(listing.toInsertJson(userId));
  }

  Future<void> setStatus(String id, String status) async {
    await _client.from('listings').update({'status': status}).eq('id', id);
  }

  Future<void> softDelete(String id) async {
    await _client.from('listings').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
  }
}
