import '../../models/channel.dart';
import '../../models/recommendation_weights.dart';

/// Interface for storage service following dependency inversion principle
abstract class IStorageService {
  // Channel management
  Future<List<Channel>> loadChannels();
  Future<void> storeChannels(List<Channel> channels);
  Future<void> saveChannels(List<Channel> channels); // Alias for compatibility
  
  // API key management
  Future<String?> loadApiKey();
  Future<void> storeApiKey(String apiKey);
  
  // PIN management
  Future<void> storeParentPin(String pin);
  Future<bool> checkParentPin(String pin);
  Future<bool> hasParentPin();
  
  // Recommendation weights management
  Future<RecommendationWeights> getRecommendationWeights();
  Future<void> storeRecommendationWeights(RecommendationWeights weights);
  
  // General preferences
  Future<void> setBool(String key, bool value);
  Future<bool> getBool(String key, {bool defaultValue = false});
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
}