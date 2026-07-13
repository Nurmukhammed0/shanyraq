import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zhk.dart';

/// Источник данных о ЖК.
///
/// Сейчас читает из локального assets/almaty_zhk_data.json (MVP,
/// без бэкенда). Когда подключим Supabase — просто переключаемся
/// на fetchFromSupabase() без изменений в экранах.
class ZhkRepository {
  Future<List<Zhk>> fetchFromLocalAsset() async {
    final raw = await rootBundle.loadString('assets/almaty_zhk_data.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final problematic = (data['problematic'] as List)
        .map((e) => Zhk.fromJson({...e as Map<String, dynamic>, 'status': 'problematic'}))
        .toList();

    final completed = (data['completed_guaranteed_almaty'] as List)
        .map((e) => Zhk.fromJson({...e as Map<String, dynamic>, 'status': 'completed_guaranteed'}))
        .toList();

    return [...problematic, ...completed];
  }

  Future<List<Zhk>> fetchFromSupabase() async {
    final client = Supabase.instance.client;
    final rows = await client.from('zhk').select().filter('deleted_at', 'is', null);
    return (rows as List)
        .map((row) => Zhk.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
