class ChannelListing {
  const ChannelListing({
    required this.channelTitle,
    required this.videos,
  });

  final String channelTitle;
  final List<ChannelVideoItem> videos;

  Map<String, dynamic> toJson() => {
        'channelTitle': channelTitle,
        'videos': videos.map((v) => v.toJson()).toList(),
      };

  factory ChannelListing.fromJson(Map<String, dynamic> json) {
    final rawVideos = json['videos'] as List<dynamic>? ?? [];
    return ChannelListing(
      channelTitle: json['channelTitle'] as String? ?? '',
      videos: rawVideos
          .map((e) => ChannelVideoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
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

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'watchUrl': watchUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (duration != null) 'durationMs': duration!.inMilliseconds,
      };

  factory ChannelVideoItem.fromJson(Map<String, dynamic> json) {
    final ms = json['durationMs'] as int?;
    return ChannelVideoItem(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      watchUrl: json['watchUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: ms != null ? Duration(milliseconds: ms) : null,
    );
  }
}
