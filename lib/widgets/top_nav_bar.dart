import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/feedback/app_feedback.dart';
import '../pages/login_page.dart';
import '../services/l10n_helper.dart';
import '../services/language_service.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({
    super.key,
    this.title,
    this.avatarLetter = 'T',
    this.onNotifications,
    this.notificationCount = 0,
    this.showBack = false,
    this.onBack,
    this.showLoginAction = true,
  });

  final String? title;
  final String avatarLetter;
  final VoidCallback? onNotifications;
  final int notificationCount;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showLoginAction;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  void _showLanguagePicker(BuildContext context) {
    final languageService = LanguageService.instance;
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) {
        watchLanguage(ctx);
        return AlertDialog(
          title: Text(tr(ctx, 'select_language')),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: LanguageService.supportedLanguages.map((lang) {
                final isSelected =
                    languageService.currentLanguageCode == lang.code;
                return ListTile(
                  leading: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: scheme.primary,
                          size: 24,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: scheme.outlineVariant,
                          size: 24,
                        ),
                  title: Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  subtitle: Text(lang.name),
                  selectedTileColor: scheme.primary.withValues(alpha: 0.08),
                  selected: isSelected,
                  onTap: () async {
                    if (!isSelected) {
                      await languageService.setLanguage(lang.code);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (!context.mounted) return;
                      AppFeedback.showSuccessSnackBar(
                        context,
                        AppMessages.languageChangedSuccess(),
                      );
                      return;
                    }
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTitle = title ?? tr(context, 'app_name');

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? scheme.surface.withValues(alpha: 0.92) : scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: isDark ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : scheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: Icon(
                languageService.isRtl
                    ? Icons.arrow_forward_ios
                    : Icons.arrow_back_ios_new,
                size: 18,
                color: scheme.onSurface,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
          ],
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryViolet,
            child: Text(
              avatarLetter.isEmpty ? '' : avatarLetter[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              resolvedTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed:
                    onNotifications ??
                    () => AppFeedback.showInfoSnackBar(
                      context,
                      AppMessages.featureComingSoon(),
                    ),
                icon: Icon(
                  Icons.notifications_none,
                  color: scheme.onSurface,
                  size: 22,
                ),
                splashRadius: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      notificationCount > 9 ? '+9' : '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Builder(
            builder: (buttonContext) {
              watchLanguage(buttonContext);
              final langCode = languageService.currentLanguageCode
                  .toUpperCase();
              return IconButton(
                onPressed: () => _showLanguagePicker(buttonContext),
                icon: Tooltip(
                  message: tr(buttonContext, 'select_language'),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      langCode,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
                splashRadius: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: authState,
            builder: (context, loggedIn, _) {
              if (!showLoginAction || loggedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: InkWell(
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage())),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.login,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
