import 'dart:io';

import 'package:newtube/services/mcp_export.dart';
import 'package:newtube/services/mcp_server_io.dart';

void main(List<String> args) {
  final output = args.isEmpty ? 'newtube.mcpb' : args.first;
  final document = mcpConfigExport(
    name: 'newtube',
    url:
        'http://127.0.0.1:${HttpMcpServer.defaultPort}${HttpMcpServer.endpointPath}',
  );
  File(output).writeAsStringSync('${encodeMcpConfig(document)}\n');
  stdout.writeln('wrote $output');
}
