import 'dart:math';

import '../models/video_info.dart';
import '../state/history_store.dart';
import '../state/search_history_store.dart';
import '../state/subscriptions_store.dart';
import '../state/watch_later_store.dart';
import 'youtube_api.dart';

final _tokenSplitPattern = RegExp(r'[^a-z0-9]+');

class HomeFeed {
  final YouTubeApi api;
  final HistoryStore history;
  final SubscriptionsStore subscriptions;
  final SearchHistoryStore searchHistory;
  final WatchLaterStore watchLater;

  const HomeFeed({
    required this.api,
    required this.history,
    required this.subscriptions,
    required this.searchHistory,
    required this.watchLater,
  });

  Future<List<VideoInfo>> fetch() async {
    final profile = _TasteProfile.build(
      history: history,
      subscriptions: subscriptions,
      searchHistory: searchHistory,
      watchLater: watchLater,
    );
    if (profile.isCold) return api.homeFeed();

    final candidates = <VideoInfo>[];
    Object? feedError;
    Future<void> collect(Future<List<VideoInfo>> Function() source) async {
      try {
        candidates.addAll(await source());
      } catch (_) {}
    }

    await Future.wait([
      () async {
        try {
          candidates.addAll(await api.homeFeed());
        } catch (e) {
          feedError = e;
        }
      }(),
      for (final id in profile.seedIds) collect(() => api.relatedVideos(id)),
      for (final id in profile.sourceChannels)
        collect(() => api.channelVideos(id)),
      for (final query in profile.queries)
        collect(() async => (await api.search(query)).videos),
    ]);

    final ranked = profile.rank(candidates);
    final error = feedError;
    if (ranked.isEmpty && error != null) throw error;
    return ranked;
  }
}

class _TasteProfile {
  static const _maxSeedVideos = 3;
  static const _maxSourceChannels = 4;
  static const _maxQueries = 2;
  static const _maxTopics = 64;

  static const _stopwords = {
    'the',
    'a',
    'an',
    'and',
    'or',
    'but',
    'of',
    'to',
    'in',
    'on',
    'for',
    'with',
    'at',
    'by',
    'from',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'it',
    'its',
    'this',
    'that',
    'these',
    'those',
    'i',
    'you',
    'your',
    'we',
    'our',
    'they',
    'their',
    'he',
    'she',
    'his',
    'her',
    'my',
    'me',
    'us',
    'them',
    'what',
    'how',
    'why',
    'when',
    'who',
    'which',
    'will',
    'can',
    'not',
    'no',
    'yes',
    'all',
    'any',
    'new',
    'now',
    'day',
    'get',
    'got',
    'one',
    'two',
    'use',
    'video',
    'videos',
    'official',
    'full',
    'watch',
    'episode',
    'ep',
    'part',
    'hd',
  };

  final Map<String, double> channels;
  final Map<String, double> authors;
  final Map<String, double> topics;
  final Set<String> watched;
  final List<String> seedIds;
  final List<String> sourceChannels;
  final List<String> queries;
  final bool isCold;

  _TasteProfile._({
    required this.channels,
    required this.authors,
    required this.topics,
    required this.watched,
    required this.seedIds,
    required this.sourceChannels,
    required this.queries,
    required this.isCold,
  });

