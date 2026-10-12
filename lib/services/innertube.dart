import '../models/video_info.dart';

const innertubeKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';

Map<String, dynamic> innertubeContext({String client = 'WEB'}) => {
  'client': switch (client) {
    'ANDROID' => {
      'clientName': 'ANDROID',
      'clientVersion': '20.10.38',
      'androidSdkVersion': 34,
      'osName': 'Android',
      'osVersion': '14',
      'hl': 'en',
      'gl': 'US',
    },
    _ => {
      'clientName': 'WEB',
      'clientVersion': '2.20250814.01.00',
      'hl': 'en',
      'gl': 'US',
    },
  },
};

void collectVideos(dynamic node, List<VideoInfo> out) {
  if (node is Map<String, dynamic>) {
    final renderer = node['videoRenderer'] ?? node['compactVideoRenderer'];
    if (renderer is Map<String, dynamic>) {
      final video = parseVideoRenderer(renderer);
      if (video != null) out.add(video);
    }
    final lockup = node['lockupViewModel'];
    if (lockup is Map<String, dynamic>) {
      final video = parseLockup(lockup);
      if (video != null) out.add(video);
    }
    for (final value in node.values) {
      collectVideos(value, out);
    }
  } else if (node is List) {
    for (final item in node) {
      collectVideos(item, out);
    }
  }
}

void collectChannels(dynamic node, List<ChannelInfo> out) {
  if (node is Map<String, dynamic>) {
    final renderer = node['channelRenderer'];
    if (renderer is Map<String, dynamic>) {
      final channel = parseChannelRenderer(renderer);
      if (channel != null) out.add(channel);
      return;
    }
    for (final value in node.values) {
      collectChannels(value, out);
    }
  } else if (node is List) {
    for (final item in node) {
      collectChannels(item, out);
    }
  }
}

String? continuationToken(dynamic node) {
  if (node is Map<String, dynamic>) {
    final command = node['continuationCommand'];
    if (command is Map<String, dynamic>) {
      final token = command['token'];
      if (token is String) return token;
    }
    for (final value in node.values) {
      final found = continuationToken(value);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final item in node) {
      final found = continuationToken(item);
      if (found != null) return found;
    }
  }
  return null;
}

VideoInfo? parseLockup(Map<String, dynamic> l) {
  if (l['contentType'] != 'LOCKUP_CONTENT_TYPE_VIDEO') return null;
  final id = l['contentId'];
  if (id is! String) return null;
  final metadata = l['metadata'];
  final lmd = metadata is Map<String, dynamic>
      ? metadata['lockupMetadataViewModel']
      : null;
  var title = '';
  var author = '';
  var views = '';
  var uploaded = '';
  String? channelId;
  if (lmd is Map<String, dynamic>) {
    final t = lmd['title'];
    if (t is Map<String, dynamic> && t['content'] is String) {
      title = t['content'] as String;
    }
    channelId = _findBrowseId(lmd['image']);
    final rows = _deepFind(lmd['metadata'], 'metadataRows');
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final parts = row['metadataParts'];
        if (parts is! List) continue;
        for (final part in parts) {
          if (part is! Map<String, dynamic>) continue;
          final text = part['text'];
          if (text is! Map<String, dynamic>) continue;
          final content = text['content'];
          if (content is! String) continue;
          if (content.contains('view') ||
              RegExp(r'^[\d.,]+\s*[KMBkm]?$').hasMatch(content)) {
            views = content;
          } else if (content.endsWith('ago')) {
            uploaded = content;
          } else if (author.isEmpty) {
            author = content;
          }
        }
      }
    }
  }
  return VideoInfo(
    id: id,
    title: title,
    author: author,
    channelId: channelId ?? '',
    thumbnailUrl: _lastSource(_deepFind(l['contentImage'], 'sources')),
    duration: _lockupDuration(l['contentImage']),
    viewCount: compactCount(views),
    uploaded: uploaded.isEmpty ? null : uploaded,
  );
}

String? _findBrowseId(dynamic node) {
  if (node is Map<String, dynamic>) {
    final endpoint = node['browseEndpoint'];
    if (endpoint is Map<String, dynamic>) {
      final id = endpoint['browseId'];
      if (id is String) return id;
    }
    for (final value in node.values) {
      final found = _findBrowseId(value);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final item in node) {
      final found = _findBrowseId(item);
      if (found != null) return found;
    }
  }
  return null;
}

