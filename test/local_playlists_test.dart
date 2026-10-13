import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/playlists_store.dart';
import 'package:newtube/ui/pages/local_playlist_page.dart';
import 'package:newtube/ui/pages/playlist_page.dart';
import 'package:newtube/ui/pages/playlists_page.dart';
import 'package:newtube/ui/pages/watch_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  group('playlists store', () {
    Future<SharedPreferences> prefs([Map<String, Object> v = const {}]) async {
      SharedPreferences.setMockInitialValues(v);
      return SharedPreferences.getInstance();
    }

    test('creates, edits and persists playlists', () async {
      final p = await prefs();
      final store = PlaylistsStore();
      expect(store.playlists, isEmpty);
      expect(store.byId('nope'), isNull);
      expect(store.containsVideo('nope', 'v1'), isFalse);

      final created = await store.create('Mix', p);
      expect(store.playlists.single.title, 'Mix');
      expect(store.byId(created.id)!.id, created.id);

      await store.addVideo(created.id, testVideos.first, p);
      await store.addVideo(created.id, testVideos.first, p);
      await store.addVideo(created.id, testVideos[1], p);
      await store.addVideo('missing', testVideos.first, p);
      expect(store.byId(created.id)!.videos, hasLength(2));
      expect(
        store.byId(created.id)!.thumbnailUrl,
        testVideos.first.thumbnailUrl,
      );
      expect(store.containsVideo(created.id, 'v1'), isTrue);

      await store.rename(created.id, 'Weekend', p);
      await store.rename('missing', 'Nope', p);
      expect(store.byId(created.id)!.title, 'Weekend');

      await store.removeVideo(created.id, 'v1', p);
      await store.removeVideo('missing', 'v1', p);
      expect(store.byId(created.id)!.videos.single.id, 'v2');

      final reloaded = await PlaylistsStore.load(p);
      final restored = reloaded.byId(created.id)!;
      expect(restored.title, 'Weekend');
      expect(restored.videoCount, 1);
      expect(restored.videos.single.id, 'v2');
      expect(restored.videos.single.title, 'Second video');

      await store.delete(created.id, p);
      expect(store.playlists, isEmpty);
    });

    test('toggleSaved stores and removes a remote playlist', () async {
      final p = await prefs();
      final store = PlaylistsStore();
      const remote = PlaylistInfo(
        id: 'PLx',
        title: 'Remote list',
        author: 'DJ',
        thumbnailUrl: 'https://i/pl.jpg',
        videos: testVideos,
      );
      await store.toggleSaved(remote, p);
      expect(store.byId('PLx')!.author, 'DJ');
      expect(store.byId('PLx')!.videoCount, 2);

      await store.toggleSaved(remote, p);
      expect(store.byId('PLx'), isNull);
    });

    test('load tolerates junk', () async {
      expect((await PlaylistsStore.load(await prefs())).playlists, isEmpty);
      expect(
        (await PlaylistsStore.load(await prefs({'playlists': 'junk'})))
            .playlists,
        isEmpty,
      );
      expect(
        (await PlaylistsStore.load(await prefs({'playlists': '{}'}))).playlists,
        isEmpty,
      );
      final store = await PlaylistsStore.load(
        await prefs({
          'playlists':
              '[{"bad": true}, {"id": "p1", "title": "Keep", '
              '"videos": [{"bad": true}, {"id": "v9", "title": "Vid"}]}]',
        }),
      );
      expect(store.playlists.single.title, 'Keep');
      expect(store.playlists.single.videos.single.id, 'v9');
      expect(store.playlists.single.videoCount, 1);
    });
  });

  group('playlists page', () {
    testWidgets('shows empty state and creates a playlist', (tester) async {
      final store = PlaylistsStore();
      final state = await testState(playlists: store);
      await pumpPage(tester, state, PlaylistsPage());
      await tester.pumpAndSettle();

      expect(find.text('No playlists yet'), findsOneWidget);
      expect(find.text('New playlist'), findsOneWidget);

      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Favourites');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(store.playlists.single.title, 'Favourites');
      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('0 videos'), findsOneWidget);
    });

    testWidgets('cancel and empty submissions do nothing', (tester) async {
      final store = PlaylistsStore();
      final state = await testState(playlists: store);
      await pumpPage(tester, state, PlaylistsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.playlists, isEmpty);

      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(store.playlists, isEmpty);
    });

    testWidgets('renames and deletes from the menu', (tester) async {
      final store = PlaylistsStore([
        const PlaylistInfo(id: 'p1', title: 'Mix', videos: testVideos),
      ]);
      final state = await testState(playlists: store);
      await pumpPage(tester, state, PlaylistsPage());
      await tester.pumpAndSettle();

      expect(find.text('2 videos'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Better mix');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(store.byId('p1')!.title, 'Better mix');
      expect(find.text('Better mix'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.byId('p1'), isNotNull);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(store.playlists, isEmpty);
      expect(find.text('No playlists yet'), findsOneWidget);
    });

    testWidgets('rename cancelled keeps the title', (tester) async {
      final store = PlaylistsStore([
        const PlaylistInfo(id: 'p1', title: 'Mix'),
      ]);
      final state = await testState(playlists: store);
      await pumpPage(tester, state, PlaylistsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(store.byId('p1')!.title, 'Mix');
    });

    testWidgets('opens the playlist detail page', (tester) async {
      final store = PlaylistsStore([
        const PlaylistInfo(id: 'p1', title: 'Mix', videos: testVideos),
      ]);
      final state = await testState(playlists: store);
      await pumpPage(tester, state, PlaylistsPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mix'));
      await tester.pumpAndSettle();
      expect(find.byType(LocalPlaylistPage), findsOneWidget);
      expect(find.text('First video'), findsOneWidget);
    });
  });

  group('local playlist page', () {
    testWidgets('lists videos, plays with context and removes entries', (
      tester,
    ) async {
      final store = PlaylistsStore([
        const PlaylistInfo(id: 'p1', title: 'Mix', videos: testVideos),
      ]);
      final player = FakePlayerController();
      final state = await testState(playlists: store, player: player);
      await pumpPage(tester, state, const LocalPlaylistPage(playlistId: 'p1'));
      await tester.pumpAndSettle();

      expect(find.text('Mix'), findsWidgets);
      expect(find.text('2 videos'), findsOneWidget);
      expect(find.text('First video'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pumpAndSettle();
      expect(store.byId('p1')!.videos.single.id, 'v2');
      expect(find.text('1 video'), findsOneWidget);

      await tester.tap(find.text('Second video'));
      await tester.pumpAndSettle();
      expect(find.byType(WatchPage), findsOneWidget);
      expect(find.text('Mix · 1/1'), findsOneWidget);
      expect(player.opened, isNotEmpty);
    });

    testWidgets('shows empty text for empty or missing playlists', (
      tester,
    ) async {
      final store = PlaylistsStore([
        const PlaylistInfo(id: 'p1', title: 'Empty list'),
      ]);
      final state = await testState(playlists: store);
      await pumpPage(tester, state, const LocalPlaylistPage(playlistId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text('This playlist is empty'), findsOneWidget);

      await pumpPage(tester, state, const LocalPlaylistPage(playlistId: 'x'));
      await tester.pumpAndSettle();
      expect(find.text('This playlist is empty'), findsOneWidget);
    });
  });

  group('watch page playlist picker', () {
    testWidgets('adds and removes the video from playlists', (tester) async {
      final store = PlaylistsStore([
        const PlaylistInfo(id: 'p1', title: 'Mix'),
      ]);
      final state = await testState(
        playlists: store,
        player: FakePlayerController(),
      );
      await pumpPage(tester, state, WatchPage(video: testVideos.first));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();
      expect(find.text('Add to playlist'), findsOneWidget);
      expect(find.text('Mix'), findsOneWidget);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(store.containsVideo('p1', 'v1'), isTrue);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(store.containsVideo('p1', 'v1'), isFalse);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Add to playlist'), findsNothing);
    });

    testWidgets('creates a playlist from the picker', (tester) async {
      final store = PlaylistsStore();
      final state = await testState(
        playlists: store,
        player: FakePlayerController(),
      );
      await pumpPage(tester, state, WatchPage(video: testVideos.first));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Queue');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(store.playlists.single.title, 'Queue');
      expect(store.containsVideo(store.playlists.single.id, 'v1'), isTrue);

      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.playlists, hasLength(1));
    });
  });

  group('playlist page save', () {
    testWidgets('saves and unsaves a remote playlist', (tester) async {
      final store = PlaylistsStore();
      final api = FakeYouTubeApi(
        playlistInfo: const PlaylistInfo(
          id: 'PLr',
          title: 'Remote mix',
          author: 'DJ',
          videoCount: 2,
          videos: testVideos,
        ),
      );
      final state = await testState(api: api, playlists: store);
      await pumpPage(tester, state, const PlaylistPage(playlistId: 'PLr'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();
      expect(store.byId('PLr'), isNotNull);
      expect(store.byId('PLr')!.videos, hasLength(2));
      expect(find.byIcon(Icons.playlist_add_check), findsOneWidget);

      await tester.tap(find.byIcon(Icons.playlist_add_check));
      await tester.pumpAndSettle();
      expect(store.byId('PLr'), isNull);
    });
  });
}
