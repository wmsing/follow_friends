import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app_branding.dart';
import '../../models/saved_sentence.dart';
import '../../services/app_settings.dart';
import '../../services/sentence_review_store.dart';
import '../../services/study_mark_store.dart';
import '../../services/youtube_learn_cache.dart';
import '../review/sentence_review_page.dart';
import 'widgets/channel_picker_sheet.dart';
import 'widgets/learn_settings_dialog.dart';
import 'prep_subtitle_page.dart';
import 'widgets/subtitle_line.dart';
import 'widgets/subtitle_lyrics_panel.dart';
import 'youtube_learn_controller.dart';

/// Default link for local manual testing.
const kDefaultTestYoutubeUrl = 'https://www.youtube.com/watch?v=Dq4RqWNRoN4';

class YoutubeLearnPage extends StatefulWidget {
  const YoutubeLearnPage({
    super.key,
    required this.settings,
    required this.sentenceStore,
    required this.studyMarkStore,
  });

  final AppSettings settings;
  final SentenceReviewStore sentenceStore;
  final StudyMarkStore studyMarkStore;

  @override
  State<YoutubeLearnPage> createState() => _YoutubeLearnPageState();
}

class _YoutubeLearnPageState extends State<YoutubeLearnPage> {
  final _urlController = TextEditingController();
  late final YoutubeLearnController _controller = YoutubeLearnController(
    settings: widget.settings,
    studyMarkStore: widget.studyMarkStore,
  );

  final _pageFocusNode = FocusNode();
  final _urlFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _urlController.text = kDefaultTestYoutubeUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  Future<void> _onFirstFrame() async {
    if (!mounted) return;
    final cache = await YoutubeLearnCache.load();
    final last = cache.lastWatchUrl;
    if (last != null &&
        last.isNotEmpty &&
        _controller.youtube.isValidYoutubeUrl(last)) {
      _urlController.text = last;
      await _loadVideo();
    }
    if (mounted) _pageFocusNode.requestFocus();
  }

  KeyEventResult _onPageKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    if (_urlFocusNode.hasFocus) return KeyEventResult.ignored;
    _controller.togglePlayPause();
    return KeyEventResult.handled;
  }

  Future<void> _loadVideo({Duration? seekAfter}) {
    return _controller.loadVideo(_urlController.text, seekAfter: seekAfter);
  }

  Future<void> _onSentenceTranslate(int cueIndex) async {
    final saved = await _controller.onSentenceTranslate(cueIndex);
    if (saved == null || !mounted) return;
    unawaited(widget.sentenceStore.upsert(saved));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已加入句子重温'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openSentenceReview() async {
    final picked = await Navigator.push<SavedSentence>(
      context,
      MaterialPageRoute(
        builder: (context) => SentenceReviewPage(store: widget.sentenceStore),
      ),
    );
    if (picked == null || !mounted) return;
    _urlController.text = picked.watchUrl;
    await _loadVideo(seekAfter: picked.cueStart);
  }

  void _openPrep() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => PrepSubtitlePage(controller: _controller),
      ),
    );
  }

  void _openChannelPicker() {
    ChannelPickerSheet.show(
      context,
      youtube: _controller.youtube,
      onVideoSelected: (url) {
        _urlController.text = url;
        _loadVideo();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _urlController.dispose();
    _pageFocusNode.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        return Focus(
          focusNode: _pageFocusNode,
          autofocus: true,
          onKeyEvent: _onPageKey,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(kAppDisplayName),
              actions: [
                PopupMenuButton<double>(
                  tooltip: '播放速度',
                  onSelected: c.setPlaybackSpeed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: Text(
                        formatPlaybackSpeedLabel(c.playbackSpeed),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  itemBuilder: (context) => [
                    for (final speed in kPlaybackSpeedOptions)
                      PopupMenuItem<double>(
                        value: speed,
                        child: Row(
                          children: [
                            if (speed == c.playbackSpeed)
                              const Icon(Icons.check, size: 18)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(formatPlaybackSpeedLabel(speed)),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_outlined),
                  tooltip: '预习选词',
                  onPressed: c.cues.isEmpty || c.loading ? null : _openPrep,
                ),
                IconButton(
                  icon: const Icon(Icons.menu_book_outlined),
                  tooltip: '句子重温',
                  onPressed: _openSentenceReview,
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => LearnSettingsDialog.show(
                    context,
                    widget.settings,
                    onSaved: _controller.applySubtitleDisplayMode,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _urlFocusNode,
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: '粘贴 YouTube 链接',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _loadVideo(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: c.loading ? null : _loadVideo,
                        child: c.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('播放'),
                      ),
                    ],
                  ),
                ),
                if (c.downloadPercent != null)
                  LinearProgressIndicator(value: c.downloadPercent! / 100),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      c.error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: c.togglePlayPause,
                    child: ColoredBox(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Video(
                              controller: c.videoController,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (c.activeCueIndex != null &&
                              c.activeCueIndex! >= 0 &&
                              c.activeCueIndex! < c.cues.length)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 20,
                              child: SubtitleLine(
                                cue: c.cues[c.activeCueIndex!],
                                isActive: true,
                                selectedWordIndices: const [],
                                glossByIndex: const {},
                                studyMarkedIndices: c.markedWordIndices(
                                  c.activeCueIndex!,
                                ),
                                studyGlossByIndex: c.studyGlossForCue(
                                  c.activeCueIndex!,
                                ),
                                loadingIndex: null,
                                showLineActions: false,
                                lightOnDark: true,
                                fontSizeActive: 20,
                                fontSizeInactive: 20,
                                onWordTap: (_, __) {},
                              ),
                            )
                          else if (c.overlayOriginalCaptions)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 20,
                              child: Builder(
                                builder: (context) {
                                  final line = c.videoOverlayCaptionText;
                                  if (line == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    line,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8,
                                          color: Colors.black87,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 280),
                    child: SubtitleLyricsPanel(
                      cues: c.cues,
                      activeCueIndex: c.activeCueIndex,
                      speakingCueIndex: c.speakingCueIndex,
                      selectedCueIndex: c.selectedCueIndex,
                      selectedWordIndices: c.selectedWordIndices,
                      glossByIndex: c.glossByIndex,
                      studyMarkedIndicesForCue: (cueIndex) {
                        if (c.activeCueIndex != cueIndex) return {};
                        return c.markedWordIndices(cueIndex);
                      },
                      studyGlossForCue: (cueIndex) {
                        if (c.activeCueIndex != cueIndex) return {};
                        return c.studyGlossForCue(cueIndex);
                      },
                      loadingIndex: c.loadingIndex,
                      onWordTap: c.onWordTap,
                      onLineReplay: c.onLineReplay,
                      onSentenceTranslate: _onSentenceTranslate,
                      sentenceGlossCueIndex: c.sentenceGlossCueIndex,
                      sentenceGloss: c.sentenceGloss,
                      sentenceGlossLoading: c.sentenceGlossLoading,
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openChannelPicker,
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('频道'),
            ),
          ),
        );
      },
    );
  }
}
