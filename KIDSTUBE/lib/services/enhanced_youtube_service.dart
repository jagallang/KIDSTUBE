import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../models/video.dart';
import '../models/recommendation_weights.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/cache_manager.dart';
import '../core/cached_data.dart';
import '../core/cache_analytics.dart';

/// Enhanced YouTube Service with graceful fallback and smart caching
class EnhancedYouTubeService implements IYouTubeService {
  final IYouTubeService _baseService;
  static const String _cachePrefix = 'enhanced_cache_';

  EnhancedYouTubeService({required IYouTubeService baseService})
      : _baseService = baseService;

  @override
  Future<bool> validateApiKey() async {
    return await _baseService.validateApiKey();
  }

  @override
  Future<List<Channel>> searchChannels(String query) async {
    final cacheKey = SmartCacheManager.getCacheKey(CacheType.channelSearch, query);
    
    try {
      // Try to get from cache first
      final cachedData = await _getCachedData<List<Channel>>(
        cacheKey,
        (json) => (json as List).map((item) => Channel.fromJson(item)).toList(),
      );

      if (cachedData?.isValid == true) {
        await _incrementViewCount(cacheKey);
        await CacheAnalytics.recordCacheAccess(
          cacheKey,
          isHit: true,
          responseTime: const Duration(milliseconds: 10),
        );
        return cachedData!.data;
      }

      // Fetch fresh data
      final stopwatch = Stopwatch()..start();
      final freshData = await _baseService.searchChannels(query);
      
      // Cache the fresh data
      await _cacheData(
        cacheKey,
        freshData,
        SmartCacheManager.getCacheDuration(CacheType.channelSearch),
        (data) => data.map((channel) => channel.toJson()).toList(),
      );
      stopwatch.stop();
      
      await CacheAnalytics.recordCacheAccess(
        cacheKey,
        isHit: false,
        responseTime: stopwatch.elapsed,
      );

      return freshData;

    } catch (e) {
      // Graceful fallback: use expired cache if available
      final expiredCache = await _getCachedData<List<Channel>>(
        cacheKey,
        (json) => (json as List).map((item) => Channel.fromJson(item)).toList(),
      );

      if (expiredCache != null) {
        print('Using expired cache for channel search: $query');
        return expiredCache.data;
      }

      // No cache available, rethrow error
      rethrow;
    }
  }

  @override
  Future<List<Video>> getChannelVideos(String uploadsPlaylistId, {String? pageToken}) async {
    final cacheKey = SmartCacheManager.getCacheKey(
      CacheType.videoList, 
      uploadsPlaylistId,
      suffix: pageToken,
    );
    
    try {
      // Check cache first
      final cachedData = await _getCachedData<List<Video>>(
        cacheKey,
        (json) => (json as List).map((item) => Video.fromCacheJson(item)).toList(),
      );

      if (cachedData?.isValid == true) {
        await _incrementViewCount(cacheKey);
        return cachedData!.data;
      }

      // Fetch fresh data
      final freshData = await _baseService.getChannelVideos(uploadsPlaylistId, pageToken: pageToken);
      
      // Cache with smart duration based on channel popularity
      final cacheDuration = SmartCacheManager.getCacheDuration(
        CacheType.videoList,
        context: {'playlistId': uploadsPlaylistId},
      );
      
      await _cacheData(
        cacheKey,
        freshData,
        cacheDuration,
        (data) => data.map((video) => video.toJson()).toList(),
      );

      return freshData;

    } catch (e) {
      // Graceful fallback: use expired cache if available
      final expiredCache = await _getCachedData<List<Video>>(
        cacheKey,
        (json) => (json as List).map((item) => Video.fromCacheJson(item)).toList(),
      );

      if (expiredCache != null) {
        print('Using expired cache for channel videos: $uploadsPlaylistId');
        return expiredCache.data;
      }

      // No cache available, rethrow error
      rethrow;
    }
  }

  @override
  Future<List<Video>> getWeightedRecommendedVideos(
    List<Channel> channels, 
    RecommendationWeights weights
  ) async {
    final channelIds = channels.map((c) => c.id).join(',');
    final cacheKey = SmartCacheManager.getCacheKey(
      CacheType.videoList,
      'weighted_${channelIds.hashCode}_${weights.hashCode}',
    );

    try {
      // Check cache first
      final cachedData = await _getCachedData<List<Video>>(
        cacheKey,
        (json) => (json as List).map((item) => Video.fromCacheJson(item)).toList(),
      );

      if (cachedData?.isValid == true) {
        await _incrementViewCount(cacheKey);
        return cachedData!.data;
      }

      // Fetch fresh data
      final freshData = await _baseService.getWeightedRecommendedVideos(channels, weights);
      
      // Cache with smart duration
      await _cacheData(
        cacheKey,
        freshData,
        SmartCacheManager.getCacheDuration(CacheType.videoList),
        (data) => data.map((video) => video.toJson()).toList(),
      );

      return freshData;

    } catch (e) {
      // Graceful fallback: use expired cache if available
      final expiredCache = await _getCachedData<List<Video>>(
        cacheKey,
        (json) => (json as List).map((item) => Video.fromCacheJson(item)).toList(),
      );

      if (expiredCache != null) {
        print('Using expired cache for weighted videos');
        return expiredCache.data;
      }

      // No cache available, rethrow error
      rethrow;
    }
  }

