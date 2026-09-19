import 'package:flutter_test/flutter_test.dart';
import 'package:learn_mac/models/channel_listing.dart';

void main() {
  test('ChannelListing json roundtrip with null and non-null duration', () {
    const listing = ChannelListing(
      channelTitle: 'Friends',
      videos: [
        ChannelVideoItem(
          videoId: 'abc',
          title: 'Pilot',
          watchUrl: 'https://www.youtube.com/watch?v=abc',
          thumbnailUrl: 'https://i.ytimg.com/vi/abc/mqdefault.jpg',
          duration: Duration(minutes: 22, seconds: 30),
        ),
        ChannelVideoItem(
          videoId: 'def',
          title: 'No duration',
          watchUrl: 'https://www.youtube.com/watch?v=def',
        ),
      ],
    );

    final restored = ChannelListing.fromJson(listing.toJson());
    expect(restored.channelTitle, listing.channelTitle);
    expect(restored.videos.length, 2);
    expect(restored.videos[0].duration, const Duration(minutes: 22, seconds: 30));
    expect(restored.videos[0].thumbnailUrl, listing.videos[0].thumbnailUrl);
    expect(restored.videos[1].duration, isNull);
    expect(restored.videos[1].thumbnailUrl, isNull);
  });
}
