import 'package:file_selector/file_selector.dart';

// coverage:ignore-start
Future<String?> openTextFileDialog() async {
  final file = await openFile(
    acceptedTypeGroups: [
      const XTypeGroup(label: 'OPML', extensions: ['opml', 'xml']),
    ],
  );
  if (file == null) return null;
  return file.readAsString();
}
// coverage:ignore-end
