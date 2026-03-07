import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final bool small;

  const StatusBadge({
    Key? key,
    required this.status,
    required this.color,
    this.small = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}