import 'package:flutter/material.dart';

import '../services/l10n_helper.dart';

class ConditionsOfUseSection extends StatelessWidget {
  const ConditionsOfUseSection({
    super.key,
    required this.conditionsFuture,
    required this.accepted,
    required this.onAcceptedChanged,
    required this.onRetry,
  });

  final Future<String?> conditionsFuture;
  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<String?>(
      future: conditionsFuture,
      builder: (context, snapshot) {
        final conditions = snapshot.data?.trim();
        final hasConditions = conditions != null && conditions.isNotEmpty;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: accepted,
              onChanged: (value) {
                onAcceptedChanged(value ?? false);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${t('accept_terms')} ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: hasConditions
                              ? () => _showConditionsPopup(context, conditions)
                              : null,
                          child: Text(
                            t('terms_of_use'),
                            style: textTheme.bodyMedium?.copyWith(
                              color: hasConditions
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              decoration: hasConditions
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      Text(
                        t('loading'),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else if (snapshot.hasError)
                      Row(
                        children: [
                          Text(
                            t('terms_load_error'),
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: onRetry,
                            child: Text(t('retry')),
                          ),
                        ],
                      )
                    else if (!hasConditions)
                      Text(
                        t('terms_unavailable'),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConditionsPopup(
    BuildContext context,
    String? conditions,
  ) async {
    final text = conditions?.trim();
    if (text == null || text.isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        watchLanguage(dialogContext);
        final textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          title: Text(t('terms_of_use')),
          content: SizedBox(
            width: 520,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t('cancel_button')),
            ),
          ],
        );
      },
    );
  }
}