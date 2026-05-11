// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/feedback/app_feedback.dart';
import '../services/api_service.dart';
import '../services/auth_local_storage.dart';
import '../services/l10n_helper.dart';
import '../widgets/home/home_action_card.dart';
import '../widgets/home/home_search_bar.dart';
import '../widgets/home/recent_publications_section.dart';
import '../widgets/top_nav_bar.dart';
import 'found_form_page.dart';
import 'login_page.dart';
import 'main_app_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.showAppBar = true,
    this.authenticated = false,
  });

  final bool showAppBar;
  final bool authenticated;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _feedRefreshSignal = ValueNotifier<int>(0);

  @override
  void dispose() {
    _scrollController.dispose();
    _feedRefreshSignal.dispose();
    super.dispose();
  }

  Future<void> _openLost() async {
    await _guardAuthThen(
      context,
      onAllowed: () => _openCreationPage('lost'),
      title: t('login_required'),
      message: t('login_required_lost'),
    );
  }

  Future<void> _openFound() async {
    await _guardAuthThen(
      context,
      onAllowed: () => _openCreationPage('found'),
      title: t('login_required'),
      message: t('login_required_found'),
    );
  }

  Future<void> _openCreationPage(String type) async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => FoundFormPage(type: type)));
    if (!mounted || created != true) return;

    _feedRefreshSignal.value++;
    AppFeedback.showSuccessSnackBar(
      context,
      AppMessages.listingPublishedSuccess(),
    );
  }

  Future<void> _guardAuthThen(
    BuildContext context, {
    required Future<void> Function() onAllowed,
    required String title,
    required String message,
  }) async {
    final storedToken = await AuthLocalStorage.instance.getToken();
    debugPrint(
      '[GuardLostFound] tokenPresent=${storedToken != null && storedToken.isNotEmpty}',
    );

    if (storedToken != null && storedToken.isNotEmpty) {
      ApiService.instance.setToken(storedToken);
      await onAllowed();
      return;
    }

    final navigator = Navigator.of(context);

    final goLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        watchLanguage(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(tr(ctx, 'cancel_button')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(tr(ctx, 'sign_in_button')),
            ),
          ],
        );
      },
    );

    if (!navigator.mounted) return;

    if (goLogin == true) {
      navigator.push(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 760;

    final lostCard = HomeActionCard(
      title: t('i_lost_item'),
      subtitle: t('i_lost_subtitle'),
      ctaLabel: t('create'),
      height: 150,
      backgroundColor: isDark ? scheme.surface : const Color(0xFFFFF1F1),
      smallIconBackground: isDark
          ? const Color(0xFF3A1F2A)
          : const Color(0xFFFFE4E4),
      smallIcon: Icons.heart_broken,
      smallIconColor: const Color(0xFFE53935),
      bigIcon: Icons.search,
      bigIconColor: const Color(0xFFE53935).withValues(alpha: 0.08),
      motionBias: 1,
      onTap: _openLost,
    );

    final foundCard = HomeActionCard(
      title: t('i_found_item'),
      subtitle: t('i_found_subtitle'),
      ctaLabel: t('create'),
      ctaColor: const Color(0xFF2E7D32),
      height: 150,
      backgroundColor: isDark ? scheme.surface : const Color(0xFFF1FBF5),
      smallIconBackground: isDark
          ? const Color(0xFF2F2A18)
          : const Color(0xFFDFF5E7),
      smallIcon: Icons.handshake,
      smallIconColor: const Color(0xFFF9A825),
      bigIcon: Icons.check_circle,
      bigIconColor: const Color(0xFF2E7D32).withValues(alpha: 0.08),
      motionBias: -1,
      onTap: _openFound,
    );

    final cardsSection = isWide
        ? Row(
            children: [
              Expanded(child: lostCard),
              const SizedBox(width: 20),
              Expanded(child: foundCard),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [lostCard, const SizedBox(height: 20), foundCard],
          );

    final content = SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cardsSection,
            const SizedBox(height: 20),
            RecentPublicationsSection(
              scrollController: _scrollController,
              refreshListenable: _feedRefreshSignal,
              headerBuilder: (onSearchChanged) => Column(
                children: [
                  SearchBarWithFilter(
                    onChanged: onSearchChanged,
                    onFilterTap: () {},
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.authenticated) {
      return AuthenticatedScaffold(
        currentIndex: mainAppShellHomeIndex,
        isTabRoot: true,
        showDefaultTopNavBar: widget.showAppBar,
        backgroundColor: scheme.scaffoldBackground(context),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: scheme.scaffoldBackground(context),
      appBar: widget.showAppBar ? const TopNavBar() : null,
      body: content,
    );
  }
}

extension _HomePageScheme on ColorScheme {
  Color scaffoldBackground(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
}
