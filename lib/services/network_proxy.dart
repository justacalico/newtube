import 'package:http/http.dart' as http;

import 'network_proxy_stub.dart'
    if (dart.library.io) 'network_proxy_io.dart'
    as impl;

// coverage:ignore-start
http.Client? proxyHttpClient(String proxySetting) =>
    impl.proxyHttpClient(proxySetting);
// coverage:ignore-end

String proxyRule(String setting) {
  var s = setting.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('socks5://')) return 'SOCKS5 ${s.substring(9)}';
  if (s.startsWith('http://')) return 'PROXY ${s.substring(7)}';
  if (s.startsWith('https://')) return 'PROXY ${s.substring(8)}';
  return 'PROXY $s';
}
