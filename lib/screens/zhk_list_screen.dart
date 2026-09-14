import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/zhk.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/zhk_repository.dart';
import '../widgets/construction_status_row.dart';
import '../widgets/empty_state_illustration.dart';
import '../widgets/zhk_photo_thumbnail.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'subscription_screen.dart';
import 'zhk_detail_screen.dart';

/// Список ЖК с документами/статусами — основной рабочий раздел.
/// Те же фильтры (статус, район), что и на карте; кнопка «Карта»
/// открывает существующую карту с уже выбранными фильтрами.
class ZhkListScreen extends StatefulWidget {
  const ZhkListScreen({super.key});

  @override
  State<ZhkListScreen> createState() => _ZhkListScreenState();
}

class _ZhkListScreenState extends State<ZhkListScreen> {
  final _repo = ZhkRepository();
  final _searchController = TextEditingController();
  List<Zhk> _all = [];
  bool _loading = true;
  String? _error;
  ZhkFilter _filter = ZhkFilter.all;
  String? _districtFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.fetchFromSupabase();
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
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
      return statusOk && districtOk && searchOk;
    }).toList();
  }

  List<String> get _districts {
    final set = _all.map((e) => e.district).whereType<String>().toSet().toList();
    set.sort();
    return set;
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
  }

  void _openMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(initialFilter: _filter, initialDistrict: _districtFilter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    final colorScheme = Theme.of(context).colorScheme;
    final points = _loading || _error != null ? const <Zhk>[] : _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('home_documents_title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Material(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
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
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Город: сейчас в базе только Алматы, поэтому фильтр
                      // статичный — переключение появится вместе со вторым
                      // городом в данных.
                      _StaticChip(icon: Icons.location_city, label: context.tr('zhk_list_city_almaty')),
                      const SizedBox(width: 8),
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
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(points)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMap,
        icon: const Icon(Icons.map_outlined),
        label: Text(context.tr('nav_map')),
      ),
    );
  }

  Widget _buildBody(List<Zhk> points) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.tr('favorites_load_error', {'error': _error!})),
        ),
      );
    }
    if (points.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: points.length,
      itemBuilder: (context, i) => _ZhkListCard(zhk: points[i]),
    );
  }

  Widget _buildEmpty() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyStateIllustration(badgeIcon: Icons.search_off),
            const SizedBox(height: 20),
            Text(context.tr('zhk_list_empty_title'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(context.tr('zhk_list_empty_body'),
                textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ZhkListCard extends StatelessWidget {
  final Zhk zhk;
  const _ZhkListCard({required this.zhk});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthService>();
    final favorites = context.watch<FavoritesService>();
    final profile = context.watch<ProfileService>();
    final isFav = favorites.isFavorite(zhk.id);
    final description = [zhk.district, zhk.address].whereType<String>().join(' · ');
    final statusColor = zhk.isProblematic ? const Color(0xFFE24B4A) : const Color(0xFF22C55E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ZhkDetailScreen(zhk: zhk)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ZhkPhotoThumbnail(photoUrl: zhk.photoUrl, width: 84, height: 84),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zhk.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (zhk.constructionStatus != null) ...[
                        const SizedBox(height: 6),
                        ConstructionStatusRow(zhk: zhk, iconSize: 14, fontSize: 12),
                      ],
                      const SizedBox(height: 8),
                      profile.isSubscribed
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                zhk.isProblematic
                                    ? context.tr('status_red_zone_short')
                                    : context.tr('status_guaranteed_short'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 12, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 3),
                                Text(context.tr('status_locked_short'),
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                    ],
                  ),
                ),
                Material(
                  color: colorScheme.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : null),
                    onPressed: () async {
                      if (!auth.isLoggedIn) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                        return;
                      }
                      try {
                        await favorites.toggle(zhk.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(context.tr('generic_error', {'error': '$e'}))));
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StaticChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
          ],
        ),
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
