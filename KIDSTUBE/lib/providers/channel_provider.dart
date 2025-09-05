import '../models/channel.dart';
import '../core/base_provider.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/interfaces/i_storage_service.dart';
import '../core/cache_manager.dart';
import '../core/debug_logger.dart';

/// Channel provider with clean architecture and dependency injection
/// Manages channel subscriptions and search functionality
class ChannelProvider extends CacheableProvider<List<Channel>> {
  final IYouTubeService _youtubeService;
  final IStorageService _storageService;
  
  List<Channel> _subscribedChannels = [];
  List<Channel> _searchResults = [];
  bool _isSearching = false;

  List<Channel> get subscribedChannels => List.unmodifiable(_subscribedChannels);
  List<Channel> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  bool get hasSubscribedChannels => _subscribedChannels.isNotEmpty;

  ChannelProvider({
    required IYouTubeService youtubeService,
    required IStorageService storageService,
  }) : _youtubeService = youtubeService,
       _storageService = storageService {
    // Use smart cache duration for user subscriptions
    final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.userSubscriptions);
    setCacheTimeout(cacheDuration);
  }

  /// Load subscribed channels
  Future<void> loadSubscribedChannels() async {
    await executeOperation<void>(
      () async {
        _subscribedChannels = await _storageService.loadChannels();
        DebugLogger.logFlow('ChannelProvider.loadSubscribedChannels: channels loaded', data: {
          'channelCount': _subscribedChannels.length,
          'channelTitles': _subscribedChannels.map((c) => c.title).toList(),
          'channelCategories': _subscribedChannels.map((c) => c.category).toList()
        });
        
        // 임시 수정: title이 비어있는 채널들을 수정
        bool needsUpdate = false;
        List<Channel> updatedChannels = [];
        
        for (Channel channel in _subscribedChannels) {
          if (channel.title.isEmpty) {
            DebugLogger.logFlow('ChannelProvider: Found channel with empty title, attempting to refresh', data: {
              'channelId': channel.id
            });
            needsUpdate = true;
            // 채널 상세 정보를 다시 가져와서 업데이트
            try {
              final details = await _youtubeService.getChannelDetails([channel.id]);
              if (details.isNotEmpty && details.first.title.isNotEmpty) {
                updatedChannels.add(details.first);
                DebugLogger.logFlow('ChannelProvider: Successfully updated channel title', data: {
                  'channelId': channel.id,
                  'newTitle': details.first.title
                });
              } else {
                updatedChannels.add(channel);
              }
            } catch (e) {
              DebugLogger.logError('ChannelProvider: Failed to refresh channel', e);
              updatedChannels.add(channel);
            }
          } else {
            updatedChannels.add(channel);
          }
        }
        
        if (needsUpdate) {
          _subscribedChannels = updatedChannels;
          await _storageService.storeChannels(_subscribedChannels);
          DebugLogger.logFlow('ChannelProvider: Updated channels saved', data: {
            'updatedCount': _subscribedChannels.length,
            'channelTitles': _subscribedChannels.map((c) => c.title).toList()
          });
        }
        
        updateCacheTimestamp();
      },
      errorPrefix: '구독 채널을 불러오는데 실패했습니다',
    );
  }

  /// Search channels with filtering
  Future<void> searchChannels(String query) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final results = await _youtubeService.searchChannels(query);
      
      // Filter channels with less than 10k subscribers
      _searchResults = results.where((channel) {
        final subscribers = _parseSubscriberCount(channel.subscriberCount);
        return subscribers >= 10000;
      }).toList();
      
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _isSearching = false;
      setError('채널 검색에 실패했습니다: ${e.toString()}');
      _searchResults.clear();
    }
  }

  /// Subscribe to a channel
  Future<void> subscribeToChannel(Channel channel) async {
    await executeOperation<void>(
      () async {
        // Check if already subscribed
        if (_subscribedChannels.any((c) => c.id == channel.id)) {
          return;
        }

        DebugLogger.logFlow('ChannelProvider.subscribeToChannel: Adding channel', data: {
          'channelId': channel.id,
          'title': channel.title,
          'thumbnail': channel.thumbnail.isEmpty ? 'EMPTY' : 'OK',
          'subscriberCount': channel.subscriberCount,
          'category': channel.category
        });

        final updatedChannels = [..._subscribedChannels, channel];
        await _storageService.storeChannels(updatedChannels);
        
        _subscribedChannels = updatedChannels;
        updateCacheTimestamp();
      },
      showLoading: false,
      errorPrefix: '채널 구독에 실패했습니다',
    );
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribeFromChannel(String channelId) async {
    await executeOperation<void>(
      () async {
        final updatedChannels = _subscribedChannels
            .where((c) => c.id != channelId)
            .toList();
        
        await _storageService.storeChannels(updatedChannels);
        
        _subscribedChannels = updatedChannels;
        updateCacheTimestamp();
      },
      showLoading: false,
      errorPrefix: '채널 구독 해제에 실패했습니다',
    );
  }

  /// Check if subscribed to a channel
  bool isSubscribed(String channelId) {
    return _subscribedChannels.any((channel) => channel.id == channelId);
  }

  /// Get channels by category
  List<Channel> getChannelsByCategory(String category) {
    return _subscribedChannels
        .where((channel) => channel.category == category)
        .toList();
  }

  /// Get category counts
  Map<String, int> getCategoryCounts() {
    const categories = [
      '한글', '키즈', '만들기', '게임', '영어', 
      '과학', '미술', '음악', '랜덤'
    ];
    
    final counts = <String, int>{};
    for (final category in categories) {
      counts[category] = getChannelsByCategory(category).length;
    }
    
    return counts;
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults.clear();
    _isSearching = false;
    notifyListeners();
  }

  /// Parse subscriber count from formatted string
  int _parseSubscriberCount(String subscriberCountStr) {
    final cleanedStr = subscriberCountStr.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanedStr.isEmpty) return 0;

    final value = double.tryParse(cleanedStr) ?? 0;
    
    if (subscriberCountStr.toLowerCase().contains('m')) {
      return (value * 1000000).toInt();
    } else if (subscriberCountStr.toLowerCase().contains('k')) {
      return (value * 1000).toInt();
    } else {
      return value.toInt();
    }
  }

  /// Refresh subscribed channels
  Future<void> refreshSubscribedChannels() async {
    setCacheTimeout(Duration.zero); // Force expiry
    await loadSubscribedChannels();
    
    // Reset to smart cache duration
    final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.userSubscriptions);
    setCacheTimeout(cacheDuration);
  }
}