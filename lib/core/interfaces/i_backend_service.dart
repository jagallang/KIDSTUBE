import '../../models/user.dart';
import '../../models/family.dart';
import '../../models/auth_response.dart';
import '../../models/video.dart';
import '../../models/channel.dart';

abstract class IBackendService {
  // Authentication
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String familyName,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AuthResponse?> refreshToken();

  // Family management
  Future<Family> getFamily();
  
  Future<Family> updateFamily({
    String? name,
    Map<String, dynamic>? settings,
  });

  Future<User> addFamilyMember({
    required String email,
    required String name,
    required String password,
    String? pin,
  });

  Future<void> removeFamilyMember(String userId);

  // Content management
  Future<List<Channel>> searchChannels(String query);
  
  Future<void> subscribeToChannel({
    required String channelId,
    required String channelTitle,
    String? channelThumbnail,
    String? channelDescription,
  });

  Future<void> unsubscribeFromChannel(String channelId);

  Future<List<Channel>> getSubscriptions();

  // Video feed
  Future<List<Video>> getFeed({
    int page = 1,
    int perPage = 20,
  });

  Future<List<Video>> getTrendingVideos();

  // Watch history
  Future<void> recordWatchHistory({
    required String videoId,
    required int durationSeconds,
    DateTime? watchedAt,
  });

  Future<List<Map<String, dynamic>>> getWatchHistory({
    int page = 1,
    int perPage = 50,
  });

  // Statistics
  Future<Map<String, dynamic>> getWatchStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  // Content blocking
  Future<void> blockContent({
    required String contentType, // 'keyword', 'channel', 'video'
    required String value,
    String? reason,
  });
}