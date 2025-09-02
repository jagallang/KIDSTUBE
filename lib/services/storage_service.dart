import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/channel.dart';
import '../models/recommendation_weights.dart';
import '../core/interfaces/i_storage_service.dart';

class StorageService implements IStorageService {
  static const String _apiKeyKey = 'api_key';
  static const String _pinKey = 'parent_pin';
  static const String _channelsKey = 'subscribed_channels';
  static const String _setupCompleteKey = 'is_setup_complete';
  static const String _recommendationWeightsKey = 'recommendation_weights';

  // Static methods for backward compatibility
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  static Future<void> setParentPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = sha256.convert(utf8.encode(pin)).toString();
    await prefs.setString(_pinKey, hashedPin);
  }

  static Future<bool> verifyParentPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);
    if (storedPin == null) return false;
    
    final hashedPin = sha256.convert(utf8.encode(pin)).toString();
    return storedPin == hashedPin;
  }

  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  static Future<void> saveChannelsStatic(List<Channel> channels) async {
    final prefs = await SharedPreferences.getInstance();
    final channelsJson = channels.map((c) => c.toJson()).toList();
    await prefs.setString(_channelsKey, json.encode(channelsJson));
  }

  static Future<List<Channel>> getChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final channelsString = prefs.getString(_channelsKey);
    if (channelsString == null) return [];
    
    final List<dynamic> channelsJson = json.decode(channelsString);
    return channelsJson.map((json) {
      // 기존 데이터와의 호환성을 위해 uploadsPlaylistId가 없으면 채널 ID에서 생성
      String uploadsPlaylistId = json['uploadsPlaylistId'] ?? '';
      if (uploadsPlaylistId.isEmpty && json['id'] != null && json['id'].startsWith('UC')) {
        uploadsPlaylistId = json['id'].replaceFirst('UC', 'UU');
      }
      
      return Channel(
        id: json['id'],
        title: json['title'],
        thumbnail: json['thumbnail'],
        subscriberCount: json['subscriberCount'],
        uploadsPlaylistId: uploadsPlaylistId,
      );
    }).toList();
  }

  static Future<void> addChannel(Channel channel) async {
    final channels = await getChannels();
    if (!channels.any((c) => c.id == channel.id)) {
      channels.add(channel);
      await saveChannelsStatic(channels);
    }
  }

  static Future<void> removeChannel(String channelId) async {
    final channels = await getChannels();
    channels.removeWhere((c) => c.id == channelId);
    await saveChannelsStatic(channels);
  }

  static Future<void> setSetupComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompleteKey, complete);
  }

  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompleteKey) ?? false;
  }

  // 추천 가중치 저장
  static Future<void> saveRecommendationWeights(RecommendationWeights weights) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recommendationWeightsKey, json.encode(weights.toJson()));
  }

  // 추천 가중치 로드
  @override
  Future<RecommendationWeights> getRecommendationWeights() async {
    final prefs = await SharedPreferences.getInstance();
    final weightsString = prefs.getString(_recommendationWeightsKey);
    if (weightsString == null) {
      // 기본값 반환 (한글3, 키즈3, 만들기2, 게임1, 랜덤1)
      return const RecommendationWeights();
    }
    
    final Map<String, dynamic> weightsJson = json.decode(weightsString);
    return RecommendationWeights.fromJson(weightsJson);
  }

  // 일반적인 설정 메서드들
  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // 인스턴스 메서드 구현 (renamed to avoid conflicts)
  @override
  Future<List<Channel>> loadChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final channelsString = prefs.getString(_channelsKey);
    if (channelsString == null) return [];
    
    final List<dynamic> channelsJson = json.decode(channelsString);
    return channelsJson.map((json) => Channel.fromJson(json)).toList();
  }

  @override
  Future<void> storeChannels(List<Channel> channels) async {
    final prefs = await SharedPreferences.getInstance();
    final channelsJson = channels.map((c) => c.toJson()).toList();
    await prefs.setString(_channelsKey, json.encode(channelsJson));
  }
  
  @override
  Future<void> saveChannels(List<Channel> channels) async {
    await storeChannels(channels);
  }

  @override
  Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  @override
  Future<void> storeApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  @override
  Future<void> storeParentPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = _hashPin(pin);
    await prefs.setString(_pinKey, hashedPin);
  }

  @override
  Future<bool> checkParentPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHashedPin = prefs.getString(_pinKey);
    if (storedHashedPin == null) return false;
    
    final hashedPin = _hashPin(pin);
    return hashedPin == storedHashedPin;
  }

  @override
  Future<bool> hasParentPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  @override
  Future<void> storeRecommendationWeights(RecommendationWeights weights) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recommendationWeightsKey, json.encode(weights.toJson()));
  }

  // Helper method for PIN hashing
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}