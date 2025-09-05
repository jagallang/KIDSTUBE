// 의존성 주입 및 서비스 로케이터
import '../cache/cache_manager.dart';
import '../security/secure_storage.dart';
import '../network/rate_limiter.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  bool _isInitialized = false;

  // 서비스 등록
  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  void registerFactory<T>(T Function() factory) {
    _services[T] = factory;
  }

  // 서비스 가져오기
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T is not registered');
    }
    
    if (service is Function) {
      return service() as T;
    }
    
    return service as T;
  }

  // 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 캐시 매니저 초기화
    final cacheManager = MemoryCacheManager(
      defaultTtl: const Duration(minutes: 30),
    );
    registerSingleton<CacheManager>(cacheManager);

    // 보안 저장소 초기화
    final secureStorage = DefaultSecureStorage();
    registerSingleton<SecureStorage>(secureStorage);

    // 레이트 리미터 초기화
    registerSingleton<RateLimiter>(YouTubeApiRateLimiter.instance);

    // 기타 서비스들 초기화
    // registerSingleton<YouTubeRepository>(YouTubeRepository(...));

    _isInitialized = true;
  }

  // 정리
  void reset() {
    _services.clear();
    _isInitialized = false;
  }

  // 등록된 서비스 확인
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }
}

// 편의를 위한 전역 접근자
T getIt<T>() => ServiceLocator.instance.get<T>();