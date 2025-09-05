import '../models/video.dart';
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
  bool _isLoadingMore = false;
  bool _hasMoreVideos = true;

  List<Video> get videos => List.unmodifiable(_videos);
  bool get hasVideos => _videos.isNotEmpty;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreVideos => _hasMoreVideos;

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
      _hasMoreVideos = true;
      notifyListeners();
      return;
    }
    
    if (_channelProvider!.subscribedChannels.isEmpty) {
      DebugLogger.logFlow('VideoProvider.loadVideos: no subscribed channels', data: {
        'channelCount': _channelProvider!.subscribedChannels.length
      });
      _videos = [];
      _hasMoreVideos = true;
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
        _hasMoreVideos = videos.isNotEmpty; // 초기 로드에서 비디오가 있으면 더 많은 비디오가 있다고 가정
        updateCacheTimestamp();
      },
      errorPrefix: '영상을 불러오는데 실패했습니다',
    );
  }

  /// Load more videos for infinite scroll
  Future<void> loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreVideos || _channelProvider == null) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      DebugLogger.logFlow('VideoProvider.loadMoreVideos started', data: {
        'currentVideoCount': _videos.length,
        'channelCount': _channelProvider!.subscribedChannels.length
      });
      
      final weights = await _storageService.getRecommendationWeights();
      
      // 각 채널에서 추가 비디오를 개별적으로 가져와서 더 다양한 콘텐츠 제공
      List<Video> newVideos = [];
      final channels = _channelProvider!.subscribedChannels;
      
      for (final channel in channels) {
        try {
          final channelVideos = await _youtubeService.getChannelVideos(
            channel.uploadsPlaylistId,
            pageToken: null, // 실제로는 페이지 토큰을 관리해야 하지만 간단한 구현으로 시작
          );
          
          // 기존 비디오와 중복되지 않는 새로운 비디오만 추가
          final existingVideoIds = _videos.map((v) => v.id).toSet();
          final uniqueChannelVideos = channelVideos
              .where((video) => !existingVideoIds.contains(video.id))
              .take(2) // 각 채널에서 최대 2개씩만 가져오기
              .toList();
          
          newVideos.addAll(uniqueChannelVideos);
          
          // 너무 많은 API 호출을 방지하기 위해 최대 10개까지만
          if (newVideos.length >= 10) break;
        } catch (e) {
          DebugLogger.logError('VideoProvider.loadMoreVideos: failed to load from channel ${channel.title}', e);
          continue;
        }
      }
      
      if (newVideos.isNotEmpty) {
        // 비디오를 셔플하여 다양성 제공
        newVideos.shuffle();
        _videos.addAll(newVideos);
        
        DebugLogger.logFlow('VideoProvider.loadMoreVideos: added new videos', data: {
          'newVideoCount': newVideos.length,
          'totalVideoCount': _videos.length
        });
      } else {
        // 새로운 고유 비디오가 없으면 더 이상 로드할 비디오가 없다고 표시
        _hasMoreVideos = false;
        DebugLogger.logFlow('VideoProvider.loadMoreVideos: no more unique videos available');
      }
      
      notifyListeners();
    } catch (e) {
      DebugLogger.logError('VideoProvider.loadMoreVideos failed', e);
      // 에러가 발생해도 더 많은 비디오 로드를 계속 시도할 수 있도록 함
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh videos with pull-to-refresh
  Future<void> refreshVideos() async {
    if (_channelProvider == null || _channelProvider!.subscribedChannels.isEmpty) {
      _videos = [];
      _hasMoreVideos = true;
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
        _hasMoreVideos = videos.isNotEmpty; // 새로고침 후 더 많은 비디오를 로드할 수 있도록 리셋
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