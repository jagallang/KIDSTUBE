import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/video.dart';
import '../models/recommendation_weights.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/debug_logger.dart';

class YouTubeService implements IYouTubeService {
  final String apiKey;
  final String baseUrl = 'https://www.googleapis.com/youtube/v3';

  YouTubeService({required this.apiKey});

  @override
  Future<List<Channel>> searchChannels(String query) async {
    // 테스트 모드일 때 더미 데이터 반환
    if (apiKey == 'TEST_API_KEY') {
      return _getDummyChannels(query);
    }
    
    try {
      // 1단계: 채널 검색
      final searchResponse = await http.get(
        Uri.parse('$baseUrl/search').replace(queryParameters: {
          'part': 'snippet',
          'type': 'channel',
          'q': query,
          'key': apiKey,
          'maxResults': '25',
        }),
      );

      if (searchResponse.statusCode != 200) {
        print('Search API error: ${searchResponse.statusCode}');
        return [];
      }

      final searchData = json.decode(searchResponse.body);
      final searchItems = searchData['items'] as List? ?? [];
      
      if (searchItems.isEmpty) {
        return [];
      }

      // 2단계: 채널 ID들 수집
      final channelIds = <String>[];
      for (final item in searchItems) {
        String channelId = '';
        if (item['id'] is String) {
          channelId = item['id'];
        } else if (item['id'] is Map && item['id']['channelId'] != null) {
          channelId = item['id']['channelId'];
        } else if (item['snippet'] != null && item['snippet']['channelId'] != null) {
          channelId = item['snippet']['channelId'];
        }
        
        if (channelId.isNotEmpty && !channelIds.contains(channelId)) {
          channelIds.add(channelId);
        }
      }

      if (channelIds.isEmpty) {
        return searchItems.map((item) => Channel.fromJson(item)).toList();
      }

      // 3단계: 채널 상세 정보 (구독자 수 포함) 가져오기
      final channelsResponse = await http.get(
        Uri.parse('$baseUrl/channels').replace(queryParameters: {
          'part': 'snippet,statistics,contentDetails',
          'id': channelIds.join(','),
          'key': apiKey,
        }),
      );

      if (channelsResponse.statusCode == 200) {
        final channelsData = json.decode(channelsResponse.body);
        final channelItems = channelsData['items'] as List? ?? [];
        final channels = channelItems.map((item) => Channel.fromJson(item)).toList();
        
        // 구독자 수 1만명 이상인 채널만 필터링
        return channels.where((channel) {
          final subscriberCount = _parseSubscriberCount(channel.subscriberCount);
          return subscriberCount >= 10000;
        }).toList();
      } else {
        print('Channels API error: ${channelsResponse.statusCode}');
        // 구독자 수 없이라도 기본 정보 반환
        return searchItems.map((item) => Channel.fromJson(item)).toList();
      }
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
    
    // 테스트 모드일 때 더미 데이터 반환
    if (apiKey == 'TEST_API_KEY') {
      final dummyVideos = _getDummyVideos(uploadsPlaylistId);
      DebugLogger.logFlow('YouTubeService.getChannelVideos: returning dummy videos', data: {
        'videoCount': dummyVideos.length
      });
      return dummyVideos;
    }
    
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
    
    // 테스트 모드일 때 더미 데이터 반환
    if (apiKey == 'TEST_API_KEY') {
      return _getDummyChannelDetails(channelIds);
    }
    
    try {
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
    // 테스트 모드는 항상 유효
    if (apiKey == 'TEST_API_KEY') {
      return true;
    }
    
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

  // 테스트용 더미 채널 데이터
  List<Channel> _getDummyChannels(String query) {
    final channels = [
      Channel(
        id: 'dummy_pororo',
        title: '뽀로로(Pororo)',
        thumbnail: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=뽀로로',
        subscriberCount: '1230000',
        uploadsPlaylistId: 'UUdummy_pororo',
      ),
      Channel(
        id: 'dummy_pinkfong',
        title: '핑크퐁(Pinkfong)',
        thumbnail: 'https://via.placeholder.com/150/FF69B4/FFFFFF?text=핑크퐁',
        subscriberCount: '5670000',
        uploadsPlaylistId: 'UUdummy_pinkfong',
      ),
      Channel(
        id: 'dummy_tayo',
        title: '타요(Tayo)',
        thumbnail: 'https://via.placeholder.com/150/0066CC/FFFFFF?text=타요',
        subscriberCount: '890000',
        uploadsPlaylistId: 'UUdummy_tayo',
      ),
      Channel(
        id: 'dummy_cocomong',
        title: '코코몽(Cocomong)',
        thumbnail: 'https://via.placeholder.com/150/00AA00/FFFFFF?text=코코몽',
        subscriberCount: '450000',
        uploadsPlaylistId: 'UUdummy_cocomong',
      ),
      Channel(
        id: 'dummy_babybus',
        title: '베이비버스(BabyBus)',
        thumbnail: 'https://via.placeholder.com/150/FFD700/FFFFFF?text=베이비버스',
        subscriberCount: '2340000',
        uploadsPlaylistId: 'UUdummy_babybus',
      ),
    ];
    
    // 검색어 필터링
    if (query.isNotEmpty) {
      return channels.where((channel) => 
        channel.title.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    return channels;
  }

  // 테스트용 더미 채널 상세 데이터
  List<Channel> _getDummyChannelDetails(List<String> channelIds) {
    final allChannels = _getDummyChannels('');
    return allChannels.where((channel) => channelIds.contains(channel.id)).toList();
  }

  // 테스트용 더미 비디오 데이터
  List<Video> _getDummyVideos(String channelId) {
    final now = DateTime.now();
    final videos = <Video>[];
    
    List<String> titles = [];
    String channelTitle = '';
    String colorHex = 'FF6B6B';
    
    if (channelId == 'dummy_pororo') {
      channelTitle = '뽀로로';
      colorHex = 'FF0000';
      titles = [
        '뽀로로와 친구들 - 눈사람 만들기',
        '뽀로로 신나는 노래모음 🎵',
        '크롱이와 함께하는 요리시간',
        '뽀로로 겨울 스포츠 도전기',
        '루피의 마법 이야기',
        '에디의 발명품 소동',
        '패티와 함께 춤춰요 💃',
        '뽀로로 우주 대모험',
        '포비와 해리의 하루',
        '뽀로로 숨바꼭질 놀이'
      ];
    } else if (channelId == 'dummy_pinkfong') {
      channelTitle = '핑크퐁';
      colorHex = 'FF69B4';
      titles = [
        '🦈 상어가족 | 인기동요',
        '🎵 핑크퐁 동물동요 모음',
        '🚗 자동차 동요 베스트',
        '🌟 반짝반짝 작은별',
        '🎃 할로윈 스페셜 송',
        '🎄 크리스마스 캐롤 모음',
        '🐰 토끼와 거북이 이야기',
        '🌈 무지개 색깔 송',
        '🎂 생일축하 노래',
        '🦋 나비야 나비야 동요'
      ];
    } else if (channelId == 'dummy_tayo') {
      channelTitle = '타요';
      colorHex = '0066CC';
      titles = [
        '🚌 타요 꼬마버스의 하루',
        '🚗 로기와 함께 출동!',
        '🚛 헤비와 친구들',
        '🏥 앰버의 구급차 활동',
        '🚒 프랭크 소방차 이야기',
        '🚕 누리의 택시 여행',
        '⛽ 시드니 주유소 친구들',
        '🎪 타요 서커스단',
        '🏖️ 바닷가 여행 대작전',
        '🎮 타요 게임 시간'
      ];
    } else if (channelId == 'dummy_cocomong') {
      channelTitle = '코코몽';
      colorHex = '00AA00';
      titles = [
        '🤖 코코몽의 로봇 친구',
        '🚀 우주선 모험 여행',
        '🧪 아리의 과학 실험',
        '🎨 미미의 그림 교실',
        '🍰 요요의 베이킹 타임',
        '⚽ 축구왕 코코몽',
        '🎪 서커스단 입단기',
        '🏰 성 탐험 대모험',
        '🌊 바다 속 친구들',
        '🎵 코코몽 댄스 파티'
      ];
    } else if (channelId == 'dummy_babybus') {
      channelTitle = '베이비버스';
      colorHex = 'FFD700';
      titles = [
        '🐼 키키와 미미의 하루',
        '🚑 병원놀이 게임',
        '👮 경찰관 체험',
        '👩‍🍳 요리사가 되어보자',
        '🏫 유치원 첫날',
        '🚗 교통안전 교육',
        '🦷 이 닦기 습관',
        '🧸 장난감 정리하기',
        '🌱 식물 키우기',
        '📚 숫자 배우기 123'
      ];
    }
    
    for (int i = 0; i < titles.length; i++) {
      videos.add(Video(
        id: 'dummy_video_${channelId}_$i',
        title: titles[i],
        thumbnail: 'https://via.placeholder.com/480x360/$colorHex/FFFFFF?text=${i+1}',
        channelTitle: channelTitle,
        publishedAt: now.subtract(Duration(hours: i * 6 + (i * 3))).toIso8601String(),
      ));
    }
    
    return videos;
  }
}