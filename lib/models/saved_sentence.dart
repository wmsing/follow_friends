class SavedSentence {
  const SavedSentence({
    this.id,
    required this.englishText,
    required this.chineseText,
    required this.videoId,
    required this.videoTitle,
    required this.watchUrl,
    required this.cueStartMs,
    required this.cueEndMs,
    this.videoDurationMs,
    required this.savedAt,
  });

  final int? id;
  final String englishText;
  final String chineseText;
  final String videoId;
  final String videoTitle;
  final String watchUrl;
  final int cueStartMs;
  final int cueEndMs;
  final int? videoDurationMs;
  final DateTime savedAt;

  Duration get cueStart => Duration(milliseconds: cueStartMs);
  Duration get cueEnd => Duration(milliseconds: cueEndMs);

  Duration get cueSegmentDuration => Duration(
        milliseconds: cueEndMs - cueStartMs,
      );

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'english_text': englishText,
        'chinese_text': chineseText,
        'video_id': videoId,
        'video_title': videoTitle,
        'watch_url': watchUrl,
        'cue_start_ms': cueStartMs,
        'cue_end_ms': cueEndMs,
        'video_duration_ms': videoDurationMs,
        'saved_at': savedAt.millisecondsSinceEpoch,
      };

  static SavedSentence fromRow(Map<String, Object?> row) {
    return SavedSentence(
      id: row['id'] as int?,
      englishText: row['english_text'] as String,
      chineseText: row['chinese_text'] as String,
      videoId: row['video_id'] as String,
      videoTitle: row['video_title'] as String,
      watchUrl: row['watch_url'] as String,
      cueStartMs: row['cue_start_ms'] as int,
      cueEndMs: row['cue_end_ms'] as int,
      videoDurationMs: row['video_duration_ms'] as int?,
      savedAt: DateTime.fromMillisecondsSinceEpoch(row['saved_at'] as int),
    );
  }
}
