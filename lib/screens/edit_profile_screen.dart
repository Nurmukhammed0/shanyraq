import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/section_card.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nameController =
      TextEditingController(text: context.read<ProfileService>().displayName ?? '');
  final _newPasswordController = TextEditingController();

  bool _savingProfile = false;
  bool _uploadingAvatar = false;
  bool _changingPassword = false;
  bool _deleting = false;
  String? _passwordError;
  String? _passwordSuccess;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _savingProfile = true);
    try {
      await context.read<ProfileService>().updateProfile(
            displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            avatarUrl: context.read<ProfileService>().avatarUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('profile_save_success'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('profile_save_error', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _uploadAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final userId = _client.auth.currentUser!.id;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: picked.mimeType, upsert: true),
          );
      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
      if (!mounted) return;
      await context.read<ProfileService>().updateProfile(
            displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            avatarUrl: publicUrl,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('profile_photo_upload_error', {'error': '$e'}))));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.trim().length < 6) {
      setState(() {
        _passwordError = context.tr('profile_password_too_short');
        _passwordSuccess = null;
      });
      return;
    }
    setState(() {
      _changingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });
    final error = await context.read<AuthService>().updatePassword(_newPasswordController.text.trim());
    if (!mounted) return;
    setState(() {
      _changingPassword = false;
      _passwordError = error;
      _passwordSuccess = error == null ? context.tr('profile_password_changed') : null;
      if (error == null) _newPasswordController.clear();
    });
  }

  Future<void> _confirmDeleteAccount() async {
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
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _deleting = true);
    final error = await context.read<AuthService>().deleteAccount();
    if (!mounted) return;
    if (error != null) {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_profile_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: colorScheme.secondaryContainer,
                    backgroundImage:
                        profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                    child: profile.avatarUrl == null
                        ? Icon(Icons.person, size: 48, color: colorScheme.onSecondaryContainer)
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: colorScheme.primary,
                    shape: CircleBorder(side: BorderSide(color: colorScheme.surface, width: 3)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploadingAvatar ? null : _uploadAvatar,
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: _uploadingAvatar
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: colorScheme.onPrimary),
                              )
                            : Icon(Icons.camera_alt, size: 17, color: colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionCard(
            icon: Icons.badge_outlined,
            title: context.tr('profile_section_name'),
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: context.tr('profile_name_hint'),
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _savingProfile ? null : _saveName,
                  child: _savingProfile
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('profile_save_name_button')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            icon: Icons.lock_outline,
            title: context.tr('profile_section_password'),
            children: [
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: context.tr('profile_new_password_hint'),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                ),
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 8),
                Text(_passwordError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              if (_passwordSuccess != null) ...[
                const SizedBox(height: 8),
                Text(_passwordSuccess!,
                    style: const TextStyle(color: Color(0xFF22C55E), fontSize: 13)),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _changingPassword ? null : _changePassword,
                  child: _changingPassword
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.tr('profile_change_password_button')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    onPressed: _deleting ? null : _confirmDeleteAccount,
                    child: _deleting
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: colorScheme.error))
                        : Text(context.tr('profile_delete_button')),
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
