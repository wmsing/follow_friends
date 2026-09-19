import 'package:flutter/material.dart';

import '../../models/saved_sentence.dart';
import '../../services/sentence_review_store.dart';

const _glossBlue = Color(0xFF1565C0);

class SentenceReviewPage extends StatefulWidget {
  const SentenceReviewPage({super.key, required this.store});

  final SentenceReviewStore store;

  @override
  State<SentenceReviewPage> createState() => _SentenceReviewPageState();
}

class _SentenceReviewPageState extends State<SentenceReviewPage> {
  final _searchController = TextEditingController();
  List<SavedSentence> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final items = await widget.store.list(query: _searchController.text);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _cueRangeLabel(SavedSentence item) {
    return '${_formatDuration(item.cueStart)}–${_formatDuration(item.cueEnd)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('句子重温')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索英文、中文或视频标题',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _reload,
                ),
              ),
              onSubmitted: (_) => _reload(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            '还没有保存的句子，播放时点右侧翻译图标',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final seg = item.cueSegmentDuration;
                          final videoDur = item.videoDurationMs != null
                              ? Duration(milliseconds: item.videoDurationMs!)
                              : null;
                          return ListTile(
                            title: Text(
                              item.englishText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  item.chineseText,
                                  style: const TextStyle(
                                    color: _glossBlue,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item.videoTitle} · ${_cueRangeLabel(item)}'
                                  '${seg.inSeconds > 0 ? ' (${_formatDuration(seg)})' : ''}'
                                  '${videoDur != null ? ' · 视频 ${_formatDuration(videoDur)}' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => Navigator.pop(context, item),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (item.id == null) return;
                                await widget.store.delete(item.id!);
                                await _reload();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
