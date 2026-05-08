import 'package:flutter/material.dart';

import '../../services/l10n_helper.dart';

class FilterSegmentedControl extends StatelessWidget {
  const FilterSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    const pillHeight = 60.0;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
      blurRadius: isDark ? 16 : 6,
      offset: const Offset(0, 6),
    );

    final labels = [t('filter_all'), t('filter_lost'), t('filter_found')];

    return Container(
      height: pillHeight,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isActive = i == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                            ? scheme.primary.withValues(alpha: 0.2)
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive && isDark
                        ? scheme.primary.withValues(alpha: 0.32)
                        : Colors.transparent,
                  ),
                  boxShadow: isActive ? [shadow] : [],
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isActive
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
