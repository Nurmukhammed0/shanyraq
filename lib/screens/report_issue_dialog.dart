import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> showReportIssueDialog(BuildContext context, String zhkId) {
  return showDialog(
    context: context,
    builder: (_) => _ReportIssueDialog(zhkId: zhkId),
  );
}

class _ReportIssueDialog extends StatefulWidget {
  final String zhkId;
  const _ReportIssueDialog({required this.zhkId});

  @override
  State<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<_ReportIssueDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Опишите, что именно не так');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('zhk_reports').insert({
        'zhk_id': widget.zhkId,
        'user_id': userId,
        'message': message,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спасибо! Мы получили ваше сообщение.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось отправить: $e';
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сообщить об ошибке'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Опишите, какая информация неверна или устарела.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Например: этот ЖК уже достроен и сдан...',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Отправить'),
        ),
      ],
    );
  }
}
