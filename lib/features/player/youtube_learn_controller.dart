import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../platform_support.dart';
import '../../models/cue.dart' as cue;
import '../../models/saved_sentence.dart';
import '../../services/app_settings.dart';
import '../../services/youtube_learn_cache.dart';
import '../../services/download_service.dart';
import '../../services/gloss_service.dart';
import '../../services/subtitle_parser.dart';
import '../../services/youtube_repository.dart';

class YoutubeLearnController extends ChangeNotifier {
  YoutubeLearnController({required AppSettings settings})
      : _settings = settings,
        _gloss = GlossService(settings: settings) {
    _positionSub = player.stream.position.listen(_onPosition);
  }

  final AppSettings _settings;
  final YoutubeRepository _youtube = YoutubeRepository();
  final DownloadService _download = DownloadService();
  final GlossService _gloss;

  final Player player = Player();
  late final VideoController videoController = VideoController(player);

  List<cue.Cue> cues = [];
  List<cue.Cue> _rawCues = [];
  List<cue.Cue> _mergedCues = [];
  int? activeCueIndex;
  int? speakingCueIndex;
  int? _overlayActiveCueIndex;
  int? selectedCueIndex;
  int? selectionAnchor;
  List<int> selectedWordIndices = [];
  final Map<int, String> glossByIndex = {};
  int? loadingIndex;
  int? sentenceGlossCueIndex;
  String? sentenceGloss;
  bool sentenceGlossLoading = false;

  String? error;
  bool loading = false;
  int? downloadPercent;

  String? _currentVideoId;
  String? _currentWatchUrl;
  String? _currentVideoTitle;
  Duration? _videoDuration;

  StreamSubscription<Duration>? _positionSub;

  YoutubeRepository get youtube => _youtube;

  bool get overlayOriginalCaptions =>
      _settings.subtitleDisplayMode == SubtitleDisplayMode.original;

  String? get videoOverlayCaptionText {
    if (!overlayOriginalCaptions) return null;
    final index = _overlayActiveCueIndex;
    if (index == null || index < 0 || index >= _rawCues.length) return null;
    final text = _rawCues[index].text.trim();
    return text.isEmpty ? null : text;
  }

  void applySubtitleDisplayMode() {
    if (_rawCues.isEmpty && _mergedCues.isEmpty) return;
    cues = _mergedCues;
    _clearWordSelection();
    _clearSentenceGloss();
    _syncCueIndices(player.state.position);
    notifyListeners();
  }

  void _syncCueIndices(Duration position) {
    activeCueIndex = cue.lyricDisplayCueIndex(cues, position);
    speakingCueIndex = cue.activeCueIndex(cues, position);
    _overlayActiveCueIndex = overlayOriginalCaptions
        ? cue.lyricDisplayCueIndex(_rawCues, position)
        : null;
  }

  void _onPosition(Duration position) {
    final displayIndex = cue.lyricDisplayCueIndex(cues, position);
    final speakingIndex = cue.activeCueIndex(cues, position);
    final overlayIndex = overlayOriginalCaptions
        ? cue.lyricDisplayCueIndex(_rawCues, position)
        : null;
    if (displayIndex != activeCueIndex ||
        speakingIndex != speakingCueIndex ||
        overlayIndex != _overlayActiveCueIndex) {
      activeCueIndex = displayIndex;
      speakingCueIndex = speakingIndex;
      _overlayActiveCueIndex = overlayIndex;
      notifyListeners();
    }
  }

  double get playbackSpeed => _settings.playbackSpeed;

  Future<void> setPlaybackSpeed(double speed) async {
    if (!kPlaybackSpeedOptions.contains(speed)) return;
    await _settings.setPlaybackSpeed(speed);
    await player.setRate(speed);
    notifyListeners();
  }

  Future<void> _applyPlaybackSpeed() => player.setRate(_settings.playbackSpeed);

