import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/chat/pages/conversations_page.dart';
import '../../services/auth_local_storage.dart';
import 'publication_menu_row.dart';

class PublicationContactMenu {
  PublicationContactMenu._();

  static Future<void> show({
    required BuildContext context,
    required bool contactWhatsApp,
    required bool contactCall,
    required bool contactChat,
    required String? ownerPhone,
    required Color purple,
  }) async {
    final phone = ownerPhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;
    final isLoggedIn = await AuthLocalStorage.instance.isLoggedIn();

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
    if (contactChat && isLoggedIn) {
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConversationsPage()),
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

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
