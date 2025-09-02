import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/interfaces/i_storage_service.dart';
import '../core/cache_manager.dart';
import '../core/cache_analytics.dart';
import '../services/cloud_backup_service.dart';

/// Background refresh manager for smart cache updates
/// Refreshes data based on usage patterns and network conditions
class BackgroundRefreshManager {
  final IYouTubeService _youtubeService;
  final IStorageService _storageService;
  final CloudBackupService? _backupService;
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  Timer? _backupTimer;
  
  BackgroundRefreshManager({
    required IYouTubeService youtubeService,
    required IStorageService storageService,
    CloudBackupService? backupService,
  }) : _youtubeService = youtubeService,
       _storageService = storageService,
       _backupService = backupService;

  /// Start background refresh with smart scheduling
  void startBackgroundRefresh() {
    // Initial delay before first refresh (avoid startup congestion)
    _refreshTimer = Timer(const Duration(minutes: 2), () {
      _performBackgroundRefresh();
      
      // Schedule periodic refreshes (every 30 minutes)
      _refreshTimer = Timer.periodic(
        const Duration(minutes: 30),
        (_) => _performBackgroundRefresh(),
      );
    });
    
    // Start auto backup timer (every 6 hours)
    if (_backupService != null) {
      _backupTimer = Timer(const Duration(minutes: 10), () {
        _backupService!.autoBackupIfNeeded();
        
        _backupTimer = Timer.periodic(
          const Duration(hours: 6),
          (_) => _backupService!.autoBackupIfNeeded(),
        );
      });
    }
  }

