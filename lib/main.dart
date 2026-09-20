import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_branding.dart';
import 'features/player/youtube_learn_page.dart';
import 'widgets/launch_splash.dart';
import 'services/app_settings.dart';
import 'services/sentence_review_store.dart';
import 'services/study_mark_store.dart';

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
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  MediaKit.ensureInitialized();
  final settings = await AppSettings.load();
  final sentenceStore = await SentenceReviewStore.open();
  final studyMarkStore = await StudyMarkStore.open();
  runApp(
    LearnMacApp(
      settings: settings,
      sentenceStore: sentenceStore,
      studyMarkStore: studyMarkStore,
    ),
  );
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
    required this.studyMarkStore,
  });

  final AppSettings settings;
  final SentenceReviewStore sentenceStore;
  final StudyMarkStore studyMarkStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppDisplayName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: LaunchSplash(
        child: YoutubeLearnPage(
          settings: settings,
          sentenceStore: sentenceStore,
          studyMarkStore: studyMarkStore,
        ),
      ),
    );
  }
}
