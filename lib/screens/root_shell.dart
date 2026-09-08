import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/grouped_list.dart';
import 'about_screen.dart';
import 'admin_screen.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

/// Корневой экран с нижней навигацией: Карта / Избранное / Профиль.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    final tabs = [
      const MapScreen(),
      const FavoritesScreen(),
      auth.isLoggedIn ? const _ProfileView() : const LoginScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: context.tr('nav_map'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: context.tr('nav_favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.tr('nav_profile'),
          ),
        ],
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = context.watch<ProfileService>();
    final colorScheme = Theme.of(context).colorScheme;
    final subscribed = profile.isSubscribed;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('nav_profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage:
                      profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null
                      ? Icon(Icons.person, color: colorScheme.onPrimaryContainer, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName?.isNotEmpty == true
                            ? profile.displayName!
                            : auth.currentUser?.email ?? context.tr('profile_signed_in_fallback'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: subscribed
                              ? const Color(0xFF22C55E).withOpacity(0.14)
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              subscribed ? Icons.check_circle : Icons.lock_outline,
                              size: 14,
                              color: subscribed ? const Color(0xFF22C55E) : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              subscribed
                                  ? context.tr('subscription_active_title')
                                  : context.tr('profile_no_subscription'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: subscribed ? const Color(0xFF22C55E) : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GroupLabel(context.tr('profile_group_account')),
          GroupCard(children: [
            MenuRow(
              icon: Icons.edit_outlined,
              title: context.tr('edit_profile_title'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            MenuRow(
              icon: Icons.workspace_premium_outlined,
              title: context.tr('profile_subscription_tile'),
              trailing: subscribed
                  ? const Icon(Icons.check_circle, size: 18, color: Color(0xFF22C55E))
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          GroupLabel(context.tr('profile_group_app')),
          GroupCard(children: [
            MenuRow(
              icon: Icons.settings_outlined,
              title: context.tr('profile_settings_tile'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            if (profile.isAdmin)
              MenuRow(
                icon: Icons.admin_panel_settings_outlined,
                title: context.tr('profile_admin_tile'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
            MenuRow(
              icon: Icons.info_outline,
              title: context.tr('about_title'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withOpacity(0.4)),
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(context.tr('profile_logout')),
              onPressed: () => auth.signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

