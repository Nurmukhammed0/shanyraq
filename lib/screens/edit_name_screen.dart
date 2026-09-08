import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/profile_service.dart';

class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key});

  @override
  State<EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  late final _nameController =
      TextEditingController(text: context.read<ProfileService>().displayName ?? '');

  bool _saving = false;
  bool _uploadingAvatar = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
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
      if (mounted) setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile_edit_name_row'))),
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
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.tr('profile_section_name'),
              hintText: context.tr('profile_name_hint'),
              prefixIcon: const Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('profile_save_name_button')),
            ),
          ),
        ],
      ),
    );
  }
}
