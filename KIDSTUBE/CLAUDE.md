# CLAUDE.md

이 파일은 이 저장소에서 작업할 때 Claude Code (claude.ai/code)에게 가이드를 제공합니다.

## 일반적인 개발 명령어

### Flutter 개발
```bash
# 의존성 설치
flutter pub get

# 애플리케이션 실행
flutter run

# 특정 디바이스에서 실행
flutter run -d chrome    # 웹 브라우저용
flutter run -d ios       # iOS 시뮬레이터용  
flutter run -d android   # Android 에뮬레이터용

# 개발 도구
flutter analyze         # flutter_lints를 이용한 정적 코드 분석
flutter format .        # Dart 스타일 가이드에 따른 코드 포맷팅
flutter test            # 유닛 테스트 실행
flutter clean           # 빌드 캐시 및 아티팩트 정리

# 프로덕션 빌드
flutter build apk       # Android APK
flutter build ios       # iOS 빌드
flutter build web       # 웹 빌드
```

### 테스트 명령어
```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 파일 실행
flutter test test/providers/video_provider_test.dart

# 커버리지와 함께 테스트 실행
flutter test --coverage
```

## 고수준 아키텍처

### Clean Architecture + SOLID 원칙
GetIt을 사용한 의존성 주입으로 Clean Architecture 원칙을 따르는 Flutter 애플리케이션입니다. 이 앱은 지능형 캐싱과 API 최적화를 통해 어린이를 위한 안전한 YouTube 경험을 제공합니다.

### 핵심 아키텍처 구성 요소

#### 1. 의존성 주입 (lib/core/service_locator.dart)
- GetIt 서비스 로케이터 패턴 사용
- 서비스를 싱글톤 또는 팩토리로 등록
- 인터페이스를 통한 깔끔한 관심사 분리
- 2단계 초기화: `initializeServices()` 및 `initializeWithApiKey()`

#### 2. Provider 패턴 상태 관리
- 상태 관리를 위해 Provider 패키지 사용
- 기본 클래스: 스마트 캐싱 기능을 가진 `CacheableProvider<T>`
- 주요 프로바이더: `VideoProvider`, `ChannelProvider`, `RecommendationProvider`
- 깔끔한 인스턴스 생성을 위한 `ProviderFactory`의 팩토리 메서드

#### 3. 서비스 레이어 아키텍처
```
IYouTubeService (인터페이스)
├── YouTubeService (기본 구현)
└── EnhancedYouTubeService (캐싱 + 폴백 포함)

IStorageService (인터페이스)  
└── StorageService (SharedPreferences 구현)
```

#### 4. 지능형 캐싱 시스템
- **스마트 TTL**: 데이터 유형별 다른 캐시 지속 시간
  - 채널 검색: 7일
  - 비디오 목록: 12시간  
  - 구독: 30일
- **우아한 폴백**: 
- **백그라운드 새로고침**: 새로고침 없음
- **캐시 분석**: 성능 추적 및 최적화

#### 5. API 최적화 기능
- **API 사용량 추적**: 실시간 할당량 모니터링 및 제한
- **백그라운드 새로고침 관리자**: 선택적 자동 새로고침 (기본값: 비활성화)
- **클라우드 백업 서비스**: 6시간마다 자동 채널 백업/복원
- 지능형 캐싱을 통한 90-95% API 호출 감소

### 디렉토리 구조
```
lib/
├── core/                    # 핵심 비즈니스 로직 & 유틸리티
│   ├── base_provider.dart   # 캐싱을 포함한 추상 Provider
│   ├── service_locator.dart # 의존성 주입 설정
│   ├── cache_manager.dart   # 스마트 캐싱 시스템
│   ├── api_usage_tracker.dart # API 할당량 관리
│   └── interfaces/          # 서비스 계약
├── models/                  # 데이터 모델 (Channel, Video 등)
├── providers/               # 상태 관리 (Provider 패턴)
├── services/                # 외부 서비스 구현
│   ├── youtube_service.dart # 기본 YouTube API 클라이언트
│   ├── enhanced_youtube_service.dart # 캐싱 레이어 포함
│   └── storage_service.dart # 로컬 지속성
├── screens/                 # UI 화면
├── utils/                   # 헬퍼 유틸리티
└── widgets/                 # 재사용 가능한 UI 컴포넌트
```

### 주요 개발 패턴

#### 서비스 등록
```dart
// In service_locator.dart
serviceLocator.registerLazySingleton<IYouTubeService>(
  () => EnhancedYouTubeService(
    baseService: YouTubeService(apiKey: apiKey),
  ),
);
```

#### Provider 생성
```dart
// Using factory methods
final provider = ProviderFactory.createVideoProvider();
```

#### 캐싱 전략
```dart
// Different TTL per data type
final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.videos);
setCacheTimeout(cacheDuration);
```

### 중요한 구현 참고사항
- 항상 한글로 설명

#### API 키 관리
- YouTube Data API v3 키 필수
- 검증과 함께 앱 설정 UI를 통해 설정 (AIza 형식 확인)
- API 키 변경 시 서비스 재초기화
- API 키를 저장소에 커밋하지 말 것

#### 콘텐츠 안전 기능
- 구독자 수로 채널 필터링 (최소 1만명 이상)
- 카테고리 기반 콘텐츠 분류 (한글, 영어, 과학, 미술)
- PIN 기반 설정 보호를 통한 부모 통제
- 프리셋을 포함한 가중치 기반 추천 시스템

#### 성능 최적화
- 재빌드 최소화를 위한 `Selector` 위젯 사용
- `cached_network_image`를 이용한 네트워크 이미지 캐싱
- 중요하지 않은 업데이트의 백그라운드 처리
- 연결 인식 캐싱 전략 (WiFi vs 모바일 데이터)

#### 오류 처리
- Provider를 통한 중앙화된 오류 처리
- 만료된 캐시 폴백을 통한 우아한 성능 저하
- 네트워크 실패 복구 메커니즘
- 범주화된 출력을 포함한 디버그 로깅 시스템

### 테스트 전략
- 
- Provider 상태 테스트
- 
- 

### 개발 워크플로
1. 변경사항을 pull한 후 항상 `flutter pub get` 실행
2. 코드 품질 확보를 위해 커밋 전 `flutter analyze` 사용
3. 
4. 개발 시 API 할당량 사용량 검증
5. 

### 참조할 중요한 파일들
- `lib/core/service_locator.dart` - 의존성 주입 설정
- `lib/core/base_provider.dart` - Provider 아키텍처 패턴  
- `lib/services/enhanced_youtube_service.dart` - 캐싱 구현
- `pubspec.yaml` - 의존성 및 Flutter 설정
- `analysis_options.yaml` - 린팅 규칙 (flutter_lints 패키지)