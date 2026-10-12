import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_update.dart';
import '../../services/version_checker.dart';
import '../../state/app_state.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  bool _checking = false;
  bool _failed = false;
  AppUpdate? _result;

  @override
  void initState() {
    super.initState();
    AppScope.read(context).packageInfo().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _failed = false;
      _result = null;
    });
    final update = await AppScope.of(context).checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _failed = update == null;
      _result = update;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final result = _result ?? state.update;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.play_circle, size: 64),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Center(child: Text('${l10n.version} $_version')),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: Text(l10n.checkForUpdates),
            subtitle: _checking
                ? Text(l10n.checkingUpdates)
                : _failed
                ? Text(l10n.checkFailed)
                : result == null
                ? null
                : result.updateAvailable
                ? Text('${l10n.updateAvailable}: ${result.latestVersion}')
                : Text(l10n.upToDate),
            trailing: _checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _checking ? null : _check,
          ),
          if (result != null && result.updateAvailable)
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.viewRelease),
              onTap: () => state.launch(Uri.parse(result.releaseUrl)),
            ),
          ListTile(
            leading: const Icon(Icons.new_releases_outlined),
            title: Text(l10n.allReleases),
            onTap: () => state.launch(Uri.parse(VersionChecker.releasesUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.sourceCode),
            onTap: () => state.launch(
              Uri.parse('https://gitlab.com/HttpAnimations/newtube'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.licence),
            subtitle: Text(l10n.licenceText),
            onTap: () => state.launch(
              Uri.parse('https://www.gnu.org/licenses/agpl-3.0.html'),
            ),
          ),
        ],
      ),
    );
  }
}
