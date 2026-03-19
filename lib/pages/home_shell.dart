import 'package:flutter/material.dart';
import 'dart:async';

import '../features/chat/pages/conversations_page.dart';
import '../state/auth_state.dart';
import '../widgets/top_nav_bar.dart';
import 'home_page.dart';
import 'found_form_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import '../services/auth_local_storage.dart';
import '../services/api_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 2});

  /// 0: Chat, 1: Créer, 2: Accueil, 3: Profil, 4: Paramètres
  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex.clamp(0, 4);
  int _unreadCount = 0;
  Timer? _badgeTimer;

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
  void initState() {
    super.initState();
    _startBadgePolling();
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

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
                .asMap()
                .entries
                .map(
                  (entry) {
                    final p = entry.value;
                    final i = entry.key;
                    Widget icon = Icon(p.icon, color: scheme.onSurfaceVariant);
                    Widget selectedIcon = Icon(p.icon, color: scheme.primary);
                    if (i == 0 && _unreadCount > 0) {
                      icon = _withBadge(icon, scheme);
                      selectedIcon = _withBadge(selectedIcon, scheme);
                    }
                    return NavigationDestination(
                      icon: icon,
                      selectedIcon: selectedIcon,
                      label: p.title,
                    );
                  },
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

  Widget _withBadge(Widget child, ColorScheme scheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _unreadCount > 9 ? '9+' : '$_unreadCount',
              style: TextStyle(
                color: scheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startBadgePolling() {
    _loadUnreadCount();
    _badgeTimer = Timer.periodic(const Duration(seconds: 6), (_) => _loadUnreadCount());
  }

  Future<void> _loadUnreadCount() async {
    try {
      final user = await AuthLocalStorage.instance.getUser();
      if (user == null) {
        if (_unreadCount != 0) setState(() => _unreadCount = 0);
        return;
      }
      final convs = await ApiService.instance.getConversations(userId: user.id);
      final total = convs.fold<int>(0, (p, c) {
        final raw = c['unread_count'] ?? 0;
        return p + (raw is num ? raw.toInt() : int.tryParse(raw.toString()) ?? 0);
      });
      if (mounted && total != _unreadCount) {
        setState(() => _unreadCount = total);
      }
    } catch (_) {
      // on ignore pour ne pas casser l'UI
    }
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
