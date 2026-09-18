import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';

/// Источник данных объявлений «Купить дом» — таблица listings в Supabase.
class ListingRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Listing>> fetchAll() async {
    final rows = await _client
        .from('listings')
        .select()
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Listing.fromJson(row as Map<String, dynamic>)).toList();
  }

  Future<void> create(Listing listing) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('listings').insert(listing.toInsertJson(userId));
  }

  Future<void> softDelete(String id) async {
    await _client.from('listings').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
  }
}
