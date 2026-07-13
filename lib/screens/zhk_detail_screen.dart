import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';
import '../models/zhk.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../widgets/construction_status_row.dart';
import '../widgets/zhk_photo_thumbnail.dart';
import 'admin_zhk_edit_screen.dart';
import 'login_screen.dart';
import 'report_issue_dialog.dart';
import 'subscription_screen.dart';

class ZhkDetailScreen extends StatelessWidget {
  final Zhk zhk;
  const ZhkDetailScreen({super.key, required this.zhk});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('zhk_delete_confirm_title')),
        content: Text(context.tr('zhk_delete_confirm_body', {'name': zhk.name})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final updated = await Supabase.instance.client
          .from('zhk')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', zhk.id)
          .select();
      if (updated.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Объект не удалён: сервер не нашёл строку (проверьте id/RLS).')),
          );
        }
        return;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
      return;
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  bool get _hasDetails =>
      (zhk.documentation?.isNotEmpty ?? false) ||
      (zhk.techStatus?.isNotEmpty ?? false) ||
      (zhk.violations?.isNotEmpty ?? false) ||
      (zhk.measures?.isNotEmpty ?? false) ||
      (zhk.court?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final favorites = context.watch<FavoritesService>();
    final profile = context.watch<ProfileService>();
    final isFav = favorites.isFavorite(zhk.id);

    Future<void> toggleFavorite() async {
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(zhk.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (profile.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.tr('zhk_edit_tooltip'),
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AdminZhkEditScreen(existing: zhk.toJson()),
                  ),
                );
                if (changed == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          if (profile.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.tr('zhk_delete_tooltip'),
              onPressed: () => _delete(context),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Фото на всю ширину, статус и избранное — поверх, как на
          // карточке товара, а не мелким текстом сбоку.
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: ZhkPhotoThumbnail(photoUrl: zhk.photoUrl, iconSize: 56),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black.withOpacity(0.35),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white),
                    onPressed: toggleFavorite,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: profile.isSubscribed ? _buildStatusBadge(context) : _buildStatusLocked(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zhk.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.map_outlined, text: zhk.district),
                _InfoRow(icon: Icons.location_on_outlined, text: zhk.address),
                _InfoRow(icon: Icons.apartment_outlined, text: zhk.developer),
                if (zhk.constructionStatus != null) ...[
                  const SizedBox(height: 4),
                  ConstructionStatusRow(zhk: zhk, iconSize: 18, fontSize: 14.5),
                ],
                const SizedBox(height: 8),
                if (_hasDetails) ...[
                  const SizedBox(height: 12),
                  profile.isSubscribed
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailCard(
                                icon: Icons.description_outlined,
                                label: context.tr('zhk_documentation'),
                                value: zhk.documentation),
                            _DetailCard(
                                icon: Icons.construction_outlined,
                                label: context.tr('zhk_tech_status'),
                                value: zhk.techStatus),
                            _DetailCard(
                                icon: Icons.warning_amber_outlined,
                                label: context.tr('zhk_violations'),
                                value: zhk.violations),
                            _DetailCard(
                                icon: Icons.task_alt_outlined,
                                label: context.tr('zhk_measures'),
                                value: zhk.measures),
                            _DetailCard(
                                icon: Icons.balance_outlined,
                                label: context.tr('zhk_court'),
                                value: zhk.court),
                          ],
                        )
                      : _buildPaywall(context),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Сообщить об ошибке в данных'),
                  onPressed: () async {
                    if (!auth.isLoggedIn) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      return;
                    }
                    if (context.mounted) {
                      showReportIssueDialog(context, zhk.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = zhk.isProblematic ? const Color(0xFFE24B4A) : const Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Text(
        zhk.isProblematic
            ? context.tr('zhk_status_problematic')
            : context.tr('zhk_status_guaranteed'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _buildStatusLocked(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(context.tr('zhk_status_locked'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywall(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.tr('paywall_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(context.tr('paywall_body'), style: const TextStyle(height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
              child: Text(context.tr('subscribe_button')),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String? text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text!, style: TextStyle(fontSize: 14.5, color: colorScheme.onSurface, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _DetailCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 3),
                Text(value!, style: const TextStyle(fontSize: 14.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
