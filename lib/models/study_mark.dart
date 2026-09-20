class StudyMark {
  const StudyMark({
    this.id,
    required this.videoId,
    required this.cueIndex,
    required this.anchorWordIndex,
    required this.wordIndices,
    required this.englishPhrase,
    required this.chineseGloss,
    required this.updatedAt,
  });

  final int? id;
  final String videoId;
  final int cueIndex;
  final int anchorWordIndex;
  final List<int> wordIndices;
  final String englishPhrase;
  final String chineseGloss;
  final DateTime updatedAt;

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'video_id': videoId,
        'cue_index': cueIndex,
        'anchor_word_index': anchorWordIndex,
        'word_indices': wordIndices.join(','),
        'english_phrase': englishPhrase,
        'chinese_gloss': chineseGloss,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static StudyMark fromRow(Map<String, Object?> row) {
    final rawIndices = row['word_indices'] as String;
    final indices = rawIndices.isEmpty
        ? <int>[]
        : rawIndices.split(',').map(int.parse).toList();
    return StudyMark(
      id: row['id'] as int?,
      videoId: row['video_id'] as String,
      cueIndex: row['cue_index'] as int,
      anchorWordIndex: row['anchor_word_index'] as int,
      wordIndices: indices,
      englishPhrase: row['english_phrase'] as String,
      chineseGloss: row['chinese_gloss'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
