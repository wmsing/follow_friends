import 'package:shared_preferences/shared_preferences.dart';

enum PlaybackMode { online, download }

/// Same steps as YouTube desktop player.
const kPlaybackSpeedOptions = <double>[
  0.25,
  0.5,
  0.75,
  1,
  1.25,
  1.5,
  1.75,
  2,
];

String formatPlaybackSpeedLabel(double speed) {
  if (speed == speed.roundToDouble()) {
    return '${speed.toInt()}x';
  }
  return '${speed}x';
}

/// Bottom panel always uses merged sentences; [original] adds raw CC on the video.
enum SubtitleDisplayMode { merged, original }

class AppSettings {
  AppSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _modeKey = 'playback_mode';
  static const _enjoyBaseKey = 'enjoy_api_base';
  static const _enjoyTokenKey = 'enjoy_api_token';
  static const _sidecarUrlKey = 'dict_sidecar_url';
  static const _subtitleModeKey = 'subtitle_display_mode';
  static const _playbackSpeedKey = 'playback_speed';

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

  SubtitleDisplayMode get subtitleDisplayMode {
    final raw = _prefs.getString(_subtitleModeKey);
    return raw == 'original'
        ? SubtitleDisplayMode.original
        : SubtitleDisplayMode.merged;
  }

  Future<void> setSubtitleDisplayMode(SubtitleDisplayMode mode) {
    return _prefs.setString(
      _subtitleModeKey,
      mode == SubtitleDisplayMode.original ? 'original' : 'merged',
    );
  }

  double get playbackSpeed {
    final v = _prefs.getDouble(_playbackSpeedKey) ?? 1;
    return kPlaybackSpeedOptions.contains(v) ? v : 1;
  }

  Future<void> setPlaybackSpeed(double speed) {
    if (!kPlaybackSpeedOptions.contains(speed)) return Future.value();
    return _prefs.setDouble(_playbackSpeedKey, speed);
  }
}
