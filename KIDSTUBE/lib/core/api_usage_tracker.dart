import 'package:shared_preferences/shared_preferences.dart';

/// YouTube API 사용량 추적 및 제한 관리
class ApiUsageTracker {
  static const String _dailyUsageKey = 'api_daily_usage';
  static const String _lastResetDateKey = 'api_last_reset_date';
  static const int _dailyLimit = 500; // 일일 API 호출 제한 (안전 마진)
  
  /// API 호출 비용 (YouTube Data API v3 기준)
  static const Map<String, int> _apiCosts = {
    'search.list': 100,        // 검색 API
    'channels.list': 1,        // 채널 정보
    'playlistItems.list': 1,   // 재생목록 아이템
    'videos.list': 1,          // 비디오 정보
  };
  
  /// API 호출 추적
  static Future<bool> trackApiCall(String apiMethod, {int count = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 일일 리셋 체크
    await _checkDailyReset(prefs);
    
    // 현재 사용량 가져오기
    final currentUsage = prefs.getInt(_dailyUsageKey) ?? 0;
    final cost = (_apiCosts[apiMethod] ?? 1) * count;
    
    // 제한 체크
    if (currentUsage + cost > _dailyLimit) {
      print('⚠️ API 일일 제한 도달: $currentUsage/$_dailyLimit units (비용: $cost)');
      return false; // API 호출 차단
    }
    
    print('✅ API 호출 허용: $apiMethod (비용: $cost) - 현재: $currentUsage/$_dailyLimit');
    
    // 사용량 업데이트
    await prefs.setInt(_dailyUsageKey, currentUsage + cost);
    
    print('📊 API 사용: $apiMethod ($cost units) - 일일 사용량: ${currentUsage + cost}/$_dailyLimit');
    
    return true; // API 호출 허용
  }
  
  /// 일일 리셋 체크
  static Future<void> _checkDailyReset(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_lastResetDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastReset != today) {
      // 새로운 날이면 사용량 리셋
      await prefs.setInt(_dailyUsageKey, 0);
      await prefs.setString(_lastResetDateKey, today);
      print('🔄 API 사용량 일일 리셋 완료');
    }
  }
  
  /// 현재 사용량 조회
  static Future<Map<String, dynamic>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs);
    
    final currentUsage = prefs.getInt(_dailyUsageKey) ?? 0;
    final percentage = (currentUsage / _dailyLimit * 100).round();
    
    return {
      'current': currentUsage,
      'limit': _dailyLimit,
      'percentage': percentage,
      'remaining': _dailyLimit - currentUsage,
      'canMakeApiCall': currentUsage < _dailyLimit,
    };
  }
  
  /// 강제 리셋 (테스트용)
  static Future<void> resetUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyUsageKey, 0);
    print('🔄 API 사용량 강제 리셋');
  }
  
  /// 예상 API 비용 계산
  static int estimateCost(String apiMethod, {int count = 1}) {
    return (_apiCosts[apiMethod] ?? 1) * count;
  }
}