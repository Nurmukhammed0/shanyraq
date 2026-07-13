import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/zhk.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/zhk_repository.dart';
import '../widgets/empty_state_illustration.dart';
import '../widgets/zhk_photo_thumbnail.dart';
import 'zhk_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _repo = ZhkRepository();
  List<Zhk> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<FavoritesService>().load();
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

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesService>();
    final profile = context.watch<ProfileService>();
    final favZhk = _all.where((z) => favorites.isFavorite(z.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('nav_favorites')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _init),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Ошибка загрузки избранного: $_error'),
                  ),
                )
              : favZhk.isEmpty
                  ? _buildEmpty(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favZhk.length,
                      itemBuilder: (context, i) {
                        final z = favZhk[i];
                        return _FavoriteCard(
                          zhk: z,
                          isSubscribed: profile.isSubscribed,
                          onRemove: () async {
                            try {
                              await favorites.remove(z.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ошибка: $e')));
                              }
                            }
                          },
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => ZhkDetailScreen(zhk: z)),
                            );
                          },
                        );
                      },
                    ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyStateIllustration(badgeIcon: Icons.favorite),
            const SizedBox(height: 20),
            Text(
              context.tr('favorites_empty_title'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('favorites_empty_body'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Zhk zhk;
  final bool isSubscribed;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.zhk,
    required this.isSubscribed,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = [zhk.district, zhk.address].whereType<String>().join(' · ');
    final statusColor = zhk.isProblematic ? const Color(0xFFE24B4A) : const Color(0xFF22C55E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                      const SizedBox(height: 8),
                      isSubscribed
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
                    icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                    onPressed: onRemove,
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
