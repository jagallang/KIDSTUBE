// 통합 캐시 관리 시스템
import 'dart:convert';
import '../errors/result.dart';
import '../errors/app_error.dart';

abstract class CacheManager {
  Future<Result<T?>> get<T>(String key, T Function(Map<String, dynamic>) fromJson);
  Future<Result<void>> set<T>(String key, T data, T Function() toJson);
  Future<Result<void>> remove(String key);
  Future<Result<void>> clear();
  Future<Result<bool>> exists(String key);
}

class MemoryCacheManager implements CacheManager {
  final Map<String, CacheItem> _cache = {};
  final Duration defaultTtl;

  MemoryCacheManager({this.defaultTtl = const Duration(minutes: 30)});

  @override
  Future<Result<T?>> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final item = _cache[key];
      if (item == null || item.isExpired) {
        _cache.remove(key);
        return const Success(null);
      }
      
      final data = fromJson(item.data);
      return Success(data);
    } catch (e) {
      return Failure(CacheError(
        message: '캐시 데이터를 가져오는 중 오류가 발생했습니다',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Result<void>> set<T>(String key, T data, T Function() toJson) async {
    try {
      final jsonData = (toJson() as dynamic).toJson() as Map<String, dynamic>;
      _cache[key] = CacheItem(
        data: jsonData,
        expiredAt: DateTime.now().add(defaultTtl),
      );
      return const Success(null);
    } catch (e) {
      return Failure(CacheError(
        message: '캐시 저장 중 오류가 발생했습니다',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Result<void>> remove(String key) async {
    try {
      _cache.remove(key);
      return const Success(null);
    } catch (e) {
      return Failure(CacheError(
        message: '캐시 삭제 중 오류가 발생했습니다',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      _cache.clear();
      return const Success(null);
    } catch (e) {
      return Failure(CacheError(
        message: '전체 캐시 삭제 중 오류가 발생했습니다',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Result<bool>> exists(String key) async {
    try {
      final item = _cache[key];
      final exists = item != null && !item.isExpired;
      return Success(exists);
    } catch (e) {
      return Failure(CacheError(
        message: '캐시 존재 여부 확인 중 오류가 발생했습니다',
        details: e.toString(),
      ));
    }
  }

  // 만료된 캐시 정리
  void cleanupExpired() {
    _cache.removeWhere((key, value) => value.isExpired);
  }
}

// 캐시 아이템 클래스
class CacheItem {
  final Map<String, dynamic> data;
  final DateTime expiredAt;

  CacheItem({
    required this.data,
    required this.expiredAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiredAt);
}

// 캐시 키 상수
class CacheKeys {
  static const String channels = 'channels_list';
  static const String videos = 'videos_list';
  static const String apiKey = 'api_key_encrypted';
  static const String weights = 'recommendation_weights';
  
  // 동적 키 생성
  static String channelVideos(String channelId) => 'channel_videos_$channelId';
  static String channelDetails(String channelId) => 'channel_details_$channelId';
}