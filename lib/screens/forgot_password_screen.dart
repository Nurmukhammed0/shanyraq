import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';

/// Экран «Забыли пароль» — отправляет письмо со ссылкой восстановления
/// через Supabase Auth. Сам сброс пароля происходит на ResetPasswordScreen,
/// когда пользователь переходит по ссылке из письма (см. AuthGate).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Встроенный email-сервис Supabase имеет жёсткий часовой лимит писем
  // (см. §11 PRD) — кулдаун не даёт случайно выжечь его повторными
  // нажатиями «отправить ещё раз» за несколько секунд.
  static const _resendCooldown = 60;

  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _loading || _cooldownSeconds > 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await context.read<AuthService>().resetPasswordForEmail(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      if (error == null) _sent = true;
    });
    if (error == null) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo()),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('forgot_password_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sent
                        ? context.tr('forgot_password_sent_body')
                        : context.tr('forgot_password_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  if (_sent) ...[
                    Icon(Icons.mark_email_read_outlined, size: 56, color: colorScheme.primary),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _loading || _cooldownSeconds > 0 ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_cooldownSeconds > 0
                              ? context.tr('forgot_password_resend_cooldown', {'n': '$_cooldownSeconds'})
                              : context.tr('forgot_password_resend')),
                    ),
                  ] else ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: context.tr('email_label'),
                        prefixIcon: const Icon(Icons.mail_outline, size: 20),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading || _cooldownSeconds > 0 ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_cooldownSeconds > 0
                              ? context.tr('forgot_password_resend_cooldown', {'n': '$_cooldownSeconds'})
                              : context.tr('forgot_password_submit')),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr('forgot_password_back_to_login')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
