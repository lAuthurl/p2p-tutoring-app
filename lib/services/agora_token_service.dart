// lib/services/agora_token_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';

class AgoraTokenService {
  // agora-token-generator-API (created by AWS Lambda)
  // ID: 38ivypaq4g | Region: eu-west-3 | Type: Regional

  static Future<String> fetchToken({
    required String channelName,
    int uid = 0,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse(
          'https://38ivypaq4g.execute-api.eu-west-3.amazonaws.com/default/agora-token-generator',
        ),
      );

      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({'channelName': channelName, 'uid': uid}));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      safePrint(
        '[AgoraTokenService] status: ${response.statusCode} body: $body',
      );

      if (response.statusCode != 200) {
        throw Exception(
          '[AgoraTokenService] HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final token = decoded['token'] as String?;

      if (token == null || token.isEmpty) {
        throw Exception('[AgoraTokenService] Empty token in response');
      }

      safePrint(
        '[AgoraTokenService] ✅ token fetched for channel: $channelName',
      );
      return token;
    } catch (e) {
      safePrint('[AgoraTokenService] error: $e');
      rethrow;
    }
  }
}
