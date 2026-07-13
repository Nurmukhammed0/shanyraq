import 'package:flutter/foundation.dart';
import '../models/zhk_model.dart';
import 'data_service.dart';
import 'favorites_service.dart';

enum ZhkFilter { all, problematic, completedGuaranteed, favoritesOnly }

class AppState extends ChangeNotifier {
  final LocalDataService _dataService = LocalDataService();
  final FavoritesService _favoritesService = FavoritesService();

  List<Zhk> _all = [];
  Set<String> _favoriteIds = {};
  ZhkFilter _filter = ZhkFilter.all;
  String? _districtFilter; // null = все районы
  bool loading = true;

  List<Zhk> get all => _all;
  Set<String> get favoriteIds => _favoriteIds;
  ZhkFilter get filter => _filter;
  String? get districtFilter => _districtFilter;

  List<String> get districts =>
      _all.map((z) => z.district).whereType<String>().toSet().toList()..sort();

  List<Zhk> get filtered {
    return _all.where((z) {
      final matchesStatus = switch (_filter) {
        ZhkFilter.all => true,
        ZhkFilter.problematic => z.status == ZhkStatus.problematic,
        ZhkFilter.completedGuaranteed => z.status == ZhkStatus.completedGuaranteed,
        ZhkFilter.favoritesOnly => _favoriteIds.contains(z.id),
      };
      final matchesDistrict = _districtFilter == null || z.district == _districtFilter;
      return matchesStatus && matchesDistrict;
    }).toList();
  }

  Future<void> init() async {
    loading = true;
    notifyListeners();
    _all = await _dataService.loadAll();
    try {
      _favoriteIds = await _favoritesService.loadFavoriteIds();
    } catch (_) {
      _favoriteIds = {}; // пользователь не залогинен — избранное пустое
    }
    loading = false;
    notifyListeners();
  }

  Future<void> reloadFavorites() async {
    try {
      _favoriteIds = await _favoritesService.loadFavoriteIds();
    } catch (_) {
      _favoriteIds = {};
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String zhkId) async {
    final isFav = _favoriteIds.contains(zhkId);
    // оптимистичное обновление UI
    if (isFav) {
      _favoriteIds.remove(zhkId);
    } else {
      _favoriteIds.add(zhkId);
    }
    notifyListeners();

    try {
      await _favoritesService.toggleFavorite(zhkId, isFav);
    } catch (e) {
      // откат при ошибке (например, не залогинен)
      if (isFav) {
        _favoriteIds.add(zhkId);
      } else {
        _favoriteIds.remove(zhkId);
      }
      notifyListeners();
      rethrow;
    }
  }

  void setFilter(ZhkFilter f) {
    _filter = f;
    notifyListeners();
  }

  void setDistrict(String? d) {
    _districtFilter = d;
    notifyListeners();
  }
}
