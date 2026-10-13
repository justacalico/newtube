import 'dart:convert';

Map<String, Object?> mcpConfigExport({
  required String name,
  required String url,
}) => {
  'mcpServers': {
    name: {'type': 'http', 'url': url},
  },
};

String encodeMcpConfig(Map<String, Object?> document) =>
    const JsonEncoder.withIndent('  ').convert(document);
