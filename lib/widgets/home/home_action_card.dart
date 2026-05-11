import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final Color? ctaColor;
  final Color backgroundColor;
  final Color smallIconBackground;
  final IconData smallIcon;
  final Color smallIconColor;
  final IconData bigIcon;
  final Color bigIconColor;
  final double height;
  final double motionBias;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.ctaColor,
    required this.backgroundColor,
    required this.smallIconBackground,
    required this.smallIcon,
    required this.smallIconColor,
    required this.bigIcon,
    required this.bigIconColor,
    required this.onTap,
    this.height = 150,
    this.motionBias = 1,
  });

  @override
  State<HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<HomeActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? scheme.surface : widget.backgroundColor;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.55);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF5F6C7B);
    final resolvedCtaColor = widget.ctaColor ?? widget.smallIconColor;

    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, _) {
        final angle = _idleController.value * math.pi * 2;
        final pulse = (math.sin(angle) + 1) / 2;
        final drift = math.cos(angle);
        final haloScale = 0.96 + (pulse * 0.18);
        final iconShiftY = (-3 + (pulse * 6)) * widget.motionBias;
        final bigIconShiftX = drift * 8 * widget.motionBias;
        final bigIconShiftY = -6 + (pulse * 14);
        final ctaArrowShift = 2 + (pulse * 5);

        return AnimatedSlide(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          offset: Offset(0, _pressed ? 0 : (_hovered ? -0.02 : 0)),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            scale: _pressed ? 0.985 : (_hovered ? 1.01 : 1),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: (_) => setState(() => _pressed = false),
                  borderRadius: BorderRadius.circular(22),
                  splashColor: widget.smallIconColor.withValues(alpha: 0.08),
                  hoverColor: widget.smallIconColor.withValues(alpha: 0.05),
                  highlightColor: widget.smallIconColor.withValues(alpha: 0.04),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: widget.height),
                    padding: const EdgeInsets.fromLTRB(24, 22, 88, 22),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _hovered
                            ? widget.smallIconColor.withValues(alpha: 0.24)
                            : borderColor,
                      ),
                      gradient: isDark
                          ? LinearGradient(
                              colors: [
                                widget.smallIconColor.withValues(
                                  alpha: _hovered ? 0.24 : 0.18,
                                ),
                                scheme.surface,
                                const Color(0xFF243041).withValues(
                                  alpha: _hovered ? 0.86 : 0.78,
                                ),
                              ],
                              stops: const [0, 0.5, 1],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                widget.backgroundColor,
                                Colors.white.withValues(
                                  alpha: _hovered ? 0.5 : 0.42,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark
                                ? (_hovered ? 0.34 : 0.28)
                                : (_hovered ? 0.14 : 0.08),
                          ),
                          blurRadius: isDark ? (_hovered ? 34 : 20) : 20,
                          offset: Offset(0, _hovered ? 18 : 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: 28 + (drift * 10 * widget.motionBias),
                          top: 16 + iconShiftY,
                          child: IgnorePointer(
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    widget.smallIconColor.withValues(
                                      alpha: isDark ? 0.12 : 0.08,
                                    ),
                                    widget.smallIconColor.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: haloScale,
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: widget.smallIconColor
                                            .withValues(
                                              alpha: isDark
                                                  ? 0.12 + (pulse * 0.05)
                                                  : 0.1 + (pulse * 0.06),
                                            ),
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(0, iconShiftY),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? widget.smallIconColor.withValues(
                                                alpha: 0.18,
                                              )
                                            : widget.smallIconBackground,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: widget.smallIconColor
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Icon(
                                        widget.smallIcon,
                                        color: widget.smallIconColor,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.subtitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subtitleColor,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.ctaLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: resolvedCtaColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Transform.translate(
                                        offset: Offset(
                                          _hovered
                                              ? ctaArrowShift
                                              : ctaArrowShift * 0.15,
                                          0,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                          color: resolvedCtaColor,
                                        ),
                                      ),
                                    ],
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
                            child: Transform.translate(
                              offset: Offset(bigIconShiftX, bigIconShiftY),
                              child: Icon(
                                widget.bigIcon,
                                size: 120,
                                color: isDark
                                    ? widget.smallIconColor.withValues(
                                        alpha: 0.1,
                                      )
                                    : widget.bigIconColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