  /// Stop background refresh
  void stopBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _backupTimer?.cancel();
    _backupTimer = null;
    _isRefreshing = false;
  }

  /// Check if background refresh is active
  bool get isRefreshing => _isRefreshing;

  /// Perform smart background refresh
  Future<void> _performBackgroundRefresh() async {
    if (_isRefreshing) return;
    
    try {
      _isRefreshing = true;
      
      // Check network conditions
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        print('Background refresh skipped: No network connection');
        return;
      }

      // Check if on mobile data (be more conservative)
      final isWifi = connectivityResults.contains(ConnectivityResult.wifi);
      final maxRefreshItems = isWifi ? 10 : 3;

      print('Starting background refresh (${isWifi ? 'WiFi' : 'Mobile'} connection)');

      // Get subscribed channels
      final channels = await _storageService.loadChannels();
      if (channels.isEmpty) return;

      // Get high-priority channels for refresh
      final priorityChannels = await _getPriorityChannels(channels, maxRefreshItems);
      
      if (priorityChannels.isEmpty) {
        print('No channels need background refresh');
        return;
      }

      print('Refreshing ${priorityChannels.length} priority channels');

      // Refresh channels with staggered delays to avoid API rate limits
      await _refreshChannelsWithDelay(priorityChannels, isWifi);

      print('Background refresh completed successfully');

    } catch (e) {
      print('Background refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Get priority channels based on usage and freshness
  Future<List<Channel>> _getPriorityChannels(List<Channel> channels, int maxItems) async {
    final channelPriorities = <ChannelPriority>[];

    for (final channel in channels) {
      final priority = await _calculateChannelPriority(channel);
      if (priority.shouldRefresh) {
        channelPriorities.add(priority);
      }
    }

    // Sort by priority score (highest first)
    channelPriorities.sort((a, b) => b.score.compareTo(a.score));

    // Return top priority channels
    return channelPriorities
        .take(maxItems)
        .map((p) => p.channel)
        .toList();
  }

  /// Calculate refresh priority for a channel
  Future<ChannelPriority> _calculateChannelPriority(Channel channel) async {
    int score = 0;
    bool shouldRefresh = false;

    try {
      // Check cache age and analytics for this channel
      final cacheKey = SmartCacheManager.getCacheKey(CacheType.videoList, channel.uploadsPlaylistId);
      final lastUpdate = await _getCacheTimestamp(cacheKey);
      final viewCount = await CacheAnalytics.getAccessFrequency(cacheKey);
      final analyticsPriority = await CacheAnalytics.calculatePriorityScore(cacheKey);
      
      if (lastUpdate != null) {
        final age = DateTime.now().difference(lastUpdate);
        final subscriberCount = _parseSubscriberCount(channel.subscriberCount);
        
        // Check if should refresh based on cache manager logic
        shouldRefresh = SmartCacheManager.shouldBackgroundRefresh(
          lastUpdate,
          CacheType.videoList,
          viewCount,
        );

        if (shouldRefresh) {
          // Calculate combined priority score
          score += _calculatePriorityScore(age, subscriberCount, viewCount);
          // Add analytics-based priority (25% weight)
          score += (analyticsPriority * 0.25).round();
        }
      } else {
        // No cache exists, high priority for initial load
        shouldRefresh = true;
        score = 100;
      }

    } catch (e) {
      print('Error calculating priority for channel ${channel.id}: $e');
      shouldRefresh = false;
      score = 0;
    }

    return ChannelPriority(
      channel: channel,
      score: score,
      shouldRefresh: shouldRefresh,
    );
  }

  /// Calculate priority score based on various factors
  int _calculatePriorityScore(Duration age, int subscriberCount, int viewCount) {
    int score = 0;
    
    // Age factor (older cache = higher priority)
    final hoursOld = age.inHours;
    if (hoursOld >= 12) score += 50;
    else if (hoursOld >= 6) score += 30;
    else if (hoursOld >= 3) score += 10;
    
    // Subscriber count factor (popular channels = higher priority)
    if (subscriberCount >= 5000000) score += 30;
    else if (subscriberCount >= 1000000) score += 20;
    else if (subscriberCount >= 100000) score += 10;
    
    // View count factor (frequently accessed = higher priority)
    if (viewCount >= 20) score += 25;
    else if (viewCount >= 10) score += 15;
    else if (viewCount >= 5) score += 5;
    
    return score;
  }

  /// Refresh channels with staggered delays
  Future<void> _refreshChannelsWithDelay(List<Channel> channels, bool isWifi) async {
    final delayBetweenRequests = isWifi 
        ? const Duration(seconds: 2)  // Faster on WiFi
        : const Duration(seconds: 5); // Slower on mobile data

    for (int i = 0; i < channels.length; i++) {
      if (!_isRefreshing) break; // Stop if refresh was cancelled
      
      try {
        final channel = channels[i];
        await _refreshSingleChannel(channel);
        
        // Add delay between requests (except for last item)
        if (i < channels.length - 1) {
          await Future.delayed(delayBetweenRequests);
        }
        
      } catch (e) {
        print('Error refreshing channel ${channels[i].id}: $e');
      }
    }
  }

  /// Refresh a single channel's videos
  Future<void> _refreshSingleChannel(Channel channel) async {
    try {
      print('Background refreshing channel: ${channel.title}');
      
      // Fetch fresh videos for this channel
      final videos = await _youtubeService.getChannelVideos(channel.uploadsPlaylistId);
      
      if (videos.isNotEmpty) {
        print('Refreshed ${videos.length} videos for ${channel.title}');
      }
      
    } catch (e) {
      print('Failed to refresh channel ${channel.title}: $e');
      rethrow;
    }
  }

  /// Get cache timestamp for a key
  Future<DateTime?> _getCacheTimestamp(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString('cache_timestamp_$key');
      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }
      return null;
    } catch (e) {
      print('Error getting cache timestamp for $key: $e');
      return null;
    }
  }

  /// Get view count for a cache key
  Future<int> _getViewCount(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('cache_viewcount_$key') ?? 0;
    } catch (e) {
      print('Error getting view count for $key: $e');
      return 0;
    }
  }

  /// Parse subscriber count from string
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

  /// Manual refresh trigger for user-initiated actions
  Future<void> triggerManualRefresh(List<Channel> channels) async {
    if (_isRefreshing) return;
    
    try {
      _isRefreshing = true;
      print('Manual refresh triggered for ${channels.length} channels');
      
      // Refresh all provided channels
      await _refreshChannelsWithDelay(channels, true); // Assume WiFi speed for manual refresh
      
      print('Manual refresh completed');
      
    } catch (e) {
      print('Manual refresh failed: $e');
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Get background refresh statistics
  Map<String, dynamic> getRefreshStatistics() {
    return {
      'isActive': _refreshTimer?.isActive ?? false,
      'isCurrentlyRefreshing': _isRefreshing,
      'nextRefreshIn': _refreshTimer?.isActive == true ? '~30 minutes' : 'Inactive',
      'refreshStrategy': 'Smart priority-based',
      'backupEnabled': _backupService != null,
      'autoBackupActive': _backupTimer?.isActive ?? false,
      'nextBackupIn': _backupTimer?.isActive == true ? '~6 hours' : 'Inactive',
    };
  }

  /// Dispose resources
  void dispose() {
    stopBackgroundRefresh();
  }
}

/// Data class for channel refresh priority
class ChannelPriority {
  final Channel channel;
  final int score;
  final bool shouldRefresh;

  const ChannelPriority({
    required this.channel,
    required this.score,
    required this.shouldRefresh,
  });

  @override
  String toString() {
    return 'ChannelPriority(${channel.title}: score=$score, shouldRefresh=$shouldRefresh)';
  }
}