import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app_branding.dart';
import 'features/player/youtube_learn_page.dart';
import 'services/app_settings.dart';
import 'services/sentence_review_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runZonedGuarded(
    () async {
      try {
        await _bootstrap();
      } catch (e, st) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(exception: e, stack: st),
        );
        runApp(StartupErrorApp(message: e.toString()));
      }
    },
    (error, stack) {
      FlutterError.dumpErrorToConsole(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      runApp(StartupErrorApp(message: error.toString()));
    },
  );
}

Future<void> _bootstrap() async {
  if (kIsWeb) {
    // SharedWorker + relative URLs break under GitHub Pages subpaths; load wasm in-app.
    final wasmUri = Uri.base.resolve('sqlite3.wasm');
    databaseFactory = createDatabaseFactoryFfiWeb(
      noWebWorker: true,
      options: SqfliteFfiWebOptions(sqlite3WasmUri: wasmUri),
    );
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  MediaKit.ensureInitialized();
  final settings = await AppSettings.load();
  final sentenceStore = await SentenceReviewStore.open();
  runApp(LearnMacApp(settings: settings, sentenceStore: sentenceStore));
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              '启动失败：$message',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class LearnMacApp extends StatelessWidget {
  const LearnMacApp({
    super.key,
    required this.settings,
    required this.sentenceStore,
  });

  final AppSettings settings;
  final SentenceReviewStore sentenceStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppDisplayName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: YoutubeLearnPage(
        settings: settings,
        sentenceStore: sentenceStore,
      ),
    );
  }
}
