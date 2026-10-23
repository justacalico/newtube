import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';

class WatchedBadge extends StatelessWidget {
  final String videoId;
  final bool compact;

  const WatchedBadge({super.key, required this.videoId, this.compact = false});

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
          child: compact
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : Row(
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

class DurationBadge extends StatelessWidget {
  final Duration? duration;

  const DurationBadge({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    final label = formatDuration(duration);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
