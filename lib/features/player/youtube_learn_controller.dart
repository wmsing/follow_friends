import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../models/channel_listing.dart';
import '../../models/cue.dart' as cue;
import '../../models/saved_sentence.dart';
import '../../services/app_settings.dart';
import '../../services/youtube_learn_cache.dart';
import '../../services/download_service.dart';
import '../../models/study_mark.dart';
import '../../services/gloss_service.dart';
import '../../services/study_mark_store.dart';
import '../../services/subtitle_parser.dart';
import '../../services/youtube_repository.dart';

class YoutubeLearnController extends ChangeNotifier {
  YoutubeLearnController({
    required AppSettings settings,
    required StudyMarkStore studyMarkStore,
  })  : _settings = settings,
        _studyMarkStore = studyMarkStore,
        _gloss = GlossService(settings: settings) {
    _positionSub = player.stream.position.listen(_onPosition);
  }

  final AppSettings _settings;
  final StudyMarkStore _studyMarkStore;
  final YoutubeRepository _youtube = YoutubeRepository();
  final DownloadService _download = DownloadService();
  final GlossService _gloss;

  final Map<int, List<StudyMark>> _studyMarksByCue = {};
  int? studyMarkLoadingCueIndex;
  int? studyMarkLoadingWordIndex;
  int? _studyPrepCueIndex;
  int? _studyPrepAnchor;
  List<int> _studyPrepIndices = [];

  final Player player = Player();
  late final VideoController videoController = VideoController(player);

  List<cue.Cue> cues = [];
  List<cue.Cue> _rawCues = [];
  List<cue.Cue> _mergedCues = [];
  int? activeCueIndex;
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

  ChannelListing? _channelListing;
  int? _channelVideoIndex;

  StreamSubscription<Duration>? _positionSub;

  YoutubeRepository get youtube => _youtube;

  String? get currentVideoId => _currentVideoId;

  bool get canPlayNextInChannel =>
      _channelListing != null &&
      _channelVideoIndex != null &&
      _channelVideoIndex! < _channelListing!.videos.length - 1;

  String? get nextChannelWatchUrl {
    if (!canPlayNextInChannel) return null;
    return _channelListing!.videos[_channelVideoIndex! + 1].watchUrl;
  }

  void bindChannelListing(ChannelListing listing) {
    _channelListing = listing;
    _syncChannelVideoIndex();
    notifyListeners();
  }

  Future<void> playNextInChannel() async {
    final url = nextChannelWatchUrl;
    if (url == null) return;
    await loadVideo(url);
  }

  void _syncChannelVideoIndex() {
    final id = _currentVideoId;
    final listing = _channelListing;
    if (listing == null || id == null) {
      _channelVideoIndex = null;
      return;
    }
    final idx = listing.videos.indexWhere((v) => v.videoId == id);
    _channelVideoIndex = idx >= 0 ? idx : null;
  }

