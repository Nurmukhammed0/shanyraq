import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/password_strength_meter.dart';

/// Показывается вместо AppShell, когда AuthService.isPasswordRecovery
/// true — то есть пользователь только что перешёл по ссылке восстановления
/// из письма. В отличие от ChangePasswordScreen здесь не нужен старый
/// пароль: сама ссылка уже подтвердила владение почтой.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _saving = false;
  String? _error;
  String _newPassword = '';
  String _confirmPassword = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _valid =>
      PasswordCheck.evaluate(_newPassword).isValid &&
      _confirmPassword.isNotEmpty &&
      _newPassword == _confirmPassword;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final error = await auth.updatePassword(_newPassword);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    // Пускаем в приложение — сессия, выданная по ссылке восстановления,
    // теперь обычная, валидный новый пароль уже сохранён.
    auth.clearPasswordRecovery();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _confirmPassword.isNotEmpty && _newPassword == _confirmPassword;
    final mismatched = _confirmPassword.isNotEmpty && _newPassword != _confirmPassword;

    return Scaffold(
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
                    context.tr('reset_password_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('reset_password_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    autofocus: true,
                    onChanged: (v) => setState(() => _newPassword = v),
                    decoration: InputDecoration(
                      labelText: context.tr('change_password_new_label'),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    ),
                  ),
                  PasswordStrengthMeter(password: _newPassword),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    onChanged: (v) => setState(() => _confirmPassword = v),
                    onSubmitted: (_) => _valid && !_saving ? _save() : null,
                    decoration: InputDecoration(
                      labelText: context.tr('change_password_confirm_label'),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: _confirmPassword.isEmpty
                          ? null
                          : Icon(
                              matches ? Icons.check_circle : Icons.cancel,
                              color: matches ? const Color(0xFF22C55E) : Colors.red,
                              size: 20,
                            ),
                    ),
                  ),
                  if (mismatched) ...[
                    const SizedBox(height: 8),
                    Text(context.tr('change_password_mismatch'),
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ] else if (matches) ...[
                    const SizedBox(height: 8),
                    Text(context.tr('change_password_match'),
                        style: const TextStyle(color: Color(0xFF22C55E), fontSize: 13)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(context.trAuthError(_error!), style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving || !_valid ? null : _save,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(context.tr('change_password_save_button')),
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
