import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Обёртка над Supabase Auth: логин, регистрация, выход,
/// текущий пользователь как ChangeNotifier для UI.
class AuthService extends ChangeNotifier {
  // true между моментом, когда пользователь переходит по ссылке
  // восстановления пароля из письма, и моментом, когда он сохранит новый
  // пароль. Supabase в этот момент уже выдаёт валидную сессию (иначе
  // updateUser не сработал бы), поэтому одного isLoggedIn недостаточно —
  // AuthGate должен отличить "восстановление пароля" от обычного входа,
  // чтобы не пустить человека в приложение со старым паролем, который он
  // только что пытался сбросить.
  bool _isPasswordRecovery;
  bool get isPasswordRecovery => _isPasswordRecovery;

  // initialPasswordRecovery приходит из main() — разобран из URL ещё до
  // Supabase.initialize(), на случай если сам passwordRecovery-эвент SDK
  // уже улетел мимо (см. комментарий в main.dart). Событие ниже оставлено
  // как дополнительный путь — не единственный.
  AuthService({bool initialPasswordRecovery = false}) : _isPasswordRecovery = initialPasswordRecovery {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
      }
      notifyListeners();
    });
  }

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Вызывается после того, как пользователь сохранил новый пароль по
  /// ссылке восстановления — пускает его дальше в обычный AppShell.
  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

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

  /// Отправляет письмо со ссылкой для восстановления пароля. Не
  /// раскрывает, зарегистрирован ли такой email — Supabase возвращает
  /// успех в обоих случаях, так что сообщение пользователю всегда одно
  /// и то же (экран ForgotPasswordScreen сам решает, что показать).
  ///
  /// redirectTo для веба указан явно (а не null): когда он не передан,
  /// supabase_flutter сам подставляет origin текущей страницы БЕЗ пути
  /// (https://nurmukhammed0.github.io/, а не .../shanyraq/) — Site URL,
  /// настроенный в панели Supabase, в этот расчёт не попадает. Из-за
  /// этого ссылка в письме вела на несуществующую страницу (404 от
  /// GitHub Pages) независимо от того, что указано в дашборде.
  Future<String?> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? 'https://nurmukhammed0.github.io/shanyraq/'
            : 'io.supabase.shanyraq://login-callback',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Не удалось отправить письмо: $e';
    }
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
