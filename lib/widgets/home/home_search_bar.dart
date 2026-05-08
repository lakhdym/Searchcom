import 'package:flutter/material.dart';

import '../../services/l10n_helper.dart';

class SearchBarWithFilter extends StatelessWidget {
  const SearchBarWithFilter({super.key, this.onChanged, this.onFilterTap});

  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? scheme.primary.withValues(alpha: 0.22)
              : scheme.outlineVariant.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: isDark ? 24 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: isDark
                ? scheme.onSurfaceVariant.withValues(alpha: 0.92)
                : scheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: t('search_objects_places_keywords'),
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: isDark ? 0.92 : 1,
                  ),
                  fontSize: 14,
                ),
              ),
              style: TextStyle(color: scheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onFilterTap ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? scheme.primary.withValues(alpha: 0.95)
                    : scheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0),
                  ),
                ),
              ),
              icon: const Icon(Icons.filter_list, size: 18),
              label: Text(
                t('filter_button'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
