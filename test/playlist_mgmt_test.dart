import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/share.dart';
import 'package:newtube/state/playlists_store.dart';
import 'package:newtube/ui/pages/local_playlist_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  PlaylistInfo pl() => const PlaylistInfo(
    id: 'pl1',
    title: 'My list',
    author: 'me',
    videos: [
      VideoInfo(id: 'a', title: 'First', author: 'x', channelId: 'c'),
      VideoInfo(id: 'b', title: 'Second', author: 'x', channelId: 'c'),
      VideoInfo(id: 'c', title: 'Third', author: 'x', channelId: 'c'),
    ],
  );

  test('moveVideo reorders and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PlaylistsStore([pl()]);
    await store.moveVideo('pl1', 0, 2, prefs);
    expect(store.byId('pl1')!.videos.map((v) => v.id), ['b', 'c', 'a']);
    await store.moveVideo('pl1', -1, 0, prefs);
    await store.moveVideo('pl1', 0, 99, prefs);
    await store.moveVideo('nope', 0, 1, prefs);
    final reloaded = await PlaylistsStore.load(prefs);
    expect(reloaded.byId('pl1')!.videos.map((v) => v.id), ['b', 'c', 'a']);
  });

  testWidgets('rename via app bar', (tester) async {
    final store = PlaylistsStore([pl()]);
    final state = await testState(playlists: store);
    await pumpPage(tester, state, const LocalPlaylistPage(playlistId: 'pl1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.byId('pl1')!.title, 'Renamed');
  });

  testWidgets('shuffle plays from a random index', (tester) async {
    final store = PlaylistsStore([pl()]);
    final state = await testState(playlists: store);
    await pumpPage(tester, state, const LocalPlaylistPage(playlistId: 'pl1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shuffle));
    await tester.pumpAndSettle();
    expect(state.playback.shuffle, isTrue);
  });

  testWidgets('export writes urls via saveFile', (tester) async {
    final store = PlaylistsStore([pl()]);
    String? saved;
    final state = await testState(
      playlists: store,
      saveFile: (name, bytes, {extension}) async {
        saved = String.fromCharCodes(bytes);
        return '/tmp/$name';
      },
    );
    await pumpPage(tester, state, const LocalPlaylistPage(playlistId: 'pl1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();
    expect(saved, contains('watch?v=a'));
    expect(find.textContaining('Exported to'), findsOneWidget);
  });

  testWidgets('export falls back to share without saveFile', (tester) async {
    final store = PlaylistsStore([pl()]);
    final shared = <String>[];
    final state = await testState(playlists: store, share: _Recorder(shared));
    await pumpPage(tester, state, const LocalPlaylistPage(playlistId: 'pl1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();
    expect(shared.single, contains('watch?v=b'));
  });
}

class _Recorder implements ShareActions {
  _Recorder(this.out);
  final List<String> out;
  @override
  Future<void> share(String text) async => out.add(text);
}
