import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> writeTextFile(
  Directory dir,
  String name,
  String contents,
) async {
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsString(contents);
  return file.path;
}

// coverage:ignore-start
Future<String?> downloadsFileSaver(String name, String contents) async {
  final dir = await getDownloadsDirectory();
  if (dir == null) return null;
  return writeTextFile(dir, name, contents);
}
// coverage:ignore-end
