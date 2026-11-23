import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/app_city.dart';
import '../models/zhk.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';
import '../services/zhk_repository.dart';
import '../widgets/construction_status_row.dart';
import '../widgets/empty_state_illustration.dart';
import '../widgets/responsive.dart';
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

  List<Zhk> get _byCity {
    final city = context.watch<SettingsService>().city;
    return _all.where((z) => z.city == city).toList();
  }

  // Общая проверка "подходит ли ЖК под статус+район+поиск", принимает
  // статус/район параметрами — нужно и для реального списка (_filtered,
  // закоммиченные _filter/_districtFilter), и для живого счётчика
  // "Показать (N)" в шторке фильтров (черновые, ещё не применённые
  // значения, пока пользователь их крутит).
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
    return statusOk && districtOk && searchOk;
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
                  // Районы — свои для каждого города, старый выбор
                  // мог не иметь смысла в новом городе.
                  setState(() => _districtFilter = null);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Статус и район — в одной шторке вместо вечно открытой строки чипов
  // (как в крупных приложениях: кнопка "Фильтры" -> панель -> "Показать").
  // Выбор внутри шторки черновой (локальные _localFilter/_localDistrict
  // через setSheetState) и применяется одним махом по кнопке снизу —
  // не на каждый тап, чтобы не дёргать список туда-сюда, пока человек
  // ещё выбирает.
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
    // Не используется напрямую здесь (статус/подписка проверяются внутри
    // _openFiltersSheet через context.read) — watch нужен, чтобы экран
    // перерисовался, если подписка изменится, пока он открыт.
    context.watch<ProfileService>();
    final city = context.watch<SettingsService>().city;
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
                            // border: InputBorder.none одного недостаточно —
                            // глобальная тема (main.dart) отдельно задаёт
                            // focusedBorder синим цветом primary, и он
                            // перекрывает border именно в фокусе. Нужно
                            // гасить все состояния явно.
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Переключатель города не нужен, пока поддерживается
                    // только один город — чип с шторкой на один вариант
                    // выглядел бы как нерабочий элемент интерфейса.
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
                    const Spacer(),
                  ],
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
    // На широком экране список стоял бы одной колонкой на всю ширину
    // окна — визуально это просто растянутая мобильная вёрстка. Вместо
    // этого раскладываем карточки сеткой.
    if (isDesktopWidth(context)) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        // mainAxisSpacing: 0 — карточка уже добавляет отступ снизу сама
        // (единый код для списка и сетки), иначе отступ удвоился бы.
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 440,
          mainAxisExtent: 116,
          crossAxisSpacing: 12,
          mainAxisSpacing: 0,
        ),
        itemCount: points.length,
        itemBuilder: (context, i) => _ZhkListCard(zhk: points[i]),
      );
    }
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

/// Кнопка-открывашка шторки фильтров статуса/района. Подсвечена цветом
/// primary, когда применён хотя бы один нестандартный фильтр — чтобы
/// было видно, что список сейчас сужен, даже когда сама шторка закрыта.
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
