# KidsTube 🎬

안전하고 교육적인 어린이 전용 YouTube 동영상 플레이어

[![Flutter Version](https://img.shields.io/badge/Flutter-3.29.2-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.7.2-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0.01-orange.svg)](https://github.com/yourusername/kidstube/releases)

## 📱 소개

KidsTube는 부모가 안심하고 자녀에게 보여줄 수 있는 교육적이고 안전한 YouTube 콘텐츠를 제공하는 Flutter 기반 모바일 애플리케이션입니다.

### ✨ 주요 기능

#### 🔐 백엔드 통합 및 사용자 관리 (v2.0.01 신규)
- 🏠 **가족 계정 시스템**: 부모/자녀 역할 기반 다중 사용자 지원
- 🔑 **JWT 인증**: 안전한 토큰 기반 로그인/회원가입 시스템
- 👨‍👩‍👧‍👦 **가족 관리**: 가족 구성원 추가/삭제, 설정 공유
- 🛡️ **고급 부모 통제**: 서버 기반 콘텐츠 필터링 및 시청 시간 제한
- 📊 **통계 및 분석**: 개인별/가족별 시청 패턴 분석
- 🔒 **보안 강화**: Flutter Secure Storage를 통한 토큰 보안 관리

#### 📱 핵심 기능
- 🔒 **부모 통제 기능**: PIN 기반 부모 설정 보호
- 📺 **안전한 콘텐츠**: 검증된 어린이 채널만 구독 가능
- 🎯 **맞춤형 추천**: 카테고리별 가중치 기반 영상 추천
- 🎨 **어린이 친화적 UI**: 직관적이고 사용하기 쉬운 인터페이스
- 📊 **카테고리 관리**: 한글, 영어, 과학, 미술 등 다양한 교육 카테고리
- ⚡ **지능형 캐싱**: 90-95% API 호출 감소, 오프라인 브라우징 지원
- 🔄 **백그라운드 갱신**: 선택적 자동 갱신으로 API 사용량 최적화
- 📊 **API 사용량 추적**: 실시간 할당량 모니터링 및 제한
- ☁️ **클라우드 백업**: 구독 채널 자동 백업 및 복원

## 🏗️ 아키텍처

### Clean Architecture + Backend Integration System (v2.0.01)

```
lib/
├── core/                          # 핵심 비즈니스 로직
│   ├── base_provider.dart         # 기본 Provider 추상 클래스
│   ├── service_locator.dart       # 의존성 주입 (GetIt)
│   ├── cache_manager.dart         # 스마트 캐시 관리 시스템
│   ├── cache_analytics.dart       # 캐시 사용 패턴 분석
│   ├── cached_data.dart           # 타입 안전 캐시 래퍼
│   ├── debug_logger.dart          # 통합 디버그 로깅 시스템
│   ├── api_usage_tracker.dart     # API 사용량 추적 및 제한
│   ├── background_refresh_manager.dart # 백그라운드 갱신 시스템
│   └── interfaces/                # 서비스 인터페이스
│       ├── i_youtube_service.dart
│       ├── i_storage_service.dart
│       └── i_backend_service.dart  # 백엔드 API 인터페이스
├── models/                        # 데이터 모델
│   ├── channel.dart
│   ├── video.dart
│   ├── recommendation_weights.dart
│   ├── user.dart                   # 사용자 모델 (부모/자녀 역할)
│   ├── family.dart                 # 가족 계정 모델
│   └── auth_response.dart          # 인증 응답 모델
├── providers/                     # 상태 관리 (Provider)
│   ├── channel_provider.dart
│   ├── video_provider.dart
│   ├── recommendation_provider.dart
│   └── auth_provider.dart          # 인증 및 사용자 관리
├── services/                      # 외부 서비스
│   ├── youtube_service.dart       # YouTube API (가중치 시스템 포함)
│   ├── enhanced_youtube_service.dart # 캐시 강화 YouTube 서비스
│   ├── cloud_backup_service.dart  # 클라우드 백업 서비스
│   ├── storage_service.dart       # 로컬 저장소
│   └── backend_service.dart       # Rails 백엔드 API 클라이언트
├── utils/                         # 유틸리티
│   ├── app_reset_util.dart        # 앱 데이터 관리
│   └── weight_test_util.dart      # 가중치 테스트 도구
├── screens/                       # UI 화면
│   ├── splash_screen.dart
│   ├── main_screen.dart
│   ├── video_player_screen.dart
│   ├── api_settings_screen.dart
│   ├── background_refresh_settings_screen.dart
│   └── ...
└── main.dart                      # 앱 진입점
```

### 아키텍처 원칙

- **SOLID 원칙**: 단일 책임, 개방-폐쇄, 리스코프 치환, 인터페이스 분리, 의존성 역전
- **의존성 주입**: GetIt을 사용한 서비스 로케이터 패턴
- **상태 관리**: Provider 패턴과 Selector를 통한 최적화
- **지능형 캐싱**: 데이터 타입별 차별화된 TTL (1일-30일)
- **API 최적화**: 사전 정의 채널 목록 및 할당량 추적
- **Graceful Fallback**: 네트워크 실패 시 만료된 캐시 활용
- **백그라운드 처리**: 선택적 자동 콘텐츠 갱신 (기본 비활성화)
- **에러 처리**: 중앙화된 에러 처리 시스템
- **보안 중심**: JWT 토큰 관리, 자동 갱신, 안전한 저장소
- **다중 사용자**: 가족 단위 계정 관리 및 역할 기반 접근 제어

## 🚀 시작하기

### 요구사항

#### 클라이언트 (Flutter 앱)
- Flutter SDK: 3.29.2 이상
- Dart SDK: 3.7.2 이상
- Android Studio / VS Code
- YouTube Data API v3 키

#### 백엔드 서버 (선택사항)
- Ruby 3.2.0+ with Rails 7.0+
- PostgreSQL 14+
- Redis (캐싱 및 백그라운드 작업용)
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

3. 백엔드 서버 설정 (선택사항)
```bash
# Rails 서버 실행 (별도 저장소)
git clone [rails-backend-repo-url]
cd kidstube-backend
bundle install
rails db:setup
rails server
```

4. API 키 및 서버 설정
   - [Google Cloud Console](https://console.cloud.google.com)에서 YouTube Data API v3 활성화
   - API 키 생성 및 복사
   - 앱 실행 후 설정에서 API 키 입력
   - 백엔드 서버 사용 시 서버 URL 설정

5. 앱 실행
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
  # Backend integration dependencies (v2.0.01)
  dio: ^5.4.0                # 고급 HTTP 클라이언트
  json_annotation: ^4.8.1    # JSON 직렬화
  flutter_secure_storage: ^9.0.0  # 보안 토큰 저장소
  jwt_decode: ^0.3.1         # JWT 토큰 유틸리티
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

### 6. 백엔드 통합 시스템 (v2.0.01 신규)
- **가족 계정 관리**: 부모/자녀 역할 기반 다중 사용자 시스템
- **JWT 인증**: 안전한 토큰 기반 로그인 및 자동 갱신
- **서버 기반 캐싱**: Rails 백엔드의 PostgreSQL + Redis 캐싱
- **고급 부모 통제**: 키워드, 채널, 영상 단위 서버 기반 차단
- **시청 기록 추적**: 개인별 시청 패턴 및 통계 분석
- **실시간 동기화**: 가족 구성원 간 설정 및 콘텐츠 동기화
- **백그라운드 작업**: 서버 측 비디오 캐싱 및 콘텐츠 업데이트
- **확장 가능한 아키텍처**: 마이크로서비스 패턴으로 확장 준비

## 🔄 버전 히스토리

### v2.0.01 (2025-01-XX) 🚀
- **🔗 백엔드 통합**: Rails API 서버와 완전한 통합
- **🔐 JWT 인증**: 자동 토큰 갱신 및 보안 저장소 구현
- **👨‍👩‍👧‍👦 가족 계정**: 부모/자녀 역할 기반 다중 사용자 지원
- **📱 보안 강화**: Flutter Secure Storage로 토큰 안전 관리
- **🎯 사용자 관리**: 회원가입, 로그인, 로그아웃 완전 구현
- **🛡️ 고급 부모 통제**: 서버 기반 콘텐츠 필터링 및 차단
- **📊 통계 시스템**: 개인별/가족별 시청 기록 및 패턴 분석
- **🎮 백엔드 피드**: 서버 캐싱을 통한 최적화된 비디오 피드
- **🏗️ 아키텍처 개선**: Clean Architecture 원칙 유지하며 백엔드 통합
- **⚡ HTTP 클라이언트**: Dio 기반 인터셉터, 재시도, 오류 처리
- **📋 JSON 직렬화**: 코드 생성을 통한 타입 안전 데이터 처리
- **🔄 상태 관리**: 인증 상태 및 가족 관리 Provider 추가

### v1.2.1 (2025-01-XX) 📚
- **📖 개발 문서 강화**: 포괄적인 CLAUDE.md 가이드 추가
- **🇰🇷 한글 번역**: 개발자 접근성 향상을 위한 완전한 한글 문서화
- **🏗️ 아키텍처 가이드**: Clean Architecture + SOLID 원칙 상세 설명
- **⚡ 개발 패턴 정리**: 의존성 주입, 캐싱 시스템, Provider 패턴 문서화
- **🛠️ 개발 도구**: Flutter 명령어, 테스트 전략, 워크플로 가이드
- **📋 구현 참고사항**: API 키 관리, 성능 최적화, 오류 처리 방법
- **🎯 개발자 경험 향상**: Claude Code와의 협업을 위한 체계적 문서 제공

### v1.1.07 (2025-01-XX) 🎯
- **🔧 가중치 시스템 완전 수정**: 부모 설정 가중치가 정확히 작동하도록 알고리즘 재설계
- **🎲 영상 다양성 혁신**: 채널당 10개 비디오 수집으로 다양성 확보, 중복 영상 완전 제거
- **🔄 새로고침 문제 해결**: 메인 화면에서 동일 영상 반복 표시 문제 근본적 해결
- **⚡ 간소화된 분배 로직**: 실제 채널이 있는 카테고리만 고려한 효율적 분배 시스템
- **🧪 테스트 유틸리티 추가**: WeightTestUtil로 가중치 계산 검증 및 디버깅 지원
- **📊 다단계 셔플링**: 채널, 영상, 최종 결과 모든 단계에서 무작위화 적용
- **🎬 사용자 경험 향상**: 새로고침할 때마다 다양하고 가중치에 맞는 영상 제공

### v1.1.06 (2025-01-XX) 🐛
- **🔧 중요한 버그 수정**: 추천 영상이 1개만 표시되던 문제 해결 (8+ 영상으로 확대)
- **🏷️ 채널 제목 자동 복구**: 빈 채널 제목 자동 감지 및 복구 시스템
- **📊 디버그 로깅 강화**: 통합 디버깅 시스템으로 문제 추적 향상
- **🎯 카테고리 분류 개선**: 키즈, 만들기, 랜덤 등 정확한 카테고리 분류
- **⚙️ Provider 컨텍스트 수정**: RecommendationSettingsScreen 안정성 향상
- **🧪 실제 API 테스트**: 더미 데이터 의존성 제거, 실제 환경 테스트 강화
- **✅ API 키 검증 개선**: AIza 형식 체크 및 상세 에러 메시지

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

### CLAUDE.md 활용
프로젝트에는 Claude Code (claude.ai/code)와의 협업을 위한 포괄적인 개발 가이드가 포함되어 있습니다:

- **한글 문서**: 모든 가이드가 한국어로 제공되어 개발자 접근성 향상
- **아키텍처 개요**: Clean Architecture + SOLID 원칙 기반 설계 설명
- **개발 명령어**: Flutter 빌드, 테스트, 분석 명령어 모음
- **패턴 가이드**: 의존성 주입, Provider 패턴, 캐싱 전략 설명
- **구현 참고사항**: API 키 관리, 성능 최적화, 오류 처리 방법

자세한 내용은 [CLAUDE.md](CLAUDE.md) 파일을 참조하세요.

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

### 백엔드 서비스 사용 (v2.0.01)
```dart
// 사용자 인증
final authProvider = context.read<AuthProvider>();
final success = await authProvider.signIn(
  email: 'user@example.com',
  password: 'password',
);

// 가족 구성원 추가
if (authProvider.currentUser?.role == UserRole.parent) {
  await authProvider.addFamilyMember(
    email: 'child@example.com',
    name: '아이 이름',
    password: 'childpassword',
    pin: '1234',
  );
}

// 백엔드에서 비디오 피드 가져오기
final backendService = serviceLocator<IBackendService>();
final videos = await backendService.getFeed(page: 1, perPage: 20);

// 시청 기록 저장
await backendService.recordWatchHistory(
  videoId: 'video_id',
  durationSeconds: 180,
  watchedAt: DateTime.now(),
);
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

### 백엔드 서비스 등록 (v2.0.01)
```dart
// 백엔드 서비스 초기화
initializeBackendServices(baseUrl: 'https://your-backend-url.com');

// 인증 Provider 등록
serviceLocator.registerFactory<AuthProvider>(
  () => AuthProvider(
    backendService: serviceLocator<IBackendService>(),
  ),
);
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