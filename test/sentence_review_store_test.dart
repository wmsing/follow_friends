import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mac/models/saved_sentence.dart';
import 'package:learn_mac/services/sentence_review_store.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upsert list query and dedupe by video plus english', () async {
    final dir = await Directory.systemTemp.createTemp('learn_mac_db_test');
    final dbPath = p.join(dir.path, 'test.db');
    final store = await SentenceReviewStore.openAtPath(dbPath);

    final base = SavedSentence(
      englishText: 'Hello world.',
      chineseText: '你好世界。',
      videoId: 'abc123',
      videoTitle: 'Test Video',
      watchUrl: 'https://www.youtube.com/watch?v=abc123',
      cueStartMs: 1000,
      cueEndMs: 4000,
      videoDurationMs: 120000,
      savedAt: DateTime(2025, 1, 1),
    );

    await store.upsert(base);
    await store.upsert(
      SavedSentence(
        englishText: 'Hello world.',
        chineseText: '你好，世界！',
        videoId: 'abc123',
        videoTitle: 'Test Video Updated',
        watchUrl: 'https://www.youtube.com/watch?v=abc123',
        cueStartMs: 1000,
        cueEndMs: 5000,
        videoDurationMs: 120000,
        savedAt: DateTime(2025, 6, 1),
      ),
    );

    final all = await store.list();
    expect(all.length, 1);
    expect(all.first.chineseText, '你好，世界！');
    expect(all.first.videoTitle, 'Test Video Updated');
    expect(all.first.cueEndMs, 5000);

    await store.upsert(
      SavedSentence(
        englishText: 'Another line.',
        chineseText: '另一句。',
        videoId: 'abc123',
        videoTitle: 'Test Video',
        watchUrl: 'https://www.youtube.com/watch?v=abc123',
        cueStartMs: 5000,
        cueEndMs: 8000,
        savedAt: DateTime(2025, 7, 1),
      ),
    );

    final found = await store.list(query: '另一');
    expect(found.length, 1);
    expect(found.first.englishText, 'Another line.');

    for (final row in await store.list()) {
      await store.delete(row.id!);
    }
    expect(await store.list(), isEmpty);

    await dir.delete(recursive: true);
  });
}
