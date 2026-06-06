import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_messages.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../core/feedback/app_feedback.dart';
import '../../features/chat/models/chat_models.dart';
import '../../features/chat/pages/chat_detail_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_storage.dart';
import '../../services/l10n_helper.dart';
import '../payment_modal.dart';
import 'publication_menu_row.dart';

class PublicationContactMenu {
  PublicationContactMenu._();

  static Future<void> show({
    required BuildContext context,
    required int listingId,
    required String listingTitle,
    required int ownerId,
    required String? currentUserId,
    String? ownerName,
    required bool contactWhatsApp,
    required bool contactCall,
    required bool contactChat,
    required bool requiresContactPayment,
    required String? ownerPhone,
    required Color purple,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phone = ownerPhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;
    final isOwner = ownerId.toString() == currentUserId.toString();
    debugPrint(
      'currentUserId=$currentUserId listingUserId=$ownerId isOwner=$isOwner',
    );
    if (isOwner) {
      return;
    }

    final items = <PopupMenuEntry<String>>[];
    if (contactWhatsApp && hasPhone) {
      items.add(
        PopupMenuItem<String>(
          value: 'wa',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: PublicationMenuRow(
            bg: isDark
                ? const Color(0xFF25D366).withValues(alpha: 0.14)
                : const Color(0xFFE8F8EF),
            icon: Icons.chat_bubble,
            iconColor: const Color(0xFF25D366),
            label: 'WhatsApp',
            textColor: scheme.onSurface,
          ),
        ),
      );
    }
    if (contactCall && hasPhone) {
      items.add(
        PopupMenuItem<String>(
          value: 'call',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: PublicationMenuRow(
            bg: isDark
                ? const Color(0xFF2563EB).withValues(alpha: 0.14)
                : const Color(0xFFE8ECFF),
            icon: Icons.call,
            iconColor: const Color(0xFF2563EB),
            label: t('phone_call'),
            textColor: scheme.onSurface,
          ),
        ),
      );
    }
    if (contactChat) {
      items.add(
        PopupMenuItem<String>(
          value: 'chat',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: PublicationMenuRow(
            bg: isDark
                ? purple.withValues(alpha: 0.16)
                : const Color(0xFFF1E9FF),
            icon: Icons.chat_bubble_outline,
            iconColor: purple,
            label: t('internal_chat'),
            textColor: scheme.onSurface,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      AppFeedback.showErrorSnackBar(context, AppMessages.contactUnavailable());
      return;
    }

    final buttonObject = context.findRenderObject();
    final overlayState = Overlay.maybeOf(context);
    final overlayObject = overlayState?.context.findRenderObject();
    if (buttonObject is! RenderBox || overlayObject is! RenderBox) {
      return;
    }
    final position = RelativeRect.fromRect(
      buttonObject.localToGlobal(Offset.zero, ancestor: overlayObject) &
          buttonObject.size,
      Offset.zero & overlayObject.size,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: items,
    );

    if (!context.mounted || choice == null) return;

    if (requiresContactPayment) {
      final granted = await _ensurePaidContactAccess(
        context,
        listingId: listingId,
      );
      if (!context.mounted || !granted) {
        return;
      }
    }

    if (choice == 'wa') {
      await _launchWhatsApp(context, phone);
      return;
    }
    if (choice == 'call') {
      await _launchCall(context, phone);
      return;
    }
    if (choice == 'chat' && context.mounted) {
      await _openInternalChat(
        context,
        listingId: listingId,
        listingTitle: listingTitle,
        ownerName: ownerName,
        requiresContactPayment: requiresContactPayment,
        avatarColor: purple,
      );
    }
  }

  static Future<bool> _ensurePaidContactAccess(
    BuildContext context, {
    required int listingId,
  }) async {
    final canProceed = await ApiService.instance.syncStoredAuthSession();
    if (!context.mounted) return false;

    if (!canProceed) {
      AppFeedback.showInfoSnackBar(context, t('sign_in_to_contact'));
      return false;
    }

    try {
      final access = await ApiService.instance.requestContactAccess(
        listingId: listingId,
      );
      if (!context.mounted) return false;

      if (access.hasAccess || !access.requiresPayment) {
        return true;
      }

      final priceLabel = '${access.amount ?? ''} ${access.currency ?? ''}'
          .trim();
      final amountLabel = priceLabel.isEmpty
          ? t('payment_required')
          : priceLabel;

      if (access.paymentId == null) {
        _showError(context, AppMessages.paymentFailed());
        return false;
      }

      var paymentConfirmed = false;
      await PaymentModal.show(
        context,
        amount: amountLabel,
        titleText: t('unlock_contact_title'),
        descriptionText: t(
          'unlock_contact_payment_notice',
        ).replaceFirst('{amount}', amountLabel),
        onPay: (_) async {
          await ApiService.instance.confirmContactAccessPayment(
            paymentId: access.paymentId!,
            listingId: listingId,
          );
          return true;
        },
        onPaymentSuccess: () {
          paymentConfirmed = true;
        },
      );

      if (!context.mounted) return paymentConfirmed;

      if (paymentConfirmed) {
        AppFeedback.showSuccessSnackBar(context, t('contact_payment_success'));
      }

      return paymentConfirmed;
    } catch (e) {
      if (!context.mounted) return false;
      _showError(
        context,
        AppErrorMapper.message(
          e,
          fallbackMessage: t('payment_failed'),
        ),
      );
      return false;
    }
  }

  static String? _normalizedPhone(String raw) {
    if (raw.isEmpty) return null;
    var cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  static Future<void> _launchWhatsApp(BuildContext context, String raw) async {
    final normalized = _normalizedPhone(raw);
    if (normalized == null) {
      _showError(context, t('whatsapp_unavailable'));
      return;
    }

    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted && !ok) {
        _showError(context, t('cannot_open_whatsapp'));
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, t('cannot_open_whatsapp'));
      }
    }
  }

  static Future<void> _launchCall(BuildContext context, String raw) async {
    final normalized = _normalizedPhone(raw);
    if (normalized == null) {
      _showError(context, t('call_unavailable'));
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalized);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted && !ok) {
        _showError(context, t('cannot_open_dialer'));
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, t('cannot_open_dialer'));
      }
    }
  }

  static Future<void> _openInternalChat(
    BuildContext context, {
    required int listingId,
    required String listingTitle,
    String? ownerName,
    required bool requiresContactPayment,
    required Color avatarColor,
  }) async {
    final user = await AuthLocalStorage.instance.getUser();
    if (!context.mounted) return;
    if (user == null) {
      AppFeedback.showInfoSnackBar(context, t('sign_in_to_chat'));
      return;
    }
    try {
      final convId = await ApiService.instance.getOrCreateConversation(
        listingId: listingId,
        userId: user.id,
      );
      final otherName = (ownerName != null && ownerName.trim().isNotEmpty)
          ? ownerName
          : t('owner');
      final conversation = ChatConversation(
        id: convId.toString(),
        user: ChatUser(
          id: 'owner-$listingId',
          name: otherName,
          avatarColor: avatarColor,
        ),
        listingId: listingId,
        listingTitle: listingTitle,
        requiresContactPayment: requiresContactPayment,
        unreadCount: 0,
        lastMessage: ChatMessage(
          id: 'seed-$convId',
          conversationId: convId.toString(),
          senderId: '',
          text: '',
          isMe: false,
          time: DateTime.now(),
          isDeletedForEveryone: false,
          deletedText: '',
        ),
      );

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(conversation: conversation),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(
        context,
        AppErrorMapper.message(e, fallbackMessage: t('cannot_open_chat')),
      );
    }
  }

  static void _showError(BuildContext context, String message) {
    AppFeedback.showErrorSnackBar(context, message);
  }
}
