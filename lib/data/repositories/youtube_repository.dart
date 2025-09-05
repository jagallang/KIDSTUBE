// 개선된 YouTube Repository with 캐싱 & 에러 처리
import '../../core/cache/cache_manager.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/rate_limiter.dart';
import '../../models/video.dart';
import '../../models/channel.dart';
import '../datasources/youtube_api_client.dart';

class YouTubeRepository {
  final YouTubeApiClient _apiClient;
  final CacheManager _cacheManager;
  final YouTubeApiRateLimiter _rateLimiter;

  YouTubeRepository({
    required YouTubeApiClient apiClient,
    required CacheManager cacheManager,
    YouTubeApiRateLimiter? rateLimiter,
  }) : _apiClient = apiClient,
       _cacheManager = cacheManager,
       _rateLimiter = rateLimiter ?? YouTubeApiRateLimiter.instance;

  // 채널 검색 (캐싱 + 레이트 리미팅)
  Future<Result<List<Channel>>> searchChannels(String query) async {
    final cacheKey = 'search_channels_$query';
    
    // 캐시에서 먼저 확인
    final cachedResult = await _cacheManager.get(
      cacheKey, 
      (json) => Channel.fromJson(json),
    );
    
    if (cachedResult.isSuccess && cachedResult.dataOrNull != null) {
      return Success([cachedResult.dataOrNull!]);
    }

    // 레이트 리미트 확인
    if (!YouTubeApiRateLimiter.canMakeWeightedRequest('search')) {
      return const Failure(QuotaExceededError());
    }

    // API 호출
    final apiResult = await _apiClient.searchChannels(query);
    
    if (apiResult.isFailure) {
      return apiResult;
    }

    // 성공 시 캐시 저장 및 레이트 리미트 기록
    final channels = apiResult.dataOrNull!;
    for (final channel in channels) {
      await _cacheManager.set(
        CacheKeys.channelDetails(channel.id),
        channel,
        () => channel,
      );
    }
    
    YouTubeApiRateLimiter.recordWeightedRequest('search');
    
    return Success(channels);
  }

  // 채널 상세 정보 가져오기
  Future<Result<Channel>> getChannelDetails(String channelId) async {
    final cacheKey = CacheKeys.channelDetails(channelId);
    
    // 캐시 확인
    final cachedResult = await _cacheManager.get(
      cacheKey,
      (json) => Channel.fromJson(json),
    );
    
    if (cachedResult.isSuccess && cachedResult.dataOrNull != null) {
      return Success(cachedResult.dataOrNull!);
    }

    // 레이트 리미트 확인
    if (!YouTubeApiRateLimiter.canMakeWeightedRequest('channels')) {
      return const Failure(QuotaExceededError());
    }

    // API 호출
    final apiResult = await _apiClient.getChannelDetails(channelId);
    
    if (apiResult.isFailure) {
      return apiResult;
    }

    // 캐시 저장
    final channel = apiResult.dataOrNull!;
    await _cacheManager.set(cacheKey, channel, () => channel);
    
    YouTubeApiRateLimiter.recordWeightedRequest('channels');
    
    return Success(channel);
  }

  // 채널 비디오 가져오기 (최적화된 방식)
  Future<Result<List<Video>>> getChannelVideos(String channelId, {int maxResults = 20}) async {
    final cacheKey = CacheKeys.channelVideos(channelId);
    
    // 캐시 확인
    final cachedResult = await _cacheManager.get(
      cacheKey,
      (json) => Video.fromJson(json),
    );
    
    if (cachedResult.isSuccess && cachedResult.dataOrNull != null) {
      return Success([cachedResult.dataOrNull!]);
    }

    // 레이트 리미트 확인
    if (!YouTubeApiRateLimiter.canMakeWeightedRequest('playlistItems')) {
      return const Failure(QuotaExceededError());
    }

    // API 호출 (playlistItems 사용으로 할당량 절약)
    final apiResult = await _apiClient.getChannelVideos(channelId, maxResults: maxResults);
    
    if (apiResult.isFailure) {
      return apiResult;
    }

    // 캐시 저장
    final videos = apiResult.dataOrNull!;
    for (final video in videos) {
      await _cacheManager.set(
        'video_${video.id}',
        video,
        () => video,
      );
    }
    
    YouTubeApiRateLimiter.recordWeightedRequest('playlistItems');
    
    return Success(videos);
  }

  // 추천 비디오 가져오기 (가중치 기반)
  Future<Result<List<Video>>> getRecommendedVideos(
    List<String> channelIds,
    Map<String, int> categoryWeights,
  ) async {
    final allVideos = <Video>[];
    final errors = <AppError>[];

    // 채널별로 비디오 가져오기
    for (final channelId in channelIds) {
      final result = await getChannelVideos(channelId);
      
      if (result.isSuccess) {
        allVideos.addAll(result.dataOrNull!);
      } else {
        errors.add(result.errorOrNull!);
      }
    }

    // 일부 오류가 있어도 일부 결과가 있으면 계속 진행
    if (allVideos.isEmpty && errors.isNotEmpty) {
      return Failure(errors.first);
    }

    // 가중치 기반 필터링 및 섞기
    final recommendedVideos = _applyWeightedRecommendation(allVideos, categoryWeights);
    
    return Success(recommendedVideos);
  }

  // 오프라인 모드 지원
  Future<Result<List<Video>>> getCachedVideos() async {
    try {
      // 캐시에서 모든 비디오 가져오기
      final cachedVideos = <Video>[];
      
      // TODO: 실제 캐시 스캔 구현
      
      if (cachedVideos.isEmpty) {
        return const Failure(CacheError(
          message: '오프라인 모드에서 사용할 수 있는 데이터가 없습니다',
          code: 'NO_CACHED_DATA',
        ));
      }
      
      return Success(cachedVideos);
    } catch (e) {
      return Failure(CacheError(
        message: '캐시된 데이터 로드 실패',
        details: e.toString(),
      ));
    }
  }

  // 가중치 기반 추천 로직
  List<Video> _applyWeightedRecommendation(
    List<Video> videos, 
    Map<String, int> weights,
  ) {
    // TODO: 실제 가중치 기반 로직 구현
    final shuffled = List<Video>.from(videos)..shuffle();
    return shuffled.take(20).toList();
  }

  // 캐시 정리
  Future<Result<void>> clearCache() async {
    return await _cacheManager.clear();
  }

  // 통계 정보
  Map<String, dynamic> getUsageStats() {
    return {
      'rateLimitStats': YouTubeApiRateLimiter.instance.getUsageStats(),
      'cacheStats': {}, // TODO: 캐시 통계 구현
    };
  }
}