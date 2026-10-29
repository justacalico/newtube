import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../models/video_info.dart';
import '../state/subscriptions_store.dart';
import 'youtube_api.dart';

class OpmlEntry {
  final String title;
  final String url;

  const OpmlEntry({required this.title, required this.url});
}

class OpmlImportResult {
  final int imported;
  final int failed;

  const OpmlImportResult(this.imported, this.failed);
}

List<OpmlEntry> parseOpml(String text) {
  final entries = <OpmlEntry>[];
  final doc = XmlDocument.parse(text);
  for (final outline in doc.findAllElements('outline')) {
    final url =
        outline.getAttribute('xmlUrl') ?? outline.getAttribute('htmlUrl');
    if (url == null || url.isEmpty) continue;
    entries.add(
      OpmlEntry(
        title:
            outline.getAttribute('title') ?? outline.getAttribute('text') ?? '',
        url: url,
      ),
    );
  }
  return entries;
}

final _channelIdPattern = RegExp(r'(?:channel_id=|/channel/)([\w-]+)');
final _quotesPattern = RegExp(r'^"|"$');

List<OpmlEntry> parseTakeoutCsv(String text) {
  final entries = <OpmlEntry>[];
  for (var line in const LineSplitter().convert(text)) {
    line = line.trim();
    if (line.isEmpty) continue;
    final parts = line.split(',');
    if (parts.length < 3) continue;
    final id = parts[0].trim();
    if (!id.startsWith('UC')) continue;
    final title = parts
        .sublist(2)
        .join(',')
        .trim()
        .replaceAll(_quotesPattern, '');
    entries.add(
      OpmlEntry(title: title, url: 'https://www.youtube.com/channel/$id'),
    );
  }
  return entries;
}

bool looksLikeTakeoutCsv(String text) => parseTakeoutCsv(text).isNotEmpty;

Future<OpmlImportResult> importOpml(
  String opml,
  YouTubeApi api,
  SubscriptionsStore store,
  SharedPreferences prefs,
) async {
  final entries = looksLikeTakeoutCsv(opml)
      ? parseTakeoutCsv(opml)
      : parseOpml(opml);
  var imported = 0;
  var failed = 0;
  for (final entry in entries) {
    var channelId = _channelIdPattern.firstMatch(entry.url)?.group(1);
    if (channelId == null || !channelId.startsWith('UC')) {
      channelId = await api.resolveChannel(entry.url);
    }
    if (channelId == null) {
      failed++;
      continue;
    }
    await store.subscribe(
      ChannelInfo(
        id: channelId,
        name: entry.title.isEmpty ? channelId : entry.title,
      ),
      prefs,
    );
    imported++;
  }
  return OpmlImportResult(imported, failed);
}

String buildOpml(List<ChannelInfo> channels) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element(
    'opml',
    attributes: {'version': '1.1'},
    nest: () {
      builder.element(
        'body',
        nest: () {
          for (final channel in channels) {
            builder.element(
              'outline',
              attributes: {
                'text': channel.name,
                'title': channel.name,
                'type': 'rss',
                'xmlUrl':
                    'https://www.youtube.com/feeds/videos.xml?channel_id=${channel.id}',
              },
            );
          }
        },
      );
    },
  );
  return builder.buildDocument().toXmlString(pretty: true);
}
