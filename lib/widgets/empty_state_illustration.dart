import 'package:flutter/material.dart';

/// Фирменная иллюстрация для пустых экранов — дом с отметкой,
/// перекликается с иконкой приложения. Рисуется кодом, а не картинкой,
/// чтобы красиво масштабироваться и подхватывать цвета темы.
class EmptyStateIllustration extends StatelessWidget {
  final IconData badgeIcon;
  final double size;

  const EmptyStateIllustration({
    super.key,
    this.badgeIcon = Icons.favorite_border,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Icon(Icons.home_rounded, size: size * 0.5, color: colorScheme.onPrimaryContainer),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.12,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: EdgeInsets.all(size * 0.06),
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: Icon(badgeIcon, size: size * 0.14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
