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
import 'notifications_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

const int mainAppShellChatIndex = 0;
const int mainAppShellCreateIndex = 1;
const int mainAppShellHomeIndex = 2;
const int mainAppShellProfileIndex = 3;
const int mainAppShellSettingsIndex = 4;

int clampMainAppShellIndex(int index) =>
    index.clamp(mainAppShellChatIndex, mainAppShellSettingsIndex);

void openAuthenticatedSection(BuildContext context, {required int index}) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => MainAppShell(initialIndex: clampMainAppShellIndex(index)),
    ),
    (route) => false,
  );
}

class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key, this.initialIndex = mainAppShellHomeIndex});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final resolvedIndex = clampMainAppShellIndex(initialIndex);

    return ValueListenableBuilder<bool>(
      valueListenable: authState,
      builder: (context, loggedIn, _) {
        if (!loggedIn) {
          return const HomePage();
        }

        switch (resolvedIndex) {
          case mainAppShellChatIndex:
            return const ConversationsPage();
          case mainAppShellCreateIndex:
            return const _CreatePublicationHubPage();
          case mainAppShellProfileIndex:
            return const ProfilePage();
          case mainAppShellSettingsIndex:
            return const SettingsPage();
          case mainAppShellHomeIndex:
          default:
            return const HomePage(authenticated: true);
        }
      },
    );
  }
}

class AuthenticatedScaffold extends StatefulWidget {
  const AuthenticatedScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.isTabRoot = false,
    this.showDefaultTopNavBar = false,
    this.resizeToAvoidBottomInset = true,
  });

  final int currentIndex;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool isTabRoot;
  final bool showDefaultTopNavBar;
  final bool resizeToAvoidBottomInset;

  @override
  State<AuthenticatedScaffold> createState() => _AuthenticatedScaffoldState();
}

class _AuthenticatedScaffoldState extends State<AuthenticatedScaffold> {
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

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final resolvedIndex = clampMainAppShellIndex(widget.currentIndex);

    final resolvedAppBar =
        widget.appBar ??
        (widget.showDefaultTopNavBar
            ? TopNavBar(
                notificationCount: _notifCount,
                onNotifications: () => _openNotifications(resolvedIndex),
              )
            : null);

    return ValueListenableBuilder<bool>(
      valueListenable: authState,
      builder: (context, loggedIn, _) {
        return Scaffold(
          resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
          backgroundColor:
              widget.backgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          appBar: resolvedAppBar,
          body: widget.body,
          bottomNavigationBar: loggedIn
              ? NavigationBar(
                  selectedIndex: resolvedIndex,
                  height: 70,
                  backgroundColor: scheme.surface.withValues(alpha: 0.94),
                  indicatorColor: scheme.primary.withValues(alpha: 0.2),
                  surfaceTintColor: Colors.transparent,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: _buildDestinations(scheme),
                )
              : null,
        );
      },
    );
  }

  List<NavigationDestination> _buildDestinations(ColorScheme scheme) {
    final items = <_ShellDestination>[
      _ShellDestination(title: t('chat'), icon: Icons.chat_bubble_outline),
      _ShellDestination(title: t('create'), icon: Icons.add_circle_outline),
      _ShellDestination(title: t('home'), icon: Icons.home_outlined),
      _ShellDestination(title: t('profile'), icon: Icons.person_outline),
      _ShellDestination(title: t('settings'), icon: Icons.settings_outlined),
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      Widget icon = Icon(item.icon, color: scheme.onSurfaceVariant);
      Widget selectedIcon = Icon(item.icon, color: scheme.primary);

      if (index == mainAppShellChatIndex && _unreadCount > 0) {
        icon = _withBadge(icon, scheme);
        selectedIcon = _withBadge(selectedIcon, scheme);
      }

      return NavigationDestination(
        icon: icon,
        selectedIcon: selectedIcon,
        label: item.title,
      );
    }).toList();
  }

  Future<void> _onDestinationSelected(int index) async {
    final resolvedIndex = clampMainAppShellIndex(index);
    final currentIndex = clampMainAppShellIndex(widget.currentIndex);

    if (resolvedIndex == currentIndex && widget.isTabRoot) {
      return;
    }

    openAuthenticatedSection(context, index: resolvedIndex);
  }

  Future<void> _openNotifications(int currentIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(currentIndex: currentIndex),
      ),
    );
    if (!mounted) return;
    _loadUnreadCount();
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
      final unreadTotal = conversations.fold<int>(0, (previous, current) {
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
        // Ignore notification failures so the connected shell stays usable.
      }

      if (mounted &&
          (unreadTotal != _unreadCount || notifTotal != _notifCount)) {
        setState(() {
          _unreadCount = unreadTotal;
          _notifCount = notifTotal;
        });
      }
    } catch (_) {
      // Ignore badge loading errors so the shell stays usable.
    }
  }
}

class _CreatePublicationHubPage extends StatelessWidget {
  const _CreatePublicationHubPage();

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AuthenticatedScaffold(
      currentIndex: mainAppShellCreateIndex,
      isTabRoot: true,
      showDefaultTopNavBar: true,
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.08),
                          scheme.secondaryContainer.withValues(alpha: 0.18),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 40,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(context, 'create_publication'),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(context, 'choose_announcement_type'),
                          style: textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _CreateOptionCard(
                    icon: Icons.search_off_outlined,
                    iconColor: Colors.redAccent,
                    title: tr(context, 'i_lost'),
                    subtitle: tr(context, 'payment_required_before_publish'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FoundFormPage(type: 'lost'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CreateOptionCard(
                    icon: Icons.volunteer_activism_outlined,
                    iconColor: Colors.green,
                    title: tr(context, 'i_found'),
                    subtitle: tr(context, 'free_publication'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FoundFormPage(type: 'found'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateOptionCard extends StatelessWidget {
  const _CreateOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
