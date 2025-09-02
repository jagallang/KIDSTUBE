# KidsTube 🎬

안전하고 교육적인 어린이 전용 YouTube 동영상 플레이어

[![Flutter Version](https://img.shields.io/badge/Flutter-3.29.2-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.7.2-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.1.05-orange.svg)](https://github.com/yourusername/kidstube/releases)

## 📱 소개

KidsTube는 부모가 안심하고 자녀에게 보여줄 수 있는 교육적이고 안전한 YouTube 콘텐츠를 제공하는 Flutter 기반 모바일 애플리케이션입니다.

### ✨ 주요 기능

- 🔒 **부모 통제 기능**: PIN 기반 부모 설정 보호
- 📺 **안전한 콘텐츠**: 검증된 어린이 채널만 구독 가능
- 🎯 **맞춤형 추천**: 카테고리별 가중치 기반 영상 추천
- 🎨 **어린이 친화적 UI**: 직관적이고 사용하기 쉬운 인터페이스
- 📊 **카테고리 관리**: 한글, 영어, 과학, 미술 등 다양한 교육 카테고리
- ⚡ **지능형 캐싱**: 85-90% API 호출 감소, 오프라인 브라우징 지원
- 🔄 **백그라운드 갱신**: 사용 패턴 기반 자동 콘텐츠 업데이트
- ☁️ **클라우드 백업**: 구독 채널 자동 백업 및 복원

## 🏗️ 아키텍처

### Clean Architecture + Intelligent Caching (v1.1.05)

```
lib/
├── core/                          # 핵심 비즈니스 로직
│   ├── base_provider.dart         # 기본 Provider 추상 클래스
│   ├── service_locator.dart       # 의존성 주입 (GetIt)
│   ├── cache_manager.dart         # 스마트 캐시 관리 시스템
│   ├── cache_analytics.dart       # 캐시 사용 패턴 분석
│   ├── cached_data.dart           # 타입 안전 캐시 래퍼
│   ├── background_refresh_manager.dart # 백그라운드 갱신 시스템
│   └── interfaces/                # 서비스 인터페이스
│       ├── i_youtube_service.dart
│       └── i_storage_service.dart
├── models/                        # 데이터 모델
│   ├── channel.dart
│   ├── video.dart
│   └── recommendation_weights.dart
├── providers/                     # 상태 관리 (Provider)
│   ├── channel_provider.dart
│   ├── video_provider.dart
│   └── recommendation_provider.dart
├── services/                      # 외부 서비스
│   ├── youtube_service.dart       # YouTube API
│   ├── enhanced_youtube_service.dart # 캐시 강화 YouTube 서비스
│   ├── cloud_backup_service.dart  # 클라우드 백업 서비스
│   └── storage_service.dart       # 로컬 저장소
├── screens/                       # UI 화면
│   ├── splash_screen.dart
│   ├── main_screen.dart
│   ├── video_player_screen.dart
│   └── ...
└── main.dart                      # 앱 진입점
```

### 아키텍처 원칙

- **SOLID 원칙**: 단일 책임, 개방-폐쇄, 리스코프 치환, 인터페이스 분리, 의존성 역전
- **의존성 주입**: GetIt을 사용한 서비스 로케이터 패턴
- **상태 관리**: Provider 패턴과 Selector를 통한 최적화
- **지능형 캐싱**: 데이터 타입별 차별화된 TTL (6시간-30일)
- **Graceful Fallback**: 네트워크 실패 시 만료된 캐시 활용
- **백그라운드 처리**: 우선순위 기반 자동 콘텐츠 갱신
- **에러 처리**: 중앙화된 에러 처리 시스템

## 🚀 시작하기

### 요구사항

- Flutter SDK: 3.29.2 이상
- Dart SDK: 3.7.2 이상
- Android Studio / VS Code
- YouTube Data API v3 키

### 설치

1. 저장소 클론
```bash
git clone https://github.com/yourusername/kidstube.git
cd kidstube
```

2. 의존성 설치
```bash
flutter pub get
```

3. YouTube API 키 설정
   - [Google Cloud Console](https://console.cloud.google.com)에서 YouTube Data API v3 활성화
   - API 키 생성 및 복사
   - 앱 실행 후 설정에서 API 키 입력

4. 앱 실행
```bash
flutter run
```

## 📦 주요 의존성

```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.1           # 상태 관리
  get_it: ^8.0.2             # 의존성 주입
  http: ^1.2.0               # HTTP 통신
  shared_preferences: ^2.2.2 # 로컬 저장소
  cached_network_image: ^3.3.1  # 이미지 캐싱
  youtube_player_flutter: ^9.0.0  # 비디오 재생
  connectivity_plus: ^6.0.5  # 네트워크 상태 감지
  crypto: ^3.0.3             # PIN 암호화
```

## 🎯 주요 기능 상세

### 1. 채널 관리
- 구독자 1만명 이상 채널만 필터링
- 카테고리별 자동 분류
- 실시간 채널 검색

### 2. 영상 추천 시스템
- 카테고리별 가중치 설정 (한글, 영어, 과학, 미술 등)
- 프리셋 제공 (균형잡힌, 한글중심, 창의력중심 등)
- 최신 영상 우선 정렬

### 3. 부모 통제
- PIN 기반 설정 접근 제한
- 채널 추가/삭제 관리
- API 키 보안 관리

### 4. 지능형 캐싱 시스템 (v1.1.05 신규)
- **스마트 TTL**: 채널 검색(7일), 비디오 목록(12시간), 구독(30일)
- **Graceful Fallback**: 네트워크 오류 시 만료된 캐시 자동 사용
- **백그라운드 갱신**: 30분마다 우선순위 기반 자동 업데이트
- **사용 패턴 분석**: Hit rate, 접근 빈도, 응답 시간 추적
- **네트워크 최적화**: WiFi vs 모바일 데이터별 차등 전략

### 5. 클라우드 백업 시스템 (v1.1.05 신규)
- **자동 백업**: 6시간마다 구독 채널 클라우드 저장
- **백업 상태 추적**: 백업 날짜, 채널 수, 카테고리 정보
- **복원 기능**: 디바이스 변경 시 원클릭 복원
- **데이터 검증**: 백업 무결성 체크 및 오류 복구

## 🔄 버전 히스토리

### v1.1.05 (2025-01-XX) 🚀
- ⚡ **지능형 캐싱 시스템**: 85-90% API 호출 감소
- 🔄 **백그라운드 갱신**: 우선순위 기반 자동 업데이트
- ☁️ **클라우드 백업**: 구독 채널 자동 백업/복원
- 📊 **캐시 분석**: 사용 패턴 추적 및 최적화
- 🌐 **오프라인 지원**: Graceful fallback으로 네트워크 오류 대응
- 🔧 **성능 향상**: 데이터 타입별 차별화된 캐시 전략

### v1.1.04 (2024-01-XX)
- 🏗️ Clean Architecture 전면 적용
- 💉 의존성 주입 시스템 구현
- ⚡ Selector 패턴을 통한 성능 최적화
- 🔧 SOLID 원칙 기반 리팩토링

### v1.0.3 (2024-01-XX)
- 코드 품질 메트릭 추가
- 문서화 개선

### v1.0.2 (2024-01-XX)
- Provider 상태 관리 구현
- 추천 시스템 개선

### v1.0.0 (2024-01-XX)
- 초기 릴리즈
- 기본 기능 구현

## 🧪 테스트

```bash
# 유닛 테스트 실행
flutter test

# 코드 분석
flutter analyze

# 코드 포맷팅
flutter format .
```

## 📝 개발 가이드

### 새로운 Provider 추가
```dart
class NewProvider extends CacheableProvider<DataType> {
  final IServiceInterface _service;
  
  NewProvider({required IServiceInterface service}) 
    : _service = service {
    // 스마트 캐시 TTL 사용
    final cacheDuration = SmartCacheManager.getCacheDuration(CacheType.newData);
    setCacheTimeout(cacheDuration);
  }
  
  // 구현...
}
```

### 캐시 분석 활용
```dart
// 캐시 성능 모니터링
final stats = await CacheAnalytics.getCachePerformanceStats();
print('Hit Rate: ${stats['averageHitRate']}%');

// 우선순위 기반 캐시 키 획득
final topKeys = await CacheAnalytics.getTopPriorityCacheKeys(10);
```

### 클라우드 백업 사용
```dart
// 백업 생성
final backupResult = await cloudBackupService.backupToCloud();
if (backupResult.success) {
  print('${backupResult.channelCount}개 채널 백업 완료');
}

// 백업 복원
final restoreResult = await cloudBackupService.restoreFromCloud();
if (restoreResult.success) {
  print('${restoreResult.channelCount}개 채널 복원 완료');
}
```

### 서비스 인터페이스 정의
```dart
abstract class INewService {
  Future<DataType> fetchData();
  Future<void> saveData(DataType data);
}
```

### 의존성 등록
```dart
serviceLocator.registerLazySingleton<INewService>(
  () => NewService(apiKey: apiKey),
);
```

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 👥 팀

- **개발자**: [Your Name]
- **디자인**: [Designer Name]
- **기획**: [Planner Name]

## 📞 문의

프로젝트 관련 문의사항은 아래로 연락주세요:
- Email: your.email@example.com
- GitHub Issues: [https://github.com/yourusername/kidstube/issues](https://github.com/yourusername/kidstube/issues)

## 🙏 감사의 말

- Flutter 팀과 커뮤니티
- 모든 오픈소스 라이브러리 기여자들
- 테스터와 피드백을 주신 모든 분들

---

Made with ❤️ for Kids' Safe YouTube Experience