  factory _TasteProfile.build({
    required HistoryStore history,
    required SubscriptionsStore subscriptions,
    required SearchHistoryStore searchHistory,
    required WatchLaterStore watchLater,
  }) {
    final channelW = <String, double>{};
    final authorW = <String, double>{};
    final topicW = <String, double>{};
    final watched = <String>{};

    void bump(Map<String, double> weights, String key, double weight) {
      weights.update(key, (v) => v + weight, ifAbsent: () => weight);
    }

    void addVideo(VideoInfo v, double weight) {
      if (v.channelId.isNotEmpty) bump(channelW, v.channelId, weight);
      if (v.author.isNotEmpty) bump(authorW, v.author.toLowerCase(), weight);
      for (final t in _tokens(v.title)) {
        bump(topicW, t, weight);
      }
    }

    var position = 0;
    for (final v in history.entries) {
      watched.add(v.id);
      addVideo(v, 1 / (1 + position * 0.05));
      position++;
    }
    for (final v in watchLater.videos) {
      addVideo(v, 0.6);
    }
    for (final c in subscriptions.channels) {
      if (c.id.isNotEmpty) bump(channelW, c.id, 0.75);
      if (c.name.isNotEmpty) bump(authorW, c.name.toLowerCase(), 0.75);
    }
    position = 0;
    for (final query in searchHistory.entries) {
      final weight = 1.5 / (1 + position * 0.1);
      for (final t in _tokens(query)) {
        bump(topicW, t, weight);
      }
      position++;
    }

    final channels = _normalize(channelW);
    final topChannels = channelW.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _TasteProfile._(
      channels: channels,
      authors: _normalize(authorW),
      topics: _normalize(topicW, cap: _maxTopics),
      watched: watched,
      seedIds: [
        for (final v in history.entries.take(_maxSeedVideos))
          if (v.id.isNotEmpty) v.id,
      ],
      sourceChannels: [
        for (final e in topChannels.take(_maxSourceChannels)) e.key,
      ],
      queries: searchHistory.entries.take(_maxQueries).toList(),
      isCold:
          watched.isEmpty &&
          watchLater.videos.isEmpty &&
          subscriptions.channels.isEmpty &&
          searchHistory.entries.isEmpty,
    );
  }

  static Iterable<String> _tokens(String text) sync* {
    for (final raw in text.toLowerCase().split(_tokenSplitPattern)) {
      if (raw.length < 3 || _stopwords.contains(raw)) continue;
      final t = raw.length > 3 && raw.endsWith('s')
          ? raw.substring(0, raw.length - 1)
          : raw;
      if (t.length < 3 || _stopwords.contains(t) || int.tryParse(t) != null) {
        continue;
      }
      yield t;
    }
  }

  static Map<String, double> _normalize(
    Map<String, double> weights, {
    int cap = 256,
  }) {
    if (weights.isEmpty) return const {};
    final entries = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(cap);
    final max = entries.first.value;
    return {for (final e in top) e.key: e.value / max};
  }

  double _score(VideoInfo v) {
    var score = 4 * (channels[v.channelId] ?? 0.0);
    score += 2 * (authors[v.author.toLowerCase()] ?? 0.0);
    var topic = 0.0;
    for (final t in _tokens(v.title)) {
      topic += topics[t] ?? 0.0;
    }
    score += 3 * min(topic / 2, 1.0);
    score += 0.1 * log(v.viewCount + 1);
    return score;
  }

  List<VideoInfo> rank(List<VideoInfo> candidates) {
    final seen = <String>{};
    final pool = <_ScoredVideo>[];
    for (final v in candidates) {
      if (v.id.isEmpty || watched.contains(v.id) || !seen.add(v.id)) continue;
      pool.add(_ScoredVideo(v, _score(v)));
    }

    final out = <VideoInfo>[];
    final placed = <String, int>{};
    while (pool.isNotEmpty) {
      var best = 0;
      var bestScore = -double.infinity;
      for (var i = 0; i < pool.length; i++) {
        final key = pool[i].video.channelId;
        final count = key.isEmpty ? 0 : placed[key] ?? 0;
        final adjusted = pool[i].score / (1 + count);
        if (adjusted > bestScore) {
          bestScore = adjusted;
          best = i;
        }
      }
      final picked = pool.removeAt(best);
      out.add(picked.video);
      final key = picked.video.channelId;
      if (key.isNotEmpty) placed[key] = (placed[key] ?? 0) + 1;
    }
    return out;
  }
}

class _ScoredVideo {
  final VideoInfo video;
  final double score;

  const _ScoredVideo(this.video, this.score);
}
