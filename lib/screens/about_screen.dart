import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      appBar: AppBar(title: const Text('О приложении')),
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
                const Text('Версия 0.1.0', style: TextStyle(color: Colors.grey)),
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
            child: const Text(
              'Шаңырақ — купольное навершие юрты, символ дома и семьи. Так и это '
              'приложение: прежде чем назвать что-то домом, стоит убедиться, что это '
              'безопасно. Мы показываем на карте проблемные жилые комплексы Алматы '
              '(«красная зона») и объекты, завершённые под госгарантией — чтобы вы '
              'видели риски заранее, а не после сделки.',
              style: TextStyle(height: 1.4),
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
                Text('Источник данных', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                const Text(
                  'Список проблемных объектов и объектов под госгарантией собран на '
                  'основе официальных отчётов по долевому строительству Алматы. '
                  'Данные могут устаревать — при обнаружении неточности напишите нам.',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Позвонить в поддержку'),
            subtitle: const Text(_supportPhone),
            onTap: () => launchUrl(Uri(scheme: 'tel', path: _supportPhone.replaceAll(' ', ''))),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Написать в поддержку'),
            subtitle: const Text(_supportEmail),
            onTap: () => launchUrl(Uri(scheme: 'mailto', path: _supportEmail)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Пользовательское соглашение'),
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
