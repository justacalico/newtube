import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

const _firefoxCorsUrl =
    'https://addons.mozilla.org/en-US/firefox/addon/cors-everywhere/';
const _chromeCorsUrl =
    'https://chromewebstore.google.com/detail/allow-cors-access-control/lhobafahddgcelffkeicbaginigeejlf';

class CorsNotice extends StatelessWidget {
  const CorsNotice({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: CorsNotice()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.corsNoticeTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.corsNoticeBody, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.extension),
              label: Text(l10n.corsFirefox),
              onPressed: () => state.launch(Uri.parse(_firefoxCorsUrl)),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.extension),
              label: Text(l10n.corsChrome),
              onPressed: () => state.launch(Uri.parse(_chromeCorsUrl)),
            ),
          ],
        ),
      ],
    );
  }
}
