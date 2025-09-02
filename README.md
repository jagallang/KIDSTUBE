# 🎬 KidsTube

안전하고 교육적인 아이들을 위한 YouTube 앱

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![YouTube API](https://img.shields.io/badge/YouTube_API-FF0000?style=for-the-badge&logo=youtube&logoColor=white)

## 📱 프로젝트 소개

KidsTube는 부모가 아이들의 YouTube 시청을 안전하게 관리할 수 있는 Flutter 앱입니다. 부모는 구독할 채널을 직접 선택하고, AI 기반 추천 시스템으로 아이의 관심사와 교육 목표에 맞는 콘텐츠 비율을 조절할 수 있습니다.

## ✨ 주요 기능

### 🔒 부모 통제 시스템
- **PIN 기반 보안**: 4자리 PIN으로 부모 설정 보호
- **채널 관리**: 부모가 직접 구독할 채널 선택 및 관리
- **추천 설정**: 카테고리별 영상 추천 비율 조절

### 🎯 AI 기반 추천 시스템
- **9개 전문 카테고리**: 한글, 키즈, 만들기, 게임, 영어, 과학, 미술, 음악, 랜덤
- **가중치 기반 알고리즘**: 부모가 설정한 비율에 따라 영상 추천
- **스마트 자동 분류**: 40+ 키워드 기반 채널 자동 카테고리 분류
- **실시간 반응형 UI**: Provider 패턴으로 즉시 업데이트

### 📊 카테고리별 필터링
- **전체 채널 보기**: 구독한 채널을 카테고리별로 필터링
- **실시간 통계**: 각 카테고리별 채널 개수 표시
- **직관적 UI**: 색상과 아이콘으로 구분된 카테고리

### ⚡ API 효율성 최적화
- **100배 효율 개선**: playlistItems.list 사용으로 API 할당량 1/100 절약
- **스마트 캐싱**: 업로드 재생목록 ID 기반 영상 로딩
- **테스트 모드**: 더미 데이터로 개발 및 테스트 지원

## 🛠️ 기술 스택

- **Frontend**: Flutter 3.29.2, Dart 3.7.2
- **API**: YouTube Data API v3
- **저장소**: SharedPreferences
- **보안**: SHA256 해시 (PIN)
- **이미지**: CachedNetworkImage
- **동영상**: youtube_player_flutter

## 📦 설치 및 실행

### 필수 조건
- Flutter SDK 3.29.2+
- Dart SDK 3.7.2+
- Android Studio / VS Code
- YouTube Data API v3 키 (선택사항)

### 설치 과정

1. **레포지토리 클론**
```bash
git clone https://github.com/jagallang/KIDSTUBE.git
cd KIDSTUBE
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **앱 실행**
```bash
# 웹에서 실행
flutter run -d chrome

# Android에서 실행  
flutter run -d android

# iOS에서 실행
flutter run -d ios
```

### YouTube API 설정 (선택사항)

실제 YouTube 데이터를 사용하려면:

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. **API 및 서비스** > **라이브러리**에서 "YouTube Data API v3" 활성화
4. **사용자 인증 정보**에서 API 키 생성
5. 앱의 **API 설정**에서 발급받은 키 입력

> 💡 **팁**: 테스트용으로 `TEST_API_KEY`를 입력하면 더미 데이터로 모든 기능을 체험할 수 있습니다.

## 📖 사용 가이드

### 첫 설정
1. **PIN 설정**: 앱 최초 실행 시 4자리 부모 PIN 설정
2. **채널 추가**: 인기 키즈 채널에서 선택하거나 직접 검색
3. **추천 설정**: 메뉴 > 추천 설정에서 카테고리별 가중치 조절

### 일상 사용
1. **메인 화면**: AI가 추천한 영상들을 2x2 그리드로 보기
2. **카테고리 필터링**: 전체 채널에서 관심 카테고리만 필터링
3. **영상 시청**: 내장 플레이어로 안전한 시청 환경 제공

## 📋 주요 화면

| 화면 | 설명 | 주요 기능 |
|------|------|-----------|
| **메인 화면** | AI 추천 영상 목록 | 2x2 그리드, 새로고침, 카테고리 기반 추천 |
| **채널 관리** | 구독 채널 관리 | 인기 채널, 검색, 구독/해제 |
| **전체 채널** | 카테고리별 필터링 | 9개 카테고리, 실시간 통계 |
| **추천 설정** | AI 알고리즘 조절 | 슬라이더, 실시간 비율, 초기화 |
| **API 설정** | API 키 관리 | 입력, 검증, 복사, 마스킹 |

## 🎨 카테고리 시스템

| 카테고리 | 아이콘 | 색상 | 키워드 예시 |
|----------|--------|------|-------------|
| **한글** | 🔤 | 파랑 | 한글, 국어, 글자, 읽기, 쓰기 |
| **키즈** | 👶 | 분홍 | 뽀로로, 핑크퐁, 타요, 코코몽 |
| **만들기** | 🔨 | 주황 | 만들기, 공작, 종이접기, DIY |
| **게임** | 🎮 | 초록 | 게임, 놀이, 퍼즐, 보드게임 |
| **영어** | 🌐 | 남색 | 영어, ABC, 파닉스, 영단어 |
| **과학** | 🔬 | 청록 | 과학, 실험, 자연, 동물, 우주 |
| **미술** | 🎨 | 진주황 | 미술, 그림, 색칠, 창작 |
| **음악** | 🎵 | 하늘 | 음악, 노래, 동요, 악기 |
| **랜덤** | 🔀 | 보라 | 기타 모든 콘텐츠 |

## 📊 API 최적화

### 기존 방식 vs 최적화 방식
```
기존: search.list API
- 채널당 100 단위 소모
- 10개 채널 = 1,000 단위
- 하루 10번 사용 = 할당량 소진

최적화: playlistItems.list API  
- 채널당 1 단위만 소모
- 10개 채널 = 10 단위
- 하루 1000번 사용 가능! 🚀
```

### 할당량 모니터링
- **일일 한도**: 10,000 단위 (무료)
- **실시간 사용량**: Google Cloud Console에서 확인
- **오류 처리**: 할당량 초과 시 테스트 모드 안내

## 📊 코드 품질 지표

### 종합 평가: 7.5/10

| 항목 | 점수 | 상태 |
|------|------|------|
| **Provider 아키텍처** | 8/10 | 🟢 우수 |
| **에러 처리** | 8/10 | 🟢 우수 |
| **성능 최적화** | 6/10 | 🟡 개선 필요 |
| **코드 품질** | 7/10 | 🟡 양호 |
| **보안** | 7/10 | 🟡 양호 |
| **유지보수성** | 7/10 | 🟡 양호 |

### 🎯 주요 강점
- ✅ 체계적인 Provider 상태관리 아키텍처
- ✅ 포괄적인 에러 처리 및 복구 메커니즘
- ✅ 메모리 최적화된 이미지 캐싱
- ✅ 반응형 UI 구현
- ✅ 보안 인식 (PIN 해싱)

### 🔧 개선 계획
- 🔄 Provider간 결합도 제거 (의존성 주입)
- ⚡ Selector 패턴 도입으로 성능 최적화
- 📝 BaseProvider 클래스로 코드 중복 제거
- 🔐 API 키 암호화 저장

## 🔧 개발자 정보

### 폴더 구조
```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── channel.dart          # 채널 모델 (카테고리 자동분류)
│   ├── video.dart           # 영상 모델
│   └── recommendation_weights.dart # 추천 가중치 모델
├── providers/                # Provider 상태 관리
│   ├── video_provider.dart   # 영상 상태 관리
│   ├── channel_provider.dart # 채널 상태 관리
│   └── recommendation_provider.dart # 추천 설정 상태 관리
├── services/                 # 비즈니스 로직
│   ├── youtube_service.dart  # YouTube API 서비스
│   └── storage_service.dart  # 로컬 저장 서비스
└── screens/                  # UI 화면
    ├── splash_screen.dart    # 스플래시
    ├── main_screen.dart      # 메인 화면 (Provider 기반)
    ├── channel_management_screen.dart # 채널 관리
    ├── all_channels_screen.dart       # 전체 채널
    ├── recommendation_settings_screen.dart # 추천 설정 (Provider 기반)
    ├── api_settings_screen.dart       # API 설정
    └── video_player_screen.dart       # 동영상 플레이어
```

### 주요 기술적 특징
- **상태 관리**: Provider 패턴 기반 반응형 아키텍처
- **비동기 처리**: Future/async-await 패턴
- **에러 처리**: 중앙화된 에러 관리 + 사용자 친화적 메시지
- **보안**: PIN SHA256 해싱
- **성능**: 메모리 최적화 이미지 캐싱, API 최적화
- **자동 분류**: 키워드 기반 채널 카테고리 자동 분류

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)  
5. Open a Pull Request

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 연락처

- **GitHub**: [@jagallang](https://github.com/jagallang)
- **프로젝트 링크**: [https://github.com/jagallang/KIDSTUBE](https://github.com/jagallang/KIDSTUBE)

## 🙏 감사의 말

- Flutter 팀의 훌륭한 프레임워크
- YouTube Data API v3 제공
- 오픈소스 커뮤니티의 지원

---

## 📋 문서

- **[코드 리뷰 v1.0.2](docs/CODE_REVIEW_v1.0.2.md)**: Provider 구현 종합 평가
- **[API 문서](docs/API.md)**: YouTube Data API 사용법 (예정)
- **[아키텍처 가이드](docs/ARCHITECTURE.md)**: 앱 구조 설명 (예정)

## 🚀 버전 히스토리

### v1.0.3 (2025-09-02)
- 📋 **종합 코드리뷰 완료**
- 📊 코드 품질 지표 측정 (7.5/10)
- 📝 상세 기술 문서 작성
- 🎯 성능 최적화 로드맵 수립
- 📈 개선 우선순위 정의

### v1.0.2 (2025-09-02)
- 🔄 **Provider 상태관리 아키텍처 도입**
- ✨ 3개 Provider 클래스로 상태 중앙화
- 🎯 반응형 UI 및 자동 업데이트 구현
- 🛠️ 에러 처리 개선 및 사용자 경험 향상
- 📱 메모리 최적화 이미지 캐싱
- 🏷️ 채널 자동 카테고리 분류 시스템
- 🔧 코드 구조 개선 및 재사용성 향상

### v1.0.0 (2025-09-02)
- 🎉 초기 릴리즈
- ✅ 9개 카테고리 추천 시스템
- ✅ API 할당량 100배 최적화  
- ✅ 부모 통제 시스템
- ✅ 카테고리별 필터링
- ✅ 안전한 동영상 플레이어

---

**아이들에게 안전하고 교육적인 YouTube 경험을 제공합니다** 🌟
