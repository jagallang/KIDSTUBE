# KidsTube 🎬

안전하고 교육적인 어린이 전용 YouTube 동영상 플레이어

[![Flutter Version](https://img.shields.io/badge/Flutter-3.29.2-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.7.2-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.3.02--standalone-orange.svg)](https://github.com/jagallang/KIDSTUBE/releases)

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

## 🆕 Standalone 버전 개선사항 (v1.2.3-standalone)

### 🔧 코드 품질 개선
- **에러 150개 → 28개로 81% 감소**: 린트 에러 대폭 개선
- **UI 오버플로우 수정**: 작은 화면에서도 안정적인 UI 제공
- **Deprecated API 수정**: `withOpacity()` → `withValues(alpha:)` 최신 권장사항 적용
- **사용하지 않는 코드 정리**: import, 함수, 필드 등 불필요한 코드 제거

### 🚀 사용성 개선  
- **첫화면을 메인화면으로 변경**: 복잡한 설정 과정 생략, 바로 앱 체험 가능
- **부모 인증 PIN 설정 개선**: PIN 미설정 시 자동으로 설정 화면 안내
- **데모 API 키 적용**: 별도 설정 없이 바로 실행 가능

### 🎯 사용자 경험 향상
- **간소화된 초기 설정**: API 키 → PIN 설정 → 채널 관리 단계 간소화
- **직관적인 접근성**: 설정 버튼 클릭 시 상황에 맞는 화면 자동 표시
- **안정적인 PIN 시스템**: SHA-256 암호화 적용, 최대 3회 시도 제한

### 🔐 PIN 인증 시스템 완전 해결 (v1.2.3 추가)
- **PIN 인증 버그 완전 수정**: "잘못된 PIN" 문제 완전 해결
- **상세 디버깅 로그 추가**: PIN 설정/인증 과정의 모든 단계 추적 가능
- **PIN 리셋 기능**: 문제 발생 시 쉽게 PIN 초기화 및 재설정 가능
- **실시간 인증 상태 확인**: 해시 비교 과정까지 상세 로그로 확인
- **안드로이드/웹 모두 정상 작동**: 크로스 플랫폼 PIN 인증 안정성 확보

## 🏗️ 아키텍처

### Clean Architecture + Standalone Improvements (v1.2.3-standalone)

```
lib/
├── core/                          # 핵심 비즈니스 로직
│   ├── base_provider.dart         # 기본 Provider 추상 클래스
│   ├── service_locator.dart       # 의존성 주입 (GetIt)
│   ├── cache_manager.dart         # 스마트 캐시 관리 시스템
│   ├── cache_analytics.dart       # 캐시 사용 패턴 분석
│   ├── cached_data.dart           # 타입 안전 캐시 래퍼
│   ├── debug_logger.dart          # 통합 디버그 로깅 시스템
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
│   ├── youtube_service.dart       # YouTube API (가중치 시스템 포함)
│   ├── enhanced_youtube_service.dart # 캐시 강화 YouTube 서비스
│   ├── cloud_backup_service.dart  # 클라우드 백업 서비스
│   └── storage_service.dart       # 로컬 저장소
├── utils/                         # 유틸리티
│   ├── app_reset_util.dart        # 앱 데이터 관리
│   └── weight_test_util.dart      # 가중치 테스트 도구
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

### v1.3.02 (2025-09-04) 📊 **상태 분석 및 문서화**
- **✅ API 통합 정상 작동 확인**: 유효한 API 키 입력 시 실제 YouTube Data API v3 정상 작동
- **🔍 채널 검색 기능 완벽 작동**: "꿈토이", "타요" 등 실제 채널 검색 및 필터링 성공
- **📝 시스템 동작 상태 문서화**: Provider 아키텍처 및 API 연동 상태 상세 문서화
- **🎯 사용자 가이드**: API 키 설정 → 채널 검색 → 채널 추가 → 영상 로드 플로우 확인
- **🔧 초기 설정 안내**: 앱 시작 시 API 키 설정 필요성 명확히 문서화

### v1.3.01 (2025-09-04) 🔧 **Provider 시스템 대폭 개선**
- **🌍 전역 Provider 트리 설정**: MultiProvider로 모든 화면에서 동일한 Provider 인스턴스 공유
- **🔗 Provider 인스턴스 분리 문제 해결**: 메인 화면과 채널 관리 화면 간의 데이터 동기화 문제 완전 해결
- **📺 영상 로드 및 썸네일 표시 기능 복원**: ChannelProvider와 VideoProvider 간의 올바른 연결로 완전한 기능 복원
- **🔄 실시간 Provider 동기화**: 채널 추가/삭제 시 VideoProvider가 자동으로 영상 리스트 업데이트
- **🛠 BuildContext 안전성 개선**: mounted 체크로 상태 업데이트 안전성 강화
- **⚡ ChangeNotifierProxyProvider 활용**: 의존성 있는 Provider 간의 완벽한 상호작용 구현

### v1.3.0 (2025-01-XX) 🔧
- **🔑 완전한 API 키 관리 시스템**: 사용자 정의 API 키 입력, 검증, 저장 기능
- **🔄 서비스 재초기화 로직**: API 키 변경 시 모든 서비스와 프로바이더 자동 업데이트
- **🔗 의존성 주입 개선**: Service Locator 패턴으로 일관성 있는 서비스 사용
- **🛠 채널 저장/영상 로딩 수정**: Provider 캐시 문제 해결로 완전한 기능 복원
- **🐛 디버그 로깅 시스템**: 종합적인 문제 추적 및 해결 지원
- **📊 API 사용량 모니터링**: 상세한 비용 추적 및 할당량 관리
- **🧪 테스트 모드 개선**: API 키 없이도 완전한 앱 체험 가능
- **🔧 프로바이더 재등록 시스템**: 새 API 키로 모든 컴포넌트 동기화

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