  Future<void> togglePlayPause() async {
    if (player.state.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> loadVideo(String url, {Duration? seekAfter}) async {
    final trimmed = url.trim();
    if (!_youtube.isValidYoutubeUrl(trimmed)) {
      error = '请输入有效的 YouTube 链接';
      notifyListeners();
      return;
    }

    final videoId = _youtube.extractVideoId(trimmed);
    if (videoId == null) {
      error = '无法解析视频 ID';
      notifyListeners();
      return;
    }

    if (kIsWeb) {
      error = kWebYoutubeUnavailableMessage;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    downloadPercent = null;
    cues = [];
    _rawCues = [];
    _mergedCues = [];
    activeCueIndex = null;
    speakingCueIndex = null;
    _overlayActiveCueIndex = null;
    _clearWordSelection();
    _clearSentenceGloss();
    notifyListeners();

    try {
      final metaFuture = _youtube.fetchVideoMeta(videoId);
      try {
        final tracks = await _youtube.fetchEnglishCaptionTracks(videoId);
        _rawCues = tracks.raw;
        _mergedCues = tracks.merged;
      } catch (_) {
        _rawCues = [];
        _mergedCues = [];
      }

      late final String mediaSource;
      if (_settings.playbackMode == PlaybackMode.download) {
        mediaSource = await _download.downloadVideo(
          trimmed,
          onProgress: (p) {
            downloadPercent = p;
            notifyListeners();
          },
        );
      } else {
        final streamUri = await _youtube.streamUrlForVideo(videoId);
        mediaSource = streamUri.toString();
      }

      final meta = await metaFuture;
      final playOnOpen = seekAfter == null;

      await player.open(Media(mediaSource), play: playOnOpen);

      if (seekAfter != null) {
        await player.seek(seekAfter);
        await player.pause();
      }

      await _applyPlaybackSpeed();

      _currentVideoId = videoId;
      _currentWatchUrl = trimmed;
      _currentVideoTitle = meta.title;
      _videoDuration = meta.duration;
      applySubtitleDisplayMode();
      _syncCueIndices(seekAfter ?? player.state.position);
      final cache = await YoutubeLearnCache.load();
      await cache.setLastWatchUrl(trimmed);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> replayCue(int cueIndex) async {
    if (cueIndex < 0 || cueIndex >= cues.length) return;
    await player.seek(cues[cueIndex].start);
    await player.play();
  }

  Future<void> seekCuePaused(int cueIndex) async {
    if (cueIndex < 0 || cueIndex >= cues.length) return;
    await player.pause();
    await player.seek(cues[cueIndex].start);
  }

  void _clearWordSelection() {
    selectedCueIndex = null;
    selectionAnchor = null;
    selectedWordIndices = [];
    glossByIndex.clear();
    loadingIndex = null;
  }

  void _clearSentenceGloss() {
    sentenceGlossCueIndex = null;
    sentenceGloss = null;
    sentenceGlossLoading = false;
  }

  Future<void> onLineReplay(int cueIndex) async {
    await replayCue(cueIndex);
    _clearWordSelection();
    _clearSentenceGloss();
    notifyListeners();
  }

  Future<void> onWordTap(int cueIndex, int index, String token) async {
    if (cueIndex < 0 || cueIndex >= cues.length) return;

    final words = splitSubtitleWords(cues[cueIndex].text);

    if (selectedCueIndex == cueIndex && selectedWordIndices.contains(index)) {
      _clearWordSelection();
      notifyListeners();
      return;
    }

    final int anchor;
    final List<int> indices;
    if (selectedCueIndex != cueIndex || selectionAnchor == null) {
      anchor = index;
      indices = [index];
    } else {
      anchor = selectionAnchor!;
      indices = wordIndicesInRange(anchor, index);
    }

    final phrase = phraseFromIndices(words, indices);
    final sentence = cues[cueIndex];
    final glossSlot = indices.first;

    await seekCuePaused(cueIndex);

    _clearSentenceGloss();
    selectedCueIndex = cueIndex;
    selectionAnchor = anchor;
    selectedWordIndices = indices;
    loadingIndex = glossSlot;
    glossByIndex.clear();
    notifyListeners();

    try {
      final gloss = await _gloss.glossWord(
        token: phrase,
        sentenceContext: sentence.text,
      );
      glossByIndex[glossSlot] = gloss;
      loadingIndex = null;
      notifyListeners();
    } catch (_) {
      loadingIndex = null;
      notifyListeners();
    }
  }

  /// Returns a sentence to persist when translation succeeded and should be saved.
  Future<SavedSentence?> onSentenceTranslate(int cueIndex) async {
    if (cueIndex < 0 || cueIndex >= cues.length) return null;

    if (sentenceGlossCueIndex == cueIndex &&
        (sentenceGloss != null || sentenceGlossLoading)) {
      _clearSentenceGloss();
      notifyListeners();
      return null;
    }

    final text = cues[cueIndex].text;
    await seekCuePaused(cueIndex);

    _clearWordSelection();
    sentenceGlossCueIndex = cueIndex;
    sentenceGloss = null;
    sentenceGlossLoading = true;
    notifyListeners();

    try {
      final gloss = await _gloss.glossSentence(text);
      sentenceGloss = gloss;
      sentenceGlossLoading = false;
      notifyListeners();

      final videoId = _currentVideoId;
      final watchUrl = _currentWatchUrl;
      if (videoId != null && watchUrl != null && gloss.isNotEmpty) {
        final cue = cues[cueIndex];
        return SavedSentence(
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
      }
    } catch (_) {
      sentenceGlossLoading = false;
      notifyListeners();
    }
    return null;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    player.dispose();
    _youtube.close();
    super.dispose();
  }
}
