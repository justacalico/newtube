import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:newtube/models/video_info.dart';
import 'package:newtube/state/history_store.dart';
import 'package:newtube/state/search_history_store.dart';
import 'package:newtube/state/settings_store.dart';
import 'package:newtube/state/subscriptions_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const channel = ChannelInfo(id: 'c1', name: 'Chan', subscribers: 10);
const video = VideoInfo(
  id: 'v1',
  title: 'Vid',
  author: 'Chan',
  channelId: 'c1',
  duration: Duration(seconds: 61),
  viewCount: 5,
);

Future<SharedPreferences> prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  group('SettingsStore', () {
    test('defaults to system theme and locale', () async {
      final store = await SettingsStore.load(await prefs());
      expect(store.theme, AppTheme.system);
      expect(store.locale, isNull);
      expect(store.autoplay, isTrue);
      expect(store.searchHistoryEnabled, isTrue);
      expect(store.mcpEnabled, isFalse);
      expect(store.sidebarCollapsed, isFalse);
      expect(store.sponsorBlockEnabled, isFalse);
      expect(store.sponsorBlockAutoSkip, isTrue);
      expect(
        store.sponsorBlockCategories,
        SettingsStore.defaultSponsorBlockCategories,
      );
      expect(store.deArrowMode, DeArrowMode.off);
      expect(store.deArrowTitles, isFalse);
      expect(store.deArrowThumbnails, isFalse);
    });

    test('persists theme, locale and autoplay', () async {
      final p = await prefs();
      final store = SettingsStore();
      await store.setTheme(AppTheme.oled, p);
      await store.setLocale(const Locale('zh', 'Hans'), p);
      await store.setAutoplay(false, p);
      await store.setSearchHistoryEnabled(false, p);
      await store.setMcpEnabled(true, p);
      await store.setSidebarCollapsed(true, p);
      await store.setSponsorBlockEnabled(true, p);
      await store.setSponsorBlockAutoSkip(false, p);
      await store.setSponsorBlockCategories({'sponsor', 'intro'}, p);
      await store.setDeArrowMode(DeArrowMode.both, p);

      final reloaded = await SettingsStore.load(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.theme, AppTheme.oled);
      expect(reloaded.locale, const Locale('zh', 'Hans'));
      expect(reloaded.autoplay, isFalse);
      expect(reloaded.searchHistoryEnabled, isFalse);
      expect(reloaded.mcpEnabled, isTrue);
      expect(reloaded.sidebarCollapsed, isTrue);
      expect(reloaded.sponsorBlockEnabled, isTrue);
      expect(reloaded.sponsorBlockAutoSkip, isFalse);
      expect(reloaded.sponsorBlockCategories, {'sponsor', 'intro'});
      expect(reloaded.deArrowMode, DeArrowMode.both);
      expect(reloaded.deArrowTitles, isTrue);
      expect(reloaded.deArrowThumbnails, isTrue);
    });

    test('system locale persists as null', () async {
      final p = await prefs();
      final store = SettingsStore(locale: const Locale('ru'));
      await store.setLocale(null, p);
      expect((await SettingsStore.load(p)).locale, isNull);
    });

    test('parses every supported locale and rejects junk', () async {
      for (final locale in supportedLocales) {
        final key = locale.countryCode == null
            ? locale.languageCode
            : '${locale.languageCode}_${locale.countryCode}';
        final p = await prefs({'locale': key});
        expect((await SettingsStore.load(p)).locale, locale);
      }
      expect(
        (await SettingsStore.load(await prefs({'locale': 'xx'}))).locale,
        isNull,
      );
      expect(
        (await SettingsStore.load(await prefs({'theme': 'bogus'}))).theme,
        AppTheme.system,
      );
    });
  });

  group('SubscriptionsStore', () {
    test('starts empty and reports subscription state', () async {
      final store = await SubscriptionsStore.load(await prefs());
      expect(store.channels, isEmpty);
      expect(store.isSubscribed('c1'), isFalse);
    });

    test('subscribe and unsubscribe persist across reloads', () async {
      final p = await prefs();
      final store = SubscriptionsStore();
      await store.subscribe(channel, p);
      expect(store.isSubscribed('c1'), isTrue);

      final reloaded = await SubscriptionsStore.load(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.channels.single.name, 'Chan');
      expect(reloaded.channels.single.subscribers, 10);

      await reloaded.unsubscribe('c1', p);
      expect(
        (await SubscriptionsStore.load(await SharedPreferences.getInstance()))
            .channels,
        isEmpty,
      );
    });

    test('corrupt and odd payloads load as empty', () async {
      expect(
        (await SubscriptionsStore.load(await prefs({'subscriptions': '{!}'})))
            .channels,
        isEmpty,
      );
      expect(
        (await SubscriptionsStore.load(await prefs({'subscriptions': '[1,2]'})))
            .channels,
        isEmpty,
      );
      expect(
        (await SubscriptionsStore.load(
          await prefs({
            'subscriptions': '{"c1":"bogus","c2":{"id":"c2","name":"N"}}',
          }),
        )).channels.single.id,
        'c2',
      );
    });
  });

  group('HistoryStore', () {
    test('records newest first and deduplicates', () async {
      final p = await prefs();
      final store = HistoryStore();
      await store.record(video, p);
      await store.record(
        const VideoInfo(id: 'v2', title: 'Two', author: 'A', channelId: 'c'),
        p,
      );
      await store.record(video, p);
      expect(store.entries.map((v) => v.id), ['v1', 'v2']);
      expect(store.entries.first.duration, const Duration(seconds: 61));
    });

    test('contains reports watched videos', () {
      final store = HistoryStore([video]);
      expect(store.contains('v1'), isTrue);
      expect(store.contains('v9'), isFalse);
    });

    test('persists across reloads', () async {
      final p = await prefs();
      await HistoryStore().record(video, p);
      final reloaded = await HistoryStore.load(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.entries.single.title, 'Vid');
      expect(reloaded.entries.single.viewCount, 5);
    });

    test('clear empties and persists', () async {
      final p = await prefs();
      final store = HistoryStore([video]);
      await store.clear(p);
      expect(store.entries, isEmpty);
      expect(
        (await HistoryStore.load(await SharedPreferences.getInstance()))
            .entries,
        isEmpty,
      );
    });

    test('caps at 200 entries', () async {
      final p = await prefs();
      final store = HistoryStore();
      for (var i = 0; i < 205; i++) {
        await store.record(
          VideoInfo(id: 'v$i', title: 't', author: 'a', channelId: 'c'),
          p,
        );
      }
      expect(store.entries.length, 200);
      expect(store.entries.first.id, 'v204');
    });

    test('positions for evicted entries are pruned', () async {
      final p = await prefs();
      final store = HistoryStore();
      await store.record(
        const VideoInfo(id: 'old', title: 't', author: 'a', channelId: 'c'),
        p,
      );
      await store.savePosition('old', const Duration(seconds: 30), p);
      expect(store.positionFor('old'), isNotNull);
      for (var i = 0; i < 200; i++) {
        await store.record(
          VideoInfo(id: 'v$i', title: 't', author: 'a', channelId: 'c'),
          p,
        );
      }
      expect(store.positionFor('old'), isNull);
      final reloaded = await HistoryStore.load(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.positionFor('old'), isNull);
    });

    test('corrupt payloads load as empty', () async {
      expect(
        (await HistoryStore.load(await prefs({'history': '{!'}))).entries,
        isEmpty,
      );
      expect(
        (await HistoryStore.load(await prefs({'history': '{"a":1}'}))).entries,
        isEmpty,
      );
      expect(
        (await HistoryStore.load(
          await prefs({'history': '[{"id":"v9","title":"T"},"bogus"]'}),
        )).entries.single.id,
        'v9',
      );
    });
  });

  group('SearchHistoryStore', () {
    test('records newest first, deduplicates and removes', () async {
      final p = await prefs();
      final store = SearchHistoryStore();
      await store.record('cats', p);
      await store.record('dogs', p);
      await store.record('cats', p);
      expect(store.entries, ['cats', 'dogs']);
      await store.remove('cats', p);
      expect(store.entries, ['dogs']);
    });

    test('persists across reloads', () async {
      final p = await prefs();
      await SearchHistoryStore().record('cats', p);
      final reloaded = await SearchHistoryStore.load(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.entries, ['cats']);
    });

    test('clear empties and persists', () async {
      final p = await prefs();
      final store = SearchHistoryStore(['cats']);
      await store.clear(p);
      expect(store.entries, isEmpty);
      expect(
        (await SearchHistoryStore.load(await SharedPreferences.getInstance()))
            .entries,
        isEmpty,
      );
    });

    test('caps at 50 entries', () async {
      final p = await prefs();
      final store = SearchHistoryStore();
      for (var i = 0; i < 55; i++) {
        await store.record('q$i', p);
      }
      expect(store.entries.length, 50);
      expect(store.entries.first, 'q54');
    });

    test('corrupt payloads load as empty', () async {
      expect(
        (await SearchHistoryStore.load(await prefs({'search_history': '{!'})))
            .entries,
        isEmpty,
      );
      expect(
        (await SearchHistoryStore.load(
          await prefs({'search_history': '{"a":1}'}),
        )).entries,
        isEmpty,
      );
      expect(
        (await SearchHistoryStore.load(
          await prefs({'search_history': '["ok",1]'}),
        )).entries,
        ['ok'],
      );
    });
  });
}
