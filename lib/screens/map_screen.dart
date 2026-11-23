import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/app_city.dart';
import '../models/zhk.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/zhk_repository.dart';
import '../widgets/zhk_preview_sheet.dart';
import 'admin_zhk_edit_screen.dart';
import 'notifications_screen.dart';
import 'subscription_screen.dart';

enum ZhkFilter { all, problematic, completedGuaranteed }

// Примерные центры городов — используются для начального положения
// карты при переключении города (а не координаты конкретных ЖК).
const _cityCenters = <String, LatLng>{
  AppCity.almaty: LatLng(43.2220, 76.8512),
  AppCity.astana: LatLng(51.1694, 71.4491),
  AppCity.shymkent: LatLng(42.3417, 69.5901),
};

class MapScreen extends StatefulWidget {
  // Заданы, когда карту открывают из списка ЖК с уже выбранными
  // фильтрами (например, «Алматы + только проблемные»). По умолчанию
  // (обычный вход в карту) — null, поведение не меняется.
  final ZhkFilter? initialFilter;
  final String? initialDistrict;

  const MapScreen({super.key, this.initialFilter, this.initialDistrict});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _repo = ZhkRepository();
  final _mapController = MapController();
  final _searchController = TextEditingController();
  List<Zhk> _all = [];
  bool _loading = true;
  ZhkFilter _filter = ZhkFilter.all;
  String? _districtFilter;
  String _searchQuery = '';
  LatLng? _myLocation;
  bool _locating = false;
  int _unseenNotifications = 0;
  RealtimeChannel? _zhkChannel;
  RealtimeChannel? _statusChannel;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? ZhkFilter.all;
    _districtFilter = widget.initialDistrict;
    _load();
    _refreshUnseenNotifications();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    final client = Supabase.instance.client;

