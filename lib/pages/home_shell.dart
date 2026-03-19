import 'package:flutter/material.dart';

import '../features/chat/pages/conversations_page.dart';
import '../state/auth_state.dart';
import '../widgets/top_nav_bar.dart';
import 'home_page.dart';
import 'found_form_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 2});

  /// 0: Chat, 1: Créer, 2: Accueil, 3: Profil, 4: Paramètres
  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex.clamp(0, 4);

  late final List<_NavPage> _pages = [
    _NavPage(
      title: 'Chat',
      icon: Icons.chat_bubble_outline,
      builder: () => const ConversationsPage(),
    ),
    _NavPage(
      title: 'Créer',
      icon: Icons.add_circle_outline,
      builder: () => const _PlaceholderPage(title: 'Créer une publication'),
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
      builder: () => const SettingsPage(),
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
          indicatorColor: scheme.primary.withValues(alpha: 0.12),
          surfaceTintColor: scheme.surfaceTint,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) async {
            // Intercepte le bouton "Créer" pour ouvrir le choix rapide
            if (i == 1) {
              await _showCreateSheet();
              return;
            }
            setState(() => _index = i);
          },
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

  Future<void> _showCreateSheet() async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Créer une publication', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Choisissez le type d’annonce à publier.',
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FoundFormPage(type: 'lost'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search_off_outlined),
                  label: const Text("J'ai perdu"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FoundFormPage(type: 'found'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: const Text("J'ai trouvé"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
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
            scheme.primary.withValues(alpha: 0.05),
            scheme.secondaryContainer.withValues(alpha: 0.03),
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
