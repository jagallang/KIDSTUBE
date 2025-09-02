import '../models/recommendation_weights.dart';
import '../core/base_provider.dart';
import '../core/interfaces/i_storage_service.dart';
import '../core/cache_manager.dart';

/// Recommendation provider with clean architecture and dependency injection
/// Manages recommendation weights configuration
class RecommendationProvider extends CacheableProvider<RecommendationWeights> {
  final IStorageService _storageService;
  
  RecommendationWeights _weights = const RecommendationWeights();

  RecommendationWeights get weights => _weights;

  RecommendationProvider({
    required IStorageService storageService,
  }) : _storageService = storageService {
    // Use smart cache duration for recommendation weights
    final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.recommendationWeights);
    setCacheTimeout(cacheDuration);
  }

  /// Load recommendation weights
  Future<void> loadWeights() async {
    await executeOperation<void>(
      () async {
        _weights = await _storageService.getRecommendationWeights();
        updateCacheTimestamp();
      },
      errorPrefix: '추천 설정을 불러오는데 실패했습니다',
    );
  }

  /// Save recommendation weights
  Future<void> saveWeights() async {
    await executeOperation<void>(
      () async {
        await _storageService.storeRecommendationWeights(_weights);
        updateCacheTimestamp();
      },
      showLoading: false,
      errorPrefix: '추천 설정 저장에 실패했습니다',
    );
  }

  /// Update weight for a specific category
  void updateWeight(String category, int value) {
    if (value < 0 || value > 10) {
      setError('가중치는 0-10 사이의 값이어야 합니다');
      return;
    }

    clearError();
    
    switch (category) {
      case '한글':
        _weights = _weights.copyWith(korean: value);
        break;
      case '키즈':
        _weights = _weights.copyWith(kids: value);
        break;
      case '만들기':
        _weights = _weights.copyWith(making: value);
        break;
      case '게임':
        _weights = _weights.copyWith(games: value);
        break;
      case '영어':
        _weights = _weights.copyWith(english: value);
        break;
      case '과학':
        _weights = _weights.copyWith(science: value);
        break;
      case '미술':
        _weights = _weights.copyWith(art: value);
        break;
      case '음악':
        _weights = _weights.copyWith(music: value);
        break;
      case '랜덤':
        _weights = _weights.copyWith(random: value);
        break;
      default:
        setError('알 수 없는 카테고리: $category');
        return;
    }
    
    notifyListeners();
  }

  /// Reset to default values
  void resetToDefaults() {
    _weights = const RecommendationWeights();
    clearError();
    notifyListeners();
  }

  /// Get weight for a specific category
  int getWeightForCategory(String category) {
    switch (category) {
      case '한글':
        return _weights.korean;
      case '키즈':
        return _weights.kids;
      case '만들기':
        return _weights.making;
      case '게임':
        return _weights.games;
      case '영어':
        return _weights.english;
      case '과학':
        return _weights.science;
      case '미술':
        return _weights.art;
      case '음악':
        return _weights.music;
      case '랜덤':
        return _weights.random;
      default:
        return 0;
    }
  }

  /// Get ratio for a specific category as percentage
  double getRatioForCategory(String category) {
    if (_weights.total == 0) return 0.0;
    return getWeightForCategory(category) / _weights.total * 100;
  }

  /// Get video count for a specific category based on total video count
  int getVideoCountForCategory(String category, int totalVideos) {
    if (_weights.total == 0) return 0;
    
    final videoCounts = _weights.getVideoCountsForTotal(totalVideos);
    return videoCounts[category] ?? 0;
  }

  /// Validate weights configuration
  bool validateWeights() {
    if (_weights.total == 0) {
      setError('최소 하나의 카테고리에 가중치를 설정해야 합니다');
      return false;
    }
    
    if (_weights.total > 90) {  // Reasonable upper limit
      setError('총 가중치가 너무 큽니다 (최대 90)');
      return false;
    }
    
    clearError();
    return true;
  }

  /// Get all categories with their weights
  Map<String, int> getAllWeights() {
    return {
      '한글': _weights.korean,
      '키즈': _weights.kids,
      '만들기': _weights.making,
      '게임': _weights.games,
      '영어': _weights.english,
      '과학': _weights.science,
      '미술': _weights.art,
      '음악': _weights.music,
      '랜덤': _weights.random,
    };
  }

  /// Apply preset configuration
  void applyPreset(String presetName) {
    clearError();
    
    switch (presetName) {
      case 'balanced':
        _weights = const RecommendationWeights(
          korean: 3, kids: 3, making: 2, games: 1, english: 2,
          science: 2, art: 1, music: 1, random: 1,
        );
        break;
      case 'educational':
        _weights = const RecommendationWeights(
          korean: 4, kids: 1, making: 2, games: 1, english: 4,
          science: 3, art: 2, music: 2, random: 1,
        );
        break;
      case 'entertainment':
        _weights = const RecommendationWeights(
          korean: 1, kids: 4, making: 2, games: 3, english: 1,
          science: 1, art: 2, music: 3, random: 3,
        );
        break;
      default:
        _weights = const RecommendationWeights();
    }
    
    notifyListeners();
  }
}