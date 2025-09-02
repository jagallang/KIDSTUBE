import 'package:flutter/foundation.dart';
import '../models/video.dart';
import '../models/channel.dart';
import '../models/recommendation_weights.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';

class VideoProvider extends ChangeNotifier {
  YouTubeService? _youtubeService;
  List<Video> _videos = [];
  List<Channel> _channels = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  List<Video> get videos => _videos;
  List<Channel> get channels => _channels;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  bool get hasVideos => _videos.isNotEmpty;
  bool get hasChannels => _channels.isNotEmpty;

  void setApiKey(String apiKey) {
    _youtubeService = YouTubeService(apiKey: apiKey);
    notifyListeners();
  }

  Future<void> loadVideos() async {
    if (_youtubeService == null) return;

    _setLoading(true);
    _clearError();

    try {
      _channels = await StorageService.getChannels();
      
      if (_channels.isNotEmpty) {
        final weights = await StorageService.getRecommendationWeights();
        final videos = await _youtubeService!.getWeightedRecommendedVideos(_channels, weights);
        
        _videos = videos;
      } else {
        _videos = [];
      }
    } catch (e) {
      _setError('영상을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshVideos() async {
    if (_youtubeService == null) return;

    _setRefreshing(true);
    _clearError();

    try {
      _channels = await StorageService.getChannels();
      
      if (_channels.isNotEmpty) {
        final weights = await StorageService.getRecommendationWeights();
        final videos = await _youtubeService!.getWeightedRecommendedVideos(_channels, weights);
        
        _videos = videos;
      } else {
        _videos = [];
      }
    } catch (e) {
      _setError('영상을 새로고침하는데 실패했습니다: ${e.toString()}');
    } finally {
      _setRefreshing(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
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

  void clearVideos() {
    _videos.clear();
    notifyListeners();
  }
}