import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/video.dart';
import '../models/recommendation_weights.dart';
import '../core/cache/cache_manager.dart';
import '../core/errors/result.dart';

class YouTubeService {
  final String apiKey;
  final String baseUrl = 'https://www.googleapis.com/youtube/v3';
  final CacheManager _cache;

  YouTubeService({required this.apiKey, CacheManager? cache}) 
    : _cache = cache ?? MemoryCacheManager(defaultTtl: const Duration(minutes: 30));

  /// 네트워크 연결 상태 확인
  Future<bool> checkNetworkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Network check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> searchChannels(String query) async {
    
    try {
      print('🔍 Searching channels with query: $query');
      
      // 네트워크 연결 확인
      final hasConnection = await checkNetworkConnection();
      if (!hasConnection) {
        return {
          'success': false,
          'channels': <Channel>[],
          'message': '인터넷 연결을 확인해주세요\n네트워크에 연결되지 않았습니다'
        };
      }
      
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

      print('🌐 Search API Response: ${searchResponse.statusCode}');
      
      if (searchResponse.statusCode != 200) {
        final errorBody = searchResponse.body;
        print('❌ Search API error body: $errorBody');
        
        String errorMessage = '검색 중 오류가 발생했습니다';
        
        if (searchResponse.statusCode == 403) {
          try {
            final errorData = json.decode(errorBody);
            final error = errorData['error'];
            if (error != null) {
              if (error['message'].toString().contains('API_KEY_INVALID')) {
                errorMessage = 'API 키가 올바르지 않습니다';
              } else if (error['message'].toString().contains('QUOTA_EXCEEDED')) {
                errorMessage = 'API 할당량이 초과되었습니다\n내일 다시 시도해주세요';
              } else if (error['message'].toString().contains('ACCESS_NOT_CONFIGURED')) {
                errorMessage = 'YouTube Data API가 활성화되지 않았습니다\nGoogle Cloud Console에서 활성화해주세요';
              } else {
                errorMessage = error['message'] ?? errorMessage;
              }
            }
          } catch (e) {
            print('Error parsing error response: $e');
          }
        } else if (searchResponse.statusCode == 400) {
          errorMessage = '잘못된 검색 요청입니다';
        } else if (searchResponse.statusCode >= 500) {
          errorMessage = 'YouTube 서버 오류입니다\n잠시 후 다시 시도해주세요';
        }
        
        return {
          'success': false,
          'channels': <Channel>[],
          'message': errorMessage,
          'statusCode': searchResponse.statusCode
        };
      }

      final searchData = json.decode(searchResponse.body);
      final searchItems = searchData['items'] as List? ?? [];
      
      print('📊 Found ${searchItems.length} search results');
      
      if (searchItems.isEmpty) {
        return {
          'success': true,
          'channels': <Channel>[],
          'message': '검색 결과가 없습니다'
        };
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
        final basicChannels = searchItems.map((item) => Channel.fromJson(item)).toList();
        return {
          'success': true,
          'channels': basicChannels,
          'message': '기본 정보로 ${basicChannels.length}개 채널을 찾았습니다'
        };
      }

      print('🔗 Fetching detailed info for ${channelIds.length} channels');

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
        final allChannels = channelItems.map((item) => Channel.fromJson(item)).toList();
        
        // 구독자 수 1만명 이상인 채널만 필터링
        final filteredChannels = allChannels.where((channel) {
          final subscriberCount = _parseSubscriberCount(channel.subscriberCount);
          return subscriberCount >= 10000;
        }).toList();
        
        print('✅ Returning ${filteredChannels.length} channels (filtered from ${allChannels.length})');
        
        return {
          'success': true,
          'channels': filteredChannels,
          'message': '${filteredChannels.length}개의 채널을 찾았습니다'
        };
      } else {
        print('⚠️ Channels API error: ${channelsResponse.statusCode}');
        // 구독자 수 없이라도 기본 정보 반환
        final basicChannels = searchItems.map((item) => Channel.fromJson(item)).toList();
        return {
          'success': true,
          'channels': basicChannels,
          'message': '기본 정보로 ${basicChannels.length}개 채널을 찾았습니다 (구독자 수 정보 없음)'
        };
      }
    } catch (e) {
      print('💥 Exception searching channels: $e');
      return {
        'success': false,
        'channels': <Channel>[],
        'message': '네트워크 연결을 확인해주세요\n($e)'
      };
    }
  }

  Future<List<Video>> getChannelVideos(String uploadsPlaylistId, {String? pageToken}) async {
    
    // 캐시 키 생성 (pageToken 포함)
    final cacheKey = pageToken != null 
      ? '${CacheKeys.channelVideos(uploadsPlaylistId)}_$pageToken'
      : CacheKeys.channelVideos(uploadsPlaylistId);
    
    // 캐시 확인
    final cachedResult = await _cache.get<List<Video>>(
      cacheKey, 
      (json) => (json['videos'] as List).map((item) => Video.fromJson(item)).toList()
    );
    
    if (cachedResult.isSuccess && cachedResult.dataOrNull != null) {
      print('캐시에서 영상 로드: $uploadsPlaylistId (${cachedResult.dataOrNull!.length}개)');
      return cachedResult.dataOrNull!;
    }
    
    try {
      final params = {
        'part': 'snippet',
        'playlistId': uploadsPlaylistId,
        'key': apiKey,
        'maxResults': '50',
      };

      if (pageToken != null) {
        params['pageToken'] = pageToken;
      }

      // playlistItems.list 사용 - API 할당량 1단위만 소모 (기존 search.list는 100단위)
      final response = await http.get(
        Uri.parse('$baseUrl/playlistItems').replace(queryParameters: params),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        final videos = items.map((item) => Video.fromPlaylistItem(item)).toList();
        
        // 캐시에 저장
        await _cache.set(
          cacheKey, 
          {'videos': videos.map((v) => v.toJson()).toList()}, 
          () => {'videos': videos.map((v) => v.toJson()).toList()}
        );
        
        print('API에서 영상 로드 및 캐시 저장: $uploadsPlaylistId (${videos.length}개)');
        return videos;
      }
      return [];
    } catch (e) {
      print('Error getting channel videos: $e');
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
    
    return allVideos.take(10).toList();
  }

  // 가중치 기반 추천 영상 가져오기 - 병렬 처리 최적화
  Future<List<Video>> getWeightedRecommendedVideos(
    List<Channel> channels, 
    RecommendationWeights weights
  ) async {
    if (channels.isEmpty || weights.total == 0) {
      return getCombinedVideos(channels);
    }

    // 카테고리별 채널 분류
    final Map<String, List<Channel>> categorizedChannels = _categorizeChannels(channels);
    
    // 카테고리별 영상 개수 계산 - 100개로 대폭 확장 (무제한에 가까운 추천)
    final videoCounts = weights.getVideoCountsForTotal(100);
    
    List<Video> recommendedVideos = [];
    
    // 병렬 처리를 위한 Future 리스트
    List<Future<List<Video>>> categoryFutures = [];
    
    // 각 카테고리별로 병렬 영상 수집
    for (final entry in videoCounts.entries) {
      final category = entry.key;
      final targetCount = entry.value;
      
      print('카테고리 $category: 목표 ${targetCount}개');
      
      if (targetCount <= 0) continue;
      
      final categoryChannels = categorizedChannels[category] ?? [];
      if (categoryChannels.isEmpty && category != '랜덤') continue;
      
      // 각 카테고리를 병렬로 처리
      categoryFutures.add(_fetchCategoryVideos(category, categoryChannels, targetCount, channels));
    }
    
    // 모든 카테고리 병렬 실행 및 결과 수집
    if (categoryFutures.isNotEmpty) {
      final allCategoryResults = await Future.wait(categoryFutures);
      for (final categoryVideos in allCategoryResults) {
        recommendedVideos.addAll(categoryVideos);
      }
    }
    
    print('병렬 수집 완료: ${recommendedVideos.length}개');
    
    // 10개 미만이면 추가 영상 수집
    if (recommendedVideos.length < 10) {
      print('${10 - recommendedVideos.length}개 추가 영상 필요');
      final existingIds = recommendedVideos.map((v) => v.id).toSet();
      final additionalVideos = await getCombinedVideos(channels);
      final uniqueAdditional = additionalVideos.where((v) => !existingIds.contains(v.id)).toList();
      recommendedVideos.addAll(uniqueAdditional.take(10 - recommendedVideos.length));
    }
    
    // 전체 결과를 섞어서 카테고리별로 분산되도록 함
    recommendedVideos.shuffle();
    
    final finalVideos = recommendedVideos.take(10).toList();
    print('최종 반환 영상 개수: ${finalVideos.length}');
    
    return finalVideos;
  }

  // 카테고리별 영상 수집 (병렬 처리용)
  Future<List<Video>> _fetchCategoryVideos(
    String category, 
    List<Channel> categoryChannels, 
    int targetCount,
    List<Channel> allChannels
  ) async {
    List<Video> categoryVideos = [];
    
    if (category == '랜덤') {
      // 랜덤의 경우 모든 채널에서 무작위 선택
      final shuffledChannels = allChannels.toList()..shuffle();
      final channelFutures = <Future<List<Video>>>[];
      
      // 각 채널에서 병렬로 영상 가져오기 (최대 5개 채널까지)
      for (int i = 0; i < min(5, shuffledChannels.length); i++) {
        final channel = shuffledChannels[i];
        if (channel.uploadsPlaylistId.isNotEmpty) {
          channelFutures.add(getChannelVideos(channel.uploadsPlaylistId));
        }
      }
      
      if (channelFutures.isNotEmpty) {
        final allChannelVideos = await Future.wait(channelFutures);
        for (final videos in allChannelVideos) {
          if (categoryVideos.length >= targetCount) break;
          if (videos.isNotEmpty) {
            videos.shuffle();
            categoryVideos.addAll(videos.take(min(2, targetCount - categoryVideos.length)));
          }
        }
      }
    } else {
      // 특정 카테고리 채널에서 병렬 영상 수집
      final channelFutures = categoryChannels
        .where((channel) => channel.uploadsPlaylistId.isNotEmpty)
        .map((channel) => getChannelVideos(channel.uploadsPlaylistId))
        .toList();
      
      if (channelFutures.isNotEmpty) {
        final allChannelVideos = await Future.wait(channelFutures);
        for (final videos in allChannelVideos) {
          categoryVideos.addAll(videos);
        }
        
        // 최신순 정렬 후 목표 개수만큼 선택
        categoryVideos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        categoryVideos = categoryVideos.take(targetCount).toList();
      }
    }
    
    return categoryVideos;
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

  Future<Map<String, dynamic>> validateApiKey() async {
    
    try {
      // 더 간단한 API 호출로 검증 - search API 사용
      final response = await http.get(
        Uri.parse('$baseUrl/search').replace(queryParameters: {
          'part': 'snippet',
          'type': 'channel',
          'q': 'YouTube',
          'maxResults': '1',
          'key': apiKey,
        }),
      );
      
      print('API Validation Response: ${response.statusCode}');
      print('API Validation Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return {'isValid': true, 'message': 'API Key is valid'};
      } else if (response.statusCode == 403) {
        final responseBody = json.decode(response.body);
        final error = responseBody['error'];
        String message = 'API 키가 유효하지 않습니다';
        
        if (error != null) {
          if (error['message'].toString().contains('API_KEY_INVALID')) {
            message = 'API 키가 올바르지 않습니다';
          } else if (error['message'].toString().contains('FORBIDDEN')) {
            message = 'YouTube Data API가 활성화되지 않았거나\n권한이 없습니다';
          } else if (error['message'].toString().contains('QUOTA_EXCEEDED')) {
            message = 'API 할당량이 초과되었습니다\n내일 다시 시도해주세요';
          } else {
            message = error['message'] ?? message;
          }
        }
        
        return {'isValid': false, 'message': message};
      } else if (response.statusCode == 400) {
        return {'isValid': false, 'message': '잘못된 API 요청입니다\nAPI 키를 확인해주세요'};
      } else {
        return {'isValid': false, 'message': 'API 검증 중 오류가 발생했습니다\n(${response.statusCode})'};
      }
    } catch (e) {
      print('API validation exception: $e');
      return {'isValid': false, 'message': '네트워크 연결을 확인해주세요'};
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

}