import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/downloads.dart';
import 'package:newtube/state/downloads_store.dart';
import 'package:newtube/ui/pages/downloads_page.dart';
import 'package:newtube/ui/pages/download_player_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('NetDownloadActions fetches and saves', () async {
    final client = http_testing.MockClient(
      (req) async => http.Response.bytes([1, 2, 3], 200),
    );
    String? savedName;
    Uint8List? savedBytes;
    final actions = NetDownloadActions(client, (
      name,
      bytes, {
      extension,
    }) async {
      savedName = name;
      savedBytes = bytes;
      return '/tmp/$name';
    });
    expect(await actions.download('https://x/v', 'v.mp4'), '/tmp/v.mp4');
    expect(savedName, 'v.mp4');
    expect(savedBytes, [1, 2, 3]);

    final failing = NetDownloadActions(
      http_testing.MockClient((req) async => http.Response('x', 404)),
      (name, bytes, {extension}) async => throw StateError('never'),
    );
    expect(await failing.download('https://x', 'v'), isNull);
  });

  test('DownloadsStore add, remove, persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = await DownloadsStore.load(prefs);
    const v = VideoInfo(id: 'd1', title: 'DL', author: 'a', channelId: 'c');
    await store.add(
      const DownloadEntry(video: v, path: '/x/d1.mp4', bytes: 9),
      prefs,
    );
    expect(store.entries.single.path, '/x/d1.mp4');
    final reloaded = await DownloadsStore.load(prefs);
    expect(reloaded.entries.single.video.id, 'd1');
    expect(reloaded.entries.single.bytes, 9);
    await reloaded.remove('d1', prefs);
    expect(reloaded.entries, isEmpty);
    expect((await DownloadsStore.load(prefs)).entries, isEmpty);
  });

  testWidgets('downloads page lists, deletes and opens downloads', (
    tester,
  ) async {
    const v = VideoInfo(
      id: 'd1',
      title: 'My DL',
      author: 'author',
      channelId: 'c',
    );
    final store = DownloadsStore([
      const DownloadEntry(video: v, path: '/x/d1.mp4', bytes: 2048),
    ]);
    final state = await testState(downloadsStore: store);
    await pumpPage(tester, state, const DownloadsPage());
    await tester.pumpAndSettle();
    expect(find.text('My DL'), findsOneWidget);

    await tester.tap(find.text('My DL'));
    await tester.pumpAndSettle();
    expect(find.byType(DownloadPlayerPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(store.entries, isEmpty);
    expect(find.text('No downloads yet'), findsOneWidget);
  });

  testWidgets('download action saves a muxed stream', (tester) async {
    final saved = <String>[];
    final actions = _FakeDownloads(saved);
    final store = DownloadsStore();
    final state = await testState(downloads: actions, downloadsStore: store);
    await pumpPage(tester, state, WatchPage(video: testVideos.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.download_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Download video').first);
    await tester.pumpAndSettle();
    expect(saved, isNotEmpty);
    expect(store.entries.single.video.id, 'v1');
  });
}

class _FakeDownloads implements DownloadActions {
  _FakeDownloads(this.calls);
  final List<String> calls;

  @override
  Future<String?> download(String url, String name) async {
    calls.add(url);
    return '/tmp/$name';
  }
}
