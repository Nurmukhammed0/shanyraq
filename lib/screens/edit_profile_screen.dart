import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../widgets/grouped_list.dart';
import 'change_password_screen.dart';
import 'edit_name_screen.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('profile_delete_confirm_title')),
        content: Text(context.tr('profile_delete_confirm_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('profile_delete_button')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await context.read<AuthService>().deleteAccount();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_profile_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupCard(children: [
            MenuRow(
              icon: Icons.badge_outlined,
              title: context.tr('profile_edit_name_row'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditNameScreen()),
              ),
            ),
            MenuRow(
              icon: Icons.lock_outline,
              title: context.tr('profile_change_password_row'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.error.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text(context.tr('profile_danger_zone_title'),
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5, color: colorScheme.error)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('profile_danger_zone_body'),
                  style: TextStyle(
                      fontSize: 12.5, color: colorScheme.error.withOpacity(0.85), height: 1.35),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                    onPressed: () => _confirmDeleteAccount(context),
                    child: Text(context.tr('profile_delete_button')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
