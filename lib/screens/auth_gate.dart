import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'app_shell.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

/// Без входа приложение вообще не показывается — сразу экран логина.
/// Заблокированный админом пользователь тоже не проходит дальше.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Пользователь перешёл по ссылке восстановления пароля из письма.
    // Проверяем это раньше isLoggedIn: сама ссылка (URL на старте) уже
    // сигнализирует о восстановлении, а обмен кода на сессию у Supabase
    // ещё может доделываться асинхронно — короткая пауза со спиннером
    // лучше, чем промелькнувший экран логина, который ничего не значит.
    if (auth.isPasswordRecovery) {
      return auth.isLoggedIn ? const ResetPasswordScreen() : const _PasswordRecoveryWaiting();
    }

    if (!auth.isLoggedIn) return const LoginScreen();

    final profile = context.watch<ProfileService>();
    if (profile.isBlocked) return const _BlockedScreen();

    return const AppShell();
  }
}

/// Показывается, пока Supabase доделывает обмен recovery-кода на сессию
/// (обычно доли секунды). Если за разумное время это не случилось —
/// скорее всего, ссылка из письма устарела или уже была использована —
/// даём явный путь назад вместо бесконечного спиннера.
class _PasswordRecoveryWaiting extends StatefulWidget {
  const _PasswordRecoveryWaiting();

  @override
  State<_PasswordRecoveryWaiting> createState() => _PasswordRecoveryWaitingState();
}

class _PasswordRecoveryWaitingState extends State<_PasswordRecoveryWaiting> {
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_timedOut) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  context.tr('password_recovery_timeout'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.read<AuthService>().clearPasswordRecovery(),
                  child: Text(context.tr('forgot_password_back_to_login')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedScreen extends StatelessWidget {
  const _BlockedScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.block, size: 34, color: colorScheme.onErrorContainer),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('blocked_title'),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('blocked_body'),
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.read<AuthService>().signOut(),
                  child: Text(context.tr('blocked_sign_out')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
