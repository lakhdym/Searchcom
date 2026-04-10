import 'package:flutter/material.dart';

import '../../services/l10n_helper.dart';

class CommentReportInput {
  const CommentReportInput({required this.reason, required this.details});

  final String reason;
  final String details;
}

class CommentActionDialogs {
  CommentActionDialogs._();

  static Future<String?> showEditDialog(
    BuildContext context, {
    required String initialContent,
  }) async {
    final controller = TextEditingController(text: initialContent);
    String? validationError;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        watchLanguage(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(t('edit_comment')),
              content: SizedBox(
                width: 480,
                child: TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: t('write_comment'),
                    errorText: validationError,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t('cancel_button')),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setDialogState(
                        () =>
                            validationError = t('validation_comment_required'),
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: Text(t('save_changes')),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  static Future<bool> showDeleteConfirmation(BuildContext context) async {
    watchLanguage(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        watchLanguage(dialogContext);
        return AlertDialog(
          title: Text(t('delete')),
          content: Text(t('delete_comment_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t('cancel_button')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t('delete')),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  static Future<CommentReportInput?> showReportSheet(
    BuildContext context,
  ) async {
    const reasons = ['spam', 'scam', 'abuse', 'illegal', 'other'];
    final detailsController = TextEditingController();
    var selectedReason = reasons.first;

    final result = await showModalBottomSheet<CommentReportInput>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        watchLanguage(sheetContext);
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('report_comment'),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setSheetState(
                        () => selectedReason = value ?? selectedReason,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: reasons
                          .map(
                            (reason) => RadioListTile<String>(
                              dense: true,
                              value: reason,
                              title: Text(_reasonLabel(reason)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: t('report_details_optional'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(t('cancel_button')),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(
                            CommentReportInput(
                              reason: selectedReason,
                              details: detailsController.text.trim(),
                            ),
                          );
                        },
                        child: Text(t('send_message')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    detailsController.dispose();
    return result;
  }

  static String _reasonLabel(String reason) {
    switch (reason) {
      case 'spam':
        return t('report_reason_spam');
      case 'scam':
        return t('report_reason_scam');
      case 'abuse':
        return t('report_reason_abuse');
      case 'illegal':
        return t('report_reason_illegal');
      default:
        return t('report_reason_other');
    }
  }
}
