import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/study_mark.dart';

class StudyMarkStore {
  StudyMarkStore._(this._db);

  final Database _db;

  static StudyMarkStore? _instance;

  static const _createSql = '''
CREATE TABLE study_marks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  video_id TEXT NOT NULL,
  cue_index INTEGER NOT NULL,
  anchor_word_index INTEGER NOT NULL,
  word_indices TEXT NOT NULL,
  english_phrase TEXT NOT NULL,
  chinese_gloss TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(video_id, cue_index, anchor_word_index)
)
''';

  static Future<StudyMarkStore> open() async {
    if (_instance != null) return _instance!;
    final path = p.join(
      (await getApplicationDocumentsDirectory()).path,
      'learn_mac_study_marks.db',
    );
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(_createSql);
        await db.execute(
          'CREATE INDEX idx_study_marks_video ON study_marks(video_id)',
        );
      },
    );
    _instance = StudyMarkStore._(db);
    return _instance!;
  }

  static Future<StudyMarkStore> openAtPath(String path) async {
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(_createSql);
      },
    );
    return StudyMarkStore._(db);
  }

  Future<List<StudyMark>> listForVideo(String videoId) async {
    final rows = await _db.query(
      'study_marks',
      where: 'video_id = ?',
      whereArgs: [videoId],
      orderBy: 'cue_index ASC, anchor_word_index ASC',
    );
    return rows.map(StudyMark.fromRow).toList();
  }

  Future<int> upsert(StudyMark mark) async {
    final row = mark.toRow();
    row.remove('id');
    return _db.insert(
      'study_marks',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMark({
    required String videoId,
    required int cueIndex,
    required int anchorWordIndex,
  }) async {
    await _db.delete(
      'study_marks',
      where: 'video_id = ? AND cue_index = ? AND anchor_word_index = ?',
      whereArgs: [videoId, cueIndex, anchorWordIndex],
    );
  }

  Future<void> deleteAllForVideo(String videoId) async {
    await _db.delete(
      'study_marks',
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
  }
}
