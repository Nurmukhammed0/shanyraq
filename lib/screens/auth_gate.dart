import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'login_screen.dart';
import 'root_shell.dart';

/// Без входа приложение вообще не показывается — сразу экран логина.
/// Заблокированный админом пользователь тоже не проходит дальше.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isLoggedIn) return const LoginScreen();

    final profile = context.watch<ProfileService>();
    if (profile.isBlocked) return const _BlockedScreen();

    return const RootShell();
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
