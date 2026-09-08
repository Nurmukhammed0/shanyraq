import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/grouped_list.dart';
import 'admin_zhk_edit_screen.dart';

/// Админка: хаб с переходом на отдельные экраны — пользователи, объекты
/// ЖК, корзина, обращения и статистика.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupCard(children: [
            MenuRow(
              icon: Icons.people_outline,
              title: 'Пользователи',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _UsersScreen()),
              ),
            ),
            MenuRow(
              icon: Icons.apartment_outlined,
              title: 'Объекты ЖК',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _ZhkScreen()),
              ),
            ),
            MenuRow(
              icon: Icons.delete_outline,
              title: 'Корзина',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _TrashScreen()),
              ),
            ),
            MenuRow(
              icon: Icons.flag_outlined,
              title: 'Обращения',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _ReportsScreen()),
              ),
            ),
            MenuRow(
              icon: Icons.bar_chart_outlined,
              title: 'Статистика',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _StatsScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _UsersScreen extends StatefulWidget {
  const _UsersScreen();

  @override
  State<_UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<_UsersScreen> {
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
      final rows = await _client.from('profiles').select().order('created_at', ascending: false);
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
    await _client.from('profiles').update({'is_subscribed': value}).eq('id', userId);
    _load();
  }

  Future<void> _setBlocked(String userId, bool value) async {
    try {
      await _client.rpc('admin_set_blocked', params: {'target_id': userId, 'blocked_value': value});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить пользователя?'),
        content: Text('«$email» будет удалён безвозвратно вместе со всеми его данными. Это необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE24B4A)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _client.rpc('admin_delete_user', params: {'target_id': userId});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Future<void> _openAddUserDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool asAdmin = false;
    bool subscribed = false;
    bool submitting = false;
    String? error;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> submit() async {
            final email = emailController.text.trim();
            final password = passwordController.text;
            if (email.isEmpty || password.length < 8) {
              setSheetState(() => error = 'Укажите email и пароль (минимум 8 символов)');
              return;
            }
            setSheetState(() {
              submitting = true;
              error = null;
            });
            try {
              final res = await _client.functions.invoke('admin-create-user', body: {
                'email': email,
                'password': password,
                'displayName': nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                'role': asAdmin ? 'admin' : 'user',
                'isSubscribed': subscribed,
              });
              final data = res.data;
              if (data is Map && data['error'] != null) {
                setSheetState(() {
                  submitting = false;
                  error = data['error'] as String;
                });
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              setSheetState(() {
                submitting = false;
                error = 'Не удалось создать: $e';
              });
            }
          }

          return AlertDialog(
            title: const Text('Новый пользователь'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль (мин. 8 символов)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Имя (необязательно)'),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Подписка сразу активна'),
                    value: subscribed,
                    onChanged: (v) => setSheetState(() => subscribed = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Роль администратора'),
                    value: asAdmin,
                    onChanged: (v) => setSheetState(() => asAdmin = v),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Color(0xFFE24B4A), fontSize: 13)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _profiles.length,
                    itemBuilder: (context, i) {
                      final p = _profiles[i];
                      final id = p['id'] as String;
                      final email = p['email'] as String? ?? '(без email)';
                      final role = p['role'] as String? ?? 'user';
                      final isSubscribed = p['is_subscribed'] == true;
                      final isAdmin = role == 'admin';
                      final isBlocked = p['blocked'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? const Color(0xFFE24B4A).withOpacity(0.08)
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: isBlocked
                              ? Border.all(color: const Color(0xFFE24B4A).withOpacity(0.4))
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(Icons.person, size: 18, color: colorScheme.onPrimaryContainer),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(email,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                        isBlocked ? 'заблокирован' : (isAdmin ? 'admin' : 'user'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isBlocked ? const Color(0xFFE24B4A) : colorScheme.onSurfaceVariant,
                                          fontWeight: isBlocked ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Подписка',
                                        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                                    Switch(
                                      value: isSubscribed,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (v) => _setSubscribed(id, v),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Admin', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                                    Switch(
                                      value: isAdmin,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (v) => _setRole(id, v ? 'admin' : 'user'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _setBlocked(id, !isBlocked),
                                  icon: Icon(isBlocked ? Icons.lock_open : Icons.block, size: 16),
                                  label: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isBlocked ? const Color(0xFF22C55E) : Colors.orange.shade800,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteUser(id, email),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Удалить'),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFE24B4A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUserDialog,
        tooltip: 'Добавить пользователя',
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}

class _ZhkScreen extends StatefulWidget {
  const _ZhkScreen();

  @override
  State<_ZhkScreen> createState() => _ZhkScreenState();
}

class _ZhkScreenState extends State<_ZhkScreen> {
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
      final rows = await _client.from('zhk').select().filter('deleted_at', 'is', null).order('name');
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
        content: Text('«$name» пропадёт из списка, но его можно будет восстановить во вкладке «Корзина».'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('В корзину')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final updated =
          await _client.from('zhk').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id).select();
      if (updated.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить: сервер не нашёл строку (проверьте id/RLS).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Объекты ЖК')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      final isProblematic = r['status'] == 'problematic';
                      final color = isProblematic ? const Color(0xFFE24B4A) : const Color(0xFF22C55E);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(Icons.location_on, color: color, size: 18),
                          ),
                          title: Text(r['name'] as String? ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(r['address'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                          onTap: () => _openEdit(r),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'В корзину',
                            onPressed: () => _moveToTrash(r['id'] as String, r['name'] as String? ?? ''),
                          ),
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

class _TrashScreen extends StatefulWidget {
  const _TrashScreen();

  @override
  State<_TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<_TrashScreen> {
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
      final rows =
          await _client.from('zhk').select().not('deleted_at', 'is', null).order('deleted_at', ascending: false);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка восстановления: $e')));
      }
    }
    _load();
  }

  Future<void> _deleteForever(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('«$name» будет удалён безвозвратно, восстановить будет нельзя.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить навсегда')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _client.from('zhk').delete().eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Корзина')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _rows.isEmpty
                  ? Center(
                      child: Text('Корзина пуста', style: Theme.of(context).textTheme.bodyMedium),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          final id = r['id'] as String;
                          final name = r['name'] as String? ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      Text(r['address'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
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
                    ),
    );
  }
}

class _ReportsScreen extends StatefulWidget {
  const _ReportsScreen();

  @override
  State<_ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<_ReportsScreen> {
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
      final rows =
          await _client.from('zhk_reports').select('*, zhk:zhk_id(name)').order('created_at', ascending: false);
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
    await _client.from('zhk_reports').update({'status': resolved ? 'resolved' : 'open'}).eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Обращения')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _rows.isEmpty
                  ? const Center(child: Text('Обращений пока нет'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          final id = r['id'] as String;
                          final zhkName = (r['zhk'] as Map?)?['name'] as String? ?? r['zhk_id'] as String? ?? '';
                          final resolved = r['status'] == 'resolved';
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(zhkName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (resolved ? const Color(0xFF22C55E) : Colors.orange)
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          resolved ? 'Решено' : 'Открыто',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: resolved ? const Color(0xFF22C55E) : Colors.orange.shade800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(r['message'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: resolved,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (v) => _toggleResolved(id, v),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _StatsScreen extends StatefulWidget {
  const _StatsScreen();

  @override
  State<_StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<_StatsScreen> {
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
      final active = await _client.from('zhk').select('id').filter('deleted_at', 'is', null);
      final trashed = await _client.from('zhk').select('id').not('deleted_at', 'is', null);
      final users = await _client.from('profiles').select('id');
      final subscribed = await _client.from('profiles').select('id').eq('is_subscribed', true);
      final openReports = await _client.from('zhk_reports').select('id').eq('status', 'open');
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      ('Активных ЖК', _activeZhk, Icons.apartment, colorScheme.primary),
                      ('В корзине', _trashedZhk, Icons.delete_outline, Colors.grey),
                      ('Пользователей', _totalUsers, Icons.people_outline, colorScheme.primary),
                      ('С подпиской', _subscribedUsers, Icons.workspace_premium_outlined, const Color(0xFF22C55E)),
                      ('Открытых обращений', _openReports, Icons.flag_outlined, Colors.orange),
                    ].map((s) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (s.$4 as Color).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(s.$3 as IconData, color: s.$4 as Color, size: 18),
                            ),
                            const SizedBox(height: 10),
                            Text('${s.$2}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(s.$1 as String, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
