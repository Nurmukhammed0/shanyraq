import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/zhk_model.dart';

/// Загружает ЖК из локального bundled JSON (assets/almaty_zhk_data.json).
/// Полезно на старте (без бэкенда) и как источник для скрипта импорта в Supabase.
class LocalDataService {
  Future<List<Zhk>> loadAll() async {
    final raw = await rootBundle.loadString('assets/almaty_zhk_data.json');
    final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;

    final List<Zhk> result = [];

    final problematic = (data['problematic'] as List<dynamic>? ?? []);
    for (final item in problematic) {
      result.add(Zhk.fromJson(item as Map<String, dynamic>, ZhkStatus.problematic));
    }

    final completed = (data['completed_guaranteed_almaty'] as List<dynamic>? ?? []);
    for (final item in completed) {
      result.add(Zhk.fromJson(item as Map<String, dynamic>, ZhkStatus.completedGuaranteed));
    }

    return result;
  }
}
