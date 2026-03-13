import 'package:flutter/material.dart';

class PublicationMenuRow extends StatelessWidget {
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final Color textColor;

  const PublicationMenuRow({
    super.key,
    required this.bg,
    required this.iconColor,
    required this.icon,
    required this.label,
    this.textColor = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
