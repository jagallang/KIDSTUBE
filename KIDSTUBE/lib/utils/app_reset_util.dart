import 'package:shared_preferences/shared_preferences.dart';

/// 앱 초기화 및 리셋 유틸리티
class AppResetUtil {
  /// 모든 앱 데이터를 완전히 리셋 (API 키, 채널, 캐시 등)
  static Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🔄 모든 앱 데이터가 리셋되었습니다.');
  }

  /// 캐시 데이터만 리셋 (API 키와 설정은 유지)
  static Future<void> resetCacheOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    
    int removedCount = 0;
    for (final key in keys) {
      if (key.startsWith('enhanced_cache_') || 
          key.startsWith('cache_analytics_') || 
          key.startsWith('cache_timestamp_') || 
          key.startsWith('cache_viewcount_')) {
        await prefs.remove(key);
        removedCount++;
      }
    }
    
    print('🗑️ $removedCount개의 캐시 항목이 삭제되었습니다.');
  }

  /// 채널 데이터만 리셋 (API 키와 PIN은 유지)
  static Future<void> resetChannelsOnly() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 채널 관련 키들
    final channelKeys = [
      'subscribed_channels',
      'setup_complete',
      'recommendation_weights',
    ];
    
    for (final key in channelKeys) {
      await prefs.remove(key);
    }
    
    // 채널 관련 캐시도 삭제
    await resetCacheOnly();
    
    print('📺 채널 데이터가 리셋되었습니다. 채널을 다시 설정해주세요.');
  }

  /// 개발자 모드용 - 더미 데이터 완전 제거 확인
  static Future<void> verifyNoDummyData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    
    final dummyKeys = keys.where((key) => 
        key.contains('dummy') || 
        key.contains('test') ||
        key.contains('TEST')).toList();
    
    if (dummyKeys.isNotEmpty) {
      print('⚠️ 발견된 더미 데이터 키들:');
      for (final key in dummyKeys) {
        print('  - $key: ${prefs.get(key)}');
        await prefs.remove(key);
      }
      print('🧹 더미 데이터가 정리되었습니다.');
    } else {
      print('✅ 더미 데이터가 없습니다. 클린한 상태입니다.');
    }
  }

  /// 캐시 상태 보고서 생성
  static Future<Map<String, dynamic>> getCacheReport() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    
    final cacheKeys = keys.where((key) => 
        key.startsWith('enhanced_cache_') || 
        key.startsWith('cache_')).toList();
    
    final analyticsKeys = keys.where((key) => 
        key.startsWith('cache_analytics_')).toList();
    
    final channelKeys = keys.where((key) => 
        key.contains('channel')).toList();
    
    return {
      'totalKeys': keys.length,
      'cacheKeys': cacheKeys.length,
      'analyticsKeys': analyticsKeys.length,
      'channelKeys': channelKeys.length,
      'sampleCacheKeys': cacheKeys.take(5).toList(),
      'hasApiKey': prefs.containsKey('api_key'),
      'hasPin': prefs.containsKey('parent_pin'),
      'isSetupComplete': prefs.getBool('setup_complete') ?? false,
    };
  }

  /// 앱 상태 디버그 출력
  static Future<void> printAppStatus() async {
    print('📊 === 앱 상태 보고서 ===');
    
    final report = await getCacheReport();
    print('전체 저장 키: ${report['totalKeys']}개');
    print('캐시 키: ${report['cacheKeys']}개');
    print('분석 키: ${report['analyticsKeys']}개');
    print('채널 키: ${report['channelKeys']}개');
    print('API 키 존재: ${report['hasApiKey']}');
    print('PIN 설정: ${report['hasPin']}');
    print('설정 완료: ${report['isSetupComplete']}');
    
    if (report['sampleCacheKeys'].isNotEmpty) {
      print('샘플 캐시 키들:');
      for (final key in report['sampleCacheKeys']) {
        print('  - $key');
      }
    }
    
    print('========================');
  }
}