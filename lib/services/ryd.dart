import 'dart:convert';

import 'package:http/http.dart' as http;

class RydException implements Exception {
  final String message;
  RydException(this.message);

  @override
  String toString() => 'RydException: $message';
}

class RydClient {
  static const _base = 'https://returnyoutubedislikeapi.com';

  final http.Client _client;

  RydClient({http.Client? client}) : _client = client ?? http.Client();

  Future<int?> dislikes(String videoId) async {
    final response = await _client.get(
      Uri.parse('$_base/votes').replace(queryParameters: {'videoId': videoId}),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw RydException('votes failed with ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return (decoded['dislikes'] as num?)?.toInt();
  }
}
