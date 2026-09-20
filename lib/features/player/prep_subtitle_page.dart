import 'package:flutter/material.dart';

import 'widgets/subtitle_line.dart';
import 'youtube_learn_controller.dart';

class PrepSubtitlePage extends StatelessWidget {
  const PrepSubtitlePage({super.key, required this.controller});

  final YoutubeLearnController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        return Scaffold(
          appBar: AppBar(
            title: const Text('预习选词'),
            actions: [
              if (c.hasStudyMarks)
                TextButton(
                  onPressed: () async {
                    await c.clearStudyMarksForVideo();
                  },
                  child: const Text('清空标记'),
                ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await c.player.play();
                },
                child: const Text('开始播放'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: c.cues.isEmpty
              ? const Center(child: Text('暂无字幕'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: c.cues.length,
                  itemBuilder: (context, cueIndex) {
                    final loading = c.studyMarkLoadingCueIndex == cueIndex
                        ? c.studyMarkLoadingWordIndex
                        : null;
                    return SubtitleLine(
                      cue: c.cues[cueIndex],
                      isActive: false,
                      selectedWordIndices: const [],
                      glossByIndex: const {},
                      studyMarkedIndices: c.markedWordIndices(cueIndex),
                      studyGlossByIndex: c.studyGlossForCue(cueIndex),
                      loadingIndex: loading,
                      showLineActions: false,
                      fontSizeActive: 20,
                      fontSizeInactive: 20,
                      onWordTap: (wordIndex, _) =>
                          c.toggleStudyMark(cueIndex, wordIndex),
                    );
                  },
                ),
        );
      },
    );
  }
}
