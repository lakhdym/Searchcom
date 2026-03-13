import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../pages/login_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_local_storage.dart';
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
          label: "Copier le lien",
          onTap: () => _copyLink(context, publication),
        ),
        _menuItem(
          icon: Icons.share,
          label: "Partager",
          onTap: () => _shareListing(publication),
        ),
        _menuItem(
          icon: Icons.flag,
          label: "Signaler",
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
      child: PublicationMenuRow(
        bg: (iconColor == Colors.red)
            ? const Color(0xFFFFE5E5)
            : const Color(0xFFF3F4F6),
        icon: icon,
        iconColor: iconColor ?? const Color(0xFF4B5563),
        label: label,
        textColor: textColor ?? const Color(0xFF111827),
      ),
    );
  }

  static void _copyLink(BuildContext context, Publication publication) {
    final link = buildListingShareUrl(publication);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Lien copié")));
  }

  static Future<void> _shareListing(Publication publication) async {
    final url = buildListingShareUrl(publication);
    final buffer = StringBuffer()
      ..write("Regarde cette annonce : ${publication.title}");
    if (publication.cityArea.isNotEmpty) {
      buffer.write(" à ${publication.cityArea}");
    }
    buffer.write("\n$url");
    await Share.share(buffer.toString());
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
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Connexion requise"),
          content: const Text(
            "Vous devez vous connecter pour signaler une annonce.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Se connecter"),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (goLogin == true) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return;
    }

    ApiService.instance.setToken(token);
    final reasons = ['spam', 'scam', 'abuse', 'illegal', 'other'];
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
                    "Signaler l'annonce",
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                              title: Text(reason),
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
                    decoration: const InputDecoration(
                      labelText: "Détails (optionnel)",
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
                        child: const Text("Annuler"),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Signalement envoyé"),
                                      ),
                                    );
                                  }
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop(true);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Erreur: $e")),
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
                            : const Text("Envoyer"),
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
}
