# Learn Mac — Flutter YouTube 学英语

粘贴 YouTube 链接播放；底部显示当前英文字幕；点词下划线并显示中文释义。

## 架构

- **UI**：`lib/features/player/youtube_learn_page.dart` 只做导航与 SnackBar；播放/字幕/查词状态在 `youtube_learn_controller.dart`。
- **播放与字幕**：`YoutubeRepository`（链接解析、流地址、英文字幕）+ `media_kit`；可选 `DownloadService`（youtubedr）。
- **释义**：`GlossService` 依次尝试 Enjoy API → 设置里的词典 Sidecar URL → `translator` 包。
- **Sidecar**：可选 Node 进程 `sidecar/dict_proxy.mjs`（本机 `lookup` HTTP），与 Flutter 进程独立，通过设置 URL 对接。
- **句子复习**：`SentenceReviewStore`（SQLite）；整句翻译成功时由页面写入。

## 运行

```bash
cd learn_mac
flutter pub get
flutter run -d macos
```

## 设置

- **在线流式**（默认）：`youtube_explode_dart` + `media_kit`
- **下载播放**：需安装 [youtubedr](https://github.com/kkdai/youtube)（`brew install youtubedr`），与 Enjoy 相同 CLI
- **Enjoy 查词**：在设置中填写 Enjoy API Token
- **词典 Sidecar**（可选）：

```bash
ENJOY_API_TOKEN=your_token node sidecar/dict_proxy.mjs
```

在 App 设置里填 `http://127.0.0.1:3847/lookup`

## 自检

```bash
flutter analyze
flutter test
```

## 联调视频

默认输入框已填入测试链接：  
https://www.youtube.com/watch?v=Dq4RqWNRoN4

有网络时跑集成测试：

```bash
flutter test --dart-define=RUN_YOUTUBE_INTEGRATION=true test/youtube_integration_test.dart
```
