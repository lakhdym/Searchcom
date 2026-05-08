import 'package:flutter/material.dart';

class HomeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color smallIconBackground;
  final IconData smallIcon;
  final Color smallIconColor;
  final IconData bigIcon;
  final Color bigIconColor;
  final double height;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.smallIconBackground,
    required this.smallIcon,
    required this.smallIconColor,
    required this.bigIcon,
    required this.bigIconColor,
    required this.onTap,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? scheme.surface : backgroundColor;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.55);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF5F6C7B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: smallIconColor.withValues(alpha: 0.08),
          hoverColor: smallIconColor.withValues(alpha: 0.05),
          highlightColor: smallIconColor.withValues(alpha: 0.04),
          child: Container(
            width: double.infinity,
            height: height,
            padding: const EdgeInsets.fromLTRB(24, 24, 80, 24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        smallIconColor.withValues(alpha: 0.18),
                        scheme.surface,
                        const Color(0xFF243041).withValues(alpha: 0.78),
                      ],
                      stops: const [0, 0.5, 1],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        backgroundColor,
                        Colors.white.withValues(alpha: 0.42),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                  blurRadius: isDark ? 28 : 20,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? smallIconColor.withValues(alpha: 0.18)
                            : smallIconBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: smallIconColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(smallIcon, color: smallIconColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: subtitleColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      bigIcon,
                      size: 120,
                      color: isDark
                          ? smallIconColor.withValues(alpha: 0.09)
                          : bigIconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
