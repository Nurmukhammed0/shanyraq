import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Обёртка над Supabase Auth: логин, регистрация, выход,
/// текущий пользователь как ChangeNotifier для UI.
class AuthService extends ChangeNotifier {
  AuthService() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return null; // null = успех
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не удалось зарегистрироваться: $e';
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не удалось войти: $e';
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Вход/регистрация через Google. Результат наблюдается через
  /// onAuthStateChange (AuthService сам уведомит слушателей).
  Future<String?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.shanyraq://login-callback',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не удалось войти через Google: $e';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не удалось сменить пароль: $e';
    }
  }

  /// Удаляет аккаунт целиком (профиль и избранное — каскадом).
  /// Необратимо.
  Future<String?> deleteAccount() async {
    try {
      await _client.rpc('delete_own_account');
      await _client.auth.signOut();
      return null;
    } catch (e) {
      return 'Не удалось удалить аккаунт: $e';
    }
  }
}
