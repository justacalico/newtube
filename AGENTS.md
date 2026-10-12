This is a YouTube client for desktop and mobile, written in Flutter. The
source of truth is GitLab; GitHub is a mirror that runs the builds.

- Refactor rather than duplicating code.
- Goal is an A+ codebase.
- Keep 100% test coverage. Run `flutter test --coverage` before finishing.
- Golden tests live in test/golden_test.dart; update with `flutter test --update-goldens`.
- All user-facing strings go through the ARB files in lib/l10n/ (en, en_GB,
  zh, zh_Hans, ru, ga). Never hardcode strings.
- Every platform service is injected through AppState so tests never touch
  the network, the player or the window manager.
- Commits must follow Conventional Commits; `cog check` must stay clean.
  Install hooks with `git config core.hooksPath .githooks`.
- The landing page is a separate Flutter web app in landing/.
- Releases are managed by cocogitto. Never edit the version in pubspec.yaml
  by hand.
