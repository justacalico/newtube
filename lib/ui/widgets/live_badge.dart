import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class LiveBadge extends StatelessWidget {
  final bool upcoming;

  const LiveBadge({super.key, this.upcoming = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: upcoming ? Colors.black87 : Colors.red.shade700,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        upcoming ? l10n.upcoming : l10n.live,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
