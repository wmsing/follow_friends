import 'package:flutter/material.dart';

import '../../../services/app_settings.dart';

class LearnSettingsDialog {
  static Future<void> show(BuildContext context, AppSettings settings) {
    final mode = settings.playbackMode;
    final enjoyToken = settings.enjoyApiToken ?? '';
    final sidecar = settings.dictSidecarUrl ?? '';

    return showDialog<void>(
      context: context,
      builder: (context) {
        var localMode = mode;
        final tokenCtrl = TextEditingController(text: enjoyToken);
        final sidecarCtrl = TextEditingController(text: sidecar);

        return AlertDialog(
          title: const Text('设置'),
          content: StatefulBuilder(
            builder: (context, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('播放模式'),
                RadioListTile<PlaybackMode>(
                  title: const Text('在线流式（默认）'),
                  value: PlaybackMode.online,
                  groupValue: localMode,
                  onChanged: (v) => setLocal(() => localMode = v!),
                ),
                RadioListTile<PlaybackMode>(
                  title: const Text('下载后播放'),
                  value: PlaybackMode.download,
                  groupValue: localMode,
                  onChanged: (v) => setLocal(() => localMode = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enjoy API Token（可选）',
                  ),
                ),
                TextField(
                  controller: sidecarCtrl,
                  decoration: const InputDecoration(
                    labelText: '词典 Sidecar URL（可选）',
                    hintText: 'http://127.0.0.1:3847/lookup',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await settings.setPlaybackMode(localMode);
                await settings.setEnjoyApiToken(
                  tokenCtrl.text.trim().isEmpty ? null : tokenCtrl.text.trim(),
                );
                await settings.setDictSidecarUrl(
                  sidecarCtrl.text.trim().isEmpty
                      ? null
                      : sidecarCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}
