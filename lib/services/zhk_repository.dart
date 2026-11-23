import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zhk.dart';

/// Источник данных о ЖК для чтения в обычных (не админских) экранах.
///
/// Читает из zhk_public, а не из таблицы zhk напрямую: RLS таблицы
/// разрешает читать все столбцы кому угодно (нужно админке и нужно,
/// чтобы бесплатные поля — статус, адрес и т.д. — видели все), а
/// платные поля (documentation/tech_status/violations/measures/court)
/// представление отдаёт только подписчикам — см. zhk_public_view.sql.
/// Без этого платный контент был доступен в обход подписки напрямую
/// через anon-ключ.
class ZhkRepository {
  Future<List<Zhk>> fetchFromSupabase() async {
    final client = Supabase.instance.client;
    final rows = await client.from('zhk_public').select().filter('deleted_at', 'is', null);
    return (rows as List)
        .map((row) => Zhk.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
