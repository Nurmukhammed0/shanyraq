import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/zhk_repository.dart';
import 'about_screen.dart';
import 'buy_house_screen.dart';
import 'zhk_list_screen.dart';

/// Главная страница: рекламный баннер о проекте (пока единственный
/// «рекламодатель» — мы сами, слот подписан как открытый для партнёров)
/// и две точки входа — покупка дома (заглушка) и документы/статусы
/// новостроек (рабочий раздел, ведёт к списку ЖК и дальше на карту).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _zhkCount;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final data = await ZhkRepository().fetchFromSupabase();
      if (!mounted) return;
      setState(() => _zhkCount = data.length);
    } catch (_) {
      // Декоративная статистика в баннере — при ошибке молча пропускаем.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('app_title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 22),
          _AdBanner(zhkCount: _zhkCount),
        ],
      ),
    );
  }
}

/// Единственный рекламный слот на главной. Пока в нём — баннер о самом
/// проекте (нам самим есть что сказать о ценности приложения); внизу —
/// пометка, что место открыто для рекламодателей, как только появятся.
class _AdBanner extends StatelessWidget {
  final int? zhkCount;
  const _AdBanner({this.zhkCount});

  void _showAdContact(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('home_ad_contact_snackbar'))));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withOpacity(0.76)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: scheme.primary.withOpacity(0.32), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -24,
            child: Icon(Icons.shield_outlined, size: 140, color: Colors.white.withOpacity(0.08)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        context.tr('home_ad_badge'),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                      ),
                    ),
                    const Spacer(),
                    if (zhkCount != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights_outlined, size: 13, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('home_ad_stat', {'count': '$zhkCount'}),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), shape: BoxShape.circle),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('home_ad_title'),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.25),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('home_ad_body'),
                            style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                      child: Text(context.tr('home_ad_cta'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: Colors.white.withOpacity(0.16)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _showAdContact(context),
                  child: Row(
                    children: [
                      Icon(Icons.campaign_outlined, size: 14, color: Colors.white.withOpacity(0.75)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.tr('home_ad_placeholder_note'),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75), fontSize: 11.5, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
