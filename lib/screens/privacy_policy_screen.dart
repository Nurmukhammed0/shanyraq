import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Черновик политики конфиденциальности. Перед публикацией в App Store /
/// Google Play и реальным запуском подписки — отдать на проверку юристу.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_privacy_policy'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: context.tr('privacy_s1_title'), body: context.tr('privacy_s1_body')),
          _Section(title: context.tr('privacy_s2_title'), body: context.tr('privacy_s2_body')),
          _Section(title: context.tr('privacy_s3_title'), body: context.tr('privacy_s3_body')),
          _Section(title: context.tr('privacy_s4_title'), body: context.tr('privacy_s4_body')),
          _Section(title: context.tr('privacy_s5_title'), body: context.tr('privacy_s5_body')),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}
