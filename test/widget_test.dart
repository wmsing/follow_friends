import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mac/services/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AppSettings defaults to online playback', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    expect(settings.playbackMode, PlaybackMode.online);
  });
}
