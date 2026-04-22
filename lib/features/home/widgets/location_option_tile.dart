import 'package:flutter/material.dart';

class LocationOptionTile extends StatelessWidget {
  const LocationOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: const Color(0xFFF8F4EF),
      borderRadius: BorderRadius.circular(20),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF181411) : const Color(0xFF9B8E84),
            size: 19,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? const Color(0xFF181411) : const Color(0xFF7D6F66),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? const Color(0xFF6B5F57) : const Color(0xFF9B8E84),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        trailing: Icon(
          enabled ? Icons.arrow_forward_ios_rounded : Icons.schedule_rounded,
          size: enabled ? 14 : 16,
          color: enabled ? const Color(0xFF6B5F57) : const Color(0xFF9B8E84),
        ),
      ),
    );
  }
}
