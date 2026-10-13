import 'dart:io';

import 'package:file_selector/file_selector.dart';

Future<String> writeTextFile(String path, String contents) async {
  await File(path).writeAsString(contents);
  return path;
}

// coverage:ignore-start
Future<String?> saveFileDialog(String name, String contents) async {
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'MCP server', extensions: ['mspb']),
    ],
  );
  if (location == null) return null;
  return writeTextFile(location.path, contents);
}
// coverage:ignore-end
