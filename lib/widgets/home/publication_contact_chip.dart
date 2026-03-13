import 'package:flutter/material.dart';

class PublicationContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? bg;
  final Color? textColor;

  const PublicationContactChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.bg,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: color ?? Theme.of(context).primaryColor),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: textColor,
        ),
      ),
      backgroundColor: bg ?? Colors.grey.shade100,
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
