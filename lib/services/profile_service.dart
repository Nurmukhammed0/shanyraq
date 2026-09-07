import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Профиль текущего пользователя: роль (user/admin) и статус подписки.
/// Подписка пока переключается вручную админом (без платёжного шлюза).
class ProfileService extends ChangeNotifier {
  Map<String, dynamic>? _profile;

  ProfileService() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => load());
    load();
  }

  SupabaseClient get _client => Supabase.instance.client;

  bool get isAdmin => _profile?['role'] == 'admin';
  bool get isSubscribed => _profile?['is_subscribed'] == true;
  String? get email => _profile?['email'] as String?;
  String? get displayName => _profile?['display_name'] as String?;
  String? get avatarUrl => _profile?['avatar_url'] as String?;

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    await _client.rpc('update_own_profile', params: {
      'new_display_name': displayName,
      'new_avatar_url': avatarUrl,
    });
    await load();
  }

  // TODO: пока имитация оплаты — просто помечает пользователя подписанным.
  // Когда подключите платёжный шлюз, вызывайте activate_own_subscription
  // из вебхука после подтверждения платежа, а не по нажатию кнопки.
  Future<void> activateSubscription() async {
    await _client.rpc('activate_own_subscription');
    await load();
  }

  Future<void> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _profile = null;
      notifyListeners();
      return;
    }
    try {
      final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      _profile = row;
    } catch (_) {
      _profile = null;
    }
    notifyListeners();
  }
}
