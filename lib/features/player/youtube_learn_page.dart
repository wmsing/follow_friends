import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../models/cue.dart';
import '../../models/saved_sentence.dart';
import '../../services/app_settings.dart';
import '../../services/download_service.dart';
import '../../services/gloss_service.dart';
import '../../services/sentence_review_store.dart';
import '../../services/subtitle_parser.dart';
import '../../services/youtube_repository.dart';
import '../review/sentence_review_page.dart';
import 'widgets/channel_picker_sheet.dart';
import 'widgets/subtitle_lyrics_panel.dart';

/// Default link for local manual testing.
const kDefaultTestYoutubeUrl = 'https://www.youtube.com/watch?v=Dq4RqWNRoN4';

class YoutubeLearnPage extends StatefulWidget {
  const YoutubeLearnPage({
    super.key,
    required this.settings,
    required this.sentenceStore,
  });

  final AppSettings settings;
  final SentenceReviewStore sentenceStore;

  @override
  State<YoutubeLearnPage> createState() => _YoutubeLearnPageState();
}

class _YoutubeLearnPageState extends State<YoutubeLearnPage> {
  final _urlController = TextEditingController();
  final _youtube = YoutubeRepository();
  final _download = DownloadService();
  late final GlossService _gloss = GlossService(settings: widget.settings);

  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);

  List<Cue> _cues = [];
  int? _activeCueIndex;
  int? _speakingCueIndex;
  int? _selectedCueIndex;
  int? _selectionAnchor;
  List<int> _selectedWordIndices = [];
  final Map<int, String> _glossByIndex = {};
  int? _loadingIndex;
  int? _sentenceGlossCueIndex;
  String? _sentenceGloss;
  bool _sentenceGlossLoading = false;

  String? _error;
  bool _loading = false;
  int? _downloadPercent;

  String? _currentVideoId;
  String? _currentWatchUrl;
  String? _currentVideoTitle;
  Duration? _videoDuration;

  StreamSubscription<Duration>? _positionSub;
  final _pageFocusNode = FocusNode();
  final _urlFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _urlController.text = kDefaultTestYoutubeUrl;
    _positionSub = _player.stream.position.listen(_onPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pageFocusNode.requestFocus();
    });
  }

  KeyEventResult _onPageKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    if (_urlFocusNode.hasFocus) return KeyEventResult.ignored;
    _togglePlayPause();
    return KeyEventResult.handled;
  }

  void _onPosition(Duration position) {
    final displayIndex = lyricDisplayCueIndex(_cues, position);
    final speakingIndex = activeCueIndex(_cues, position);
    if (displayIndex != _activeCueIndex ||
        speakingIndex != _speakingCueIndex) {
      setState(() {
        _activeCueIndex = displayIndex;
        _speakingCueIndex = speakingIndex;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_player.state.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _loadVideo({Duration? seekAfter}) async {
    final url = _urlController.text.trim();
    if (!_youtube.isValidYoutubeUrl(url)) {
      setState(() => _error = '请输入有效的 YouTube 链接');
      return;
    }

    final videoId = _youtube.extractVideoId(url);
    if (videoId == null) {
      setState(() => _error = '无法解析视频 ID');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _downloadPercent = null;
      _cues = [];
      _activeCueIndex = null;
      _speakingCueIndex = null;
      _clearWordSelection();
      _clearSentenceGloss();
    });

    try {
      final metaFuture = _youtube.fetchVideoMeta(videoId);
      List<Cue> cues;
      try {
        cues = await _youtube.fetchEnglishCaptions(videoId);
      } catch (e) {
        cues = [];
      }

      late final String mediaSource;
      if (widget.settings.playbackMode == PlaybackMode.download) {
        mediaSource = await _download.downloadVideo(
          url,
          onProgress: (p) => setState(() => _downloadPercent = p),
        );
      } else {
        final streamUri = await _youtube.streamUrlForVideo(videoId);
        mediaSource = streamUri.toString();
      }

      final meta = await metaFuture;
      final playOnOpen = seekAfter == null;

      await _player.open(Media(mediaSource), play: playOnOpen);

      if (seekAfter != null) {
        await _player.seek(seekAfter);
        await _player.pause();
      }

      setState(() {
        _currentVideoId = videoId;
        _currentWatchUrl = url;
        _currentVideoTitle = meta.title;
        _videoDuration = meta.duration;
        _cues = cues;
        final pos = seekAfter ?? _player.state.position;
        _activeCueIndex = lyricDisplayCueIndex(_cues, pos);
        _speakingCueIndex = activeCueIndex(_cues, pos);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _replayCue(int cueIndex) async {
    if (cueIndex < 0 || cueIndex >= _cues.length) return;
    await _player.seek(_cues[cueIndex].start);
    await _player.play();
  }

  Future<void> _seekCuePaused(int cueIndex) async {
    if (cueIndex < 0 || cueIndex >= _cues.length) return;
    await _player.pause();
    await _player.seek(_cues[cueIndex].start);
  }

  void _clearWordSelection() {
    _selectedCueIndex = null;
    _selectionAnchor = null;
    _selectedWordIndices = [];
    _glossByIndex.clear();
    _loadingIndex = null;
  }

  void _clearSentenceGloss() {
    _sentenceGlossCueIndex = null;
    _sentenceGloss = null;
    _sentenceGlossLoading = false;
  }

  Future<void> _onLineReplay(int cueIndex) async {
    await _replayCue(cueIndex);
    setState(() {
      _clearWordSelection();
      _clearSentenceGloss();
    });
  }

  Future<void> _onWordTap(int cueIndex, int index, String token) async {
    if (cueIndex < 0 || cueIndex >= _cues.length) return;

    final words = splitSubtitleWords(_cues[cueIndex].text);

    if (_selectedCueIndex == cueIndex &&
        _selectedWordIndices.contains(index)) {
      setState(_clearWordSelection);
      return;
    }

    final int anchor;
    final List<int> indices;
    if (_selectedCueIndex != cueIndex || _selectionAnchor == null) {
      anchor = index;
      indices = [index];
    } else {
      anchor = _selectionAnchor!;
      indices = wordIndicesInRange(anchor, index);
    }

    final phrase = phraseFromIndices(words, indices);
    final sentence = _cues[cueIndex];
    final glossSlot = indices.first;

    await _seekCuePaused(cueIndex);

    setState(() {
      _clearSentenceGloss();
      _selectedCueIndex = cueIndex;
      _selectionAnchor = anchor;
      _selectedWordIndices = indices;
      _loadingIndex = glossSlot;
      _glossByIndex.clear();
    });

    try {
      final gloss = await _gloss.glossWord(
        token: phrase,
        sentenceContext: sentence.text,
      );
      if (!mounted) return;
      setState(() {
        _glossByIndex[glossSlot] = gloss;
        _loadingIndex = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingIndex = null);
    }
  }

  Future<void> _onSentenceTranslate(int cueIndex) async {
    if (cueIndex < 0 || cueIndex >= _cues.length) return;

    if (_sentenceGlossCueIndex == cueIndex &&
        (_sentenceGloss != null || _sentenceGlossLoading)) {
      setState(_clearSentenceGloss);
      return;
    }

    final text = _cues[cueIndex].text;
    await _seekCuePaused(cueIndex);

    setState(() {
      _clearWordSelection();
      _sentenceGlossCueIndex = cueIndex;
      _sentenceGloss = null;
      _sentenceGlossLoading = true;
    });

    try {
      final gloss = await _gloss.glossSentence(text);
      if (!mounted) return;
      setState(() {
        _sentenceGloss = gloss;
        _sentenceGlossLoading = false;
      });

      final videoId = _currentVideoId;
      final watchUrl = _currentWatchUrl;
      if (videoId != null && watchUrl != null && gloss.isNotEmpty) {
        final cue = _cues[cueIndex];
        final item = SavedSentence(
          englishText: text,
          chineseText: gloss,
          videoId: videoId,
          videoTitle: _currentVideoTitle ?? videoId,
          watchUrl: watchUrl,
          cueStartMs: cue.start.inMilliseconds,
          cueEndMs: cue.end.inMilliseconds,
          videoDurationMs: _videoDuration?.inMilliseconds,
          savedAt: DateTime.now(),
        );
        unawaited(widget.sentenceStore.upsert(item));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已加入句子重温'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _sentenceGlossLoading = false);
    }
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

  Future<void> _openSettings() async {
    final mode = widget.settings.playbackMode;
    final enjoyToken = widget.settings.enjoyApiToken ?? '';
    final sidecar = widget.settings.dictSidecarUrl ?? '';

    await showDialog<void>(
      context: context,
      builder: (context) {
        var localMode = mode;
        final tokenCtrl = TextEditingController(text: enjoyToken);
        final sidecarCtrl = TextEditingController(text: sidecar);

        return AlertDialog(
          title: const Text('设置'),
          content: StatefulBuilder(
            builder: (context, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('播放模式'),
                RadioListTile<PlaybackMode>(
                  title: const Text('在线流式（默认）'),
                  value: PlaybackMode.online,
                  groupValue: localMode,
                  onChanged: (v) => setLocal(() => localMode = v!),
                ),
                RadioListTile<PlaybackMode>(
                  title: const Text('下载后播放'),
                  value: PlaybackMode.download,
                  groupValue: localMode,
                  onChanged: (v) => setLocal(() => localMode = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enjoy API Token（可选）',
                  ),
                ),
                TextField(
                  controller: sidecarCtrl,
                  decoration: const InputDecoration(
                    labelText: '词典 Sidecar URL（可选）',
                    hintText: 'http://127.0.0.1:3847/lookup',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.settings.setPlaybackMode(localMode);
                await widget.settings.setEnjoyApiToken(
                  tokenCtrl.text.trim().isEmpty ? null : tokenCtrl.text.trim(),
                );
                await widget.settings.setDictSidecarUrl(
                  sidecarCtrl.text.trim().isEmpty
                      ? null
                      : sidecarCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _openChannelPicker() {
    ChannelPickerSheet.show(
      context,
      youtube: _youtube,
      onVideoSelected: (url) {
        _urlController.text = url;
        _loadVideo();
      },
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    _youtube.close();
    _urlController.dispose();
    _pageFocusNode.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _pageFocusNode,
      autofocus: true,
      onKeyEvent: _onPageKey,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('YouTube 学英语'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: '句子重温',
            onPressed: _openSentenceReview,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
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
                  onPressed: _loading ? null : _loadVideo,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('播放'),
                ),
              ],
            ),
          ),
          if (_downloadPercent != null)
            LinearProgressIndicator(value: _downloadPercent! / 100),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_error!, style: TextStyle(color: Colors.red[700])),
            ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlayPause,
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Video(
                    controller: _videoController,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 260),
              child: SubtitleLyricsPanel(
                cues: _cues,
                activeCueIndex: _activeCueIndex,
                speakingCueIndex: _speakingCueIndex,
                selectedCueIndex: _selectedCueIndex,
                selectedWordIndices: _selectedWordIndices,
                glossByIndex: _glossByIndex,
                loadingIndex: _loadingIndex,
                onWordTap: _onWordTap,
                onLineReplay: _onLineReplay,
                onSentenceTranslate: _onSentenceTranslate,
                sentenceGlossCueIndex: _sentenceGlossCueIndex,
                sentenceGloss: _sentenceGloss,
                sentenceGlossLoading: _sentenceGlossLoading,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChannelPicker,
        icon: const Icon(Icons.video_library_outlined),
        label: const Text('频道'),
      ),
    ),
    );
  }
}
