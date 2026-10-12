import 'dart:convert';

import 'package:http/http.dart' as http;

class ReleaseAsset {
  final String name;
  final String url;

  const ReleaseAsset({required this.name, required this.url});
}

class Release {
  final String tag;
  final String name;
  final String? releasedAt;
  final List<ReleaseAsset> assets;

  const Release({
    required this.tag,
    required this.name,
    this.releasedAt,
    this.assets = const [],
  });
}

class ReleasesService {
  static const project = 'HttpAnimations%2Fnewtube';
  static const projectUrl = 'https://gitlab.com/HttpAnimations/newtube';
  static const releasesUrl = '$projectUrl/-/releases';

  final http.Client _client;

  ReleasesService([http.Client? client]) : _client = client ?? http.Client();

  Future<List<Release>> fetch() async {
    final response = await _client.get(Uri.parse(
        'https://gitlab.com/api/v4/projects/$project/releases?per_page=20'));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return [
      for (final r in decoded)
        if (r is Map<String, dynamic> && r['tag_name'] is String)
          Release(
            tag: r['tag_name'] as String,
            name: r['name'] as String? ?? r['tag_name'] as String,
            releasedAt: r['released_at'] as String?,
            assets: _assets(r),
          ),
    ];
  }

  static List<ReleaseAsset> _assets(Map<String, dynamic> release) {
    final assets = release['assets'];
    if (assets is! Map<String, dynamic>) return const [];
    final links = assets['links'];
    if (links is! List) return const [];
    return [
      for (final link in links)
        if (link is Map<String, dynamic> &&
            link['url'] is String &&
            link['name'] is String)
          ReleaseAsset(
            name: link['name'] as String,
            url: link['direct_asset_url'] as String? ?? link['url'] as String,
          ),
    ];
  }
}
