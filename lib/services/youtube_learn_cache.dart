import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel_listing.dart';

class YoutubeLearnCache {
  YoutubeLearnCache(this._prefs);

  final SharedPreferences _prefs;

  static const _lastWatchUrlKey = 'youtube_learn_last_watch_url';
  static const _channelInputKey = 'youtube_learn_channel_input';
  static const _channelListingKey = 'youtube_learn_channel_listing';

  static YoutubeLearnCache? _instance;

  static Future<YoutubeLearnCache> load() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = YoutubeLearnCache(prefs);
    return _instance!;
  }

  String? get lastWatchUrl => _prefs.getString(_lastWatchUrlKey);

  Future<void> setLastWatchUrl(String url) {
    return _prefs.setString(_lastWatchUrlKey, url.trim());
  }

  ({String? channelInput, ChannelListing? listing}) loadChannelCache() {
    final input = _prefs.getString(_channelInputKey);
    final raw = _prefs.getString(_channelListingKey);
    if (raw == null || raw.isEmpty) {
      return (channelInput: input, listing: null);
    }
    try {
      final listing =
          ChannelListing.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return (channelInput: input, listing: listing);
    } catch (_) {
      return (channelInput: input, listing: null);
    }
  }

  Future<void> saveChannelListing(String input, ChannelListing listing) {
    return Future.wait([
      _prefs.setString(_channelInputKey, input.trim()),
      _prefs.setString(_channelListingKey, jsonEncode(listing.toJson())),
    ]);
  }
}
