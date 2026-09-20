import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../youtube_learn_controller.dart';
import 'subtitle_line.dart';

const _captionFontNormal = 20.0;
const _captionFontFullscreen = 34.0;

/// SRT/CC overlay on the video surface (including media_kit fullscreen route).
class VideoCaptionOverlay extends StatelessWidget {
  const VideoCaptionOverlay({super.key, required this.controller});

  final YoutubeLearnController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final fullscreen = isFullscreen(context);
    final fontSize =
        fullscreen ? _captionFontFullscreen : _captionFontNormal;
    final top = fullscreen
        ? MediaQuery.paddingOf(context).top + 20
        : 20.0;
    final index = c.activeCueIndex;
    if (index != null && index >= 0 && index < c.cues.length) {
      return Positioned(
        left: 16,
        right: 16,
        top: top,
        child: IgnorePointer(
          child: SubtitleLine(
            cue: c.cues[index],
            isActive: true,
            selectedWordIndices: const [],
            glossByIndex: const {},
            studyMarkedIndices: c.markedWordIndices(index),
            studyGlossByIndex: c.studyGlossForCue(index),
            loadingIndex: null,
            showLineActions: false,
            lightOnDark: true,
            fontSizeActive: fontSize,
            fontSizeInactive: fontSize,
            onWordTap: (_, __) {},
          ),
        ),
      );
    }
    if (c.overlayOriginalCaptions) {
      final line = c.videoOverlayCaptionText;
      if (line == null) return const SizedBox.shrink();
      return Positioned(
        left: 16,
        right: 16,
        top: top,
        child: IgnorePointer(
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(blurRadius: 8, color: Colors.black87),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
