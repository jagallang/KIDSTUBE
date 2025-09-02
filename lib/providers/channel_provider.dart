import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';

class ChannelProvider extends ChangeNotifier {
  YouTubeService? _youtubeService;
  List<Channel> _subscribedChannels = [];
  List<Channel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  List<Channel> get subscribedChannels => _subscribedChannels;
  List<Channel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasSubscribedChannels => _subscribedChannels.isNotEmpty;

  void setApiKey(String apiKey) {
    _youtubeService = YouTubeService(apiKey: apiKey);
    notifyListeners();
  }

  Future<void> loadSubscribedChannels() async {
    _setLoading(true);
    _clearError();

    try {
      _subscribedChannels = await StorageService.getChannels();
    } catch (e) {
      _setError('구독 채널을 불러오는데 실패했습니다: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchChannels(String query) async {
    if (_youtubeService == null || query.trim().isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _setSearching(true);
    _clearError();

    try {
      final results = await _youtubeService!.searchChannels(query);
      
      // 구독자 1만명 이하 채널 필터링
      _searchResults = results.where((channel) {
        final subscribers = int.tryParse(channel.subscriberCount.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        return subscribers >= 10000;
      }).toList();
    } catch (e) {
      _setError('채널 검색에 실패했습니다: ${e.toString()}');
      _searchResults.clear();
    } finally {
      _setSearching(false);
    }
  }

  Future<void> subscribeToChannel(Channel channel) async {
    try {
      // 이미 구독중인지 확인
      if (_subscribedChannels.any((c) => c.id == channel.id)) {
        return;
      }

      // 저장소에 추가
      final updatedChannels = [..._subscribedChannels, channel];
      await StorageService.saveChannels(updatedChannels);
      
      // 로컬 상태 업데이트
      _subscribedChannels = updatedChannels;
      notifyListeners();
    } catch (e) {
      _setError('채널 구독에 실패했습니다: ${e.toString()}');
    }
  }

  Future<void> unsubscribeFromChannel(String channelId) async {
    try {
      // 저장소에서 제거
      final updatedChannels = _subscribedChannels.where((c) => c.id != channelId).toList();
      await StorageService.saveChannels(updatedChannels);
      
      // 로컬 상태 업데이트
      _subscribedChannels = updatedChannels;
      notifyListeners();
    } catch (e) {
      _setError('채널 구독 해제에 실패했습니다: ${e.toString()}');
    }
  }

  bool isSubscribed(String channelId) {
    return _subscribedChannels.any((channel) => channel.id == channelId);
  }

  List<Channel> getChannelsByCategory(String category) {
    return _subscribedChannels.where((channel) {
      return channel.category == category;
    }).toList();
  }

  Map<String, int> getCategoryCounts() {
    final counts = <String, int>{};
    const categories = ['한글', '키즈', '만들기', '게임', '영어', '과학', '미술', '음악', '랜덤'];
    
    for (final category in categories) {
      counts[category] = getChannelsByCategory(category).length;
    }
    
    return counts;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
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

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }
}