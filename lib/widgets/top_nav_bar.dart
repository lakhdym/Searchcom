import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../pages/login_page.dart';
import '../state/auth_state.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavBar({
    super.key,
    this.title = 'Trouvé!',
    this.avatarLetter = 'T',
    this.onNotifications,
    this.notificationCount = 0,
    this.showBack = false,
    this.onBack,
    this.showLoginAction = true,
  });

  final String title;
  final String avatarLetter;
  final VoidCallback? onNotifications;
  final int notificationCount;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showLoginAction;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: scheme.onSurface),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotifications ?? () {},
                icon: Icon(Icons.notifications_none, color: scheme.onSurface, size: 22),
                splashRadius: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ValueListenableBuilder<bool>(
            valueListenable: authState,
            builder: (context, loggedIn, _) {
              if (!showLoginAction || loggedIn) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.login, size: 18, color: Colors.white),
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
