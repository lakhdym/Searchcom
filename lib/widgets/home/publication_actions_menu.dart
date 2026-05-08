import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_messages.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../core/feedback/app_feedback.dart';
import '../../pages/login_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_storage.dart';
import '../../services/l10n_helper.dart';
import 'home_models.dart';
import 'publication_menu_row.dart';

class PublicationActionsMenu {
  PublicationActionsMenu._();

  static String buildListingShareUrl(Publication publication) {
    const base = 'https://italents.ma/app/listing';
    return '$base/${publication.id}';
  }

  static Future<void> show({
    required BuildContext context,
    required Publication publication,
  }) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    const menuWidth = 220.0;
    const offsetX = 8.0;

    var desiredTopLeft = button.localToGlobal(
      Offset(button.size.width + offsetX, 0),
      ancestor: overlay,
    );

    if (desiredTopLeft.dx + menuWidth > overlay.size.width) {
      desiredTopLeft = button.localToGlobal(
        const Offset(-menuWidth - offsetX, 0),
        ancestor: overlay,
      );
      if (desiredTopLeft.dx < 8) {
        desiredTopLeft = Offset(8, desiredTopLeft.dy);
      }
    }

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        desiredTopLeft.dx,
        desiredTopLeft.dy,
        menuWidth,
        button.size.height,
      ),
      Offset.zero & overlay.size,
    );

    await showMenu<void>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: [
        _menuItem(
          icon: Icons.link,
          label: t('copy_link'),
          onTap: () => _copyLink(context, publication),
        ),
        _menuItem(
          icon: Icons.share,
          label: t('share'),
          onTap: () => _shareListing(publication),
        ),
        _menuItem(
          icon: Icons.flag,
          label: t('report'),
          iconColor: Colors.red,
          textColor: Colors.red,
          onTap: () => _reportListing(context, publication),
        ),
      ],
    );
  }

  static PopupMenuItem<void> _menuItem({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<void>(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final resolvedIcon = iconColor ?? scheme.onSurfaceVariant;
          return PublicationMenuRow(
            bg: (iconColor == Colors.red)
                ? Colors.red.withValues(alpha: isDark ? 0.16 : 0.12)
                : scheme.surfaceContainer,
            icon: icon,
            iconColor: resolvedIcon,
            label: label,
            textColor: textColor ?? scheme.onSurface,
          );
        },
      ),
    );
  }

  static void _copyLink(BuildContext context, Publication publication) {
    final link = buildListingShareUrl(publication);
    Clipboard.setData(ClipboardData(text: link));
    AppFeedback.showSuccessSnackBar(context, t('link_copied'));
  }

  static Future<void> _shareListing(Publication publication) async {
    final url = buildListingShareUrl(publication);
    final buffer = StringBuffer()
      ..write('${t('share_listing_intro')}: ${publication.title}');
    if (publication.cityArea.isNotEmpty) {
      buffer.write(' - ${publication.cityArea}');
    }
    buffer.write('\n$url');
    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  static Future<void> _reportListing(
    BuildContext context,
    Publication publication,
  ) async {
    final token = await AuthLocalStorage.instance.getToken();
    if (!context.mounted) return;

    if (token == null || token.isEmpty) {
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          watchLanguage(dialogContext);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(tr(dialogContext, 'login_required')),
            content: Text(tr(dialogContext, 'sign_in_to_report')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(tr(dialogContext, 'cancel_button')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(tr(dialogContext, 'sign_in_button')),
              ),
            ],
          );
        },
      );

      if (!context.mounted) return;
      if (goLogin == true) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
      return;
    }

    ApiService.instance.setToken(token);
    final reasons = const ['spam', 'scam', 'abuse', 'illegal', 'other'];
    var selected = reasons.first;
    final detailsController = TextEditingController();
    var sending = false;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        watchLanguage(sheetContext);
        final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
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
                    tr(sheetContext, 'report_listing'),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (value) {
                      setSheetState(() => selected = value ?? selected);
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
                      labelText: tr(sheetContext, 'report_details_optional'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: sending
                            ? null
                            : () => Navigator.of(sheetContext).pop(),
                        child: Text(tr(sheetContext, 'cancel_button')),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: sending
                            ? null
                            : () async {
                                setSheetState(() => sending = true);
                                try {
                                  await ApiService.instance.reportListing(
                                    listingId: publication.id,
                                    reason: selected,
                                    details: detailsController.text,
                                  );
                                  if (context.mounted) {
                                    AppFeedback.showSuccessSnackBar(
                                      context,
                                      AppMessages.reportSentSuccess(),
                                    );
                                  }
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop(true);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppFeedback.showErrorSnackBar(
                                      context,
                                      AppErrorMapper.message(
                                        e,
                                        fallbackMessage:
                                            AppMessages.reportSendError(),
                                      ),
                                    );
                                  }
                                  if (sheetContext.mounted) {
                                    setSheetState(() => sending = false);
                                  }
                                }
                              },
                        child: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(tr(sheetContext, 'send_message')),
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
