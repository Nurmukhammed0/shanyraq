import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/empty_state_illustration.dart';

/// Раздел покупки дома — пока статус-заглушка без функционала.
class BuyHouseScreen extends StatelessWidget {
  const BuyHouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('home_buy_title'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyStateIllustration(badgeIcon: Icons.hourglass_top_rounded),
              const SizedBox(height: 20),
              Text(
                context.tr('home_buy_badge'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('buy_house_coming_body'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
