import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'buy_house_screen.dart';
import 'zhk_list_screen.dart';

/// Главная страница: две точки входа — покупка дома (пока заглушка)
/// и документы/статусы новостроек (рабочий раздел, ведёт к списку ЖК
/// и дальше на карту).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('app_title'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HomeActionCard(
                icon: Icons.description_outlined,
                title: context.tr('home_documents_title'),
                subtitle: context.tr('home_documents_subtitle'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ZhkListScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _HomeActionCard(
                icon: Icons.home_work_outlined,
                title: context.tr('home_buy_title'),
                subtitle: context.tr('home_buy_subtitle'),
                badge: context.tr('home_buy_badge'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BuyHouseScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 26, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5)),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(badge!,
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