    // Карта: любое изменение в zhk (добавили/отредактировали/удалили/
    // восстановили из корзины — с любого устройства или вкладки) —
    // перезагружаем список без ручного refresh страницы.
    _zhkChannel = client
        .channel('public:zhk')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'zhk',
          callback: (payload) => _load(),
        )
        .subscribe();

    // Уведомления: новая запись в логе статусов — пересчитываем бейдж
    // сразу, не дожидаясь, пока пользователь откроет экран уведомлений.
    _statusChannel = client
        .channel('public:zhk_status_log')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'zhk_status_log',
          callback: (payload) => _refreshUnseenNotifications(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_zhkChannel != null) Supabase.instance.client.removeChannel(_zhkChannel!);
    if (_statusChannel != null) Supabase.instance.client.removeChannel(_statusChannel!);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _repo.fetchFromSupabase();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  Future<void> _refreshUnseenNotifications() async {
    if (!context.read<AuthService>().isLoggedIn) return;
    if (!context.read<SettingsService>().statusNotifications) {
      setState(() => _unseenNotifications = 0);
      return;
    }
    final count = await NotificationsScreen.unseenCount(context.read<FavoritesService>());
    if (!mounted) return;
    setState(() => _unseenNotifications = count);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _refreshUnseenNotifications();
  }

  List<Zhk> get _byCity {
    final city = context.watch<SettingsService>().city;
    return _all.where((z) => z.city == city).toList();
  }

  // См. zhk_list_screen.dart — тот же приём: статус/район параметрами,
  // чтобы использовать и для реального списка, и для черновых значений
  // в шторке фильтров (живой счётчик "Показать (N)" до применения).
  bool _matches(Zhk z, {required ZhkFilter filter, required String? district}) {
    final statusOk = switch (filter) {
      ZhkFilter.all => true,
      ZhkFilter.problematic => z.status == 'problematic',
      ZhkFilter.completedGuaranteed => z.status == 'completed_guaranteed',
    };
    final districtOk = district == null || z.district == district;
    final query = _searchQuery.trim().toLowerCase();
    final searchOk = query.isEmpty ||
        z.name.toLowerCase().contains(query) ||
        (z.address?.toLowerCase().contains(query) ?? false);
    return statusOk && districtOk && searchOk && z.hasCoordinates;
  }

  List<Zhk> get _filtered {
    final isSubscribed = context.read<ProfileService>().isSubscribed;
    final effectiveFilter = isSubscribed ? _filter : ZhkFilter.all;
    return _byCity.where((z) => _matches(z, filter: effectiveFilter, district: _districtFilter)).toList();
  }

  List<String> get _districts {
    final set = _byCity.map((e) => e.district).whereType<String>().toSet().toList();
    set.sort();
    return set;
  }

  Future<void> _openCitySheet() async {
    final settings = context.read<SettingsService>();
    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(context.tr('city_picker_title'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final city in AppCity.all)
              ListTile(
                title: Text(context.tr(AppCity.labelKey(city))),
                trailing: settings.city == city ? Icon(Icons.check, color: colorScheme.primary) : null,
                onTap: () {
                  settings.setCity(city);
                  setState(() => _districtFilter = null);
                  Navigator.pop(ctx);
                  _mapController.move(_cityCenters[city] ?? _cityCenters[AppCity.almaty]!, 11);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openZhk(Zhk zhk) {
    showZhkPreview(context, zhk);
  }

  Future<void> _addZhkAt(LatLng point) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminZhkEditScreen(
          existing: {'lat': point.latitude, 'lng': point.longitude},
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        _showLocationError(context.tr('map_location_services_disabled'));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showLocationError(context.tr('map_location_permission_denied'));
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _myLocation = point);
      _mapController.move(point, 15);
    } catch (_) {
      if (mounted) _showLocationError(context.tr('map_location_unavailable'));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // См. zhk_list_screen.dart — тот же паттерн: кнопка "Фильтры" ->
  // шторка со статусом и районом -> "Показать" применяет разом.
  Future<void> _openFiltersSheet() async {
    final profile = context.read<ProfileService>();
    var localFilter = _filter;
    var localDistrict = _districtFilter;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            final effectiveLocalFilter = profile.isSubscribed ? localFilter : ZhkFilter.all;
            final matchCount = _byCity
                .where((z) => _matches(z, filter: effectiveLocalFilter, district: localDistrict))
                .length;

            Widget statusTile({
              required ZhkFilter value,
              required String label,
              Color? dotColor,
              bool locked = false,
            }) {
              final selected = localFilter == value;
              return ListTile(
                leading: dotColor == null
                    ? const SizedBox(width: 10)
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                      ),
                title: Text(label),
                trailing: locked
                    ? Icon(Icons.lock_outline, size: 18, color: colorScheme.onSurfaceVariant)
                    : (selected ? Icon(Icons.check, color: colorScheme.primary) : null),
                onTap: locked
                    ? () {
                        Navigator.pop(ctx);
                        _openSubscription();
                      }
                    : () => setSheetState(() => localFilter = value),
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
                    child: Row(
                      children: [
                        Text(context.tr('filters_button'),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setSheetState(() {
                            localFilter = ZhkFilter.all;
                            localDistrict = null;
                          }),
                          child: Text(context.tr('filters_reset')),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          child: Text(context.tr('filters_status_section'),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12.5, color: colorScheme.onSurfaceVariant)),
                        ),
                        statusTile(value: ZhkFilter.all, label: context.tr('filter_all')),
                        statusTile(
                          value: ZhkFilter.problematic,
                          label: context.tr('filter_problematic'),
                          dotColor: const Color(0xFFE24B4A),
                          locked: !profile.isSubscribed,
                        ),
                        statusTile(
                          value: ZhkFilter.completedGuaranteed,
                          label: context.tr('filter_guaranteed'),
                          dotColor: const Color(0xFF22C55E),
                          locked: !profile.isSubscribed,
                        ),
                        const Divider(height: 24),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                          child: Text(context.tr('filter_district_hint'),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12.5, color: colorScheme.onSurfaceVariant)),
                        ),
                        ListTile(
                          title: Text(context.tr('filter_district_all')),
                          trailing:
                              localDistrict == null ? Icon(Icons.check, color: colorScheme.primary) : null,
                          onTap: () => setSheetState(() => localDistrict = null),
                        ),
                        ..._districts.map((d) => ListTile(
                              title: Text(d),
                              trailing:
                                  localDistrict == d ? Icon(Icons.check, color: colorScheme.primary) : null,
                              onTap: () => setSheetState(() => localDistrict = d),
                            )),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: () {
                        setState(() {
                          _filter = localFilter;
                          _districtFilter = localDistrict;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(context.tr('filters_show_results', {'n': '$matchCount'})),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSubscription() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    final auth = context.watch<AuthService>();
    final city = context.watch<SettingsService>().city;
    final points = _filtered;
    final withoutCoords = _byCity.where((z) => !z.hasCoordinates).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Esri Canvas (light/dark gray base) — обобщённая справочная подложка,
    // почти не обновляется для новых/неформальных районов на окраинах
    // Алматы (там как раз много объектов из списка). Переходим на обычные
    // тайлы OpenStreetMap — покрытие улиц там намного актуальнее
    // (сообщество регулярно дорисовывает новые дороги).
    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _cityCenters[city] ?? _cityCenters[AppCity.almaty]!,
                    initialZoom: 11,
                    interactionOptions: const InteractionOptions(
                      // Поворот карты выключен: наши маркеры-капли не
                      // разворачиваются вместе с картой, при вращении
                      // выглядят и работают некорректно.
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onLongPress: profile.isAdmin
                        ? (tapPosition, point) => _addZhkAt(point)
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tileUrl,
                      userAgentPackageName: 'com.example.almaty_zhk_app',
                    ),
                    if (isDark)
                      // Лёгкий полупрозрачный оверлей вместо ColorFiltered-матрицы:
                      // SVG color-matrix фильтр поверх целой карты — известный
                      // источник крашей WebKit на iOS в html-рендерере Flutter Web.
                      IgnorePointer(
                        child: Container(color: const Color(0xFF13224A).withOpacity(0.16)),
                      ),
                    const RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        ...points.map((z) {
                          final Color pinColor;
                          final IconData pinIcon;
                          if (profile.isSubscribed) {
                            if (z.isProblematic) {
                              pinColor = const Color(0xFFE24B4A);
                              pinIcon = Icons.priority_high_rounded;
                            } else {
                              pinColor = const Color(0xFF22C55E);
                              pinIcon = Icons.check_rounded;
                            }
                          } else {
                            pinColor = Theme.of(context).colorScheme.primary;
                            pinIcon = Icons.home_rounded;
                          }
                          return Marker(
                            point: LatLng(z.lat!, z.lng!),
                            width: 26,
                            height: 30,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () => _openZhk(z),
                              child: _ZhkPin(color: pinColor, icon: pinIcon),
                            ),
                          );
                        }),
                        if (_myLocation != null)
                          Marker(
                            point: _myLocation!,
                            width: 22,
                            height: 22,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (profile.isAdmin)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('map_long_press_hint'),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                // Плавающая строка поиска — заменяет обычный AppBar,
                // карта идёт от самого верха экрана. Ниже — постоянный
                // ряд чипсов-фильтров (в духе 2ГИС), без выезжающей панели.
                Positioned(
                  top: topInset + 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (Navigator.of(context).canPop()) ...[
                            Material(
                              elevation: 3,
                              shadowColor: Colors.black26,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Material(
                              elevation: 3,
                              shadowColor: Colors.black26,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                children: [
                                  const SizedBox(width: 14),
                                  Icon(Icons.search,
                                      size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: context.tr('search_hint'),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        filled: false,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      onChanged: (v) => setState(() => _searchQuery = v),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  else
                                    const SizedBox(width: 14),
                                ],
                              ),
                            ),
                          ),
                          if (auth.isLoggedIn) ...[
                            const SizedBox(width: 8),
                            Material(
                              elevation: 3,
                              shadowColor: Colors.black26,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                icon: Badge(
                                  label: Text('$_unseenNotifications'),
                                  isLabelVisible: _unseenNotifications > 0,
                                  child: Icon(
                                    _unseenNotifications > 0
                                        ? Icons.notifications
                                        : Icons.notifications_none,
                                  ),
                                ),
                                tooltip: context.tr('map_notifications_tooltip'),
                                onPressed: _openNotifications,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildChipsRow(),
                    ],
                  ),
                ),
                if (withoutCoords > 0)
                  Positioned(
                    top: topInset + 120,
                    left: 12,
                    right: 12,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          context.tr('map_missing_coords', {'n': '$withoutCoords'}),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            IconButton(
                              tooltip: context.tr('map_locate_tooltip'),
                              onPressed: _locating ? null : _locateMe,
                              icon: _locating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                            ),
                            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                            IconButton(
                              tooltip: context.tr('map_zoom_in_tooltip'),
                              onPressed: () => _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              ),
                              icon: const Icon(Icons.add),
                            ),
                            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                            IconButton(
                              tooltip: context.tr('map_zoom_out_tooltip'),
                              onPressed: () => _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              ),
                              icon: const Icon(Icons.remove),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChipsRow() {
    final city = context.watch<SettingsService>().city;
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          if (AppCity.all.length > 1) ...[
            _FilterChip(
              label: context.tr(AppCity.labelKey(city)),
              selected: true,
              icon: Icons.expand_more,
              onTap: _openCitySheet,
            ),
            const SizedBox(width: 8),
          ],
          _FiltersButton(
            active: _filter != ZhkFilter.all || _districtFilter != null,
            onTap: _openFiltersSheet,
          ),
        ],
      ),
    );
  }
}

// Каплевидный маркер (в духе 2ГИС/Google Maps): кружок с иконкой статуса
// на белом ободке и хвостик-указатель снизу, острие которого совпадает
// с координатой (см. alignment: Alignment.topCenter у Marker).
class _ZhkPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _ZhkPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 18,
            left: 8.5,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 3, offset: const Offset(0, 1.5)),
                ],
              ),
              child: Icon(icon, size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;
  final IconData? icon;
  final bool locked;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
    this.icon,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fg = selected ? colorScheme.onPrimary : colorScheme.onSurface;
    return Material(
      color: selected ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                ),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
              if (locked) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock_outline, size: 12, color: fg.withOpacity(0.8)),
              ],
              if (icon != null) ...[
                const SizedBox(width: 2),
                Icon(icon, size: 16, color: fg.withOpacity(0.8)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// См. zhk_list_screen.dart — тот же виджет, своя копия (приватный
/// класс, файл не делится кодом с экраном списка).
class _FiltersButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FiltersButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fg = active ? colorScheme.onPrimary : colorScheme.onSurface;
    return Material(
      color: active ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 17, color: fg),
              const SizedBox(width: 6),
              Text(context.tr('filters_button'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
