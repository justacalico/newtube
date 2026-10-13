import 'dart:convert';

import 'mcp_server.dart';

const mcspFormat = 'mcsp';
const mcspFormatVersion = 1;

Map<String, Object?> mcspExport({
  required String name,
  required String version,
  required String url,
  DateTime? exportedAt,
}) => {
  'format': mcspFormat,
  'version': mcspFormatVersion,
  'exported': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
  'server': {
    'name': name,
    'version': version,
    'transport': 'streamable-http',
    'url': url,
  },
  'tools': mcpToolDefinitions,
};

String encodeMcsp(Map<String, Object?> document) =>
    const JsonEncoder.withIndent('  ').convert(document);
