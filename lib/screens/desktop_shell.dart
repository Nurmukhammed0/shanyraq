import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import 'buy_house_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'root_shell.dart' show ProfileView;
import 'zhk_list_screen.dart';

/// Десктоп/планшет (ширина ≥ kDesktopBreakpoint): постоянный сайдбар
/// слева вместо нижней навигации, широкая область контента справа.
/// Экраны внутри — те же самые виджеты, что и в мобильной раскладке
/// (RootShell её вообще не знает и не меняется из-за этого файла);
/// «Документы» и «Купить дом» на десктопе вынесены в сайдбар напрямую,
/// а не спрятаны за кнопками на главной — места на широком экране хватает.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      const HomeScreen(),
      const ZhkListScreen(),
      const BuyHouseScreen(),
      const FavoritesScreen(),
      auth.isLoggedIn ? const ProfileView() : const LoginScreen(),
    ];

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(selected: _index, onSelect: (i) => setState(() => _index = i)),
          VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      (Icons.home_outlined, Icons.home, context.tr('nav_home')),
      (Icons.description_outlined, Icons.description, context.tr('home_documents_title')),
      (Icons.home_work_outlined, Icons.home_work, context.tr('home_buy_title')),
      (Icons.favorite_border, Icons.favorite, context.tr('nav_favorites')),
      (Icons.person_outline, Icons.person, context.tr('nav_profile')),
    ];

    return Container(
      width: 232,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(context.tr('app_title'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Material(
                color: selected == i ? colorScheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        Icon(
                          selected == i ? items[i].$2 : items[i].$1,
                          size: 20,
                          color: selected == i
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            items[i].$3,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: selected == i ? FontWeight.w700 : FontWeight.w500,
                              color: selected == i
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
