import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/listing.dart';
import '../services/listing_repository.dart';
import '../services/profile_service.dart';

/// Форма добавления объявления собственником. Доступна только
/// с активной подпиской (проверяется и на уровне RLS в базе).
class ListingEditScreen extends StatefulWidget {
  const ListingEditScreen({super.key});

  @override
  State<ListingEditScreen> createState() => _ListingEditScreenState();
}

class _ListingEditScreenState extends State<ListingEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ListingRepository();

  final _title = TextEditingController();
  final _price = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _rooms = TextEditingController();
  final _area = TextEditingController();
  final _phone = TextEditingController();
  final _contactName = TextEditingController();
  final _description = TextEditingController();
  String _photoUrl = '';

  bool _saving = false;
  bool _uploadingPhoto = false;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileService>();
    _contactName.text = profile.displayName ?? '';
  }

  @override
  void dispose() {
    for (final c in [_title, _price, _district, _address, _rooms, _area, _phone, _contactName, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _uploadPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final userId = _client.auth.currentUser!.id;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('listing-photos').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: picked.mimeType, upsert: true),
          );
      final publicUrl = _client.storage.from('listing-photos').getPublicUrl(path);
      if (!mounted) return;
      setState(() => _photoUrl = publicUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('generic_error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final listing = Listing(
        id: '',
        ownerId: '',
        title: _title.text.trim(),
        price: double.tryParse(_price.text.trim().replaceAll(' ', '').replaceAll(',', '.')),
        city: 'Алматы',
        district: _district.text.trim().isEmpty ? null : _district.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        rooms: int.tryParse(_rooms.text.trim()),
        areaSqm: double.tryParse(_area.text.trim().replaceAll(',', '.')),
        phone: _phone.text.trim(),
        contactName: _contactName.text.trim().isEmpty ? null : _contactName.text.trim(),
        photoUrl: _photoUrl.isEmpty ? null : _photoUrl,
      );
      await _repo.create(listing);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('generic_error', {'error': '$e'}))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('listing_edit_required') : null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('listing_edit_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.tr('listing_edit_photo_label'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: _photoUrl.isEmpty
                    ? Container(
                        color: colorScheme.secondaryContainer,
                        child: Icon(Icons.add_a_photo_outlined, size: 36, color: colorScheme.onSecondaryContainer),
                      )
                    : Image.network(_photoUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _uploadingPhoto ? null : _uploadPhoto,
              icon: _uploadingPhoto
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_outlined),
              label: Text(_uploadingPhoto
                  ? context.tr('listing_edit_uploading')
                  : context.tr('listing_edit_upload_button')),
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: context.tr('listing_edit_title_field')),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: InputDecoration(labelText: context.tr('listing_edit_price')),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rooms,
                    decoration: InputDecoration(labelText: context.tr('listing_edit_rooms')),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _area,
                    decoration: InputDecoration(labelText: context.tr('listing_edit_area')),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _district,
              decoration: InputDecoration(labelText: context.tr('filter_district_hint')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: context.tr('listing_edit_address')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: context.tr('listing_edit_description')),
              maxLines: 4,
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _contactName,
              decoration: InputDecoration(labelText: context.tr('listing_edit_contact_name')),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: context.tr('listing_edit_phone')),
              keyboardType: TextInputType.phone,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(context.tr('listing_edit_disclaimer'),
                        style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant, height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.tr('listing_edit_publish_button')),
            ),
          ],
        ),
      ),
    );
  }
}
