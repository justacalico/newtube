import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    as impl;

typedef SaveTextFile = Future<String?> Function(String name, String contents);

// coverage:ignore-start
SaveTextFile get downloadsFileSaver => impl.downloadsFileSaver;
// coverage:ignore-end
