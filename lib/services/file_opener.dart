import 'file_opener_stub.dart'
    if (dart.library.io) 'file_opener_io.dart'
    as impl;

typedef OpenFile = Future<String?> Function();

// coverage:ignore-start
OpenFile get openTextFileDialog => impl.openTextFileDialog;
// coverage:ignore-end
