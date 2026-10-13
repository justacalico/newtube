import 'dart:typed_data';

import 'file_saver_stub.dart' if (dart.library.io) 'file_saver_io.dart' as impl;

typedef SaveFile = Future<String?> Function(String name, Uint8List bytes);

// coverage:ignore-start
SaveFile get saveFileDialog => impl.saveFileDialog;
// coverage:ignore-end
