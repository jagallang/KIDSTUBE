import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/video.dart';
import '../models/recommendation_weights.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/debug_logger.dart';
import '../core/api_usage_tracker.dart';

class YouTubeService implements IYouTubeService {
  final String apiKey;
  final String baseUrl = 'https://www.googleapis.com/youtube/v3';

  YouTubeService({required this.apiKey});

  @override
  Future<List<Channel>> searchChannels(String query) async {
    print('🔍 YouTube 채널 검색 시작: "$query"');
    print('🔑 사용 중인 API 키: ${apiKey.substring(0, 8)}...');
    
    // 테스트 모드는 삭제 - 실제 API만 사용
    // if (apiKey == 'TEST_API_KEY') {
    //   print('🧪 테스트 모드: 더미 데이터 반환');
    //   return _getDummyChannels(query);
    // }
    
    try {
      // 실제 YouTube Search API 사용
      // API 사용량 체크 (search.list는 100 units 소모)
      final canCall = await ApiUsageTracker.trackApiCall('search.list');
      if (!canCall) {
        print('API 일일 제한 도달 - 채널 검색 차단');
        return [];
      }
      
      print('Searching channels with query: $query');
      
      // YouTube Search API로 채널 검색
      final searchResponse = await http.get(
        Uri.parse('$baseUrl/search').replace(queryParameters: {
          'part': 'snippet',
          'q': query,
          'type': 'channel',
          'key': apiKey,
          'maxResults': '20',
          'relevanceLanguage': 'ko',  // 한국어 콘텐츠 우선
          'safeSearch': 'strict',     // 어린이 안전 검색
        }),
      );
      
      print('Search API response status: ${searchResponse.statusCode}');
      
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        print('✅ Search API response received');
        print('📊 Full search response: ${searchResponse.body.substring(0, 500)}...');
        
        final searchItems = searchData['items'] as List? ?? [];
        print('📝 Found ${searchItems.length} search items');
        
        if (searchItems.isEmpty) {
          print('❌ No search results found');
          return [];
        }
        
        // 검색 결과에서 채널 ID 추출
        final channelIds = searchItems
            .map((item) {
              print('🆔 Channel ID found: ${item['snippet']['channelId']}');
              return item['snippet']['channelId'] as String;
            })
            .join(',');
        
        print('🔗 Channel IDs to fetch: $channelIds');
        print('📤 Found ${searchItems.length} channels, fetching details...');
        
        // 채널 상세 정보 조회 (1 unit per request)
        final channelsResponse = await http.get(
          Uri.parse('$baseUrl/channels').replace(queryParameters: {
            'part': 'snippet,statistics,contentDetails',
            'id': channelIds,
            'key': apiKey,
          }),
        );
        
        if (channelsResponse.statusCode == 200) {
          final channelsData = json.decode(channelsResponse.body);
          print('✅ Channels API response received');
          print('📊 Channels response: ${channelsResponse.body.substring(0, 300)}...');
          
          final channelItems = channelsData['items'] as List? ?? [];
          print('📝 Channel items count: ${channelItems.length}');
          
          final channels = channelItems.map((item) => Channel.fromJson(item)).toList();
          
          print('🎯 Successfully fetched ${channels.length} channel details');
          
          // 구독자 수 1만명 이상인 채널만 필터링
          final filteredChannels = channels.where((channel) {
            final subscriberCount = _parseSubscriberCount(channel.subscriberCount);
            print('👥 Channel ${channel.title}: ${channel.subscriberCount} subscribers (parsed: $subscriberCount)');
            return subscriberCount >= 10000;
          }).toList();
          
          print('✨ Filtered to ${filteredChannels.length} channels with 10k+ subscribers');
          print('📋 Final channels: ${filteredChannels.map((c) => c.title).join(', ')}');
          
          return filteredChannels;
        } else {
          print('Error fetching channel details: ${channelsResponse.statusCode}');
        }
      } else {
        print('Search API error: ${searchResponse.statusCode}');
        print('Response body: ${searchResponse.body}');
      }
      
      return [];
      
    } catch (e) {
      print('Error searching channels: $e');
      return [];
    }
  }

  @override
  Future<List<Video>> getChannelVideos(String uploadsPlaylistId, {String? pageToken}) async {
    DebugLogger.logFlow('YouTubeService.getChannelVideos started', data: {
      'uploadsPlaylistId': uploadsPlaylistId,
      'pageToken': pageToken,
      'isTestMode': apiKey == 'TEST_API_KEY'
    });
    
    // 테스트 모드는 삭제 - 실제 API만 사용
    // if (apiKey == 'TEST_API_KEY') {
    //   final dummyVideos = _getDummyVideos(uploadsPlaylistId);
    //   DebugLogger.logFlow('YouTubeService.getChannelVideos: returning dummy videos', data: {
    //     'videoCount': dummyVideos.length
    //   });
    //   return dummyVideos;
    // }
    
    try {
      final params = {
        'part': 'snippet',
        'playlistId': uploadsPlaylistId,
        'key': apiKey,
        'maxResults': '10',
      };

      if (pageToken != null) {
        params['pageToken'] = pageToken;
      }

      // API 사용량 체크
      final canCall = await ApiUsageTracker.trackApiCall('playlistItems.list');
      if (!canCall) {
        DebugLogger.logError('YouTubeService.getChannelVideos: API 일일 제한 도달', 'API daily limit reached');
        return [];
      }
      
      DebugLogger.logFlow('YouTubeService.getChannelVideos: making API call', data: {
        'url': '$baseUrl/playlistItems',
        'playlistId': uploadsPlaylistId
      });

      // playlistItems.list 사용 - API 할당량 1단위만 소모 (기존 search.list는 100단위)
      final response = await http.get(
        Uri.parse('$baseUrl/playlistItems').replace(queryParameters: params),
      );

      DebugLogger.logFlow('YouTubeService.getChannelVideos: API response received', data: {
        'statusCode': response.statusCode,
        'bodyLength': response.body.length
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        final videos = items.map((item) => Video.fromPlaylistItem(item)).toList();
        
        DebugLogger.logFlow('YouTubeService.getChannelVideos: videos parsed', data: {
          'videoCount': videos.length,
          'itemsCount': items.length
        });
        
        return videos;
      } else {
        DebugLogger.logError('YouTubeService.getChannelVideos: API error', 
          'Status: ${response.statusCode}, Body: ${response.body}');
        return [];
      }
    } catch (e) {
      DebugLogger.logError('YouTubeService.getChannelVideos: Exception', e);
      return [];
    }
  }

  Future<List<Video>> getCombinedVideos(List<Channel> channels) async {
    List<Video> allVideos = [];
    
    for (Channel channel in channels) {
      if (channel.uploadsPlaylistId.isNotEmpty) {
        final videos = await getChannelVideos(channel.uploadsPlaylistId);
        allVideos.addAll(videos);
      }
    }
    
    allVideos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    return allVideos.take(20).toList();
  }

  // 가중치 기반 추천 영상 가져오기
  @override
  Future<List<Video>> getWeightedRecommendedVideos(
    List<Channel> channels, 
    RecommendationWeights weights
  ) async {
    DebugLogger.logFlow('YouTubeService.getWeightedRecommendedVideos started', data: {
      'channelCount': channels.length,
      'totalWeight': weights.total
    });
    
    if (channels.isEmpty || weights.total == 0) {
      DebugLogger.logFlow('YouTubeService.getWeightedRecommendedVideos: using getCombinedVideos fallback');
      return getCombinedVideos(channels);
    }

    // 모든 채널에서 비디오를 미리 수집 (채널당 최대 10개)
    Map<Channel, List<Video>> channelVideos = {};
    for (Channel channel in channels) {
      if (channel.uploadsPlaylistId.isNotEmpty) {
        final videos = await getChannelVideos(channel.uploadsPlaylistId);
        if (videos.isNotEmpty) {
          // 채널별로 최신 10개의 비디오를 가져와서 다양성 확보
          videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          channelVideos[channel] = videos.take(10).toList();
        }
      }
    }

    DebugLogger.logFlow('YouTubeService.getWeightedRecommendedVideos: collected all videos', data: {
      'channelsWithVideos': channelVideos.length,
      'totalVideos': channelVideos.values.fold(0, (sum, videos) => sum + videos.length)
    });

    // 카테고리별 채널 분류
    final Map<String, List<Channel>> categorizedChannels = _categorizeChannels(channels);
    DebugLogger.logFlow('YouTubeService.getWeightedRecommendedVideos: channels categorized', data: {
      'categoryCounts': categorizedChannels.map((k, v) => MapEntry(k, v.length))
    });
    
    // 카테고리별 영상 개수 계산 (간소화된 분배)
    final videoCounts = _calculateSimplifiedVideoDistribution(categorizedChannels, weights);
    DebugLogger.logFlow('YouTubeService.getWeightedRecommendedVideos: simplified video distribution', data: {
      'videoCounts': videoCounts
    });
    
    List<Video> allSelectedVideos = [];
    Set<String> usedVideoIds = {}; // 중복 방지
    
    // 각 카테고리별로 영상 선택 (중복 없음)
    for (final entry in videoCounts.entries) {
      final category = entry.key;
      final targetCount = entry.value;
      
      if (targetCount <= 0) continue;
      
      final categoryChannels = categorizedChannels[category] ?? [];
      List<Video> categoryVideos = [];
      
      // 카테고리 채널들에서 영상 수집
      for (Channel channel in categoryChannels..shuffle()) {
        final videos = channelVideos[channel] ?? [];
        for (Video video in videos..shuffle()) {
          if (categoryVideos.length >= targetCount) break;
          if (!usedVideoIds.contains(video.id)) {
            categoryVideos.add(video);
            usedVideoIds.add(video.id);
          }
        }
        if (categoryVideos.length >= targetCount) break;
      }
      
      DebugLogger.logFlow('YouTubeService.getWeightedRecommendedVideos: selected videos for category', data: {
        'category': category,
        'targetCount': targetCount,
        'actualCount': categoryVideos.length
      });
      
      allSelectedVideos.addAll(categoryVideos);
    }
    
    // 목표 개수 미달 시 남은 비디오로 채우기
    if (allSelectedVideos.length < 20) {
      final remainingCount = 20 - allSelectedVideos.length;
      List<Video> remainingVideos = [];
      
      for (final videos in channelVideos.values) {
        for (Video video in videos) {
          if (!usedVideoIds.contains(video.id)) {
            remainingVideos.add(video);
            usedVideoIds.add(video.id);
          }
        }
      }
      
      remainingVideos.shuffle();
      allSelectedVideos.addAll(remainingVideos.take(remainingCount));
    }
    
    // 최종 결과 섞기 (카테고리 간 균등 분산)
    allSelectedVideos.shuffle();
    
    DebugLogger.logFlow('YouTubeService.getWeightedRecommendedVideos completed', data: {
      'finalVideoCount': allSelectedVideos.length,
      'uniqueVideos': usedVideoIds.length
    });
    
    return allSelectedVideos.take(20).toList();
  }

  /// 간소화된 영상 분배 계산 (가중치 기반)
  Map<String, int> _calculateSimplifiedVideoDistribution(
    Map<String, List<Channel>> categorizedChannels, 
    RecommendationWeights weights
  ) {
    // 실제로 채널이 있는 카테고리만 고려
    final activeCategories = <String, int>{};
    final categoryWeights = {
      '한글': weights.korean,
      '키즈': weights.kids,
      '만들기': weights.making,
      '게임': weights.games,
      '영어': weights.english,
      '과학': weights.science,
      '미술': weights.art,
      '음악': weights.music,
      '랜덤': weights.random,
    };
    
    // 채널이 있는 카테고리의 가중치만 수집
    int totalActiveWeight = 0;
    for (final entry in categorizedChannels.entries) {
      if (entry.value.isNotEmpty) {
        final weight = categoryWeights[entry.key] ?? 0;
        if (weight > 0) {
          activeCategories[entry.key] = weight;
          totalActiveWeight += weight;
        }
      }
    }
    
    // 가중치 기반으로 20개 영상 분배
    Map<String, int> distribution = {};
    int distributedCount = 0;
    
    for (final entry in activeCategories.entries) {
      final category = entry.key;
      final weight = entry.value;
      
      // 가중치 비율로 영상 개수 계산 (최소 1개 보장)
      int videoCount = ((20 * weight / totalActiveWeight).round()).clamp(1, 20);
      
      // 채널 수보다 많은 영상을 요청하지 않도록 제한
      final channelCount = categorizedChannels[category]?.length ?? 0;
      videoCount = min(videoCount, channelCount * 3); // 채널당 최대 3개
      
      distribution[category] = videoCount;
      distributedCount += videoCount;
    }
    
    // 20개 초과 시 비례적으로 줄이기
    if (distributedCount > 20) {
      final scale = 20.0 / distributedCount;
      int adjustedTotal = 0;
      for (final key in distribution.keys.toList()) {
        final adjusted = (distribution[key]! * scale).round().clamp(1, 20);
        distribution[key] = adjusted;
        adjustedTotal += adjusted;
      }
      
      // 정확히 20개가 되도록 미세 조정
      while (adjustedTotal > 20) {
        final maxKey = distribution.entries.where((e) => e.value > 1)
            .reduce((a, b) => a.value > b.value ? a : b).key;
        distribution[maxKey] = distribution[maxKey]! - 1;
        adjustedTotal--;
      }
    }
    
    return distribution;
  }

  // 채널을 카테고리별로 분류
  Map<String, List<Channel>> _categorizeChannels(List<Channel> channels) {
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
      '키즈': [],
      '한글': [],
      '만들기': [],
      '게임': [],
      '영어': [],
      '과학': [],
      '미술': [],
      '음악': [],
      '랜덤': [],
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

    return result;
  }

  @override
  Future<List<Channel>> getChannelDetails(List<String> channelIds) async {
    if (channelIds.isEmpty) return [];
    
    // 테스트 모드는 삭제 - 실제 API만 사용
    // if (apiKey == 'TEST_API_KEY') {
    //   return _getDummyChannelDetails(channelIds);
    // }
    
    try {
      // API 사용량 체크
      final canCall = await ApiUsageTracker.trackApiCall('channels.list');
      if (!canCall) {
        print('API 일일 제한 도달 - 채널 상세정보 조회 차단');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/channels').replace(queryParameters: {
          'part': 'snippet,statistics,contentDetails',
          'id': channelIds.join(','),
          'key': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        return items.map((item) => Channel.fromJson(item)).toList();
      } else {
        print('Get channel details error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting channel details: $e');
      return [];
    }
  }

  @override
  Future<bool> validateApiKey() async {
    // 테스트 모드는 삭제 - 실제 API만 사용
    // if (apiKey == 'TEST_API_KEY') {
    //   return true;
    // }
    
    try {
      // 더 단순한 API 호출로 검증 (channels API 사용)
      final response = await http.get(
        Uri.parse('$baseUrl/channels').replace(queryParameters: {
          'part': 'snippet',
          'id': 'UC_x5XG1OV2P6uZZ5FSM9Ttw', // Google Developers 채널
          'key': apiKey,
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        // API 키가 잘못되었거나 권한이 없는 경우
        print('API Key validation failed: ${response.body}');
        return false;
      } else {
        // 다른 오류
        print('API validation error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('API validation exception: $e');
      return false;
    }
  }

  // 구독자 수 문자열을 숫자로 변환
  int _parseSubscriberCount(String subscriberCountStr) {
    if (subscriberCountStr.isEmpty || subscriberCountStr == '0') {
      return 0;
    }

    String cleanStr = subscriberCountStr.toLowerCase().replaceAll(',', '');
    double multiplier = 1;
    
    if (cleanStr.contains('k')) {
      multiplier = 1000;
      cleanStr = cleanStr.replaceAll('k', '');
    } else if (cleanStr.contains('m')) {
      multiplier = 1000000;
      cleanStr = cleanStr.replaceAll('m', '');
    }

    try {
      double value = double.parse(cleanStr);
      return (value * multiplier).round();
    } catch (e) {
      print('Error parsing subscriber count: $subscriberCountStr');
      return 0;
    }
  }

  // 사전 정의된 키즈 채널 목록
  List<Map<String, String>> _getPredefinedKidsChannels() {
    return [
      {'id': 'UCcdwLMPsaU2ezNSJU1nFoBQ', 'title': '핑크퉁 (한국어 - Pinkfong)', 'keywords': '핑크퉁 pinkfong 동요 상어가족'},
      {'id': 'UCZx3nJJ9lFLJkN8pGtuM4DA', 'title': '뿐로로(Pororo)', 'keywords': '뿐로로 pororo 크롱 루피 패티'},
      {'id': 'UCOJplhB0wGQWv9OuRmMT-4g', 'title': 'Tayo 타요', 'keywords': '타요 tayo 버스 꼬마버스'},
      {'id': 'UCJplp6SdfOJI0P0VXYlW8GA', 'title': '브레드이발바닥', 'keywords': '브레드 이발바닥 빵'},
      {'id': 'UCQ5xK8p4KbmgAqL0AIIN5GA', 'title': '아기상어 올리 브루크린', 'keywords': '아기상어 올리 브루크린 babyshark'},
      {'id': 'UC9VvlCrMIXfzu7qEekEGM-Q', 'title': '다이노코', 'keywords': '다이노코 공룡 dinosaur'},
      {'id': 'UCfrr0mYePKXMIvUJ7NXrX_w', 'title': '코코몹', 'keywords': '코코몹 cocomong'},
      {'id': 'UCUVTlX2eN-CUf-6Qe1WW5_A', 'title': 'BabyBus', 'keywords': '베이비버스 babybus 키키 미미'},
      {'id': 'UCqiI-lakOzZ1wKI8vR1k-1A', 'title': '토모키즈', 'keywords': '토모키즈 tomokids'},
      {'id': 'UCN0J5CaTaPv1gK6z5QjiLqg', 'title': '라인키즈', 'keywords': '라인키즈 linekids 라인프렌즈'},
      {'id': 'UC1dLf3cC9RN8vN8W7xWi-3Q', 'title': '지니키즈', 'keywords': '지니키즈 jinikids 지니'},
      {'id': 'UC8IRcpAuFPHR93XwBAXc5fw', 'title': '캐리와 장난감 친구들', 'keywords': '캐리 캐리와장난감친구들 carrie'},
      {'id': 'UCCQnm2HEs5DWQGOdKvLY_gg', 'title': '시크릿쥬쥬', 'keywords': '시크릿쥬쥬 secret jouju'},
      {'id': 'UCfrr6P7t8eJ94FfTJXTaU0Q', 'title': '프리티큐어', 'keywords': '프리티큐어 prettycure'},
      {'id': 'UCLkAepWjdylmXSltofFvsYQ', 'title': 'BANGTANTV', 'keywords': 'bts 방탄소년단 bangtantv'},
      {'id': 'UCX6OQ3DkcsbYNE6H8uQQuVA', 'title': 'MrBeast', 'keywords': 'mrbeast 미스터비스트'},
      {'id': 'UCEDkO7wshcDZ7UZo17rPkzQ', 'title': '보람튜브', 'keywords': '보람튜브 boram 보람'},
      {'id': 'UCF39xPmlr1Ds5WShxpKDwqg', 'title': '도티도티', 'keywords': '도티도티 dotty 도티'},
      {'id': 'UCp9w2H88dy-GinZXe8nyx-Q', 'title': '포켓몹', 'keywords': '포켓몹 pokemonkids 포켓몬'},
      {'id': 'UCnWWLTNKFJT7SPD_mXdvCHw', 'title': '레고', 'keywords': '레고 lego 레고키즈'},
      {'id': 'UCY2qt3dw2TQJxvBrDiYGHdQ', 'title': 'Pink Pong', 'keywords': 'pinkpong 핑크퐁 영어'},
      {'id': 'UCSKhg6h-n4tiq_POc8JJ0JQ', 'title': '토이푸딩', 'keywords': '토이푸딩 toypudding 장난감'},
      {'id': 'UCl-0hm5_RkuNwGjHrO1K5HQ', 'title': '수리네 미니어처', 'keywords': '수리 미니어처 장난감'},
      {'id': 'UCHYd3mCvTUVHcUwXCjOKOZA', 'title': '키네틱샌드', 'keywords': '키네틱샌드 kinetic sand 모래놀이'},
      {'id': 'UCcdI9y0Fp1XY0CAKoq3tJJA', 'title': '오은영키즈', 'keywords': '오은영 키즈 영어 교육'},
      {'id': 'UCJNgT0vsJy1hDy1LUmR7LYw', 'title': '앤게임', 'keywords': '앤게임 게임 로블록스'},
      {'id': 'UCKfFErjlYqK1az8VXUrp7Pw', 'title': '파니의 텔레토비', 'keywords': '파니 텔레토비 pani'},
      {'id': 'UCcCjxqZQKMPPmPO73315P9g', 'title': '수리수리 마수리', 'keywords': '수리수리마수리 마술 트릭'},
      {'id': 'UCQ5YRbtOym9jiw2oe4RqiEA', 'title': '블리피', 'keywords': '블리피 blippi 영어교육'},
      {'id': 'UC7fyfh_A3aIidNRddmM7-8Q', 'title': 'CoComelon', 'keywords': 'cocomelon 코코멜론 영어동요'}
    ];
  }
}