import 'package:flutter/material.dart';

import '../../../models/cue.dart';
import 'subtitle_line.dart' show SubtitleLine, kSubtitleLineFontActive, kSubtitleLineFontInactive;

class SubtitleLyricsPanel extends StatelessWidget {
  const SubtitleLyricsPanel({
    super.key,
    required this.cues,
    required this.activeCueIndex,
    required this.selectedWordIndices,
    required this.glossByIndex,
    required this.studyMarkedIndicesForCue,
    required this.studyGlossForCue,
    required this.loadingIndex,
    required this.onWordTap,
    required this.onLineReplay,
    required this.onSentenceTranslate,
    this.selectedCueIndex,
    this.sentenceGlossCueIndex,
    this.sentenceGloss,
    this.sentenceGlossLoading = false,
  });

  static const double currentFontSize = kSubtitleLineFontActive;
  static const double pastFontSize = kSubtitleLineFontInactive;

  final List<Cue> cues;
  final int? activeCueIndex;
  final int? selectedCueIndex;
  final List<int> selectedWordIndices;
  final Map<int, String> glossByIndex;
  final Set<int> Function(int cueIndex) studyMarkedIndicesForCue;
  final Map<int, String> Function(int cueIndex) studyGlossForCue;
  final int? loadingIndex;
  final void Function(int cueIndex, int wordIndex, String token) onWordTap;
  final void Function(int cueIndex) onLineReplay;
  final void Function(int cueIndex) onSentenceTranslate;
  final int? sentenceGlossCueIndex;
  final String? sentenceGloss;
  final bool sentenceGlossLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleSet = lyricVisibleCueIndices(
      activeCueIndex,
      cues.length,
      pinnedCueIndex: selectedCueIndex,
    ).toSet();
    if (sentenceGlossCueIndex != null) {
      visibleSet.add(sentenceGlossCueIndex!);
    }
    final visible = visibleSet.toList()..sort();

    if (cues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '未获取到英文字幕（视频可能无字幕或网络失败）',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '字幕加载中…',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final cueIndex in visible) ...[
            SubtitleLine(
              cue: cues[cueIndex],
              isActive: activeCueIndex != null && cueIndex == activeCueIndex,
              selectedWordIndices: selectedCueIndex == cueIndex
                  ? selectedWordIndices
                  : const [],
              glossByIndex: selectedCueIndex == cueIndex
                  ? glossByIndex
                  : const {},
              studyMarkedIndices: studyMarkedIndicesForCue(cueIndex),
              studyGlossByIndex: studyGlossForCue(cueIndex),
              loadingIndex:
                  selectedCueIndex == cueIndex ? loadingIndex : null,
              onWordTap: (wordIndex, token) =>
                  onWordTap(cueIndex, wordIndex, token),
              onLineReplay: () => onLineReplay(cueIndex),
              onSentenceTranslate: () => onSentenceTranslate(cueIndex),
              sentenceGloss: sentenceGlossCueIndex == cueIndex
                  ? sentenceGloss
                  : null,
              sentenceGlossLoading:
                  sentenceGlossCueIndex == cueIndex && sentenceGlossLoading,
            ),
            if (cueIndex != visible.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
