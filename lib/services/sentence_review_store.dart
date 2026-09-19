import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/saved_sentence.dart';

class SentenceReviewStore {
  SentenceReviewStore._(this._db);

  final Database _db;

  static SentenceReviewStore? _instance;

  static Future<SentenceReviewStore> open() async {
    if (_instance != null) return _instance!;
    final path = kIsWeb
        ? 'learn_mac_sentences.db'
        : p.join(
            (await getApplicationDocumentsDirectory()).path,
            'learn_mac_sentences.db',
          );
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE saved_sentences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  english_text TEXT NOT NULL,
  chinese_text TEXT NOT NULL,
  video_id TEXT NOT NULL,
  video_title TEXT NOT NULL,
  watch_url TEXT NOT NULL,
  cue_start_ms INTEGER NOT NULL,
  cue_end_ms INTEGER NOT NULL,
  video_duration_ms INTEGER,
  saved_at INTEGER NOT NULL,
  UNIQUE(video_id, english_text)
)
''');
        await db.execute(
          'CREATE INDEX idx_saved_sentences_saved_at ON saved_sentences(saved_at DESC)',
        );
      },
    );
    _instance = SentenceReviewStore._(db);
    return _instance!;
  }

  /// For tests: open an isolated database file.
  static Future<SentenceReviewStore> openAtPath(String path) async {
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE saved_sentences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  english_text TEXT NOT NULL,
  chinese_text TEXT NOT NULL,
  video_id TEXT NOT NULL,
  video_title TEXT NOT NULL,
  watch_url TEXT NOT NULL,
  cue_start_ms INTEGER NOT NULL,
  cue_end_ms INTEGER NOT NULL,
  video_duration_ms INTEGER,
  saved_at INTEGER NOT NULL,
  UNIQUE(video_id, english_text)
)
''');
      },
    );
    return SentenceReviewStore._(db);
  }

  Future<int> upsert(SavedSentence item) async {
    final row = item.toRow();
    row.remove('id');
    return _db.insert(
      'saved_sentences',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SavedSentence>> list({String? query, int limit = 200}) async {
    final trimmed = query?.trim();
    List<Map<String, Object?>> rows;
    if (trimmed == null || trimmed.isEmpty) {
      rows = await _db.query(
        'saved_sentences',
        orderBy: 'saved_at DESC',
        limit: limit,
      );
    } else {
      final pattern = '%$trimmed%';
      rows = await _db.query(
        'saved_sentences',
        where:
            'english_text LIKE ? OR chinese_text LIKE ? OR video_title LIKE ?',
        whereArgs: [pattern, pattern, pattern],
        orderBy: 'saved_at DESC',
        limit: limit,
      );
    }
    return rows.map(SavedSentence.fromRow).toList();
  }

  Future<void> delete(int id) async {
    await _db.delete(
      'saved_sentences',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
