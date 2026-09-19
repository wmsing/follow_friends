import 'package:flutter/material.dart';

import '../../../models/cue.dart';
import '../../../services/subtitle_parser.dart';
import 'word_gloss.dart';

const Color kActiveLyricLineColor = Colors.black;
const Color kInactiveLyricLineColor = Color(0xFF9E9E9E);

class SubtitleLyricsPanel extends StatelessWidget {
  const SubtitleLyricsPanel({
    super.key,
    required this.cues,
    required this.activeCueIndex,
    required this.selectedWordIndices,
    required this.glossByIndex,
    required this.loadingIndex,
    required this.onWordTap,
    required this.onLineReplay,
    required this.onSentenceTranslate,
    this.selectedCueIndex,
    this.speakingCueIndex,
    this.sentenceGlossCueIndex,
    this.sentenceGloss,
    this.sentenceGlossLoading = false,
  });

  final List<Cue> cues;
  final int? activeCueIndex;
  final int? speakingCueIndex;
  final int? selectedCueIndex;
  final List<int> selectedWordIndices;
  final Map<int, String> glossByIndex;
  final int? loadingIndex;
  final void Function(int cueIndex, int wordIndex, String token) onWordTap;
  final void Function(int cueIndex) onLineReplay;
  final void Function(int cueIndex) onSentenceTranslate;
  final int? sentenceGlossCueIndex;
  final String? sentenceGloss;
  final bool sentenceGlossLoading;

  static const double _currentFontSize = 30;
  static const Color _glossColor = Color(0xFF1565C0);
  static const double _pastFontSize = 18;

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
            _LyricLine(
              cue: cues[cueIndex],
              isActive:
                  speakingCueIndex != null && cueIndex == speakingCueIndex,
              selectedWordIndices: selectedCueIndex == cueIndex
                  ? selectedWordIndices
                  : const [],
              glossByIndex: selectedCueIndex == cueIndex
                  ? glossByIndex
                  : const {},
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

class _LyricLine extends StatelessWidget {
  const _LyricLine({
    required this.cue,
    required this.isActive,
    required this.selectedWordIndices,
    required this.glossByIndex,
    required this.loadingIndex,
    required this.onWordTap,
    required this.onLineReplay,
    required this.onSentenceTranslate,
    this.sentenceGloss,
    this.sentenceGlossLoading = false,
  });

  final Cue cue;
  final bool isActive;
  final List<int> selectedWordIndices;
  final Map<int, String> glossByIndex;
  final int? loadingIndex;
  final void Function(int wordIndex, String token) onWordTap;
  final VoidCallback onLineReplay;
  final VoidCallback onSentenceTranslate;
  final String? sentenceGloss;
  final bool sentenceGlossLoading;

  @override
  Widget build(BuildContext context) {
    final words = splitSubtitleWords(cue.text);
    final fontSize = isActive
        ? SubtitleLyricsPanel._currentFontSize
        : SubtitleLyricsPanel._pastFontSize;
    final lineColor =
        isActive ? kActiveLyricLineColor : kInactiveLyricLineColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onLineReplay,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                iconSize: 20,
                tooltip: '重播本句',
                icon: Icon(Icons.replay_rounded, color: lineColor),
              ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < words.length; i++)
                      WordGloss(
                        word: words[i],
                        selected: selectedWordIndices.contains(i),
                        gloss: glossByIndex[i],
                        loading: loadingIndex == i,
                        fontSize: fontSize,
                        lineColor: lineColor,
                        onTap: () => onWordTap(i, words[i]),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSentenceTranslate,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                iconSize: 20,
                tooltip: '翻译整句',
                icon: Icon(Icons.translate_rounded, color: lineColor),
              ),
            ],
          ),
          if (sentenceGlossLoading || (sentenceGloss?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 32, right: 32),
              child: sentenceGlossLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Text(
                      sentenceGloss!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SubtitleLyricsPanel._glossColor,
                            height: 1.35,
                          ),
                    ),
            ),
        ],
      ),
    );
  }
}
