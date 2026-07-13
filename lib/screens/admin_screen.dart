import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_zhk_edit_screen.dart';

/// Админка: пользователи (роль/подписка), объекты ЖК (добавление,
/// редактирование, мягкое удаление) и корзина удалённых объектов.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Админка'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Пользователи'),
              Tab(text: 'Объекты ЖК'),
              Tab(text: 'Корзина'),
              Tab(text: 'Обращения'),
              Tab(text: 'Статистика'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(),
            _ZhkTab(),
            _TrashTab(),
            _ReportsTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;

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
      final rows = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить пользователей: $e';
        _loading = false;
      });
    }
  }

  Future<void> _setRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
    _load();
  }

  Future<void> _setSubscribed(String userId, bool value) async {
    await _client
        .from('profiles')
        .update({'is_subscribed': value}).eq('id', userId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child:
              Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                    width: 60,
                    child: Text('Подписка',
                        style: TextStyle(fontSize: 11),
                        textAlign: TextAlign.center)),
                SizedBox(
                    width: 60,
                    child: Text('Admin',
                        style: TextStyle(fontSize: 11),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _profiles.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _profiles[i];
                final id = p['id'] as String;
                final email = p['email'] as String? ?? '(без email)';
                final role = p['role'] as String? ?? 'user';
                final isSubscribed = p['is_subscribed'] == true;
                final isAdmin = role == 'admin';

                return ListTile(
                  title: Text(email),
                  subtitle: Text(isAdmin ? 'admin' : 'user'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Подписка',
                        child: Switch(
                          value: isSubscribed,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) => _setSubscribed(id, v),
                        ),
                      ),
                      Tooltip(
                        message: 'Admin',
                        child: Switch(
                          value: isAdmin,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) => _setRole(id, v ? 'admin' : 'user'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ZhkTab extends StatefulWidget {
  const _ZhkTab();

  @override
  State<_ZhkTab> createState() => _ZhkTabState();
}

class _ZhkTabState extends State<_ZhkTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;

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
      final rows = await _client
          .from('zhk')
          .select()
          .filter('deleted_at', 'is', null)
          .order('name');
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить объекты: $e';
        _loading = false;
      });
    }
  }

  Future<void> _moveToTrash(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Переместить в корзину?'),
        content: Text(
            '«$name» пропадёт из списка, но его можно будет восстановить во вкладке «Корзина».'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('В корзину')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final updated = await _client
          .from('zhk')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select();
      if (updated.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Не удалось удалить: сервер не нашёл строку (проверьте id/RLS).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
    _load();
  }

  Future<void> _openEdit([Map<String, dynamic>? row]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminZhkEditScreen(existing: row)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24), child: Text(_error!)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      final isProblematic = r['status'] == 'problematic';
                      return ListTile(
                        leading: Icon(Icons.location_on,
                            color: isProblematic ? Colors.red : Colors.green),
                        title: Text(r['name'] as String? ?? ''),
                        subtitle: Text(r['address'] as String? ?? ''),
                        onTap: () => _openEdit(r),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'В корзину',
                          onPressed: () => _moveToTrash(
                              r['id'] as String, r['name'] as String? ?? ''),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TrashTab extends StatefulWidget {
  const _TrashTab();

  @override
  State<_TrashTab> createState() => _TrashTabState();
}

class _TrashTabState extends State<_TrashTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;

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
      final rows = await _client
          .from('zhk')
          .select()
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить корзину: $e';
        _loading = false;
      });
    }
  }

  Future<void> _restore(String id) async {
    try {
      await _client.from('zhk').update({'deleted_at': null}).eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка восстановления: $e')));
      }
    }
    _load();
  }

  Future<void> _deleteForever(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text(
            '«$name» будет удалён безвозвратно, восстановить будет нельзя.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить навсегда')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _client.from('zhk').delete().eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child:
              Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Корзина пуста',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = _rows[i];
          final id = r['id'] as String;
          final name = r['name'] as String? ?? '';
          return ListTile(
            title: Text(name),
            subtitle: Text(r['address'] as String? ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: 'Восстановить',
                  onPressed: () => _restore(id),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined),
                  tooltip: 'Удалить навсегда',
                  onPressed: () => _deleteForever(id, name),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;

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
      final rows = await _client
          .from('zhk_reports')
          .select('*, zhk:zhk_id(name)')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить обращения: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggleResolved(String id, bool resolved) async {
    await _client
        .from('zhk_reports')
        .update({'status': resolved ? 'resolved' : 'open'}).eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child:
              Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_rows.isEmpty) {
      return const Center(child: Text('Обращений пока нет'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = _rows[i];
          final id = r['id'] as String;
          final zhkName = (r['zhk'] as Map?)?['name'] as String? ??
              r['zhk_id'] as String? ??
              '';
          final resolved = r['status'] == 'resolved';
          return ListTile(
            title: Text(zhkName),
            subtitle: Text(
              '${resolved ? 'Решено' : 'Открыто'} · ${r['message'] as String? ?? ''}',
            ),
            isThreeLine: true,
            trailing: Tooltip(
              message: resolved ? 'Решено' : 'Открыто',
              child: Switch(
                value: resolved,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) => _toggleResolved(id, v),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsTab extends StatefulWidget {
  const _StatsTab();

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  bool _loading = true;
  String? _error;
  int _activeZhk = 0;
  int _trashedZhk = 0;
  int _totalUsers = 0;
  int _subscribedUsers = 0;
  int _openReports = 0;

  SupabaseClient get _client => Supabase.instance.client;

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
      final active = await _client
          .from('zhk')
          .select('id')
          .filter('deleted_at', 'is', null);
      final trashed =
          await _client.from('zhk').select('id').not('deleted_at', 'is', null);
      final users = await _client.from('profiles').select('id');
      final subscribed =
          await _client.from('profiles').select('id').eq('is_subscribed', true);
      final openReports =
          await _client.from('zhk_reports').select('id').eq('status', 'open');
      if (!mounted) return;
      setState(() {
        _activeZhk = (active as List).length;
        _trashedZhk = (trashed as List).length;
        _totalUsers = (users as List).length;
        _subscribedUsers = (subscribed as List).length;
        _openReports = (openReports as List).length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить статистику: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child:
              Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    final stats = [
      ('Активных объектов ЖК', _activeZhk, Icons.apartment),
      ('В корзине', _trashedZhk, Icons.delete_outline),
      ('Пользователей', _totalUsers, Icons.people_outline),
      ('С подпиской', _subscribedUsers, Icons.workspace_premium_outlined),
      ('Открытых обращений', _openReports, Icons.flag_outlined),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: stats.map((s) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(s.$3, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text('${s.$2}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(s.$1, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
