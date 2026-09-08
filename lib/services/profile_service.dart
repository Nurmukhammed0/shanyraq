import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Профиль текущего пользователя: роль (user/admin) и статус подписки.
/// Подписка пока переключается вручную админом (без платёжного шлюза).
class ProfileService extends ChangeNotifier {
  Map<String, dynamic>? _profile;

  // Способ оплаты и последние 4 цифры карты — часть имитации оплаты,
  // хранятся только в памяти (не в базе): это не настоящие платёжные
  // данные, а просто то, что показываем на экране подписки для вида.
  String? _paymentMethod;
  String? _cardLast4;

  ProfileService() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => load());
    load();
  }

  SupabaseClient get _client => Supabase.instance.client;

  bool get isAdmin => _profile?['role'] == 'admin';
  bool get isSubscribed => _profile?['is_subscribed'] == true;
  bool get autoRenew => _profile?['auto_renew'] as bool? ?? true;
  String? get email => _profile?['email'] as String?;
  String? get displayName => _profile?['display_name'] as String?;
  String? get avatarUrl => _profile?['avatar_url'] as String?;
  String? get paymentMethod => _paymentMethod;
  String? get cardLast4 => _cardLast4;

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
  Future<void> activateSubscription({required String method, String? cardLast4}) async {
    await _client.rpc('activate_own_subscription');
    _paymentMethod = method;
    _cardLast4 = cardLast4;
    await load();
  }

  Future<void> setAutoRenew(bool enabled) async {
    await _client.rpc('set_own_auto_renew', params: {'enabled': enabled});
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
