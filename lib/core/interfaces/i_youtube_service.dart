import '../../models/channel.dart';
import '../../models/video.dart';
import '../../models/recommendation_weights.dart';

/// Interface for YouTube service following dependency inversion principle
abstract class IYouTubeService {
  /// Validates the API key
  Future<bool> validateApiKey();

  /// Searches for channels based on query
  Future<List<Channel>> searchChannels(String query);

  /// Gets videos from a channel's uploads playlist
  Future<List<Video>> getChannelVideos(String uploadsPlaylistId, {String? pageToken});

  /// Gets weighted recommended videos based on channels and weights
  Future<List<Video>> getWeightedRecommendedVideos(
    List<Channel> channels, 
    RecommendationWeights weights,
  );

  /// Gets channel details by IDs
  Future<List<Channel>> getChannelDetails(List<String> channelIds);
}