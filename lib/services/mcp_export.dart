import 'dart:convert';

import 'mcp_server.dart';

const mspbFormat = 'mspb';
const mspbFormatVersion = 1;

Map<String, Object?> mspbExport({
  required String name,
  required String version,
  required String url,
  DateTime? exportedAt,
}) => {
  'format': mspbFormat,
  'version': mspbFormatVersion,
  'exported': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
  'server': {
    'name': name,
    'version': version,
    'transport': 'streamable-http',
    'url': url,
  },
  'tools': mcpToolDefinitions,
};

String encodeMspb(Map<String, Object?> document) =>
    const JsonEncoder.withIndent('  ').convert(document);
