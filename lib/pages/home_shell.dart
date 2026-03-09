import 'package:flutter/material.dart';

import '../features/chat/pages/conversations_page.dart';
import '../state/auth_state.dart';
import '../widgets/top_nav_bar.dart';
import 'home_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 2; // default Home

  late final List<_NavPage> _pages = [
    _NavPage(
      title: 'Chat',
      icon: Icons.chat_bubble_outline,
      builder: () => const ConversationsPage(),
    ),
    _NavPage(
      title: 'Créer',
      icon: Icons.campaign_outlined,
      builder: () => const _PlaceholderPage(title: 'Créer une publicité'),
    ),
    _NavPage(
      title: 'Accueil',
      icon: Icons.home_outlined,
      builder: () => const HomePage(showAppBar: false),
    ),
    _NavPage(
      title: 'Profil',
      icon: Icons.person_outline,
      builder: () => const ProfilePage(),
    ),
    _NavPage(
      title: 'Paramètres',
      icon: Icons.settings_outlined,
      builder: () => const _PlaceholderPage(title: 'Paramètres'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: authState,
      builder: (context, loggedIn, _) {
        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: const TopNavBar(),
          body: IndexedStack(
            index: _index,
            children: _pages.map((p) => p.builder()).toList(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            height: 70,
            backgroundColor: scheme.surface,
            indicatorColor: scheme.primary.withOpacity(0.12),
            surfaceTintColor: scheme.surfaceTint,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: _pages
                .map(
                  (p) => NavigationDestination(
                    icon: Icon(p.icon, color: scheme.onSurfaceVariant),
                    selectedIcon: Icon(p.icon, color: scheme.primary),
                    label: p.title,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _NavPage {
  final String title;
  final IconData icon;
  final Widget Function() builder;
  _NavPage({required this.title, required this.icon, required this.builder});
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.05),
            scheme.secondaryContainer.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.widgets_outlined, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Contenu à venir',
              style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
