import 'package:flutter/material.dart';

/// Логотип приложения — дом с отметкой "проверено", как на иконке
/// приложения. Используется на экранах входа/регистрации/онбординга.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2454FF),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.home_rounded, size: size * 0.5, color: Colors.white),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.12,
            child: Container(
              padding: EdgeInsets.all(size * 0.05),
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: size * 0.16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
