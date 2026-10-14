import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/services/opml.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const csv = '''
Channel Id,Channel Url,Channel Title
UC111,https://www.youtube.com/channel/UC111,Channel One
UC222,https://www.youtube.com/channel/UC222,"Channel, Two"
notUC,x,y
''';

void main() {
  test('parses takeout csv', () {
    final entries = parseTakeoutCsv(csv);
    expect(entries.length, 2);
    expect(entries.first.title, 'Channel One');
    expect(entries.last.title, 'Channel, Two');
    expect(looksLikeTakeoutCsv(csv), isTrue);
    expect(looksLikeTakeoutCsv('<opml><body></body></opml>'), isFalse);
  });

  test('importOpml merges csv channels', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SubscriptionsStore();
    final api = FakeYouTubeApi();
    final result = await importOpml(csv, api, store, prefs);
    expect(result.imported, 2);
    expect(result.failed, 0);
    expect(store.isSubscribed('UC111'), isTrue);
    expect(store.isSubscribed('UC222'), isTrue);
  });
}