  @override
  Future<List<Channel>> getChannelDetails(List<String> channelIds) async {
    final cacheKey = SmartCacheManager.getCacheKey(
      CacheType.channelDetails,
      channelIds.join(','),
    );

    try {
      // Check cache first
      final cachedData = await _getCachedData<List<Channel>>(
        cacheKey,
        (json) => (json as List).map((item) => Channel.fromJson(item)).toList(),
      );

      if (cachedData?.isValid == true) {
        await _incrementViewCount(cacheKey);
        return cachedData!.data;
      }

      // Fetch fresh data
      final freshData = await _baseService.getChannelDetails(channelIds);
      
      // Cache with long duration (channel details change slowly)
      await _cacheData(
        cacheKey,
        freshData,
        SmartCacheManager.getCacheDuration(CacheType.channelDetails),
        (data) => data.map((channel) => channel.toJson()).toList(),
      );

      return freshData;

    } catch (e) {
      // Graceful fallback: use expired cache if available
      final expiredCache = await _getCachedData<List<Channel>>(
        cacheKey,
        (json) => (json as List).map((item) => Channel.fromJson(item)).toList(),
      );

      if (expiredCache != null) {
        print('Using expired cache for channel details');
        return expiredCache.data;
      }

      // No cache available, rethrow error
      rethrow;
    }
  }

  /// Get cached data with type safety
  Future<CachedData<T>?> _getCachedData<T>(
    String key,
    T Function(dynamic) deserializer,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_cachePrefix$key');
      
      if (jsonString == null) return null;
      
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return CachedData.fromJson(jsonMap, deserializer);
    } catch (e) {
      print('Error loading cached data for $key: $e');
      return null;
    }
  }

  /// Cache data with metadata
  Future<void> _cacheData<T>(
    String key,
    T data,
    Duration ttl,
    dynamic Function(T) serializer,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cachedData = CachedData<T>(
        data: data,
        timestamp: DateTime.now(),
        ttl: ttl,
        metadata: {
          'cacheType': key.split('_')[0],
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      final jsonMap = cachedData.toJson();
      jsonMap['data'] = serializer(data);
      
      final jsonString = json.encode(jsonMap);
      await prefs.setString('$_cachePrefix$key', jsonString);
    } catch (e) {
      print('Error caching data for $key: $e');
    }
  }

  /// Increment view count for cache analytics
  Future<void> _incrementViewCount(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('${_cachePrefix}viewcount_$key') ?? 0;
      await prefs.setInt('${_cachePrefix}viewcount_$key', currentCount + 1);
    } catch (e) {
      print('Error incrementing view count for $key: $e');
    }
  }

  /// Get cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
      
      int totalCaches = 0;
      int validCaches = 0;
      int expiredCaches = 0;
      int totalViewCount = 0;

      for (final key in keys) {
        if (key.contains('viewcount_')) {
          totalViewCount += prefs.getInt(key) ?? 0;
          continue;
        }

        totalCaches++;
        
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
            final timestamp = DateTime.parse(jsonMap['timestamp']);
            final ttl = Duration(milliseconds: jsonMap['ttl']);
            
            if (DateTime.now().difference(timestamp) < ttl) {
              validCaches++;
            } else {
              expiredCaches++;
            }
          } catch (e) {
            expiredCaches++; // Count parsing errors as expired
          }
        }
      }

      final hitRate = totalViewCount > 0 ? (validCaches / totalViewCount * 100) : 0.0;

      return {
        'totalCaches': totalCaches,
        'validCaches': validCaches,
        'expiredCaches': expiredCaches,
        'totalViewCount': totalViewCount,
        'hitRate': hitRate,
        'cacheKeys': keys.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'totalCaches': 0,
        'validCaches': 0,
        'expiredCaches': 0,
        'totalViewCount': 0,
        'hitRate': 0.0,
        'cacheKeys': 0,
      };
    }
  }

  /// Clear expired caches
  Future<void> clearExpiredCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
      
      for (final key in keys) {
        if (key.contains('viewcount_')) continue;
        
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
            final timestamp = DateTime.parse(jsonMap['timestamp']);
            final ttl = Duration(milliseconds: jsonMap['ttl']);
            
            if (DateTime.now().difference(timestamp) >= ttl) {
              await prefs.remove(key);
              await prefs.remove('${_cachePrefix}viewcount_${key.replaceFirst(_cachePrefix, '')}');
            }
          } catch (e) {
            // Remove corrupted cache entries
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error clearing expired caches: $e');
    }
  }
}