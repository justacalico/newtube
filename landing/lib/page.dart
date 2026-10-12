import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';
import 'main.dart';
import 'releases.dart';
import 'showcase.dart';

const languageNames = {
  'en_GB': 'Traditional English',
  'zh_Hans': '简体中文',
  'ru': 'Русский',
  'ga': 'Gaeilge',
};

class LandingPage extends StatefulWidget {
  final LandingTheme theme;
  final ValueChanged<LandingTheme> onThemeChanged;
  final ValueChanged<Locale?> onLocaleChanged;

  const LandingPage({
    super.key,
    required this.theme,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _service = ReleasesService();
  List<Release>? _releases;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final releases = await _service.fetch();
      if (mounted) setState(() => _releases = releases);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _open(String url) => launchUrl(Uri.parse(url));

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 48, bottom: 16),
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = LandingLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width > 860;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NewTube'),
        actions: [
          _themePicker(l10n),
          _localePicker(l10n),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 48),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 48,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: wide ? 420 : double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NewTube',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(l10n.tagline,
                            style:
                                Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.download),
                              label: Text(l10n.download),
                              onPressed: () => _open(
                                  ReleasesService.releasesUrl),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: Text(l10n.openApp),
                              onPressed: () => _open('app/'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: wide ? 560 : double.infinity,
                    child: const ShowcaseArt(variant: 1, height: 300),
                  ),
                ],
              ),
              _sectionTitle(l10n.features),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _feature(Icons.privacy_tip_outlined, l10n.featurePrivacy,
                      l10n.featurePrivacyText, wide),
                  _feature(Icons.devices, l10n.featurePlatforms,
                      l10n.featurePlatformsText, wide),
                  _feature(Icons.play_circle_outline, l10n.featurePlayer,
                      l10n.featurePlayerText, wide),
                  _feature(Icons.subscriptions_outlined, l10n.featureSubs,
                      l10n.featureSubsText, wide),
                ],
              ),
              _sectionTitle(l10n.screenshots),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _screenshot('assets/screenshots/app_shell.png', wide),
                  _screenshot('assets/screenshots/watch_page.png', wide),
                  _screenshot('assets/screenshots/home_page.png', wide),
                ],
              ),
              _sectionTitle(l10n.appSectionTitle),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.appSectionText),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open('app/'),
                ),
              ),
              _sectionTitle(l10n.downloads),
              Text(l10n.downloadsHint),
              const SizedBox(height: 16),
              _releaseList(l10n),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.viewOnGitLab),
                onPressed: () => _open(ReleasesService.releasesUrl),
              ),
              const SizedBox(height: 48),
              Center(
                child: TextButton(
                  onPressed: () => _open(ReleasesService.projectUrl),
                  child: Text(l10n.sourceCode),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(
      IconData icon, String title, String text, bool wide) {
    return SizedBox(
      width: wide ? 260 : double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(text, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _screenshot(String asset, bool wide) => SizedBox(
        width: wide ? 340 : double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      );

  Widget _releaseList(LandingLocalizations l10n) {
    if (_error != null) {
      return Column(
        children: [
          Text(l10n.loadReleasesFailed),
          TextButton(onPressed: _load, child: Text(l10n.retry)),
        ],
      );
    }
    final releases = _releases;
    if (releases == null) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator()));
    }
    if (releases.isEmpty) {
      return Text(l10n.viewOnGitLab);
    }
    return Column(
      children: [
        for (final release in releases.take(3))
          Card(
            child: ExpansionTile(
              title: Text(release.name),
              subtitle: Text('${l10n.releasedOn} '
                  '${(release.releasedAt ?? '').split('T').first}'),
              children: [
                if (release.assets.isEmpty)
                  ListTile(
                    title: Text(l10n.viewOnGitLab),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _open(
                        '${ReleasesService.releasesUrl}/${release.tag}'),
                  )
                else
                  for (final asset in release.assets)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.download, size: 18),
                      title: Text(asset.name),
                      onTap: () => _open(asset.url),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _themePicker(LandingLocalizations l10n) {
    return DropdownButton<LandingTheme>(
      value: widget.theme,
      underline: const SizedBox(),
      onChanged: (theme) {
        if (theme != null) widget.onThemeChanged(theme);
      },
      items: [
        DropdownMenuItem(
            value: LandingTheme.system, child: Text(l10n.themeSystem)),
        DropdownMenuItem(
            value: LandingTheme.light, child: Text(l10n.themeLight)),
        DropdownMenuItem(
            value: LandingTheme.dark, child: Text(l10n.themeDark)),
        DropdownMenuItem(
            value: LandingTheme.oled, child: Text(l10n.themeOled)),
      ],
    );
  }

  Widget _localePicker(LandingLocalizations l10n) {
    final current = Localizations.localeOf(context);
    final key = '${current.languageCode}_${current.countryCode ?? ''}';
    return DropdownButton<String>(
      value: languageNames.containsKey(key) ? key : 'system',
      underline: const SizedBox(),
      onChanged: (value) {
        if (value == 'system') {
          widget.onLocaleChanged(null);
          return;
        }
        for (final locale in landingLocales) {
          if ('${locale.languageCode}_${locale.countryCode ?? ''}' ==
              value) {
            widget.onLocaleChanged(locale);
          }
        }
      },
      items: [
        DropdownMenuItem(value: 'system', child: Text(l10n.languageSystem)),
        for (final e in languageNames.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
    );
  }
}
