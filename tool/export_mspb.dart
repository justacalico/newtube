import 'dart:io';

import 'package:newtube/services/mcp_export.dart';
import 'package:newtube/services/mcp_server_io.dart';

void main(List<String> args) {
  final output = args.isEmpty ? 'newtube.mspb' : args.first;
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final version =
      RegExp(r'^version: (\S+)', multiLine: true).firstMatch(pubspec)![1]!;
  final document = mspbExport(
    name: 'newtube',
    version: version.split('+').first,
    url:
        'http://127.0.0.1:${HttpMcpServer.defaultPort}${HttpMcpServer.endpointPath}',
  );
  File(output).writeAsStringSync('${encodeMspb(document)}\n');
  stdout.writeln('wrote $output');
}
