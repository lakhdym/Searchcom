import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../services/l10n_helper.dart';
import 'home_shell.dart';

enum AppErrorKind {
  notFound,
  unexpected,
  listingNotFound,
  conversationNotFound,
  deleted,
  unauthorized,
  navigation,
}

class AppErrorPage extends StatelessWidget {
  const AppErrorPage({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.onRetry,
    this.onBackHome,
  });

  final AppErrorKind kind;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onBackHome;

  factory AppErrorPage.notFound({Key? key, VoidCallback? onBackHome}) {
    return AppErrorPage(
      key: key,
      kind: AppErrorKind.notFound,
      onBackHome: onBackHome,
    );
  }

  factory AppErrorPage.unexpected({
    Key? key,
    String? message,
    VoidCallback? onRetry,
    VoidCallback? onBackHome,
  }) {
    return AppErrorPage(
      key: key,
      kind: AppErrorKind.unexpected,
      message: message,
      onRetry: onRetry,
      onBackHome: onBackHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final config = _resolveConfig();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.08),
              scheme.surface,
              scheme.secondaryContainer.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: config.accent.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          config.icon,
                          size: 42,
                          color: config.accent,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        title ?? config.title,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message ?? config.message,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onBackHome ?? () => _goHome(context),
                          icon: const Icon(Icons.home_outlined),
                          label: Text(AppMessages.backToHome()),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppMessages.tryAgain()),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AppErrorConfig _resolveConfig() {
    switch (kind) {
      case AppErrorKind.notFound:
        return _AppErrorConfig(
          title: AppMessages.pageNotFoundTitle(),
          message: AppMessages.pageNotFoundMessage(),
          icon: Icons.travel_explore_outlined,
          accent: const Color(0xFF2563EB),
        );
      case AppErrorKind.listingNotFound:
        return _AppErrorConfig(
          title: AppMessages.pageNotFoundTitle(),
          message: AppMessages.listingNotFound(),
          icon: Icons.campaign_outlined,
          accent: const Color(0xFFF59E0B),
        );
      case AppErrorKind.conversationNotFound:
        return _AppErrorConfig(
          title: AppMessages.pageNotFoundTitle(),
          message: AppMessages.conversationNotFound(),
          icon: Icons.chat_bubble_outline,
          accent: const Color(0xFF0EA5E9),
        );
      case AppErrorKind.deleted:
        return _AppErrorConfig(
          title: AppMessages.pageNotFoundTitle(),
          message: AppMessages.deletedPageMessage(),
          icon: Icons.delete_outline,
          accent: const Color(0xFFEF4444),
        );
      case AppErrorKind.unauthorized:
        return _AppErrorConfig(
          title: AppMessages.unexpectedErrorTitle(),
          message: AppMessages.accessDenied(),
          icon: Icons.lock_outline,
          accent: const Color(0xFFEF4444),
        );
      case AppErrorKind.navigation:
        return _AppErrorConfig(
          title: AppMessages.unexpectedErrorTitle(),
          message: AppMessages.navigationErrorMessage(),
          icon: Icons.alt_route_outlined,
          accent: const Color(0xFF8B5CF6),
        );
      case AppErrorKind.unexpected:
        return _AppErrorConfig(
          title: AppMessages.unexpectedErrorTitle(),
          message: AppMessages.unexpectedErrorMessage(),
          icon: Icons.error_outline,
          accent: const Color(0xFFEF4444),
        );
    }
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }
}

class _AppErrorConfig {
  const _AppErrorConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
}
