class ChannelListing {
  const ChannelListing({
    required this.channelTitle,
    required this.videos,
  });

  final String channelTitle;
  final List<ChannelVideoItem> videos;
}

class ChannelVideoItem {
  const ChannelVideoItem({
    required this.videoId,
    required this.title,
    required this.watchUrl,
    this.thumbnailUrl,
    this.duration,
  });

  final String videoId;
  final String title;
  final String watchUrl;
  final String? thumbnailUrl;
  final Duration? duration;
}
