import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zhk.dart';

/// Источник данных о ЖК — таблица zhk в Supabase.
class ZhkRepository {
  Future<List<Zhk>> fetchFromSupabase() async {
    final client = Supabase.instance.client;
    final rows = await client.from('zhk').select().filter('deleted_at', 'is', null);
    return (rows as List)
        .map((row) => Zhk.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
