import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mac/models/cue.dart';
import 'package:learn_mac/services/youtube_repository.dart';

/// Golden test video (manual / CI with network).
/// https://www.youtube.com/watch?v=Dq4RqWNRoN4
const kTestYoutubeUrl = 'https://www.youtube.com/watch?v=Dq4RqWNRoN4';
const kTestVideoId = 'Dq4RqWNRoN4';

void main() {
  final runLive = const bool.fromEnvironment('RUN_YOUTUBE_INTEGRATION');

  group('YouTube integration', () {
    test('URL validation and video id', () {
      final repo = YoutubeRepository();
      expect(repo.isValidYoutubeUrl(kTestYoutubeUrl), isTrue);
      expect(repo.extractVideoId(kTestYoutubeUrl), kTestVideoId);
      repo.close();
    });

    test('stream URL and English captions', () async {
      if (!runLive) return;

      final repo = YoutubeRepository();
      final stream = await repo.streamUrlForVideo(kTestVideoId);
      expect(stream.scheme, isIn(['https', 'http']));

      final cues = await repo.fetchEnglishCaptions(kTestVideoId);
      expect(cues, isNotEmpty);
      expect(cues.first.text.trim(), isNotEmpty);
      expect(activeCue(cues, cues.first.start), isNotNull);
      repo.close();
    }, skip: runLive ? false : 'Set --dart-define=RUN_YOUTUBE_INTEGRATION=true');
  });
}
