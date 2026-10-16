import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/app_logo.dart';
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
/// Профиль — не пункт меню, а карточка пользователя внизу (аватар,
/// имя, быстрый выход), как в типичных десктоп-приложениях.
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
          _Sidebar(
            selected: _index,
            onSelect: (i) => setState(() => _index = i),
            onOpenProfile: () => setState(() => _index = 4),
          ),
          VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenProfile;
  const _Sidebar({required this.selected, required this.onSelect, required this.onOpenProfile});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _collapsed = false;

  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileService>();
    final auth = context.watch<AuthService>();

    final items = [
      (Icons.home_outlined, Icons.home, context.tr('nav_home')),
      (Icons.description_outlined, Icons.description, context.tr('home_documents_title')),
      (Icons.home_work_outlined, Icons.home_work, context.tr('home_buy_title')),
      (Icons.favorite_border, Icons.favorite, context.tr('nav_favorites')),
    ];

    // Важно: позиция иконки НЕ зависит от _collapsed (всегда одна и та же
    // отступ слева, всегда MainAxisAlignment.start) — схлопывается только
    // подпись через _CollapsingLabel. Раньше Row дополнительно мгновенно
    // переключал mainAxisAlignment/padding на center при сворачивании —
    // из-за этого иконка и синяя подсветка выбранного пункта «прыгали»
    // вместо того, чтобы плавно ехать вместе с анимацией ширины.
    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      width: _collapsed ? 76 : 232,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const AppLogo(size: 30),
                _CollapsingLabel(
                  collapsed: _collapsed,
                  duration: _duration,
                  curve: _curve,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(context.tr('app_title'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        overflow: TextOverflow.clip,
                        softWrap: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: context.tr(_collapsed ? 'sidebar_expand' : 'sidebar_collapse'),
              onPressed: () => setState(() => _collapsed = !_collapsed),
              icon: AnimatedRotation(
                duration: _duration,
                curve: _curve,
                turns: _collapsed ? 0.5 : 0,
                child: const Icon(Icons.chevron_left),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Tooltip(
                message: _collapsed ? items[i].$3 : '',
                child: Material(
                  color: widget.selected == i ? colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => widget.onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      child: Row(
                        children: [
                          Icon(
                            widget.selected == i ? items[i].$2 : items[i].$1,
                            size: 20,
                            color: widget.selected == i
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          _CollapsingLabel(
                            collapsed: _collapsed,
                            duration: _duration,
                            curve: _curve,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                items[i].$3,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: widget.selected == i ? FontWeight.w700 : FontWeight.w500,
                                  color: widget.selected == i
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          _UserCard(
            collapsed: _collapsed,
            selected: widget.selected == 4,
            displayName: profile.displayName,
            email: auth.currentUser?.email,
            avatarUrl: profile.avatarUrl,
            onTap: widget.onOpenProfile,
            onLogout: () => auth.signOut(),
          ),
        ],
      ),
    );
  }
}

/// Подпись пункта меню, которая плавно схлопывается вместе с сайдбаром,
/// а не просто исчезает/появляется скачком.
class _CollapsingLabel extends StatelessWidget {
  final bool collapsed;
  final Duration duration;
  final Curve curve;
  final Widget child;
  const _CollapsingLabel({
    required this.collapsed,
    required this.duration,
    required this.curve,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRect(
        child: AnimatedAlign(
          duration: duration,
          curve: curve,
          alignment: Alignment.centerLeft,
          widthFactor: collapsed ? 0 : 1,
          child: AnimatedOpacity(
            duration: duration,
            opacity: collapsed ? 0 : 1,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final bool collapsed;
  final bool selected;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback onLogout;

  const _UserCard({
    required this.collapsed,
    required this.selected,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = (displayName?.isNotEmpty ?? false) ? displayName! : (email ?? '');

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Icon(Icons.person, size: 16, color: colorScheme.onPrimaryContainer)
          : null,
    );

    return Material(
      color: selected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              avatar,
              Expanded(
                child: ClipRect(
                  child: AnimatedAlign(
                    duration: _SidebarState._duration,
                    curve: _SidebarState._curve,
                    alignment: Alignment.centerLeft,
                    widthFactor: collapsed ? 0 : 1,
                    child: AnimatedOpacity(
                      duration: _SidebarState._duration,
                      opacity: collapsed ? 0 : 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 4),
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!collapsed)
                IconButton(
                  iconSize: 17,
                  visualDensity: VisualDensity.compact,
                  tooltip: context.tr('profile_logout'),
                  icon: Icon(Icons.logout, color: colorScheme.error),
                  onPressed: onLogout,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
