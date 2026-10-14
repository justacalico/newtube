import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/services/innertube_api.dart';
import 'package:newtube/ui/pages/search_page.dart';

import 'fakes.dart';

void main() {
  test('searchSuggestions parses querySuggestion items', () async {
    final inputs = <String>[];
    final api = InnertubeApi(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        inputs.add(body['input'] as String? ?? '');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'suggestionGroups': [
                {
                  'items': [
                    {
                      'querySuggestion': {'text': 'flutter widgets'},
                    },
                    {
                      'querySuggestion': {'text': 'flutter tutorial'},
                    },
                  ],
                },
              ],
            }),
          ),
          200,
        );
      }),
    );
    final suggestions = await api.searchSuggestions('flutter');
    expect(inputs, ['flutter']);
    expect(suggestions, ['flutter widgets', 'flutter tutorial']);
  });

  testWidgets('suggestion chips search on tap', (tester) async {
    final api = FakeYouTubeApi(searchResults: SearchResults(videos: testVideos))
      ..suggestions = ['flutter widgets', 'flutter tutorial'];
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('flutter widgets'), findsOneWidget);
    await tester.tap(find.text('flutter widgets'));
    await tester.pumpAndSettle();
    expect(find.textContaining('flutter widgets'), findsWidgets);
  });

  testWidgets('local history mixes into suggestions', (tester) async {
    final api = FakeYouTubeApi(searchResults: SearchResults(videos: testVideos))
      ..suggestions = ['flutter remote'];
    final state = await testState(
      api: api,
      initialPrefs: {'search_history': '["flutter widgets"]'},
    );
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.history), findsWidgets);
    expect(find.byIcon(Icons.search), findsWidgets);
  });

  testWidgets('clearing the field resets suggestions', (tester) async {
    final api = FakeYouTubeApi(searchResults: SearchResults(videos: testVideos))
      ..suggestions = ['flutter widgets'];
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('flutter widgets'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('flutter widgets'), findsNothing);
    expect(find.text('No searches yet'), findsOneWidget);
  });

  testWidgets('a stale suggestion response is dropped', (tester) async {
    final gate = Completer<List<String>>();
    final api = FakeYouTubeApi(searchResults: SearchResults(videos: testVideos))
      ..suggestionsGate = gate
      ..suggestions = ['fresh result'];
    final state = await testState(api: api);
    await pumpPage(tester, state, const SearchPage());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'flutter more');
    await tester.pump(const Duration(milliseconds: 400));
    gate.complete(['stale result']);
    await tester.pumpAndSettle();
    expect(find.text('stale result'), findsNothing);
    expect(find.text('fresh result'), findsOneWidget);
  });
}
