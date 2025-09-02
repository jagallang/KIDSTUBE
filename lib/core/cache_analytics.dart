import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache analytics and usage pattern tracking
/// Tracks access patterns, hit rates, and user behavior for smart caching decisions
class CacheAnalytics {
  static const String _analyticsPrefix = 'cache_analytics_';
  static const String _userBehaviorPrefix = 'user_behavior_';
  
  /// Record cache access for analytics
  static Future<void> recordCacheAccess(
    String cacheKey, {
    required bool isHit,
    required Duration responseTime,
    String? userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update access count
      final accessCountKey = '${_analyticsPrefix}count_$cacheKey';
      final currentCount = prefs.getInt(accessCountKey) ?? 0;
      await prefs.setInt(accessCountKey, currentCount + 1);
      
      // Update hit count if cache hit
      if (isHit) {
        final hitCountKey = '${_analyticsPrefix}hits_$cacheKey';
        final currentHits = prefs.getInt(hitCountKey) ?? 0;
        await prefs.setInt(hitCountKey, currentHits + 1);
      }
      
      // Record access time for pattern analysis
      final accessTimeKey = '${_analyticsPrefix}last_access_$cacheKey';
      await prefs.setString(accessTimeKey, DateTime.now().toIso8601String());
      
      // Track response time for performance analytics
      final responseTimeKey = '${_analyticsPrefix}response_time_$cacheKey';
      await prefs.setInt(responseTimeKey, responseTime.inMilliseconds);
      
      // Record user behavior pattern (if userId provided)
      if (userId != null) {
        await _recordUserBehavior(userId, cacheKey);
      }
      
    } catch (e) {
      print('Error recording cache access: $e');
    }
  }
  
