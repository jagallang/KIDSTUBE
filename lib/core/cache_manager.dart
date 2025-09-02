import '../models/channel.dart';

/// Smart cache manager for differentiated TTL strategies
/// Provides optimized caching durations based on data types and usage patterns
class SmartCacheManager {
  /// Cache duration strategies for different data types (더 공격적인 캐싱)
  static const Map<CacheType, Duration> _cacheDurations = {
    CacheType.channelSearch: Duration(days: 30),       // 채널 정보는 거의 변하지 않음
    CacheType.videoList: Duration(days: 3),            // 비디오 목록을 3일간 캐싱
    CacheType.popularVideos: Duration(days: 2),        // 인기 채널도 2일간 캐싱
    CacheType.channelDetails: Duration(days: 7),       // 구독자 수는 천천히 변함
    CacheType.userSubscriptions: Duration(days: 30),   // 사용자 관리 데이터
    CacheType.recommendationWeights: Duration(days: 30), // 사용자 설정
  };

  /// Get cache duration for specific data type
  static Duration getCacheDuration(CacheType type, {Map<String, dynamic>? context}) {
    // 인기 채널도 더 긴 캐시 적용 (API 절약)
    if (type == CacheType.videoList && context != null) {
      final subscriberCount = _parseSubscriberCount(context['subscriberCount'] ?? '0');
      
      // 매우 인기있는 채널 (5M+ 구독자)도 최소 1일 캐싱
      if (subscriberCount >= 5000000) {
        return const Duration(days: 1);
      }
      
      // 인기 채널 (1M+ 구독자)은 2일 캐싱
      if (subscriberCount >= 1000000) {
        return const Duration(days: 2);
      }
    }
    
    return _cacheDurations[type] ?? const Duration(hours: 12);
  }

  /// Parse subscriber count from formatted string
  static int _parseSubscriberCount(String subscriberCountStr) {
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

  /// Check if data should be refreshed based on usage patterns
  static bool shouldBackgroundRefresh(DateTime lastUpdate, CacheType type, int viewCount) {
    final now = DateTime.now();
    final age = now.difference(lastUpdate);
    final cacheDuration = getCacheDuration(type);
    
    // Background refresh when 50% of cache time has passed
    final refreshThreshold = Duration(
      milliseconds: (cacheDuration.inMilliseconds * 0.5).round(),
    );
    
    // Frequently viewed content gets refreshed more often
    final adjustedThreshold = viewCount > 5 
        ? Duration(milliseconds: (refreshThreshold.inMilliseconds * 0.7).round())
        : refreshThreshold;
    
    return age > adjustedThreshold;
  }

  /// Get priority for background refresh
  static int getRefreshPriority(String channelId, int viewCount, int subscriberCount) {
    int priority = 0;
    
    // High view count = higher priority
    if (viewCount > 10) priority += 3;
    else if (viewCount > 5) priority += 2;
    else if (viewCount > 2) priority += 1;
    
    // Popular channels = higher priority
    if (subscriberCount > 5000000) priority += 3;
    else if (subscriberCount > 1000000) priority += 2;
    else if (subscriberCount > 100000) priority += 1;
    
    return priority;
  }

  /// Get recommended cache key for data
  static String getCacheKey(CacheType type, String identifier, {String? suffix}) {
    final baseKey = '${type.name}_$identifier';
    return suffix != null ? '${baseKey}_$suffix' : baseKey;
  }
}

/// Enum for different cache types
enum CacheType {
  channelSearch,
  videoList,
  popularVideos,
  channelDetails,
  userSubscriptions,
  recommendationWeights,
}

/// Extension to get display names for cache types
extension CacheTypeExtension on CacheType {
  String get displayName {
    switch (this) {
      case CacheType.channelSearch:
        return '채널 검색';
      case CacheType.videoList:
        return '비디오 목록';
      case CacheType.popularVideos:
        return '인기 비디오';
      case CacheType.channelDetails:
        return '채널 상세정보';
      case CacheType.userSubscriptions:
        return '사용자 구독';
      case CacheType.recommendationWeights:
        return '추천 가중치';
    }
  }
}