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
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  MediaKit.ensureInitialized();
  final settings = await AppSettings.load();
  final sentenceStore = await SentenceReviewStore.open();
  runApp(LearnMacApp(settings: settings, sentenceStore: sentenceStore));
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
