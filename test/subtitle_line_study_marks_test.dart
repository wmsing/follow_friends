import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mac/features/player/widgets/subtitle_line.dart';
import 'package:learn_mac/models/cue.dart';

void main() {
  testWidgets('SubtitleLine shows study gloss under marked anchor', (tester) async {
    const cue = Cue(
      start: Duration.zero,
      end: Duration(seconds: 2),
      text: 'Hello world',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubtitleLine(
            cue: cue,
            isActive: true,
            selectedWordIndices: const [],
            glossByIndex: const {},
            studyMarkedIndices: const {0},
            studyGlossByIndex: const {0: '你好'},
            loadingIndex: null,
            onWordTap: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('你好'), findsOneWidget);
  });
}
