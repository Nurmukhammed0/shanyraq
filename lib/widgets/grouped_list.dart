import 'package:flutter/material.dart';

/// Карточка сгруппированного списка (пункты меню с разделителями) —
/// общий паттерн для Профиля, Редактирования профиля, Настроек, Админки.
class GroupCard extends StatelessWidget {
  final List<Widget> children;
  const GroupCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: 60, color: colorScheme.outlineVariant.withOpacity(0.4)),
          ],
        ],
      ),
    );
  }
}

class GroupLabel extends StatelessWidget {
  final String text;
  const GroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;

  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = iconColor ?? colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: tint.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: iconColor)),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
