import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../widgets/password_strength_meter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _oldPasswordVerified = false;
  bool _verifying = false;
  bool _saving = false;
  String? _oldPasswordError;
  String _oldPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyOldPassword() async {
    setState(() {
      _verifying = true;
      _oldPasswordError = null;
    });
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _oldPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _oldPasswordVerified = true;
        _verifying = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _oldPasswordError = context.tr('change_password_wrong_old');
        _verifying = false;
      });
    }
  }

  bool get _newPasswordValid =>
      PasswordCheck.evaluate(_newPassword).isValid &&
      _confirmPassword.isNotEmpty &&
      _newPassword == _confirmPassword;

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context.read<AuthService>().updatePassword(_newPassword);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('profile_password_changed'))));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile_change_password_row'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: _oldPasswordVerified ? _buildNewPasswordStep(context) : _buildOldPasswordStep(context),
        ),
      ),
    );
  }

  Widget _buildOldPasswordStep(BuildContext context) {
    return Column(
      key: const ValueKey('old'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _oldPasswordController,
          obscureText: true,
          autofocus: true,
          onChanged: (v) => setState(() => _oldPassword = v),
          onSubmitted: (_) => _verifyOldPassword(),
          decoration: InputDecoration(
            labelText: context.tr('change_password_old_label'),
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
          ),
        ),
        if (_oldPasswordError != null) ...[
          const SizedBox(height: 8),
          Text(_oldPasswordError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _verifying || _oldPassword.isEmpty ? null : _verifyOldPassword,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _verifying
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr('change_password_continue_button')),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(BuildContext context) {
    final matches = _confirmPassword.isNotEmpty && _newPassword == _confirmPassword;
    final mismatched = _confirmPassword.isNotEmpty && _newPassword != _confirmPassword;

    return Column(
      key: const ValueKey('new'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
            const SizedBox(width: 8),
            Text(context.tr('change_password_verified'),
                style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 20),
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
          decoration: InputDecoration(
            labelText: context.tr('change_password_confirm_label'),
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: _confirmPassword.isEmpty
                ? null
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      matches ? Icons.check_circle : Icons.cancel,
                      key: ValueKey(matches),
                      color: matches ? const Color(0xFF22C55E) : Colors.red,
                      size: 20,
                    ),
                  ),
          ),
        ),
        if (mismatched) ...[
          const SizedBox(height: 8),
          Text(context.tr('change_password_mismatch'), style: const TextStyle(color: Colors.red, fontSize: 13)),
        ] else if (matches) ...[
          const SizedBox(height: 8),
          Text(context.tr('change_password_match'),
              style: const TextStyle(color: Color(0xFF22C55E), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving || !_newPasswordValid ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _saving
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(context.tr('change_password_save_button')),
        ),
      ],
    );
  }
}
