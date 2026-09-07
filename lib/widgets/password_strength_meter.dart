import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

enum PasswordStrengthLevel { weak, medium, strong }

class PasswordCheck {
  final bool hasLength;
  final bool hasUppercase;
  final bool hasDigit;
  final bool hasSymbol;

  const PasswordCheck({
    required this.hasLength,
    required this.hasUppercase,
    required this.hasDigit,
    required this.hasSymbol,
  });

  int get score => [hasLength, hasUppercase, hasDigit, hasSymbol].where((e) => e).length;
  bool get isValid => hasLength && hasUppercase && hasDigit && hasSymbol;

  PasswordStrengthLevel get level {
    if (score <= 1) return PasswordStrengthLevel.weak;
    if (score <= 3) return PasswordStrengthLevel.medium;
    return PasswordStrengthLevel.strong;
  }

  static final _uppercase = RegExp(r'[A-ZА-ЯЁ]');
  static final _digit = RegExp(r'[0-9]');
  static final _symbol = RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]/\\~`;']''');

  factory PasswordCheck.evaluate(String password) {
    return PasswordCheck(
      hasLength: password.length >= 8,
      hasUppercase: _uppercase.hasMatch(password),
      hasDigit: _digit.hasMatch(password),
      hasSymbol: _symbol.hasMatch(password),
    );
  }
}

/// Индикатор надёжности пароля: полоса-заполнение + чек-лист требований.
/// Ничего не показывает, пока поле пустое.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final check = PasswordCheck.evaluate(password);
    final colorScheme = Theme.of(context).colorScheme;

    final Color barColor;
    final String label;
    if (check.level == PasswordStrengthLevel.weak) {
      barColor = const Color(0xFFE24B4A);
      label = context.tr('password_strength_weak');
    } else if (check.level == PasswordStrengthLevel.medium) {
      barColor = const Color(0xFFF59E0B);
      label = context.tr('password_strength_medium');
    } else {
      barColor = const Color(0xFF22C55E);
      label = context.tr('password_strength_strong');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 6,
                        width: constraints.maxWidth,
                        color: colorScheme.surfaceVariant,
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          height: 6,
                          width: constraints.maxWidth * (check.score / 4),
                          color: barColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: barColor),
                child: Text(label),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Requirement(met: check.hasLength, label: context.tr('password_req_length')),
              _Requirement(met: check.hasUppercase, label: context.tr('password_req_uppercase')),
              _Requirement(met: check.hasDigit, label: context.tr('password_req_digit')),
              _Requirement(met: check.hasSymbol, label: context.tr('password_req_symbol')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final bool met;
  final String label;
  const _Requirement({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = met ? const Color(0xFF22C55E) : colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            key: ValueKey(met),
            size: 13,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11.5, color: color)),
      ],
    );
  }
}
