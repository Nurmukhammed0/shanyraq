import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'root_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _seenKey = 'onboarding.seen';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page({required this.icon, required this.title, required this.body});
}

const _pages = [
  _Page(
    icon: Icons.map_outlined,
    title: 'Шаңырақ — дом на карте',
    body: 'Показываем на карте проблемные жилые комплексы и объекты, '
        'завершённые под госгарантией — чтобы вы видели риски до сделки.',
  ),
  _Page(
    icon: Icons.warning_amber_outlined,
    title: 'Красная зона и гарантия',
    body: 'Красный маркер — у объекта есть нарушения или проблемы со стройкой. '
        'Зелёный — комплекс сдан под госгарантией дольщикам.',
  ),
  _Page(
    icon: Icons.workspace_premium_outlined,
    title: 'Подробности по подписке',
    body: 'Базовая информация (адрес, застройщик) доступна всем бесплатно. '
        'Детали — нарушения, суд, документация — открываются по подписке.',
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen._seenKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Пропустить'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(page.icon, size: 56, color: colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.4, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? colorScheme.primary : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLast
                      ? _finish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  child: Text(isLast ? 'Начать' : 'Далее'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
