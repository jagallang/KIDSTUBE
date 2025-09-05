// API 요청 레이트 리미터
class RateLimiter {
  final Map<String, List<DateTime>> _requestHistory = {};
  final int maxRequests;
  final Duration timeWindow;

  RateLimiter({
    required this.maxRequests,
    required this.timeWindow,
  });

  // 요청 허용 여부 확인
  bool canMakeRequest(String endpoint) {
    final now = DateTime.now();
    final history = _requestHistory[endpoint] ?? [];
    
    // 시간 윈도우 밖의 요청들 제거
    history.removeWhere((time) => now.difference(time) > timeWindow);
    
    return history.length < maxRequests;
  }

  // 요청 기록
  void recordRequest(String endpoint) {
    final now = DateTime.now();
    final history = _requestHistory[endpoint] ?? [];
    
    history.add(now);
    _requestHistory[endpoint] = history;
    
    // 시간 윈도우 밖의 요청들 제거
    history.removeWhere((time) => now.difference(time) > timeWindow);
  }

  // 다음 요청까지 대기 시간
  Duration? getWaitTime(String endpoint) {
    if (canMakeRequest(endpoint)) return null;
    
    final history = _requestHistory[endpoint] ?? [];
    if (history.isEmpty) return null;
    
    final oldestRequest = history.first;
    final nextAvailableTime = oldestRequest.add(timeWindow);
    return nextAvailableTime.difference(DateTime.now());
  }

  // 통계 정보
  Map<String, int> getUsageStats() {
    final stats = <String, int>{};
    _requestHistory.forEach((endpoint, history) {
      stats[endpoint] = history.length;
    });
    return stats;
  }

  // 히스토리 초기화
  void reset() {
    _requestHistory.clear();
  }
}

// YouTube API 전용 레이트 리미터
class YouTubeApiRateLimiter {
  static final RateLimiter _instance = RateLimiter(
    maxRequests: 100, // 100 requests per hour
    timeWindow: const Duration(hours: 1),
  );

  static RateLimiter get instance => _instance;

  // YouTube API 엔드포인트별 가중치
  static const Map<String, int> endpointWeights = {
    'search': 100,
    'videos': 1,
    'channels': 1,
    'playlistItems': 1,
  };

  // 가중치를 고려한 요청 가능 여부
  static bool canMakeWeightedRequest(String endpoint) {
    final weight = endpointWeights[endpoint] ?? 1;
    
    // 현재 사용량 확인
    final currentUsage = _instance.getUsageStats().values
        .fold(0, (sum, count) => sum + count);
    
    return (currentUsage + weight) <= _instance.maxRequests;
  }

  // 가중치를 고려한 요청 기록
  static void recordWeightedRequest(String endpoint) {
    final weight = endpointWeights[endpoint] ?? 1;
    
    // 가중치만큼 요청 기록
    for (int i = 0; i < weight; i++) {
      _instance.recordRequest(endpoint);
    }
  }
}