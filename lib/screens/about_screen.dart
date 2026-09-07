import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

const _supportPhone = '+7 771 470 72 22';
const _supportEmail = 'nurbeekovn@gmail.com';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.home_work_outlined, size: 36, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 12),
                const Text('Шаңырақ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(context.tr('about_version'), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              context.tr('about_description'),
              style: const TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('about_data_source_heading'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  context.tr('about_data_source_body'),
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: Text(context.tr('about_call_support')),
            subtitle: const Text(_supportPhone),
            onTap: () => launchUrl(Uri(scheme: 'tel', path: _supportPhone.replaceAll(' ', ''))),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(context.tr('about_email_support')),
            subtitle: const Text(_supportEmail),
            onTap: () => launchUrl(Uri(scheme: 'mailto', path: _supportEmail)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(context.tr('about_privacy_policy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(context.tr('about_terms')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
