import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Избранные ЖК текущего пользователя. Хранится в Supabase
/// (таблица favorites), кэшируется локально в памяти как Set<String>
/// с id ЖК для быстрой проверки в UI (isFavorite).
class FavoritesService extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String zhkId) => _favoriteIds.contains(zhkId);

  SupabaseClient get _client => Supabase.instance.client;

  /// Загрузить избранное текущего пользователя из Supabase.
  /// Вызывать после логина / при старте, если пользователь уже вошёл.
  Future<void> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _favoriteIds.clear();
      notifyListeners();
      return;
    }
    final rows = await _client
        .from('favorites')
        .select('zhk_id')
        .eq('user_id', userId);

    _favoriteIds
      ..clear()
      ..addAll((rows as List).map((r) => r['zhk_id'] as String));
    notifyListeners();
  }

  Future<void> toggle(String zhkId) async {
    if (isFavorite(zhkId)) {
      await remove(zhkId);
    } else {
      await add(zhkId);
    }
  }

  Future<void> add(String zhkId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return; // экран должен требовать логин перед вызовом
    _favoriteIds.add(zhkId); // оптимистично обновляем UI
    notifyListeners();
    try {
      await _client.from('favorites').insert({
        'user_id': userId,
        'zhk_id': zhkId,
      });
    } catch (_) {
      // Не удалось сохранить на сервере — откатываем оптимистичное
      // обновление, чтобы UI не врал о состоянии избранного.
      _favoriteIds.remove(zhkId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> remove(String zhkId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    _favoriteIds.remove(zhkId);
    notifyListeners();
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('zhk_id', zhkId);
    } catch (_) {
      _favoriteIds.add(zhkId);
      notifyListeners();
      rethrow;
    }
  }

  /// Вызывать при выходе из аккаунта.
  void clear() {
    _favoriteIds.clear();
    notifyListeners();
  }
}
