import 'dart:typed_data';

import 'package:http/http.dart' as http;

typedef SaveFileFn = Future<String?> Function(
  String name,
  Uint8List bytes, {
  String? extension,
});

abstract class DownloadActions {
  Future<String?> download(String url, String name);
}

class NetDownloadActions implements DownloadActions {
  NetDownloadActions(this._client, this._save);

  final http.Client _client;
  final SaveFileFn _save;

  @override
  Future<String?> download(String url, String name) async {
    final resp = await _client.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    return _save(name, resp.bodyBytes, extension: 'mp4');
  }
}
