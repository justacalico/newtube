import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'overlay_badge.dart';

class LiveBadge extends StatelessWidget {
  final bool upcoming;

  const LiveBadge({super.key, this.upcoming = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OverlayBadge(
      color: upcoming ? Colors.black87 : Theme.of(context).colorScheme.error,
      child: Text(
        upcoming ? l10n.upcoming : l10n.live,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
