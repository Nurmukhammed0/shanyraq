import 'package:flutter/material.dart';

import '../widgets/responsive.dart';
import 'desktop_shell.dart';
import 'root_shell.dart';

/// Переключатель мобильной/десктопной раскладки по ширине экрана.
/// Мобильная (RootShell, нижняя навигация) не меняется — переключение
/// происходит только здесь, при входе в приложение.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return isDesktopWidth(context) ? const DesktopShell() : const RootShell();
  }
}
