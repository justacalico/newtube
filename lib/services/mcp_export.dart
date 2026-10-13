import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'mcp_server.dart';
import 'mcpb_bridge.dart';

Uint8List mcpbExport({
  required String name,
  required String version,
  required String url,
}) {
  final manifest = const JsonEncoder.withIndent('  ').convert({
    'manifest_version': '0.3',
    'name': name,
    'version': version,
    'description': 'Search YouTube, read channel and video details and play videos in newtube.',
    'author': {'name': 'newtube'},
    'server': {
      'type': 'node',
      'entry_point': 'server/bridge.js',
      'mcp_config': {
        'command': 'node',
        'args': ['\${__dirname}/server/bridge.js', url],
      },
    },
    'tools': [
      for (final tool in mcpToolDefinitions)
        {'name': tool['name'], 'description': tool['description']},
    ],
    'compatibility': {
      'runtimes': {'node': '>=18.0.0'},
    },
  });
  final bundle = Archive()
    ..addFile(ArchiveFile.string('manifest.json', manifest))
    ..addFile(ArchiveFile.string('server/bridge.js', mcpbBridge));
  return Uint8List.fromList(ZipEncoder().encode(bundle));
}
