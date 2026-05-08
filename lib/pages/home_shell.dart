import 'dart:async';

import 'package:flutter/material.dart';

import '../features/chat/pages/conversations_page.dart';
import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/l10n_helper.dart';
import '../state/auth_state.dart';
import '../widgets/top_nav_bar.dart';
import 'found_form_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'notifications_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 2});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex.clamp(0, 4);
  int _unreadCount = 0;
  int _notifCount = 0;
  Timer? _badgeTimer;

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

  List<_NavPage> _buildPages() {
    return [
      _NavPage(
        title: t('chat'),
        icon: Icons.chat_bubble_outline,
        builder: () => const ConversationsPage(),
      ),
      _NavPage(
        title: t('create'),
        icon: Icons.add_circle_outline,
        builder: () => _PlaceholderPage(title: t('create_publication')),
      ),
      _NavPage(
        title: t('home'),
        icon: Icons.home_outlined,
        builder: () => const HomePage(showAppBar: false),
      ),
      _NavPage(
        title: t('profile'),
        icon: Icons.person_outline,
        builder: () => const ProfilePage(),
      ),
      _NavPage(
        title: t('settings'),
        icon: Icons.settings_outlined,
        builder: () => const SettingsPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final pages = _buildPages();
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: authState,
      builder: (context, loggedIn, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: TopNavBar(
            notificationCount: _notifCount,
            onNotifications: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
              // après ouverture, on considère tout comme vu
              await AuthLocalStorage.instance.setLastNotifSeen(DateTime.now());
              if (mounted) setState(() => _notifCount = 0);
              _loadUnreadCount(); // rafraîchit immédiatement le badge
            },
          ),
          body: IndexedStack(
            index: _index,
            children: pages.map((page) => page.builder()).toList(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            height: 70,
            backgroundColor: scheme.surface.withValues(alpha: 0.94),
            indicatorColor: scheme.primary.withValues(alpha: 0.2),
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) async {
              if (i == 1) {
                await _showCreateSheet();
                return;
              }
              setState(() => _index = i);
            },
            destinations: pages.asMap().entries.map((entry) {
              final page = entry.value;
              final i = entry.key;
              Widget icon = Icon(page.icon, color: scheme.onSurfaceVariant);
              Widget selectedIcon = Icon(page.icon, color: scheme.primary);
              if (i == 0 && _unreadCount > 0) {
                icon = _withBadge(icon, scheme);
                selectedIcon = _withBadge(selectedIcon, scheme);
              }
              return NavigationDestination(
                icon: icon,
                selectedIcon: selectedIcon,
                label: page.title,
              );
            }).toList(),
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
        watchLanguage(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(ctx, 'create_publication'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(ctx, 'choose_announcement_type'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
                  label: Text(tr(ctx, 'i_lost')),
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
                  label: Text(tr(ctx, 'i_found')),
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
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _loadUnreadCount(),
    );
  }

  Future<void> _loadUnreadCount() async {
    try {
      final user = await AuthLocalStorage.instance.getUser();
      if (user == null) {
        if (_unreadCount != 0 || _notifCount != 0) {
          setState(() {
            _unreadCount = 0;
            _notifCount = 0;
          });
        }
        return;
      }
      final conversations = await ApiService.instance.getConversations(
        userId: user.id,
      );
      final total = conversations.fold<int>(0, (previous, current) {
        final raw = current['unread_count'] ?? 0;
        return previous +
            (raw is num ? raw.toInt() : int.tryParse(raw.toString()) ?? 0);
      });
      int notifTotal = 0;
      try {
        notifTotal = await ApiService.instance.fetchNotificationsCount(
          userId: user.id,
        );
      } catch (_) {
        // on ignore les erreurs de notif pour ne pas bloquer le badge chat
      }
      if (mounted && (total != _unreadCount || notifTotal != _notifCount)) {
        setState(() {
          _unreadCount = total;
          _notifCount = notifTotal;
        });
      }
    } catch (_) {
      // Ignore pour ne pas casser l'UI.
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
    watchLanguage(context);
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
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'coming_soon'),
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
