import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

import 'app_settings.dart';
import 'enjoy_api_service.dart';
import 'subtitle_parser.dart';

class GlossService {
  GlossService({
    required AppSettings settings,
    EnjoyApiService? enjoyApi,
    GoogleTranslator? translator,
  })  : _settings = settings,
        _enjoyApi = enjoyApi ?? EnjoyApiService(settings),
        _translator = translator ?? GoogleTranslator();

  final AppSettings _settings;
  final EnjoyApiService _enjoyApi;
  final GoogleTranslator _translator;
  final Map<String, String> _cache = {};

  Future<String> glossWord({
    required String token,
    required String sentenceContext,
  }) async {
    final word = normalizeLookupWord(token);
    if (word.isEmpty) return '';

    final cacheKey = word;
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    String? result;

    result = await _enjoyApi.lookupWord(word: word, context: sentenceContext);

    final sidecar = _settings.dictSidecarUrl;
    if ((result == null || result.isEmpty) && sidecar != null) {
      result = await _lookupSidecar(sidecar, word);
    }

    if (result == null || result.isEmpty) {
      final translated = await _translator.translate(word, to: 'zh-cn');
      result = translated.text;
    }

    _cache[cacheKey] = result;
    return result;
  }

  Future<String> glossSentence(String english) async {
    final text = english.trim();
    if (text.isEmpty) return '';
    final translated = await _translator.translate(text, to: 'zh-cn');
    return translated.text;
  }

  Future<String?> _lookupSidecar(String baseUrl, String word) async {
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {'word': word},
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['translation'] as String? ?? body['definition'] as String?;
    } catch (_) {
      return null;
    }
  }
}
