import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Wraps youtubedr (same CLI as Enjoy) for optional offline playback.
class DownloadService {
  DownloadService({String? youtubedrPath}) : _youtubedrPath = youtubedrPath;

  final String? _youtubedrPath;

  Future<String> resolveYoutubedrBinary() async {
    if (_youtubedrPath != null && await File(_youtubedrPath).exists()) {
      return _youtubedrPath;
    }

    final which = await Process.run('which', ['youtubedr']);
    if (which.exitCode == 0) {
      final path = (which.stdout as String).trim();
      if (path.isNotEmpty) return path;
    }

    final repoRelative = p.normalize(
      p.join(
        Directory.current.path,
        '..',
        'enjoy',
        'lib',
        'youtubedr',
        'youtubedr',
      ),
    );
    if (await File(repoRelative).exists()) return repoRelative;

    throw StateError(
      '未找到 youtubedr。请 brew install youtubedr，或将二进制放到 enjoy/lib/youtubedr/',
    );
  }

  Future<String> downloadVideo(
    String url, {
    void Function(int percent)? onProgress,
  }) async {
    final bin = await resolveYoutubedrBinary();
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(dir.path, 'learn_mac_downloads'));
    await downloadDir.create(recursive: true);

    final videoId = Uri.parse(url).queryParameters['v'] ??
        url.split('/').last.split('?').first;
    final filename = 'video_$videoId.mp4';
    final outPath = p.join(downloadDir.path, filename);

    if (await File(outPath).exists()) {
      final size = await File(outPath).length();
      if (size > 0) return outPath;
    }

    final process = await Process.start(bin, [
      'download',
      url,
      '--quality=medium',
      '--filename=$filename',
      '--directory=${downloadDir.path}',
    ]);

    process.stdout.transform(utf8.decoder).listen((chunk) {
      final match = RegExp(r'iB (\d+) %').firstMatch(chunk);
      if (match != null) {
        onProgress?.call(int.parse(match.group(1)!));
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('youtubedr 下载失败 (exit $exitCode)');
    }

    if (!await File(outPath).exists()) {
      throw StateError('下载完成但找不到文件: $outPath');
    }
    return outPath;
  }
}
