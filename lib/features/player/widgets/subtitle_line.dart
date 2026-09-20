import 'package:flutter/material.dart';

import '../../../models/cue.dart';
import '../../../services/subtitle_parser.dart';
import 'word_gloss.dart';

const double kSubtitleLineFontActive = 30;
const double kSubtitleLineFontInactive = 18;
const Color kSubtitleGlossColor = Color(0xFF1565C0);
const Color kActiveLyricLineColor = Colors.black;
const Color kInactiveLyricLineColor = Color(0xFF757575);

class SubtitleLine extends StatelessWidget {
  const SubtitleLine({
    super.key,
    required this.cue,
    required this.isActive,
    required this.selectedWordIndices,
    required this.glossByIndex,
    required this.studyMarkedIndices,
    required this.studyGlossByIndex,
    required this.loadingIndex,
    required this.onWordTap,
    this.onLineReplay,
    this.onSentenceTranslate,
    this.sentenceGloss,
    this.sentenceGlossLoading = false,
    this.lightOnDark = false,
    this.showLineActions = true,
    this.fontSizeActive = kSubtitleLineFontActive,
    this.fontSizeInactive = kSubtitleLineFontInactive,
  });

  final Cue cue;
  final bool isActive;
  final List<int> selectedWordIndices;
  final Map<int, String> glossByIndex;
  final Set<int> studyMarkedIndices;
  final Map<int, String> studyGlossByIndex;
  final int? loadingIndex;
  final void Function(int wordIndex, String token) onWordTap;
  final VoidCallback? onLineReplay;
  final VoidCallback? onSentenceTranslate;
  final String? sentenceGloss;
  final bool sentenceGlossLoading;
  final bool lightOnDark;
  final bool showLineActions;
  final double fontSizeActive;
  final double fontSizeInactive;

  @override
  Widget build(BuildContext context) {
    final words = splitSubtitleWords(cue.text);
    final fontSize = isActive ? fontSizeActive : fontSizeInactive;
    final lineColor = lightOnDark
        ? Colors.white
        : (isActive ? kActiveLyricLineColor : kInactiveLyricLineColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sentenceGlossLoading || (sentenceGloss?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 32, right: 32),
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
                            color: kSubtitleGlossColor,
                            height: 1.35,
                          ),
                    ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showLineActions && onLineReplay != null)
                IconButton(
                  onPressed: onLineReplay,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 20,
                  tooltip: '重播本句',
                  icon: Icon(Icons.replay_rounded, color: lineColor),
                )
              else if (showLineActions)
                const SizedBox(width: 32),
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
                        studyMark: studyMarkedIndices.contains(i) &&
                            !selectedWordIndices.contains(i),
                        gloss: glossByIndex[i] ?? studyGlossByIndex[i],
                        loading: loadingIndex == i,
                        fontSize: fontSize,
                        lineColor: lineColor,
                        lightOnDark: lightOnDark,
                        onTap: () => onWordTap(i, words[i]),
                      ),
                  ],
                ),
              ),
              if (showLineActions && onSentenceTranslate != null)
                IconButton(
                  onPressed: onSentenceTranslate,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  iconSize: 20,
                  tooltip: '翻译整句',
                  icon: Icon(Icons.translate_rounded, color: lineColor),
                )
              else if (showLineActions)
                const SizedBox(width: 32),
            ],
          ),
        ],
      ),
    );
  }
}