  Future<void> _restoreChannelListingFromCache() async {
    if (_channelListing != null) return;
    final cache = await YoutubeLearnCache.load();
    _channelListing = cache.loadChannelCache().listing;
  }

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
    _overlayActiveCueIndex = overlayOriginalCaptions
        ? cue.lyricDisplayCueIndex(_rawCues, position)
        : null;
  }

  void _onPosition(Duration position) {
    final displayIndex = cue.lyricDisplayCueIndex(cues, position);
    final overlayIndex = overlayOriginalCaptions
        ? cue.lyricDisplayCueIndex(_rawCues, position)
        : null;
    if (displayIndex != activeCueIndex ||
        overlayIndex != _overlayActiveCueIndex) {
      activeCueIndex = displayIndex;
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

    loading = true;
    error = null;
    downloadPercent = null;
    cues = [];
    _rawCues = [];
    _mergedCues = [];
    _studyMarksByCue.clear();
    _studyPrepCueIndex = null;
    _studyPrepAnchor = null;
    _studyPrepIndices = [];
    studyMarkLoadingCueIndex = null;
    studyMarkLoadingWordIndex = null;
    activeCueIndex = null;
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

      await player.open(Media(mediaSource), play: false);
      if (seekAfter != null) {
        await player.seek(seekAfter);
      }
      await player.pause();

      await _applyPlaybackSpeed();

      _currentVideoId = videoId;
      _currentWatchUrl = trimmed;
      _currentVideoTitle = meta.title;
      _videoDuration = meta.duration;
      await _restoreChannelListingFromCache();
      _syncChannelVideoIndex();
      await _loadStudyMarks(videoId);
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

  Future<void> _loadStudyMarks(String videoId) async {
    _studyMarksByCue.clear();
    final marks = await _studyMarkStore.listForVideo(videoId);
    for (final mark in marks) {
      _studyMarksByCue.putIfAbsent(mark.cueIndex, () => []).add(mark);
    }
  }

  Set<int> markedWordIndices(int cueIndex) {
    final marks = _studyMarksByCue[cueIndex];
    if (marks == null) return {};
    final indices = <int>{};
    for (final mark in marks) {
      indices.addAll(mark.wordIndices);
    }
    return indices;
  }

  Map<int, String> studyGlossForCue(int cueIndex) {
    final marks = _studyMarksByCue[cueIndex];
    if (marks == null) return {};
    final gloss = <int, String>{};
    for (final mark in marks) {
      if (mark.chineseGloss.isNotEmpty) {
        gloss[mark.anchorWordIndex] = mark.chineseGloss;
      }
    }
    return gloss;
  }

  Set<int> studyMarkedIndicesForPanel(int cueIndex) {
    if (activeCueIndex != cueIndex) return {};
    return markedWordIndices(cueIndex);
  }

  Map<int, String> studyGlossForPanel(int cueIndex) {
    if (activeCueIndex != cueIndex) return {};
    return studyGlossForCue(cueIndex);
  }

  bool get hasStudyMarks => _studyMarksByCue.isNotEmpty;

  Future<void> toggleStudyMark(int cueIndex, int index) async {
    if (cueIndex < 0 || cueIndex >= cues.length) return;
    final videoId = _currentVideoId;
    if (videoId == null) return;

    final words = splitSubtitleWords(cues[cueIndex].text);

    if (_studyPrepCueIndex == cueIndex && _studyPrepIndices.contains(index)) {
      final anchor = _studyPrepAnchor;
      if (anchor != null) {
        await _studyMarkStore.deleteMark(
          videoId: videoId,
          cueIndex: cueIndex,
          anchorWordIndex: anchor,
        );
        _removeMarkFromMemory(cueIndex, anchor);
      }
      _studyPrepCueIndex = null;
      _studyPrepAnchor = null;
      _studyPrepIndices = [];
      studyMarkLoadingCueIndex = null;
      studyMarkLoadingWordIndex = null;
      notifyListeners();
      return;
    }

    final int anchor;
    final List<int> indices;
    if (_studyPrepCueIndex != cueIndex || _studyPrepAnchor == null) {
      anchor = index;
      indices = [index];
    } else {
      anchor = _studyPrepAnchor!;
      indices = wordIndicesInRange(anchor, index);
    }

    final phrase = phraseFromIndices(words, indices);
    final sentence = cues[cueIndex];
    final glossSlot = indices.first;

    _studyPrepCueIndex = cueIndex;
    _studyPrepAnchor = anchor;
    _studyPrepIndices = indices;
    studyMarkLoadingCueIndex = cueIndex;
    studyMarkLoadingWordIndex = glossSlot;
    notifyListeners();

    try {
      final gloss = await _gloss.glossWord(
        token: phrase,
        sentenceContext: sentence.text,
      );
      final mark = StudyMark(
        videoId: videoId,
        cueIndex: cueIndex,
        anchorWordIndex: glossSlot,
        wordIndices: indices,
        englishPhrase: phrase,
        chineseGloss: gloss,
        updatedAt: DateTime.now(),
      );
      await _studyMarkStore.upsert(mark);
      _upsertMarkInMemory(mark);
      studyMarkLoadingCueIndex = null;
      studyMarkLoadingWordIndex = null;
      notifyListeners();
    } catch (_) {
      studyMarkLoadingCueIndex = null;
      studyMarkLoadingWordIndex = null;
      notifyListeners();
    }
  }

  void _upsertMarkInMemory(StudyMark mark) {
    final list = _studyMarksByCue.putIfAbsent(mark.cueIndex, () => []);
    list.removeWhere((m) => m.anchorWordIndex == mark.anchorWordIndex);
    list.add(mark);
  }

  void _removeMarkFromMemory(int cueIndex, int anchorWordIndex) {
    final list = _studyMarksByCue[cueIndex];
    if (list == null) return;
    list.removeWhere((m) => m.anchorWordIndex == anchorWordIndex);
    if (list.isEmpty) _studyMarksByCue.remove(cueIndex);
  }

  Future<void> clearStudyMarksForVideo() async {
    final videoId = _currentVideoId;
    if (videoId == null) return;
    await _studyMarkStore.deleteAllForVideo(videoId);
    _studyMarksByCue.clear();
    _studyPrepCueIndex = null;
    _studyPrepAnchor = null;
    _studyPrepIndices = [];
    studyMarkLoadingCueIndex = null;
    studyMarkLoadingWordIndex = null;
    notifyListeners();
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
