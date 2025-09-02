import 'package:get_it/get_it.dart';
import '../services/youtube_service.dart';
import '../services/enhanced_youtube_service.dart';
import '../services/storage_service.dart';
import '../core/interfaces/i_youtube_service.dart';
import '../core/interfaces/i_storage_service.dart';
import '../providers/video_provider.dart';
import '../providers/channel_provider.dart';
import '../providers/recommendation_provider.dart';
import '../core/background_refresh_manager.dart';
import '../services/cloud_backup_service.dart';

/// Service locator for dependency injection
/// Follows single responsibility principle and provides clean dependency management
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services and providers with dependency injection
Future<void> initializeServices() async {
  // Register storage service
  serviceLocator.registerLazySingleton<IStorageService>(
    () => StorageService(),
  );

  // Register YouTube service factory (requires API key)
  serviceLocator.registerFactoryParam<IYouTubeService, String, void>(
    (apiKey, _) => YouTubeService(apiKey: apiKey),
  );

  // Register providers with dependencies
  serviceLocator.registerFactory<ChannelProvider>(
    () => ChannelProvider(
      youtubeService: serviceLocator<IYouTubeService>(),
      storageService: serviceLocator<IStorageService>(),
    ),
  );

  serviceLocator.registerFactory<VideoProvider>(
    () => VideoProvider(
      youtubeService: serviceLocator<IYouTubeService>(),
      storageService: serviceLocator<IStorageService>(),
    ),
  );

  serviceLocator.registerFactory<RecommendationProvider>(
    () => RecommendationProvider(
      storageService: serviceLocator<IStorageService>(),
    ),
  );

  // Register cloud backup service
  serviceLocator.registerLazySingleton<CloudBackupService>(
    () => CloudBackupService(
      storageService: serviceLocator<IStorageService>(),
    ),
  );
}

/// Initialize services with API key and enhanced caching
void initializeWithApiKey(String apiKey) {
  // Unregister existing services if they exist
  if (serviceLocator.isRegistered<IYouTubeService>()) {
    serviceLocator.unregister<IYouTubeService>();
  }
  if (serviceLocator.isRegistered<BackgroundRefreshManager>()) {
    serviceLocator.unregister<BackgroundRefreshManager>();
  }

  // Register Enhanced YouTube service with graceful fallback and smart caching
  serviceLocator.registerLazySingleton<IYouTubeService>(
    () => EnhancedYouTubeService(
      baseService: YouTubeService(apiKey: apiKey),
    ),
  );

  // Register background refresh manager with backup service
  serviceLocator.registerLazySingleton<BackgroundRefreshManager>(
    () => BackgroundRefreshManager(
      youtubeService: serviceLocator<IYouTubeService>(),
      storageService: serviceLocator<IStorageService>(),
      backupService: serviceLocator<CloudBackupService>(),
    ),
  );
}

/// Reset services (useful for testing)
Future<void> resetServices() async {
  await serviceLocator.reset();
  await initializeServices();
}

/// Helper to get services
T getService<T extends Object>() => serviceLocator<T>();

/// Provider factory methods for clean instantiation
class ProviderFactory {
  static VideoProvider createVideoProvider() {
    return VideoProvider(
      youtubeService: serviceLocator<IYouTubeService>(),
      storageService: serviceLocator<IStorageService>(),
    );
  }

  static ChannelProvider createChannelProvider() {
    return ChannelProvider(
      youtubeService: serviceLocator<IYouTubeService>(),
      storageService: serviceLocator<IStorageService>(),
    );
  }

  static RecommendationProvider createRecommendationProvider() {
    return RecommendationProvider(
      storageService: serviceLocator<IStorageService>(),
    );
  }
}