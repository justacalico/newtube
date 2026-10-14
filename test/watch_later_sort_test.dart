import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/watch_later_store.dart';
import 'package:newtube/ui/pages/watch_later_page.dart';
import 'package:newtube/ui/widgets/video_list_tile.dart';
import 'package:newtube/utils/relative_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  test('parseRelativeDate', () {
    final now = DateTime(2026, 6, 1);
    expect(parseRelativeDate('3 days ago', now), DateTime(2026, 5, 29));
    expect(parseRelativeDate('2 hours ago', now), DateTime(2026, 5, 31, 22));
    expect(parseRelativeDate('just now', now), isNull);
    expect(parseRelativeDate(null), isNull);
  });

  test('move reorders and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = WatchLaterStore({
      'a': testVideos[0],
      'b': testVideos[1],
      'c': const VideoInfo(id: 'c', title: 'C', author: '', channelId: ''),
    });
    await store.move(0, 2, prefs);
    expect(store.videos.map((v) => v.id).toList(), ['v2', 'c', 'v1']);
    final reloaded = await WatchLaterStore.load(prefs);
    expect(reloaded.videos.map((v) => v.id).toList(), ['v2', 'c', 'v1']);
  });

  testWidgets('watch later sorts longest', (tester) async {
    final store = WatchLaterStore({
      'v1': const VideoInfo(
        id: 'v1',
        title: 'ShortOne',
        author: '',
        channelId: '',
        duration: Duration(minutes: 2),
      ),
      'v2': const VideoInfo(
        id: 'v2',
        title: 'LongOne',
        author: '',
        channelId: '',
        duration: Duration(hours: 2),
      ),
    });
    final state = await testState(watchLater: store);
    await pumpPage(tester, state, const WatchLaterPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Added order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Longest'));
    await tester.pumpAndSettle();
    final tiles = tester.widgetList<VideoListTile>(find.byType(VideoListTile));
    expect(tiles.first.video.title, 'LongOne');
  });
}