  /// Calculate cache hit rate for a specific key
  static Future<double> getCacheHitRate(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessCount = prefs.getInt('${_analyticsPrefix}count_$cacheKey') ?? 0;
      final hitCount = prefs.getInt('${_analyticsPrefix}hits_$cacheKey') ?? 0;
      
      if (accessCount == 0) return 0.0;
      return (hitCount / accessCount) * 100;
    } catch (e) {
      print('Error calculating hit rate: $e');
      return 0.0;
    }
  }
  
  /// Get access frequency for cache priority calculation
  static Future<int> getAccessFrequency(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('${_analyticsPrefix}count_$cacheKey') ?? 0;
    } catch (e) {
      print('Error getting access frequency: $e');
      return 0;
    }
  }
  
  /// Get last access time for cache priority calculation
  static Future<DateTime?> getLastAccessTime(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('${_analyticsPrefix}last_access_$cacheKey');
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      print('Error getting last access time: $e');
      return null;
    }
  }
  
  /// Calculate cache priority score based on usage patterns
  static Future<int> calculatePriorityScore(String cacheKey) async {
    try {
      int score = 0;
      
      // Access frequency factor (40% weight)
      final accessFrequency = await getAccessFrequency(cacheKey);
      if (accessFrequency >= 50) score += 40;
      else if (accessFrequency >= 20) score += 30;
      else if (accessFrequency >= 10) score += 20;
      else if (accessFrequency >= 5) score += 10;
      
      // Recency factor (30% weight)
      final lastAccess = await getLastAccessTime(cacheKey);
      if (lastAccess != null) {
        final timeSinceAccess = DateTime.now().difference(lastAccess);
        if (timeSinceAccess.inHours <= 1) score += 30;
        else if (timeSinceAccess.inHours <= 6) score += 25;
        else if (timeSinceAccess.inHours <= 24) score += 20;
        else if (timeSinceAccess.inDays <= 7) score += 10;
      }
      
      // Hit rate factor (20% weight)
      final hitRate = await getCacheHitRate(cacheKey);
      if (hitRate >= 90) score += 20;
      else if (hitRate >= 70) score += 15;
      else if (hitRate >= 50) score += 10;
      else if (hitRate >= 30) score += 5;
      
      // Performance factor (10% weight)
      final prefs = await SharedPreferences.getInstance();
      final responseTime = prefs.getInt('${_analyticsPrefix}response_time_$cacheKey') ?? 0;
      if (responseTime > 0) {
        if (responseTime <= 100) score += 10; // Very fast
        else if (responseTime <= 500) score += 8; // Fast
        else if (responseTime <= 1000) score += 5; // Moderate
        else if (responseTime <= 2000) score += 2; // Slow
      }
      
      return score;
    } catch (e) {
      print('Error calculating priority score: $e');
      return 0;
    }
  }
  
  /// Get top priority cache keys for background refresh
  static Future<List<String>> getTopPriorityCacheKeys(int limit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys()
          .where((key) => key.startsWith('${_analyticsPrefix}count_'))
          .map((key) => key.replaceFirst('${_analyticsPrefix}count_', ''))
          .toList();
      
      final priorityScores = <MapEntry<String, int>>[];
      
      for (final key in allKeys) {
        final score = await calculatePriorityScore(key);
        priorityScores.add(MapEntry(key, score));
      }
      
      // Sort by score (highest first) and return top N
      priorityScores.sort((a, b) => b.value.compareTo(a.value));
      
      return priorityScores
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error getting top priority keys: $e');
      return [];
    }
  }
  
  /// Record user behavior patterns for personalized caching
  static Future<void> _recordUserBehavior(String userId, String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final behaviorKey = '${_userBehaviorPrefix}$userId';
      
      // Get existing behavior data
      final behaviorJson = prefs.getString(behaviorKey);
      Map<String, dynamic> behaviorData = {};
      
      if (behaviorJson != null) {
        behaviorData = json.decode(behaviorJson);
      }
      
      // Update access count for this cache key
      behaviorData[cacheKey] = (behaviorData[cacheKey] ?? 0) + 1;
      
      // Keep only top 50 most accessed keys to prevent unlimited growth
      if (behaviorData.length > 50) {
        final sortedEntries = behaviorData.entries.toList()
          ..sort((a, b) => (b.value as int).compareTo(a.value as int));
        behaviorData = Map.fromEntries(sortedEntries.take(50));
      }
      
      // Save updated behavior data
      await prefs.setString(behaviorKey, json.encode(behaviorData));
      
    } catch (e) {
      print('Error recording user behavior: $e');
    }
  }
  
  /// Get user's preferred content types based on access patterns
  static Future<Map<String, int>> getUserPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final behaviorKey = '${_userBehaviorPrefix}$userId';
      final behaviorJson = prefs.getString(behaviorKey);
      
      if (behaviorJson != null) {
        final behaviorData = json.decode(behaviorJson) as Map<String, dynamic>;
        return behaviorData.map((key, value) => MapEntry(key, value as int));
      }
      
      return {};
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }
  
  /// Get overall cache performance statistics
  static Future<Map<String, dynamic>> getCachePerformanceStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKeys = prefs.getKeys()
          .where((key) => key.startsWith('${_analyticsPrefix}count_'))
          .map((key) => key.replaceFirst('${_analyticsPrefix}count_', ''))
          .toList();
      
      if (cacheKeys.isEmpty) {
        return {
          'totalCaches': 0,
          'averageHitRate': 0.0,
          'totalAccesses': 0,
          'topPerformingCaches': [],
        };
      }
      
      int totalAccesses = 0;
      double totalHitRate = 0.0;
      List<MapEntry<String, double>> hitRates = [];
      
      for (final key in cacheKeys) {
        final accessCount = prefs.getInt('${_analyticsPrefix}count_$key') ?? 0;
        final hitRate = await getCacheHitRate(key);
        
        totalAccesses += accessCount;
        totalHitRate += hitRate;
        hitRates.add(MapEntry(key, hitRate));
      }
      
      // Sort by hit rate
      hitRates.sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'totalCaches': cacheKeys.length,
        'averageHitRate': cacheKeys.isNotEmpty ? (totalHitRate / cacheKeys.length) : 0.0,
        'totalAccesses': totalAccesses,
        'topPerformingCaches': hitRates.take(10)
            .map((entry) => {
              'cacheKey': entry.key,
              'hitRate': entry.value,
            }).toList(),
      };
    } catch (e) {
      print('Error getting cache performance stats: $e');
      return {
        'error': e.toString(),
        'totalCaches': 0,
        'averageHitRate': 0.0,
        'totalAccesses': 0,
        'topPerformingCaches': [],
      };
    }
  }
  
  /// Clean old analytics data to prevent storage bloat
  static Future<void> cleanOldAnalytics({int keepDays = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
      
      final keysToRemove = <String>[];
      
      // Check last access times and remove old entries
      for (final key in prefs.getKeys()) {
        if (key.startsWith('${_analyticsPrefix}last_access_')) {
          final timeString = prefs.getString(key);
          if (timeString != null) {
            try {
              final lastAccess = DateTime.parse(timeString);
              if (lastAccess.isBefore(cutoffDate)) {
                final cacheKey = key.replaceFirst('${_analyticsPrefix}last_access_', '');
                keysToRemove.addAll([
                  '${_analyticsPrefix}count_$cacheKey',
                  '${_analyticsPrefix}hits_$cacheKey',
                  '${_analyticsPrefix}last_access_$cacheKey',
                  '${_analyticsPrefix}response_time_$cacheKey',
                ]);
              }
            } catch (e) {
              // Remove invalid date entries
              keysToRemove.add(key);
            }
          }
        }
      }
      
      // Remove old analytics data
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      print('Cleaned ${keysToRemove.length} old analytics entries');
      
    } catch (e) {
      print('Error cleaning old analytics: $e');
    }
  }
}