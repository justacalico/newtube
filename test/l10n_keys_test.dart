import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/l10n/app_localizations_en.dart';
import 'package:newtube/l10n/app_localizations_zh.dart';

void main() {
  test('new nav and downloads strings exist in all locales', () {
    for (final l10n in [
      AppLocalizationsEn(),
      AppLocalizationsEnGb(),
      AppLocalizationsZhHans(),
    ]) {
      expect(l10n.navSubs, isNotEmpty);
      expect(l10n.noDownloadsHint, isNotEmpty);
    }
  });
}
