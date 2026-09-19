# 多语言跟读

用 YouTube 视频做多语言跟读：播放、英文字幕同步、点词释义、整句翻译与句子复习。**macOS 桌面版功能最全**；另有 **Web** 演示（GitHub Pages）。

用户可见产品名在 `lib/app_branding.dart` 的 `kAppDisplayName`；Web / macOS 安装名见 `web/index.html`、`web/manifest.json`、`macos/Runner/Info.plist`（`CFBundleDisplayName`）。GitHub 仓库名为 `follow_friends`（Pages 路径 `/follow_friends/`）；Dart 包名仍为 `learn_mac`，不影响界面标题。

## 架构

- **UI**：`lib/features/player/youtube_learn_page.dart` 只做导航与 SnackBar；播放/字幕/查词状态在 `youtube_learn_controller.dart`。
- **播放与字幕**：`YoutubeRepository`（链接解析、流地址、英文字幕）+ `media_kit`；可选 `DownloadService`（youtubedr）。
- **释义**：`GlossService` 依次尝试 Enjoy API → 设置里的词典 Sidecar URL → `translator` 包。
- **Sidecar**：可选 Node 进程 `sidecar/dict_proxy.mjs`（本机 `lookup` HTTP），与 Flutter 进程独立，通过设置 URL 对接。
- **句子复习**：`SentenceReviewStore`（SQLite）；整句翻译成功时由页面写入。

## 运行

```bash
git clone https://github.com/wmsing/follow_friends.git
cd follow_friends
flutter pub get
flutter run -d macos
```

### Web（本地）

```bash
flutter pub get
dart run sqflite_common_ffi_web:setup   # 首次 / 升级 sqflite 后：生成 web/sqflite_sw.js
flutter run -d chrome
```

终端会打印 Dart 异常（例如插件未实现）；浏览器按 **F12 → Console** 看 JS / Flutter 报错。

模拟 GitHub Pages 子路径（与线上相同的 `/follow_friends/`）：

```bash
flutter build web --release --base-href "/follow_friends/"
mkdir -p /tmp/follow_friends_pages/follow_friends
cp -r build/web/* /tmp/follow_friends_pages/follow_friends/
cd /tmp/follow_friends_pages && python3 -m http.server 8080
```

浏览器打开 <http://localhost:8080/follow_friends/>（不要用根路径 `/`，否则资源 404、白屏）。

### GitHub Pages

公开仓库可免费使用 Pages。推送 `main` 后由 [`.github/workflows/deploy_web.yml`](.github/workflows/deploy_web.yml) 自动构建并发布。

1. 仓库 **Settings → Pages → Build and deployment → Source** 选 **GitHub Actions**。
2. 等 workflow 跑完后访问：<https://wmsing.github.io/follow_friends/>

本地与 CI 构建（项目页需带 base path）：

```bash
flutter build web --release --base-href "/follow_friends/"
```

**Web 限制**：浏览器 **无法** 直连 YouTube（CORS），网页版 **不能播放/拉字幕**（仅 UI 演示）。完整跟读请用 **macOS 桌面版**；也无法使用「下载后播放 / youtubedr」。若将来需要网页播放，须自建后端代理（本项目未包含）。

## 设置

- **在线流式**（默认）：`youtube_explode_dart` + `media_kit`
- **下载播放**（仅 macOS）：需安装 [youtubedr](https://github.com/kkdai/youtube)（`brew install youtubedr`）
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
