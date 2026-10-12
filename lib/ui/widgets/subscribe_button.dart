import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/video_info.dart';
import '../../state/app_state.dart';

class SubscribeButton extends StatelessWidget {
  final ChannelInfo channel;

  const SubscribeButton({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: state.subscriptions,
      builder: (context, _) {
        final subscribed = state.subscriptions.isSubscribed(channel.id);
        return FilledButton.tonalIcon(
          icon: Icon(subscribed ? Icons.check : Icons.add),
          label: Text(subscribed ? l10n.subscribed : l10n.subscribe),
          onPressed: () {
            if (subscribed) {
              state.subscriptions.unsubscribe(channel.id, state.prefs);
            } else {
              state.subscriptions.subscribe(channel, state.prefs);
            }
          },
        );
      },
    );
  }
}
