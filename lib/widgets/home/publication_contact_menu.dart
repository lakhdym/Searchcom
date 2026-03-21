import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/chat/models/chat_models.dart';
import '../../features/chat/pages/chat_detail_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_storage.dart';
import 'publication_menu_row.dart';

class PublicationContactMenu {
  PublicationContactMenu._();

  static Future<void> show({
    required BuildContext context,
    required int listingId,
    required String listingTitle,
    String? ownerName,
    required bool contactWhatsApp,
    required bool contactCall,
    required bool contactChat,
    required String? ownerPhone,
    required Color purple,
  }) async {
    final phone = ownerPhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;

    final items = <PopupMenuEntry<String>>[];
    if (contactWhatsApp && hasPhone) {
      items.add(
        PopupMenuItem<String>(
          value: 'wa',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: PublicationMenuRow(
            bg: const Color(0xFFE8F8EF),
            icon: Icons.chat_bubble,
            iconColor: const Color(0xFF25D366),
            label: "WhatsApp",
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
            bg: const Color(0xFFE8ECFF),
            icon: Icons.call,
            iconColor: const Color(0xFF2563EB),
            label: "Appeler",
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
            bg: const Color(0xFFF1E9FF),
            icon: Icons.chat_bubble_outline,
            iconColor: purple,
            label: "Chat interne",
          ),
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun moyen de contact disponible")),
      );
      return;
    }

    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero, ancestor: overlay) & button.size,
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      items: items,
    );

    if (!context.mounted || choice == null) return;

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
        avatarColor: purple,
      );
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
      _showSnack(context, "Numéro WhatsApp indisponible");
      return;
    }

    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted && !ok) {
        _showSnack(context, "Impossible d'ouvrir WhatsApp");
      }
    } catch (_) {
      if (context.mounted) {
        _showSnack(context, "Impossible d'ouvrir WhatsApp");
      }
    }
  }

  static Future<void> _launchCall(BuildContext context, String raw) async {
    final normalized = _normalizedPhone(raw);
    if (normalized == null) {
      _showSnack(context, "Numéro d'appel indisponible");
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalized);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted && !ok) {
        _showSnack(context, "Impossible d'ouvrir le composeur");
      }
    } catch (_) {
      if (context.mounted) {
        _showSnack(context, "Impossible d'ouvrir le composeur");
      }
    }
  }

  static Future<void> _openInternalChat(
    BuildContext context, {
    required int listingId,
    required String listingTitle,
    String? ownerName,
    required Color avatarColor,
  }) async {
    final user = await AuthLocalStorage.instance.getUser();
    if (user == null) {
      _showSnack(context, "Connectez-vous pour discuter");
      return;
    }
    try {
      final convId = await ApiService.instance.getOrCreateConversation(
        listingId: listingId,
        userId: user.id,
      );
      final otherName =
          (ownerName != null && ownerName.trim().isNotEmpty) ? ownerName : 'Propriétaire';
      final conversation = ChatConversation(
        id: convId.toString(),
        user: ChatUser(
          id: 'owner-$listingId',
          name: otherName,
          avatarColor: avatarColor,
        ),
        listingTitle: listingTitle,
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
      _showSnack(context, "Impossible d'ouvrir le chat : $e");
    }
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
