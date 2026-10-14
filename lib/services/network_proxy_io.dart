import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'network_proxy.dart';

// coverage:ignore-start
http.Client? proxyHttpClient(String proxySetting) {
  final rule = proxyRule(proxySetting);
  if (rule.isEmpty) return null;
  final inner = HttpClient();
  inner.findProxy = (uri) => rule;
  return IOClient(inner);
}
// coverage:ignore-end
