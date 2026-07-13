import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            icon: Icons.palette_outlined,
            title: context.tr('settings_theme'),
            children: [
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                    label: Text(context.tr('theme_light')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text(context.tr('theme_dark')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.smartphone_outlined, size: 18),
                    label: Text(context.tr('theme_system')),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            icon: Icons.translate,
            title: context.tr('settings_language'),
            children: [
              for (final lang in AppLanguage.values) ...[
                _LanguageRow(
                  label: switch (lang) {
                    AppLanguage.ru => 'Русский',
                    AppLanguage.kz => 'Қазақша',
                    AppLanguage.en => 'English',
                  },
                  selected: settings.language == lang,
                  onTap: () => settings.setLanguage(lang),
                ),
                if (lang != AppLanguage.values.last)
                  Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14.5,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
