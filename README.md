# 多语言跟读

用 YouTube 视频做多语言跟读：播放、英文字幕同步、预习选词、点词释义、整句翻译与句子复习。**目标平台：macOS 桌面版。**

用户可见产品名在 `lib/app_branding.dart` 的 `kAppDisplayName`；macOS 应用包名为 `follow_friends.app`（见 `macos/Runner/Configs/AppInfo.xcconfig`）。GitHub 仓库：[follow_friends](https://github.com/wmsing/follow_friends)；Dart 包名仍为 `learn_mac`。

## macOS 安装（发布版）

1. 打开 [Releases](https://github.com/wmsing/follow_friends/releases)，下载最新 `follow_friends-macos-*.zip`。
2. 解压后将 `follow_friends.app` 拖入「应用程序」或任意目录。
3. 首次打开若被 Gatekeeper 拦截：系统设置 → 隐私与安全性 → 仍要打开；或在 Finder 中右键应用 → 打开。
4. 需要网络访问 YouTube 与翻译服务；本机数据（句子复习、预习标记）保存在用户文档目录下的 SQLite 库中。

从源码自行打包：

```bash
flutter build macos --release
# 产物：build/macos/Build/Products/Release/follow_friends.app
```

## 使用

1. **加载视频**：粘贴 YouTube 链接，点「播放」。加载完成后默认**暂停**，便于先预习。
2. **预习选词**（AppBar「预习选词」）：全文英文字幕列表中点选或拖选词组（橙线下划线 + 中文释义）；标记按视频保存，下次打开同一视频会自动载入。顶栏「开始播放」返回主界面并播放；「清空标记」删除本视频全部预习记录。
3. **播放学习**：空格切换播放/暂停。当前句在底部歌词区与画面底部叠层显示英文；若该句有预习标记，标记词会显示中文释义（橙线 = 预习，播放时点词查词为另一套交互）。
4. **点词释义**：播放中点击底部字幕中的单词，会定位到该句并显示释义（Enjoy / Sidecar / 在线翻译，见设置）。
5. **整句翻译**：每行右侧翻译图标；成功后可写入「句子重温」。
6. **句子重温**：AppBar 书本图标，浏览已保存句子并跳回对应视频时间点。
7. **频道**：左下角浮钮，从频道列表选视频。

快捷键：**空格** = 播放/暂停（焦点不在链接输入框时）。

## 架构

- **UI**：`lib/features/player/youtube_learn_page.dart` 导航；播放/字幕/查词/预习状态在 `youtube_learn_controller.dart`。
- **播放与字幕**：`YoutubeRepository` + `media_kit`；可选 `DownloadService`（youtubedr）。
- **释义**：`GlossService` → Enjoy API → 词典 Sidecar → `translator`。
- **预习标记**：`StudyMarkStore`（SQLite `learn_mac_study_marks.db`），按 `videoId` + 合并句下标持久化。
- **句子复习**：`SentenceReviewStore`（SQLite）；整句翻译成功时写入。

## 开发运行

```bash
git clone https://github.com/wmsing/follow_friends.git
cd follow_friends
flutter pub get
flutter run -d macos
```

## 设置

- **在线流式**（默认）：`youtube_explode_dart` + `media_kit`
- **下载播放**：需安装 [youtubedr](https://github.com/kkdai/youtube)（`brew install youtubedr`）
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
