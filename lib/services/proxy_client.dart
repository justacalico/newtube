import 'package:http/http.dart' as http;

String proxiedUrl(String url, String? prefix) {
  if (prefix == null || prefix.isEmpty) return url;
  return '$prefix${Uri.encodeComponent(url)}';
}

class ProxiedClient extends http.BaseClient {
  final http.Client _inner;
  final String? Function() _prefix;

  ProxiedClient(this._inner, this._prefix);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final prefix = _prefix();
    if (prefix == null || prefix.isEmpty) {
      return _inner.send(request);
    }
    final proxied =
        http.StreamedRequest(
            request.method,
            Uri.parse(proxiedUrl(request.url.toString(), prefix)),
          )
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..persistentConnection = request.persistentConnection
          ..headers.addAll(request.headers)
          ..contentLength = request.contentLength;
    request.finalize().listen(
      proxied.sink.add,
      onError: proxied.sink.addError,
      onDone: proxied.sink.close,
    );
    return _inner.send(proxied);
  }

  @override
  void close() => _inner.close();
}
