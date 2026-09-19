import 'package:shared_preferences/shared_preferences.dart';

enum PlaybackMode { online, download }

class AppSettings {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _modeKey = 'playback_mode';
  static const _enjoyBaseKey = 'enjoy_api_base';
  static const _enjoyTokenKey = 'enjoy_api_token';
  static const _sidecarUrlKey = 'dict_sidecar_url';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(prefs);
  }

  PlaybackMode get playbackMode {
    final raw = _prefs.getString(_modeKey);
    return raw == 'download' ? PlaybackMode.download : PlaybackMode.online;
  }

  Future<void> setPlaybackMode(PlaybackMode mode) {
    return _prefs.setString(
      _modeKey,
      mode == PlaybackMode.download ? 'download' : 'online',
    );
  }

  String get enjoyApiBase =>
      _prefs.getString(_enjoyBaseKey) ?? 'https://enjoy.bot';

  Future<void> setEnjoyApiBase(String value) =>
      _prefs.setString(_enjoyBaseKey, value);

  String? get enjoyApiToken => _prefs.getString(_enjoyTokenKey);

  Future<void> setEnjoyApiToken(String? token) {
    if (token == null || token.isEmpty) {
      return _prefs.remove(_enjoyTokenKey);
    }
    return _prefs.setString(_enjoyTokenKey, token);
  }

  String? get dictSidecarUrl => _prefs.getString(_sidecarUrlKey);

  Future<void> setDictSidecarUrl(String? url) {
    if (url == null || url.isEmpty) {
      return _prefs.remove(_sidecarUrlKey);
    }
    return _prefs.setString(_sidecarUrlKey, url);
  }
}
