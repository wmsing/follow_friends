import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mac/models/cue.dart';
import 'package:learn_mac/services/subtitle_parser.dart';

void main() {
  test('activeCue finds cue for position', () {
    final cues = [
      const Cue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 2),
        text: 'Hello world',
      ),
      const Cue(
        start: Duration(seconds: 2),
        end: Duration(seconds: 5),
        text: 'Second line',
      ),
    ];

    expect(activeCue(cues, const Duration(seconds: 1))?.text, 'Hello world');
    expect(activeCue(cues, const Duration(seconds: 3))?.text, 'Second line');
    expect(activeCue(cues, const Duration(seconds: 10))?.text, 'Second line');
  });

  test('activeCueIndex follows next start when ends overlap', () {
    final cues = [
      const Cue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 10),
        text: 'first',
      ),
      const Cue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 12),
        text: 'second',
      ),
    ];
    expect(activeCueIndex(cues, const Duration(seconds: 4)), 0);
    expect(activeCueIndex(cues, const Duration(seconds: 7)), 1);
  });

  test('splitSubtitleWords keeps punctuation', () {
    expect(splitSubtitleWords('Hello, world!'), ['Hello,', 'world!']);
  });

  test('normalizeLookupWord strips punctuation', () {
    expect(normalizeLookupWord('Hello,'), 'hello');
  });

  test('mergeCuesIntoSentences joins until sentence punctuation', () {
    final raw = [
      const Cue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 1),
        text: 'I am',
      ),
      const Cue(
        start: Duration(seconds: 1),
        end: Duration(seconds: 2),
        text: 'sorry.',
      ),
      const Cue(
        start: Duration(seconds: 3),
        end: Duration(seconds: 4),
        text: 'Are you',
      ),
      const Cue(
        start: Duration(seconds: 4),
        end: Duration(seconds: 5),
        text: 'okay?',
      ),
    ];
    final merged = mergeCuesIntoSentences(raw);
    expect(merged.length, 2);
    expect(merged[0].text, 'I am sorry.');
    expect(merged[0].start, Duration.zero);
    expect(merged[0].end, const Duration(seconds: 2));
    expect(merged[1].text, 'Are you okay?');
  });

  test('mergeCuesIntoSentences breaks on newline and >>', () {
    final raw = [
      const Cue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 1),
        text: 'Line one\nLine two.',
      ),
      const Cue(
        start: Duration(seconds: 2),
        end: Duration(seconds: 3),
        text: '>> Speaker two.',
      ),
    ];
    final merged = mergeCuesIntoSentences(raw);
    expect(merged.length, 3);
    expect(merged[0].text, 'Line one');
    expect(merged[1].text, 'Line two.');
    expect(merged[2].text, 'Speaker two.');
  });

  test('phraseFromIndices joins tapped word range', () {
    expect(
      phraseFromIndices(['I', 'am', 'sorry'], wordIndicesInRange(0, 2)),
      'I am sorry',
    );
  });

  test('lyricDisplayCueIndex holds line in gap between cues', () {
    final cues = [
      const Cue(
        start: Duration(seconds: 0),
        end: Duration(seconds: 2),
        text: 'a',
      ),
      const Cue(
        start: Duration(seconds: 5),
        end: Duration(seconds: 7),
        text: 'b',
      ),
    ];
    expect(lyricDisplayCueIndex(cues, const Duration(seconds: 3)), 0);
    expect(lyricDisplayCueIndex(cues, const Duration(seconds: 6)), 1);
  });

  test('lyricVisibleCueIndices shows two before and after current', () {
    expect(lyricVisibleCueIndices(4, 10), [2, 3, 4, 5, 6]);
    expect(lyricVisibleCueIndices(1, 10), [0, 1, 2, 3]);
    expect(lyricVisibleCueIndices(0, 10), [0, 1, 2]);
    expect(lyricVisibleCueIndices(null, 10), isEmpty);
  });

  test('lyricVisibleCueIndices keeps pinned translation line visible', () {
    expect(
      lyricVisibleCueIndices(8, 10, pinnedCueIndex: 2),
      [2, 6, 7, 8, 9],
    );
  });
}
