import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Форма создания/редактирования объекта ЖК. Если [existing] передан —
/// режим редактирования, иначе создаётся новая запись.
class AdminZhkEditScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const AdminZhkEditScreen({super.key, this.existing});

  @override
  State<AdminZhkEditScreen> createState() => _AdminZhkEditScreenState();
}

class _AdminZhkEditScreenState extends State<AdminZhkEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _id = TextEditingController(text: widget.existing?['id'] as String? ?? '');
  late final _name = TextEditingController(text: widget.existing?['name'] as String? ?? '');
  late final _district = TextEditingController(text: widget.existing?['district'] as String? ?? '');
  late final _address = TextEditingController(text: widget.existing?['address'] as String? ?? '');
  late final _developer = TextEditingController(text: widget.existing?['developer'] as String? ?? '');
  late final _documentation =
      TextEditingController(text: widget.existing?['documentation'] as String? ?? '');
  late final _techStatus = TextEditingController(text: widget.existing?['tech_status'] as String? ?? '');
  late final _violations = TextEditingController(text: widget.existing?['violations'] as String? ?? '');
  late final _measures = TextEditingController(text: widget.existing?['measures'] as String? ?? '');
  late final _court = TextEditingController(text: widget.existing?['court'] as String? ?? '');
  late final _lat = TextEditingController(text: widget.existing?['lat']?.toString() ?? '');
  late final _lng = TextEditingController(text: widget.existing?['lng']?.toString() ?? '');
  late final _photoUrl = TextEditingController(text: widget.existing?['photo_url'] as String? ?? '');
  late final _completionYear =
      TextEditingController(text: widget.existing?['completion_year']?.toString() ?? '');

  late String _status = widget.existing?['status'] as String? ?? 'problematic';
  late String? _constructionStatus = widget.existing?['construction_status'] as String?;
  bool _saving = false;
  bool _uploadingPhoto = false;

  bool get _isEditing => widget.existing?['id'] != null;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    for (final c in [
      _id,
      _name,
      _district,
      _address,
      _developer,
      _documentation,
      _techStatus,
      _violations,
      _measures,
      _court,
      _lat,
      _lng,
      _photoUrl,
      _completionYear,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _uploadPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final path =
          '${_id.text.trim().isEmpty ? DateTime.now().millisecondsSinceEpoch : _id.text.trim()}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _client.storage.from('zhk-photos').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: picked.mimeType, upsert: true),
          );
      final publicUrl = _client.storage.from('zhk-photos').getPublicUrl(path);
      if (!mounted) return;
      setState(() => _photoUrl.text = publicUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки фото: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'id': _id.text.trim(),
        'name': _name.text.trim(),
        'district': _nullIfEmpty(_district.text),
        'address': _nullIfEmpty(_address.text),
        'developer': _nullIfEmpty(_developer.text),
        'status': _status,
        'documentation': _nullIfEmpty(_documentation.text),
        'tech_status': _nullIfEmpty(_techStatus.text),
        'violations': _nullIfEmpty(_violations.text),
        'measures': _nullIfEmpty(_measures.text),
        'court': _nullIfEmpty(_court.text),
        'lat': _lat.text.trim().isEmpty ? null : double.tryParse(_lat.text.trim()),
        'lng': _lng.text.trim().isEmpty ? null : double.tryParse(_lng.text.trim()),
        'photo_url': _nullIfEmpty(_photoUrl.text),
        'construction_status': _constructionStatus,
        'completion_year': _completionYear.text.trim().isEmpty
            ? null
            : int.tryParse(_completionYear.text.trim()),
      };

      if (_isEditing) {
        await _client.from('zhk').update(payload).eq('id', widget.existing!['id'] as String);
      } else {
        await _client.from('zhk').insert(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildPhotoField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Фото', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: _photoUrl.text.trim().isEmpty
                ? Container(
                    color: colorScheme.secondaryContainer,
                    child: Icon(Icons.apartment, size: 36, color: colorScheme.onSecondaryContainer),
                  )
                : Image.network(_photoUrl.text.trim(), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _uploadingPhoto ? null : _uploadPhoto,
          icon: _uploadingPhoto
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload),
          label: Text(_uploadingPhoto ? 'Загрузка...' : 'Загрузить фото'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _photoUrl,
          decoration: const InputDecoration(labelText: 'Или ссылка на фото (URL)'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Редактировать ЖК' : 'Новый ЖК')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _id,
              enabled: !_isEditing,
              decoration: const InputDecoration(labelText: 'ID (уникальный, латиницей)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Статус'),
              items: const [
                DropdownMenuItem(value: 'problematic', child: Text('Проблемный / красная зона')),
                DropdownMenuItem(value: 'completed_guaranteed', child: Text('Завершён под госгарантией')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'problematic'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _district, decoration: const InputDecoration(labelText: 'Район')),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Адрес')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _developer, decoration: const InputDecoration(labelText: 'Застройщик')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _constructionStatus,
                    decoration: const InputDecoration(labelText: 'Стройка (видно всем)'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Не указано')),
                      DropdownMenuItem(value: 'built', child: Text('Построен')),
                      DropdownMenuItem(value: 'in_progress', child: Text('Строится')),
                    ],
                    onChanged: (v) => setState(() => _constructionStatus = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _completionYear,
                    decoration: const InputDecoration(labelText: 'Год сдачи'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    decoration: const InputDecoration(labelText: 'Широта (lat)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    decoration: const InputDecoration(labelText: 'Долгота (lng)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPhotoField(context),
            const Divider(height: 32),
            Text('Детали (видны только с подпиской)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentation,
              decoration: const InputDecoration(labelText: 'Разрешительная документация'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _techStatus,
              decoration: const InputDecoration(labelText: 'Техническое состояние'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _violations,
              decoration: const InputDecoration(labelText: 'Нарушения'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _measures,
              decoration: const InputDecoration(labelText: 'Принятые меры'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _court,
              decoration: const InputDecoration(labelText: 'Судебный статус'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
