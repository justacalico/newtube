import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

Future<String> writeFile(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes);
  return path;
}

// coverage:ignore-start
Future<String?> saveFileDialog(String name, Uint8List bytes) async {
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'MCP server', extensions: ['mcpb']),
    ],
  );
  if (location == null) return null;
  return writeFile(location.path, bytes);
}
// coverage:ignore-end
