import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/favorites_service.dart';
import '../widgets/empty_state_illustration.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const _lastSeenKey = 'notifications.lastSeenAt';

  /// Считает количество непросмотренных изменений статуса среди
  /// избранных ЖК — для бейджа на колокольчике.
  static Future<int> unseenCount(FavoritesService favorites) async {
    final favoriteIds = favorites.favoriteIds.toList();
    if (favoriteIds.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_lastSeenKey);
    var query = Supabase.instance.client
        .from('zhk_status_log')
        .select('id')
        .inFilter('zhk_id', favoriteIds);
    if (lastSeen != null) {
      query = query.gt('changed_at', lastSeen);
    }
    try {
      final rows = await query;
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final favoriteIds = context.read<FavoritesService>().favoriteIds.toList();
      if (favoriteIds.isEmpty) {
        setState(() {
          _rows = [];
          _loading = false;
        });
        return;
      }
      final rows = await Supabase.instance.client
          .from('zhk_status_log')
          .select('*, zhk:zhk_id(name)')
          .inFilter('zhk_id', favoriteIds)
          .order('changed_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          NotificationsScreen._lastSeenKey, DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.tr('notifications_load_error', {'error': '$e'});
        _loading = false;
      });
    }
  }

  String _statusLabel(BuildContext context, String? status) => switch (status) {
        'problematic' => context.tr('notif_status_problematic'),
        'completed_guaranteed' => context.tr('notif_status_guaranteed'),
        _ => context.tr('notif_status_unknown'),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications_title')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const EmptyStateIllustration(badgeIcon: Icons.notifications),
                            const SizedBox(height: 20),
                            Text(context.tr('notifications_empty_title'),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('notifications_empty_body'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = _rows[i];
                        final name = (r['zhk'] as Map?)?['name'] as String? ?? r['zhk_id'];
                        final oldStatus = _statusLabel(context, r['old_status'] as String?);
                        final newStatus = _statusLabel(context, r['new_status'] as String?);
                        return ListTile(
                          leading: const Icon(Icons.notifications_active_outlined),
                          title: Text(name),
                          subtitle: Text('$oldStatus → $newStatus'),
                        );
                      },
                    ),
    );
  }
}
