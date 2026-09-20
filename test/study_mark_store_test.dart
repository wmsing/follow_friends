import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mac/models/study_mark.dart';
import 'package:learn_mac/services/study_mark_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tmp;
  late StudyMarkStore store;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('study_mark_test_');
    store = await StudyMarkStore.openAtPath('${tmp.path}/marks.db');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('upsert and listForVideo', () async {
    final mark = StudyMark(
      videoId: 'vid1',
      cueIndex: 2,
      anchorWordIndex: 0,
      wordIndices: [0, 1],
      englishPhrase: 'hello world',
      chineseGloss: '你好世界',
      updatedAt: DateTime(2026, 1, 1),
    );
    await store.upsert(mark);

    final list = await store.listForVideo('vid1');
    expect(list, hasLength(1));
    expect(list.first.englishPhrase, 'hello world');
    expect(list.first.wordIndices, [0, 1]);
    expect(list.first.chineseGloss, '你好世界');
  });

  test('replace mark with same anchor', () async {
    final base = StudyMark(
      videoId: 'vid1',
      cueIndex: 0,
      anchorWordIndex: 1,
      wordIndices: [1],
      englishPhrase: 'foo',
      chineseGloss: '甲',
      updatedAt: DateTime(2026, 1, 1),
    );
    await store.upsert(base);
    await store.upsert(
      StudyMark(
        videoId: 'vid1',
        cueIndex: 0,
        anchorWordIndex: 1,
        wordIndices: [1, 2],
        englishPhrase: 'foo bar',
        chineseGloss: '甲乙',
        updatedAt: DateTime(2026, 1, 2),
      ),
    );

    final list = await store.listForVideo('vid1');
    expect(list, hasLength(1));
    expect(list.first.englishPhrase, 'foo bar');
    expect(list.first.wordIndices, [1, 2]);
  });

  test('deleteMark and deleteAllForVideo', () async {
    await store.upsert(
      StudyMark(
        videoId: 'vid1',
        cueIndex: 0,
        anchorWordIndex: 0,
        wordIndices: [0],
        englishPhrase: 'a',
        chineseGloss: '一',
        updatedAt: DateTime(2026),
      ),
    );
    await store.deleteMark(
      videoId: 'vid1',
      cueIndex: 0,
      anchorWordIndex: 0,
    );
    expect(await store.listForVideo('vid1'), isEmpty);

    await store.upsert(
      StudyMark(
        videoId: 'vid1',
        cueIndex: 1,
        anchorWordIndex: 0,
        wordIndices: [0],
        englishPhrase: 'b',
        chineseGloss: '二',
        updatedAt: DateTime(2026),
      ),
    );
    await store.deleteAllForVideo('vid1');
    expect(await store.listForVideo('vid1'), isEmpty);
  });
}
