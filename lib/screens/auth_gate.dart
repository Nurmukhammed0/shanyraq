import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'root_shell.dart';

/// Без входа приложение вообще не показывается — сразу экран логина.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return auth.isLoggedIn ? const RootShell() : const LoginScreen();
  }
}
