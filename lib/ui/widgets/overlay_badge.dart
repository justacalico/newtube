import 'package:flutter/material.dart';

class OverlayBadge extends StatelessWidget {
  final Widget child;
  final Color color;

  const OverlayBadge({
    super.key,
    required this.child,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconTheme.merge(
        data: const IconThemeData(color: Colors.white, size: 12),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white, fontSize: 11),
          child: child,
        ),
      ),
    );
  }
}
