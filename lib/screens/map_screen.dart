import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/zhk.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/zhk_repository.dart';
import '../widgets/zhk_preview_sheet.dart';
import 'admin_zhk_edit_screen.dart';
import 'notifications_screen.dart';
import 'subscription_screen.dart';

enum ZhkFilter { all, problematic, completedGuaranteed }

// Примерный центр Алматы — используется, пока нет геокодированных
// координат у части объектов.
const _almatyCenter = LatLng(43.2220, 76.8512);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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

  List<Zhk> get _filtered {
    final isSubscribed = context.read<ProfileService>().isSubscribed;
    final effectiveFilter = isSubscribed ? _filter : ZhkFilter.all;
    return _all.where((z) {
      final statusOk = switch (effectiveFilter) {
        ZhkFilter.all => true,
        ZhkFilter.problematic => z.status == 'problematic',
        ZhkFilter.completedGuaranteed => z.status == 'completed_guaranteed',
      };
      final districtOk = _districtFilter == null || z.district == _districtFilter;
      final query = _searchQuery.trim().toLowerCase();
      final searchOk = query.isEmpty ||
          z.name.toLowerCase().contains(query) ||
          (z.address?.toLowerCase().contains(query) ?? false);
      return statusOk && districtOk && searchOk && z.hasCoordinates;
    }).toList();
  }

  List<String> get _districts {
    final set = _all.map((e) => e.district).whereType<String>().toSet().toList();
    set.sort();
    return set;
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

  Future<void> _openDistrictSheet() async {
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
              child: Text(context.tr('filter_district_hint'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              title: Text(context.tr('filter_district_all')),
              trailing: _districtFilter == null ? Icon(Icons.check, color: colorScheme.primary) : null,
              onTap: () {
                setState(() => _districtFilter = null);
                Navigator.pop(ctx);
              },
            ),
            ..._districts.map((d) => ListTile(
                  title: Text(d),
                  trailing: _districtFilter == d ? Icon(Icons.check, color: colorScheme.primary) : null,
                  onTap: () {
                    setState(() => _districtFilter = d);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
    final points = _filtered;
    final withoutCoords = _all.where((z) => !z.hasCoordinates).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // CARTO теперь требует платный API-ключ для basemaps.cartocdn.com —
    // используем бесплатные тайлы Esri (ключ не нужен).
    final tileUrl = isDark
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}'
        : 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}';

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
                    initialCenter: _almatyCenter,
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
                        TextSourceAttribution('Esri'),
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
                                tooltip: 'Уведомления',
                                onPressed: _openNotifications,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildChipsRow(profile),
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
                              tooltip: 'Мой геолокация',
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
                              tooltip: 'Увеличить',
                              onPressed: () => _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              ),
                              icon: const Icon(Icons.add),
                            ),
                            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                            IconButton(
                              tooltip: 'Уменьшить',
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

  Widget _buildChipsRow(ProfileService profile) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: context.tr('filter_all'),
            selected: _filter == ZhkFilter.all,
            onTap: () => setState(() => _filter = ZhkFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: context.tr('filter_problematic'),
            selected: _filter == ZhkFilter.problematic,
            dotColor: const Color(0xFFE24B4A),
            locked: !profile.isSubscribed,
            onTap: profile.isSubscribed
                ? () => setState(() => _filter = ZhkFilter.problematic)
                : _openSubscription,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: context.tr('filter_guaranteed'),
            selected: _filter == ZhkFilter.completedGuaranteed,
            dotColor: const Color(0xFF22C55E),
            locked: !profile.isSubscribed,
            onTap: profile.isSubscribed
                ? () => setState(() => _filter = ZhkFilter.completedGuaranteed)
                : _openSubscription,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _districtFilter ?? context.tr('filter_district_hint'),
            selected: _districtFilter != null,
            icon: Icons.expand_more,
            onTap: _openDistrictSheet,
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
