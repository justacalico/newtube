import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/search_filter.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/ui/pages/search_page.dart';

import 'fakes.dart';

void main() {
  group('SearchFilter', () {
    test('empty filter produces no params', () {
      expect(const SearchFilter().toParams(), isNull);
      expect(const SearchFilter().isEmpty, isTrue);
    });

    test('encodes sort, type, upload date and duration', () {
      expect(
        const SearchFilter(sort: SearchSort.date).toParams(),
        base64.encode(const [0x08, 0x02]),
      );
      expect(
        const SearchFilter(type: SearchType.video).toParams(),
        base64.encode(const [0x12, 0x02, 0x10, 0x01]),
      );
      expect(
        const SearchFilter(uploadDate: UploadDate.week).toParams(),
        base64.encode(const [0x12, 0x02, 0x08, 0x03]),
      );
      expect(
        const SearchFilter(duration: VideoDuration.long).toParams(),
        base64.encode(const [0x12, 0x02, 0x18, 0x03]),
      );
      expect(
        const SearchFilter(
          sort: SearchSort.views,
          type: SearchType.live,
        ).toParams(),
        base64.encode(const [0x08, 0x03, 0x12, 0x02, 0x10, 0x05]),
      );
    });

    test('copyWith preserves untouched fields', () {
      const filter = SearchFilter(
        sort: SearchSort.date,
        type: SearchType.video,
      );
      expect(filter.copyWith(sort: SearchSort.rating).sort, SearchSort.rating);
      expect(filter.copyWith(sort: SearchSort.rating).type, SearchType.video);
      expect(
        filter.copyWith(sort: SearchSort.rating, type: SearchType.live),
        isNot(equals(filter)),
      );
      expect(filter.copyWith(), equals(filter));
      expect(filter.hashCode, filter.copyWith().hashCode);
    });
  });

  test('innertube search passes the params token', () async {
    String? params;
    final api = InnertubeApi(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        params = body['params'] as String?;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'contents': {'twoColumnSearchResultsRenderer': {}},
            }),
          ),
          200,
        );
      }),
    );
    await api.search('x', filter: const SearchFilter(type: SearchType.video));
    expect(params, base64.encode(const [0x12, 0x02, 0x10, 0x01]));
  });

  testWidgets('filter menus refetch results', (tester) async {
    final api = FakeYouTubeApi(
      searchResults: SearchResults(videos: testVideos),
    );
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sort ·'), findsWidgets);

    await tester.tap(find.textContaining('Type ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Channels'));
    await tester.pumpAndSettle();
    expect(api.searchFilters.last?.type, SearchType.channel);

    await tester.tap(find.textContaining('Duration ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Under 4 minutes'));
    await tester.pumpAndSettle();
    expect(api.searchFilters.last?.duration, VideoDuration.short);

    await tester.tap(find.textContaining('Sort ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload date'));
    await tester.pumpAndSettle();
    expect(api.searchFilters.last?.sort, SearchSort.date);

    await tester.tap(find.textContaining('Upload date ·'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(api.searchFilters.last?.uploadDate, UploadDate.week);

    for (final (menu, pick, check) in [
      ('Type ·', 'Videos', () => api.searchFilters.last?.type),
      ('Type ·', 'Playlists', () => api.searchFilters.last?.type),
      ('Type ·', 'Live', () => api.searchFilters.last?.type),
      ('Upload date ·', 'This month', () => api.searchFilters.last?.uploadDate),
      ('Upload date ·', 'This year', () => api.searchFilters.last?.uploadDate),
      ('Duration ·', '4-20 minutes', () => api.searchFilters.last?.duration),
      ('Duration ·', 'Over 20 minutes', () => api.searchFilters.last?.duration),
      ('Sort ·', 'View count', () => api.searchFilters.last?.sort),
      ('Sort ·', 'Rating', () => api.searchFilters.last?.sort),
      ('Sort ·', 'Relevance', () => api.searchFilters.last?.sort),
      ('Type ·', 'All', () => api.searchFilters.last?.type),
      ('Upload date ·', 'Any time', () => api.searchFilters.last?.uploadDate),
      ('Duration ·', 'Any duration', () => api.searchFilters.last?.duration),
    ]) {
      await tester.tap(find.textContaining(menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pick));
      await tester.pumpAndSettle();
      expect(check(), isNotNull);
    }
  });
}
