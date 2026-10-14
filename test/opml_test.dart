import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/services/opml.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:newtube/ui/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const _opml = '''
<opml version="1.1">
  <body>
    <outline text="Channel A" title="Channel A" type="rss"
      xmlUrl="https://www.youtube.com/feeds/videos.xml?channel_id=UCaaa" />
    <outline text="Channel B" type="rss"
      htmlUrl="https://www.youtube.com/channel/UCbbb" />
    <outline text="Channel C" type="rss"
      xmlUrl="https://www.youtube.com/@chanC" />
    <outline text="No URL" type="rss" />
    <outline />
  </body>
</opml>
''';

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  group('opml', () {
    test('parses outlines with urls', () {
      final entries = parseOpml(_opml);
      expect(entries, hasLength(3));
      expect(entries[0].title, 'Channel A');
      expect(entries[1].url, contains('/channel/UCbbb'));
    });

    test('buildOpml round-trips through parseOpml', () {
      final text = buildOpml([
        const ChannelInfo(id: 'UCa', name: 'A & B'),
        const ChannelInfo(id: 'UCb', name: 'C'),
      ]);
      final entries = parseOpml(text);
      expect(entries, hasLength(2));
      expect(entries[0].title, 'A & B');
      expect(entries[0].url, contains('channel_id=UCa'));
    });

    test('imports resolvable entries and counts failures', () async {
      final prefs = await _prefs();
      final store = SubscriptionsStore();
      final api = FakeYouTubeApi()
        ..channelResolutions = {'https://www.youtube.com/@chanC': 'UCccc'};
      final result = await importOpml(_opml, api, store, prefs);
      expect(result.imported, 3);
      expect(result.failed, 0);
      expect(store.isSubscribed('UCaaa'), isTrue);
      expect(store.isSubscribed('UCbbb'), isTrue);
      expect(store.isSubscribed('UCccc'), isTrue);
      expect(
        store.channels.firstWhere((c) => c.id == 'UCaaa').name,
        'Channel A',
      );
      expect(
        store.channels.firstWhere((c) => c.id == 'UCccc').name,
        'Channel C',
      );
    });

    test('counts unresolvable entries as failures', () async {
      final prefs = await _prefs();
      final store = SubscriptionsStore();
      final api = FakeYouTubeApi();
      final result = await importOpml(_opml, api, store, prefs);
      expect(result.imported, 2);
      expect(result.failed, 1);
    });

    test('throws on malformed xml', () {
      expect(() => parseOpml('not xml'), throwsA(anything));
    });
  });

  group('resolveChannel', () {
    InnertubeApi api(Map<String, dynamic> response) => InnertubeApi(
      httpClient: MockClient(
        (_) async =>
            http.Response.bytes(utf8.encode(jsonEncode(response)), 200),
      ),
    );

    test('extracts the browse id from resolve_url', () async {
      final a = api({
        'endpoint': {
          'browseEndpoint': {'browseId': 'UCresolved'},
        },
      });
      expect(
        await a.resolveChannel('https://www.youtube.com/@x'),
        'UCresolved',
      );
    });

    test('rejects non-channel endpoints', () async {
      expect(await api({'endpoint': {}}).resolveChannel('x'), isNull);
      expect(
        await api({
          'endpoint': {
            'browseEndpoint': {'browseId': 'PLAYLIST1'},
          },
        }).resolveChannel('x'),
        isNull,
      );
      expect(
        await api({
          'endpoint': {
            'browseEndpoint': {'browseId': 42},
          },
        }).resolveChannel('x'),
        isNull,
      );
    });
  });

  group('settings page', () {
    testWidgets('import tile is hidden without a file opener', (tester) async {
      final state = await testState();
      await pumpPage(tester, state, const SettingsPage());
      await tester.pumpAndSettle();
      expect(find.text('Import subscriptions'), findsNothing);
      expect(find.text('Export subscriptions'), findsNothing);
    });

    testWidgets('imports subscriptions from a picked file', (tester) async {
      final api = FakeYouTubeApi()
        ..channelResolutions = {'https://www.youtube.com/@chanC': 'UCccc'};
      final subs = SubscriptionsStore();
      final state = await testState(
        api: api,
        subscriptions: subs,
        openFile: () async => _opml,
      );
      await pumpPage(tester, state, const SettingsPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).at(0), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Import subscriptions'),
        300,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Import subscriptions'));
      await tester.pumpAndSettle();

      expect(subs.isSubscribed('UCaaa'), isTrue);
      expect(find.text('Imported 3 channels, 0 failed'), findsOneWidget);
    });

    testWidgets('reports a bad opml file', (tester) async {
      final state = await testState(
        subscriptions: SubscriptionsStore(),
        openFile: () async => 'junk',
      );
      await pumpPage(tester, state, const SettingsPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).at(0), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Import subscriptions'),
        300,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Import subscriptions'));
      await tester.pumpAndSettle();
      expect(find.text('Could not read the OPML file'), findsOneWidget);
    });

    testWidgets('does nothing when the picker is cancelled', (tester) async {
      final state = await testState(openFile: () async => null);
      await pumpPage(tester, state, const SettingsPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).at(0), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Import subscriptions'),
        300,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Import subscriptions'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('exports subscriptions as opml', (tester) async {
      String? name;
      final state = await testState(
        subscriptions: SubscriptionsStore({
          'UCa': const ChannelInfo(id: 'UCa', name: 'Chan A'),
        }),
        saveFile: (n, bytes, {extension}) async {
          name = n;
          return '/tmp/$n';
        },
      );
      await pumpPage(tester, state, const SettingsPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).at(0), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Export subscriptions'),
        300,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Export subscriptions'));
      await tester.pumpAndSettle();
      expect(name, 'newtube_subscriptions.opml');
      expect(
        find.text('Subscriptions exported to /tmp/newtube_subscriptions.opml'),
        findsOneWidget,
      );
    });

    testWidgets('reports a failed export', (tester) async {
      final state = await testState(
        saveFile: (n, b, {extension}) async => null,
      );
      await pumpPage(tester, state, const SettingsPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).at(0), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Export subscriptions'),
        300,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      await tester.tap(find.text('Export subscriptions'));
      await tester.pumpAndSettle();
      expect(find.text('Export cancelled or failed'), findsOneWidget);
    });
  });
}
