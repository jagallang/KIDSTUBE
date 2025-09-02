import 'package:flutter/foundation.dart';
import '../models/recommendation_weights.dart';
import '../services/storage_service.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationWeights _weights = const RecommendationWeights();
  bool _isLoading = false;
  String? _error;

  RecommendationWeights get weights => _weights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWeights() async {
    _setLoading(true);
    _clearError();

    try {
      _weights = await StorageService.getRecommendationWeights();
    } catch (e) {
      _setError('추천 설정을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveWeights() async {
    _clearError();

    try {
      await StorageService.saveRecommendationWeights(_weights);
    } catch (e) {
      _setError('추천 설정 저장에 실패했습니다: ${e.toString()}');
    }
  }

  void updateWeight(String category, int value) {
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
    }
    notifyListeners();
  }

  void resetToDefaults() {
    _weights = const RecommendationWeights();
    notifyListeners();
  }

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

  double getRatioForCategory(String category) {
    if (_weights.total == 0) return 0.0;
    return getWeightForCategory(category) / _weights.total * 100;
  }

  int getVideoCountForCategory(String category, int totalVideos) {
    final videoCounts = _weights.getVideoCountsForTotal(totalVideos);
    return videoCounts[category] ?? 0;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}