String? _lastSource(dynamic sources) {
  if (sources is! List) return null;
  for (final s in sources.reversed) {
    if (s is Map && s['url'] is String) return s['url'] as String;
  }
  return null;
}

dynamic _deepFind(dynamic node, String key) {
  if (node is Map<String, dynamic>) {
    if (node.containsKey(key)) return node[key];
    for (final value in node.values) {
      final found = _deepFind(value, key);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final item in node) {
      final found = _deepFind(item, key);
      if (found != null) return found;
    }
  }
  return null;
}

Duration? _lockupDuration(dynamic node) {
  if (node is Map<String, dynamic>) {
    final badge = node['thumbnailBadgeViewModel'];
    if (badge is Map<String, dynamic>) {
      final text = badge['text'];
      if (text is String) {
        final parts = text.split(':').map(int.tryParse).toList();
        if (parts.isNotEmpty && parts.every((p) => p != null)) {
          var seconds = 0;
          for (final n in parts) {
            seconds = seconds * 60 + n!;
          }
          return Duration(seconds: seconds);
        }
      }
    }
    for (final value in node.values) {
      final found = _lockupDuration(value);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final item in node) {
      final found = _lockupDuration(item);
      if (found != null) return found;
    }
  }
  return null;
}

ChannelInfo? parseChannelRenderer(Map<String, dynamic> r) {
  final id = r['channelId'];
  if (id is! String) return null;
  return ChannelInfo(
    id: id,
    name: runs(r['title']) ?? '',
    thumbnailUrl: thumbnail(r['thumbnail']),
    subscribers: compactCount(runs(r['subscriberCountText']) ?? ''),
  );
}

VideoInfo? parseVideoRenderer(Map<String, dynamic> r) {
  final id = r['videoId'];
  if (id is! String) return null;
  return VideoInfo(
    id: id,
    title: runs(r['title']) ?? '',
    author: runs(r['ownerText']) ?? runs(r['shortBylineText']) ?? '',
    channelId: browseId(r['ownerText']) ?? browseId(r['shortBylineText']) ?? '',
    thumbnailUrl: thumbnail(r['thumbnail']),
    duration: duration(r['lengthText']),
    viewCount: compactCount(runs(r['viewCountText']) ?? ''),
    uploaded: runs(r['publishedTimeText']),
  );
}

int compactCount(String text) {
  final suffixed = RegExp('([0-9][0-9.,]*)\\s*([KMB])')
      .firstMatch(text.toUpperCase());
  final match = suffixed ?? RegExp('([0-9][0-9.,]*)').firstMatch(text);
  if (match == null) return 0;
  final value = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0;
  final suffix = match.groupCount >= 2 ? match.group(2) : null;
  return switch (suffix) {
    'K' => (value * 1000).round(),
    'M' => (value * 1000000).round(),
    'B' => (value * 1000000000).round(),
    _ => value.round(),
  };
}

String? runs(dynamic node) {
  if (node is! Map<String, dynamic>) return null;
  final simple = node['simpleText'];
  if (simple is String) return simple;
  final runList = node['runs'];
  if (runList is List) {
    return runList
        .whereType<Map<String, dynamic>>()
        .map((r) => r['text'])
        .whereType<String>()
        .join();
  }
  return null;
}

String? browseId(dynamic node) {
  if (node is! Map<String, dynamic>) return null;
  final runList = node['runs'];
  if (runList is! List || runList.isEmpty) return null;
  final first = runList.first;
  if (first is! Map<String, dynamic>) return null;
  final endpoint = first['navigationEndpoint'];
  if (endpoint is! Map<String, dynamic>) return null;
  final browse = endpoint['browseEndpoint'];
  if (browse is! Map<String, dynamic>) return null;
  final id = browse['browseId'];
  return id is String ? id : null;
}

String? thumbnail(dynamic node) {
  if (node is! Map<String, dynamic>) return null;
  final thumbs = node['thumbnails'];
  if (thumbs is! List || thumbs.isEmpty) return null;
  final last = thumbs.last;
  if (last is! Map<String, dynamic>) return null;
  final url = last['url'];
  return url is String ? url : null;
}

Duration? duration(dynamic node) {
  final text = runs(node);
  if (text == null) return null;
  final parts = text.split(':').map(int.tryParse).toList();
  if (parts.any((p) => p == null)) return null;
  var seconds = 0;
  for (final n in parts) {
    seconds = seconds * 60 + n!;
  }
  return Duration(seconds: seconds);
}
