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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: scheme.onSurfaceVariant, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: t('search_objects_places_keywords'),
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onFilterTap ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
