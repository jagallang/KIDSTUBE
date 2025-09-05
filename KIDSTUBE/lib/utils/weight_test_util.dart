import '../models/recommendation_weights.dart';
import '../models/channel.dart';
import '../core/debug_logger.dart';

/// 가중치 시스템 테스트 및 디버깅 유틸리티
class WeightTestUtil {
  /// 가중치 설정 테스트 및 시뮬레이션
  static void testWeightDistribution() {
    DebugLogger.log('=== Weight System Test Started ===', tag: 'WEIGHT_TEST');
    
    // 테스트 가중치 설정들
    final testWeights = [
      RecommendationWeights(), // 기본값
      RecommendationWeights(korean: 5, kids: 3, making: 1, english: 1), // 한글 중심
      RecommendationWeights(kids: 5, making: 3, art: 2), // 창의력 중심
      RecommendationWeights(korean: 2, kids: 2, english: 3, science: 3), // 균형잡힌
    ];
    
    final testNames = ['기본값', '한글중심', '창의력중심', '균형잡힌'];
    
    for (int i = 0; i < testWeights.length; i++) {
      final weights = testWeights[i];
      final name = testNames[i];
      
      DebugLogger.log('--- $name 가중치 테스트 ---', tag: 'WEIGHT_TEST');
      DebugLogger.log('총 가중치: ${weights.total}', tag: 'WEIGHT_TEST');
      
      final counts = weights.getVideoCountsForTotal(20);
      DebugLogger.log('20개 영상 분배:', tag: 'WEIGHT_TEST');
      
      int totalDistributed = 0;
      for (final entry in counts.entries) {
        DebugLogger.log('  ${entry.key}: ${entry.value}개', tag: 'WEIGHT_TEST');
        totalDistributed += entry.value;
      }
      
      DebugLogger.log('실제 분배된 총 개수: $totalDistributed', tag: 'WEIGHT_TEST');
      DebugLogger.log('', tag: 'WEIGHT_TEST'); // 빈 줄
    }
    
    DebugLogger.log('=== Weight System Test Completed ===', tag: 'WEIGHT_TEST');
  }
  
  /// 채널 카테고리 분류 테스트
  static void testChannelCategorization(List<Channel> channels) {
    DebugLogger.log('=== Channel Categorization Test ===', tag: 'CATEGORY_TEST');
    DebugLogger.log('총 채널 수: ${channels.length}', tag: 'CATEGORY_TEST');
    
    // 간단한 카테고리 분류 로직 (youtube_service.dart의 로직과 동일)
    final Map<String, List<String>> categoryKeywords = {
      '키즈': ['뽀로로', '핑크퐁', '타요', '코코몽', '베이비버스', '키즈', '아기', '어린이', '유아', '키드'],
      '한글': ['한글', '한국어', '국어', '글자', '받침', '자음', '모음', '읽기', '쓰기'],
      '만들기': ['만들기', '공작', '종이접기', '그리기', '창작', '손놀이', 'DIY', '만든다'],
      '게임': ['게임', '놀이', '퍼즐', '숨바꼭질', '술래잡기', '보드게임', '카드게임', '놀이터'],
      '영어': ['영어', 'English', 'ABC', 'Alphabet', '알파벳', 'phonics', '파닉스', '영단어', '영어동요'],
      '과학': ['과학', '실험', 'science', '탐구', '관찰', '자연', '동물', '식물', '우주', '지구', '발명'],
      '미술': ['미술', '그림', '그리기', '색칠', '만들기', '조형', 'art', '디자인', '창작', '컬러링'],
      '음악': ['음악', '노래', '동요', '리듬', '악기', 'music', '피아노', '기타', '합창', '멜로디']
    };

    Map<String, List<Channel>> result = {
      '키즈': [], '한글': [], '만들기': [], '게임': [],
      '영어': [], '과학': [], '미술': [], '음악': [], '랜덤': [],
    };

    for (Channel channel in channels) {
      bool categorized = false;
      
      for (final entry in categoryKeywords.entries) {
        final category = entry.key;
        final keywords = entry.value;
        
        if (keywords.any((keyword) => 
          channel.title.toLowerCase().contains(keyword.toLowerCase()))) {
          result[category]!.add(channel);
          categorized = true;
          break;
        }
      }
      
      if (!categorized) {
        result['랜덤']!.add(channel);
      }
    }
    
    // 결과 출력
    for (final entry in result.entries) {
      if (entry.value.isNotEmpty) {
        DebugLogger.log('${entry.key}: ${entry.value.length}개 채널', tag: 'CATEGORY_TEST');
        for (final channel in entry.value) {
          DebugLogger.log('  - ${channel.title}', tag: 'CATEGORY_TEST');
        }
      }
    }
    
    DebugLogger.log('=== Channel Categorization Test Completed ===', tag: 'CATEGORY_TEST');
  }
  
  /// 영상 다양성 분석 (중복 체크)
  static void analyzeVideoDiversity(List<dynamic> videos) {
    DebugLogger.log('=== Video Diversity Analysis ===', tag: 'DIVERSITY_TEST');
    
    final videoIds = videos.map((v) => v.toString()).toSet();
    final channelTitles = <String>{};
    
    // 채널별 영상 수 계산 (실제 Video 객체라면)
    final channelCounts = <String, int>{};
    
    for (final video in videos) {
      // 실제 Video 객체인 경우의 처리를 위한 더미 로직
      final channelTitle = 'Channel_${videos.indexOf(video) % 5}'; // 임시
      channelCounts[channelTitle] = (channelCounts[channelTitle] ?? 0) + 1;
      channelTitles.add(channelTitle);
    }
    
    DebugLogger.log('총 영상 수: ${videos.length}', tag: 'DIVERSITY_TEST');
    DebugLogger.log('고유 영상 수: ${videoIds.length}', tag: 'DIVERSITY_TEST');
    DebugLogger.log('중복 영상 수: ${videos.length - videoIds.length}', tag: 'DIVERSITY_TEST');
    DebugLogger.log('채널 수: ${channelTitles.length}', tag: 'DIVERSITY_TEST');
    
    if (channelCounts.isNotEmpty) {
      DebugLogger.log('채널별 영상 분포:', tag: 'DIVERSITY_TEST');
      for (final entry in channelCounts.entries) {
        DebugLogger.log('  ${entry.key}: ${entry.value}개', tag: 'DIVERSITY_TEST');
      }
    }
    
    DebugLogger.log('=== Video Diversity Analysis Completed ===', tag: 'DIVERSITY_TEST');
  }
}