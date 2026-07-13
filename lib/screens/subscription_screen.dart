import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../services/profile_service.dart';
import '../widgets/app_logo.dart';

const _supportPhone = '+7 771 470 72 22';
const _supportEmail = 'nurbeekovn@gmail.com';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const _benefits = [
    ('Статус риска на карте', 'Красная зона или госгарантия — сразу видно на маркере', Icons.location_on_outlined),
    ('Разрешительная документация', 'Что оформлено, а что отсутствует у застройщика', Icons.description_outlined),
    ('Нарушения и меры', 'Полная история претензий и принятых мер', Icons.gavel_outlined),
    ('Судебный статус', 'Есть ли иски, решения о сносе, исполнительные листы', Icons.balance_outlined),
    ('Уведомления', 'Сообщим, если статус избранного ЖК изменится', Icons.notifications_active_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('subscription_title'))),
      body: SafeArea(
        child: profile.isSubscribed ? _buildActive(context, colorScheme) : _buildPaywall(context, profile, colorScheme),
      ),
    );
  }

  Widget _buildActive(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('subscription_active_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('subscription_active_body'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 32),
        ..._benefits.map((b) => _BenefitRow(title: b.$1, subtitle: b.$2, icon: b.$3, unlocked: true)),
      ],
    );
  }

  Widget _buildPaywall(BuildContext context, ProfileService profile, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        const Center(child: AppLogo(size: 64)),
        const SizedBox(height: 20),
        const Text(
          'Полная картина перед покупкой',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Адрес и застройщик видны всем бесплатно. Подписка открывает то,\n'
          'что реально влияет на решение о покупке.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 28),
        ..._benefits.map((b) => _BenefitRow(title: b.$1, subtitle: b.$2, icon: b.$3, unlocked: false)),
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
              Text('Как оформить', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Онлайн-оплата пока не подключена — активируем вручную. '
                'Напишите или позвоните, укажите свой email${profile.email != null ? ' (${profile.email})' : ''}, '
                'и мы включим подписку.',
                style: const TextStyle(height: 1.4, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => launchUrl(Uri(scheme: 'mailto', path: _supportEmail)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.mail_outline, size: 20),
          label: const Text('Написать на почту'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri(scheme: 'tel', path: _supportPhone.replaceAll(' ', ''))),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.phone_outlined, size: 20),
          label: const Text('Позвонить: $_supportPhone'),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool unlocked;

  const _BenefitRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = unlocked ? const Color(0xFF22C55E) : colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, size: 20, color: Color(0xFF22C55E))
          else
            Icon(Icons.lock_outline, size: 18, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
