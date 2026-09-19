import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_settings.dart';

class EnjoyApiService {
  EnjoyApiService(this._settings);

  final AppSettings _settings;

  bool get isConfigured {
    final token = _settings.enjoyApiToken;
    return token != null && token.isNotEmpty;
  }

  Future<String?> lookupWord({
    required String word,
    required String context,
    String nativeLanguage = 'zh-CN',
  }) async {
    final token = _settings.enjoyApiToken;
    if (token == null || token.isEmpty) return null;

    final base = _settings.enjoyApiBase.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/api/lookups');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'word': word,
        'context': context,
        'native_language': nativeLanguage,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final meaning = body['meaning'] as Map<String, dynamic>?;
    if (meaning == null) return null;

    final translation = meaning['translation'] as String?;
    if (translation != null && translation.isNotEmpty) return translation;

    final definition = meaning['definition'] as String?;
    return definition;
  }
}
