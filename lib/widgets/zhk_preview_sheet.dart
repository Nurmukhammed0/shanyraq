import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/zhk.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../screens/login_screen.dart';
import '../screens/zhk_detail_screen.dart';
import 'construction_status_row.dart';
import 'zhk_photo_thumbnail.dart';

/// Компактное превью ЖК, которое выезжает снизу при тапе на маркер карты.
/// Полная страница открывается только по кнопке «Подробнее» —
/// так пользователь не грузит весь экран ради беглого взгляда.
Future<void> showZhkPreview(BuildContext context, Zhk zhk) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ZhkPreviewSheet(zhk: zhk),
  );
}

class _ZhkPreviewSheet extends StatelessWidget {
  final Zhk zhk;
  const _ZhkPreviewSheet({required this.zhk});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final favorites = context.watch<FavoritesService>();
    final profile = context.watch<ProfileService>();
    final isFav = favorites.isFavorite(zhk.id);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
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
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (zhk.address != null)
                        Text(
                          zhk.address!,
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (zhk.constructionStatus != null) ...[
                        const SizedBox(height: 4),
                        ConstructionStatusRow(zhk: zhk),
                      ],
                      const SizedBox(height: 6),
                      if (profile.isSubscribed)
                        Text(
                          zhk.isProblematic
                              ? context.tr('zhk_status_problematic')
                              : context.tr('zhk_status_guaranteed'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: zhk.isProblematic ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.lock_outline, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(context.tr('status_locked_short'),
                                style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : null),
                  onPressed: () async {
                    if (!auth.isLoggedIn) {
                      Navigator.of(context).pop();
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
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ZhkDetailScreen(zhk: zhk)),
                  );
                },
                child: Text(context.tr('more_details')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
