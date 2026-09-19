import 'package:flutter/material.dart';

import '../../../models/channel_listing.dart';
import '../../../services/youtube_repository.dart';

class ChannelPickerSheet extends StatefulWidget {
  const ChannelPickerSheet({
    super.key,
    required this.youtube,
    required this.onVideoSelected,
  });

  final YoutubeRepository youtube;
  final void Function(String watchUrl) onVideoSelected;

  static Future<void> show(
    BuildContext context, {
    required YoutubeRepository youtube,
    required void Function(String watchUrl) onVideoSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: ChannelPickerSheet(
          youtube: youtube,
          onVideoSelected: onVideoSelected,
        ),
      ),
    );
  }

  @override
  State<ChannelPickerSheet> createState() => _ChannelPickerSheetState();
}

class _ChannelPickerSheetState extends State<ChannelPickerSheet> {
  final _channelController = TextEditingController(
    text: 'https://www.youtube.com/@Friends',
  );

  bool _loading = false;
  String? _error;
  ChannelListing? _listing;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _listing = null;
    });

    try {
      final listing =
          await widget.youtube.fetchChannelVideos(_channelController.text);
      if (!mounted) return;
      setState(() => _listing = listing);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null || d.inSeconds <= 0) return '';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _subtitle(ChannelVideoItem video) {
    final parts = <String>[];
    final dur = _formatDuration(video.duration);
    if (dur.isNotEmpty) parts.add(dur);
    if (parts.isEmpty) return video.videoId;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _channelController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube 频道',
                    hintText: 'https://www.youtube.com/@Friends',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _load,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('加载'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: TextStyle(color: Colors.red[700])),
          ),
        if (_listing != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _listing!.channelTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        Expanded(
          child: _listing == null
              ? Center(
                  child: Text(
                    '输入频道链接后点加载',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _listing!.videos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final video = _listing!.videos[index];
                    return ListTile(
                      leading: video.thumbnailUrl == null
                          ? const Icon(Icons.play_circle_outline)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                video.thumbnailUrl!,
                                width: 88,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                      title: Text(
                        video.title.isNotEmpty ? video.title : video.videoId,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_subtitle(video)),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onVideoSelected(video.watchUrl);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
