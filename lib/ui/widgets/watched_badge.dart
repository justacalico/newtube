import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class WatchedBadge extends StatelessWidget {
  final String videoId;

  const WatchedBadge({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return ListenableBuilder(
      listenable: state.history,
      builder: (context, _) {
        if (!state.history.contains(videoId)) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, color: Colors.white, size: 12),
              const SizedBox(width: 2),
              Text(
                AppLocalizations.of(context).watched,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}
