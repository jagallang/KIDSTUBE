import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../models/channel.dart';
import '../models/recommendation_weights.dart';
import '../core/base_provider.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/interfaces/i_storage_service.dart';
import '../core/cache_manager.dart';
import '../core/debug_logger.dart';
import 'channel_provider.dart';

/// Video provider with clean architecture and dependency injection
/// Manages video state without tight coupling to channel state
class VideoProvider extends CacheableProvider<List<Video>> {
  final IYouTubeService _youtubeService;
  final IStorageService _storageService;
  
  List<Video> _videos = [];
  ChannelProvider? _channelProvider;

  List<Video> get videos => List.unmodifiable(_videos);
  bool get hasVideos => _videos.isNotEmpty;

  VideoProvider({
    required IYouTubeService? youtubeService,
    required IStorageService storageService,
  }) : _youtubeService = youtubeService ?? _createDummyYouTubeService(),
       _storageService = storageService {
    // Use smart cache duration for video lists
    final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.videoList);
    setCacheTimeout(cacheDuration);
  }

  // v2.0.1: Create dummy YouTube service for null safety
  static IYouTubeService _createDummyYouTubeService() {
    // Return a dummy implementation that doesn't perform any operations
    return _DummyYouTubeService();
  }

  /// Set channel provider for reactive updates
  void setChannelProvider(ChannelProvider channelProvider) {
    _channelProvider = channelProvider;
    // Listen to channel updates and refresh videos accordingly
    _channelProvider?.addListener(_onChannelsChanged);
  }

  /// Handle channel changes
  void _onChannelsChanged() {
    DebugLogger.logFlow('VideoProvider._onChannelsChanged triggered', data: {
      'hasChannels': _channelProvider?.subscribedChannels.isNotEmpty ?? false,
      'channelCount': _channelProvider?.subscribedChannels.length ?? 0,
      'isCacheExpired': isCacheExpired
    });
    
    if (_channelProvider?.subscribedChannels.isNotEmpty ?? false) {
      if (isCacheExpired) {
        DebugLogger.logFlow('VideoProvider._onChannelsChanged: refreshing videos');
        refreshVideos();
      } else {
        DebugLogger.logFlow('VideoProvider._onChannelsChanged: cache still valid');
      }
    }
  }

  /// Load videos with proper state management
  Future<void> loadVideos() async {
    DebugLogger.logFlow('VideoProvider.loadVideos started');
    
    if (_channelProvider == null) {
      DebugLogger.logFlow('VideoProvider.loadVideos: channelProvider is null');
      _videos = [];
      notifyListeners();
      return;
    }
    
    if (_channelProvider!.subscribedChannels.isEmpty) {
      DebugLogger.logFlow('VideoProvider.loadVideos: no subscribed channels', data: {
        'channelCount': _channelProvider!.subscribedChannels.length
      });
      _videos = [];
      notifyListeners();
      return;
    }

    DebugLogger.logFlow('VideoProvider.loadVideos: starting video fetch', data: {
      'channelCount': _channelProvider!.subscribedChannels.length
    });

    await executeOperation<void>(
      () async {
        final weights = await _storageService.getRecommendationWeights();
        DebugLogger.logFlow('VideoProvider.loadVideos: got weights', data: {
          'totalWeight': weights.total,
          'korean': weights.korean,
          'kids': weights.kids
        });
        
        final videos = await _youtubeService.getWeightedRecommendedVideos(
          _channelProvider!.subscribedChannels, 
          weights,
        );
        
        DebugLogger.logFlow('VideoProvider.loadVideos: got videos', data: {
          'videoCount': videos.length
        });
        
        _videos = videos;
        updateCacheTimestamp();
      },
      errorPrefix: '영상을 불러오는데 실패했습니다',
    );
  }

  /// Refresh videos with pull-to-refresh
  Future<void> refreshVideos() async {
    if (_channelProvider == null || _channelProvider!.subscribedChannels.isEmpty) {
      _videos = [];
      notifyListeners();
      return;
    }

    await executeOperation<void>(
      () async {
        final weights = await _storageService.getRecommendationWeights();
        final videos = await _youtubeService.getWeightedRecommendedVideos(
          _channelProvider!.subscribedChannels, 
          weights,
        );
        
        _videos = videos;
        updateCacheTimestamp();
      },
      isRefresh: true,
      errorPrefix: '영상을 새로고침하는데 실패했습니다',
    );
  }

  /// Clear video cache
  void clearVideos() {
    _videos = [];
    updateCacheTimestamp();
    notifyListeners();
  }

  /// Force refresh ignoring cache
  Future<void> forceRefresh() async {
    setCacheTimeout(Duration.zero); // Force expiry
    await loadVideos();
    
    // Reset to smart cache duration
    final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.videoList);
    setCacheTimeout(cacheDuration);
  }

  /// Check if has channels (used by UI)
  bool get hasChannels => _channelProvider?.hasSubscribedChannels ?? false;

  @override
  void dispose() {
    _channelProvider?.removeListener(_onChannelsChanged);
    super.dispose();
  }
}

/// Dummy YouTube service for v2.0.1 backend-only architecture
class _DummyYouTubeService implements IYouTubeService {
  @override
  Future<bool> validateApiKey() async {
    return false; // Always return false since no API key
  }

  @override
  Future<List<Channel>> searchChannels(String query) async {
    return []; // Return empty list
  }

  @override
  Future<List<Video>> getChannelVideos(String uploadsPlaylistId, {String? pageToken}) async {
    return []; // Return empty list
  }

  @override
  Future<List<Video>> getWeightedRecommendedVideos(
    List<Channel> channels, 
    RecommendationWeights weights,
  ) async {
    try {
      // v2.0.1: 백엔드 API에서 비디오 가져오기
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/v1/videos'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final videosData = jsonData['data']['videos'] as List;
        
        List<Video> videos = videosData.map((videoJson) => Video.fromBackendApi(videoJson)).toList();
        
        return videos;
      } else {
        print('백엔드 API 호출 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('백엔드 API 호출 중 에러: $e');
      return [];
    }
  }

  @override
  Future<List<Channel>> getChannelDetails(List<String> channelIds) async {
    return []; // Return empty list
  }
}