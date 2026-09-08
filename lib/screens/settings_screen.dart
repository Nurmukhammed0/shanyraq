import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../widgets/grouped_list.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeLabel(BuildContext context, ThemeMode mode) => switch (mode) {
        ThemeMode.light => context.tr('theme_light'),
        ThemeMode.dark => context.tr('theme_dark'),
        ThemeMode.system => context.tr('theme_system'),
      };

  String _languageLabel(AppLanguage lang) => switch (lang) {
        AppLanguage.ru => 'Русский',
        AppLanguage.kz => 'Қазақша',
        AppLanguage.en => 'English',
      };

  Future<void> _openThemeSheet(BuildContext context, SettingsService settings) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(context.tr('settings_theme'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(switch (mode) {
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.system => Icons.smartphone_outlined,
                }),
                title: Text(_themeLabel(context, mode)),
                trailing: settings.themeMode == mode
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openLanguageSheet(BuildContext context, SettingsService settings) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(context.tr('settings_language'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final lang in AppLanguage.values)
              ListTile(
                title: Text(_languageLabel(lang)),
                trailing: settings.language == lang
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  settings.setLanguage(lang);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupCard(children: [
            MenuRow(
              icon: Icons.palette_outlined,
              title: context.tr('settings_theme'),
              trailing: Text(_themeLabel(context, settings.themeMode),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              onTap: () => _openThemeSheet(context, settings),
            ),
            MenuRow(
              icon: Icons.translate,
              title: context.tr('settings_language'),
              trailing: Text(_languageLabel(settings.language),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              onTap: () => _openLanguageSheet(context, settings),
            ),
          ]),
          const SizedBox(height: 20),
          GroupLabel(context.tr('settings_notifications_group')),
          GroupCard(children: [
            _ToggleRow(
              icon: Icons.notifications_active_outlined,
              title: context.tr('settings_status_notifications_title'),
              subtitle: context.tr('settings_status_notifications_body'),
              value: settings.statusNotifications,
              onChanged: settings.setStatusNotifications,
            ),
            _ToggleRow(
              icon: Icons.mail_outline,
              title: context.tr('settings_email_notifications_title'),
              subtitle: context.tr('settings_email_notifications_body'),
              value: settings.emailNotifications,
              onChanged: settings.setEmailNotifications,
            ),
          ]),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
