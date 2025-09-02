import '../models/video.dart';
import '../core/base_provider.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/interfaces/i_storage_service.dart';
import '../core/cache_manager.dart';
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
    required IYouTubeService youtubeService,
    required IStorageService storageService,
  }) : _youtubeService = youtubeService,
       _storageService = storageService {
    // Use smart cache duration for video lists
    final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.videoList);
    setCacheTimeout(cacheDuration);
  }

  /// Set channel provider for reactive updates
  void setChannelProvider(ChannelProvider channelProvider) {
    _channelProvider = channelProvider;
    // Listen to channel updates and refresh videos accordingly
    _channelProvider?.addListener(_onChannelsChanged);
  }

  /// Handle channel changes
  void _onChannelsChanged() {
    if (_channelProvider?.subscribedChannels.isNotEmpty ?? false) {
      if (isCacheExpired) {
        refreshVideos();
      }
    }
  }

  /// Load videos with proper state management
  Future<void> loadVideos() async {
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