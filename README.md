# KIDSTUBE

어린이를 위한 안전한 YouTube 플레이어 애플리케이션입니다. Clean Architecture와 지능형 캐싱 시스템을 통해 최적화된 성능과 사용자 경험을 제공합니다.

## 🎯 주요 기능

### 📱 어린이 안전 기능
- **채널 필터링**: 구독자 수 1만명 이상의 검증된 채널만 표시
- **카테고리 분류**: 한글, 키즈, 만들기, 게임, 영어, 과학, 미술, 음악으로 자동 분류
- **PIN 보호**: 부모 설정 메뉴 접근 보호
- **가중치 기반 추천**: 카테고리별 선호도를 반영한 맞춤 추천
- **무한 스크롤**: 아래로 스크롤하면 자동으로 추가 추천 영상 로드

### ⚡ 성능 최적화
- **지능형 캐싱**: 90-95% API 호출 감소
  - 채널 검색: 7일 캐시
  - 비디오 목록: 12시간 캐시
  - 구독 정보: 30일 캐시
- **우아한 폴백**: 네트워크 오류 시 만료된 캐시 활용
- **백그라운드 새로고림**: 선택적 자동 업데이트 (기본값: 비활성화)
- **API 사용량 추적**: 실시간 할당량 모니터링

### 🔧 기술적 특징
- **Clean Architecture**: 의존성 주입과 인터페이스 기반 설계
- **Provider 상태 관리**: 반응형 UI 업데이트
- **클라우드 백업**: 6시간마다 자동 채널 백업/복원
- **디버그 로깅**: 카테고리별 로그 시스템

## 🏗️ 아키텍처

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

### 핵심 아키텍처 패턴
- **의존성 주입**: GetIt 서비스 로케이터 패턴
- **Repository Pattern**: YouTube API 추상화
- **Provider Pattern**: 반응형 상태 관리
- **Strategy Pattern**: 캐싱 전략 구현

## 🚀 시작하기

### 필수 요구사항
- Flutter SDK 3.29.2 이상
- Dart 3.7.2 이상
- YouTube Data API v3 키

### 설치 및 실행

1. **의존성 설치**
```bash
flutter pub get
```

2. **애플리케이션 실행**
```bash
flutter run
```

3. **개발 도구**
```bash
flutter analyze         # 정적 코드 분석
flutter format .        # 코드 포맷팅
flutter test            # 유닛 테스트 실행
flutter clean           # 빌드 캐시 정리
```

4. **프로덕션 빌드**
```bash
flutter build apk       # Android APK
flutter build ios       # iOS 빌드
flutter build web       # 웹 빌드
```

### API 키 설정
1. [Google Cloud Console](https://console.cloud.google.com/)에서 YouTube Data API v3 활성화
2. API 키 생성 (AIza로 시작하는 형식)
3. 앱 실행 후 설정 화면에서 API 키 입력

## 📊 성능 통계

- **API 호출 감소**: 90-95%
- **캐시 적중률**: 85% 이상
- **평균 응답 시간**: 10ms (캐시), 1-3초 (네트워크)
- **메모리 사용량**: 최적화된 이미지 캐싱으로 최소화

## 🛠️ 개발 가이드

### 코드 품질
- **flutter_lints** 패키지를 사용한 정적 분석
- **Clean Architecture** 원칙 준수
- **SOLID** 원칙 적용
- 한글 주석과 문서화

### 테스트 전략
- Provider 상태 테스트
- 서비스 레이어 단위 테스트
- 캐싱 로직 검증

### 디버깅
```dart
DebugLogger.logFlow('작업 설명', data: {'key': 'value'});
DebugLogger.logError('오류 설명', error);
```

## 📝 버전 히스토리

### v1.3.06 (2025-01-09)
- Clean Architecture 적용
- 지능형 캐싱 시스템 구현
- API 사용량 최적화 (90-95% 감소)
- 백그라운드 새로고침 기능
- 클라우드 백업 시스템
- 카테고리별 디버그 로깅

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 🔧 기술 스택

- **Frontend**: Flutter (Dart)
- **상태 관리**: Provider
- **의존성 주입**: GetIt
- **캐싱**: SharedPreferences
- **네트워킹**: HTTP package
- **이미지 캐싱**: cached_network_image
- **동영상 플레이어**: youtube_player_flutter

## 📞 지원

문제가 있거나 기능 요청이 있으시면 [Issues](https://github.com/jagallang/KIDSTUBE/issues)에 등록해주세요.

---

⭐ 이 프로젝트가 도움이 되었다면 Star를 눌러주세요!