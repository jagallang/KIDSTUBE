# 🚀 KidsTube v1.0.0 → v2.0.0 마이그레이션 가이드

## 📋 개요

기존 v1.0.0 코드를 에러 최소화와 성능 최적화를 위한 새로운 구조로 마이그레이션하는 가이드입니다.

## 🏗️ 새로운 아키텍처 구조

### Before (v1.0.0)
```
lib/
├── main.dart
├── models/
├── services/
└── screens/
```

### After (v2.0.0)
```
lib/
├── core/                    # 🆕 핵심 인프라
│   ├── cache/              # 캐싱 시스템
│   ├── errors/             # 에러 처리
│   ├── network/            # 네트워크 관리  
│   ├── security/           # 보안 관련
│   └── di/                 # 의존성 주입
├── data/                   # 🆕 데이터 레이어
│   ├── datasources/        # 데이터 소스
│   └── repositories/       # 리포지토리
├── domain/                 # 🆕 비즈니스 로직
├── presentation/           # 🔄 UI 레이어 (기존 screens/)
└── models/                 # ✅ 그대로 유지
```

## 🔄 마이그레이션 단계별 로드맵

### Phase 1: 핵심 인프라 구축 ✅
- [x] 에러 처리 시스템 (`core/errors/`)
- [x] Result 패턴 구현
- [x] 캐싱 시스템 (`core/cache/`)
- [x] 레이트 리미터 (`core/network/`)
- [x] 보안 저장소 (`core/security/`)
- [x] 의존성 주입 (`core/di/`)

### Phase 2: 데이터 레이어 리팩토링 🔄
- [ ] YouTube API Client 구현
- [ ] Repository 패턴 완성
- [ ] 기존 StorageService 마이그레이션
- [ ] 기존 YouTubeService 마이그레이션

### Phase 3: UI 레이어 개선 🔄
- [ ] 기존 screens/ → presentation/screens/ 이동
- [ ] 에러 처리 UI 개선
- [ ] 로딩 상태 관리 개선
- [ ] 공통 위젯 분리

### Phase 4: 테스트 및 최적화 🔄
- [ ] 유닛 테스트 추가
- [ ] 통합 테스트 구현
- [ ] 성능 최적화
- [ ] 메모리 사용량 최적화

## 🛠️ 구체적인 마이그레이션 작업

### 1. 기존 YouTubeService → YouTubeRepository 마이그레이션

**기존 코드 (lib/services/youtube_service.dart):**
```dart
class YouTubeService {
  static Future<List<Channel>> searchChannels(String query) async {
    // 직접 HTTP 호출
  }
}
```

**새로운 코드 (lib/data/repositories/youtube_repository.dart):**
```dart
class YouTubeRepository {
  Future<Result<List<Channel>>> searchChannels(String query) async {
    // 캐싱 + 레이트 리미팅 + 에러 처리
  }
}
```

### 2. 기존 StorageService → SecureStorage 마이그레이션

**기존 코드:**
```dart
class StorageService {
  static Future<void> saveApiKey(String key) async {
    // 평문 저장
  }
}
```

**새로운 코드:**
```dart
class SecureStorage {
  Future<Result<void>> write(String key, String value) async {
    // 암호화 저장
  }
}
```

### 3. 화면별 에러 처리 개선

**기존 코드:**
```dart
try {
  final videos = await YouTubeService.getVideos();
  setState(() {
    _videos = videos;
  });
} catch (e) {
  print('Error: $e'); // 콘솔만 출력
}
```

**새로운 코드:**
```dart
final result = await _repository.getVideos();
result.fold(
  onSuccess: (videos) {
    setState(() {
      _videos = videos;
      _isLoading = false;
    });
  },
  onFailure: (error) {
    setState(() {
      _error = error.message;
      _isLoading = false;
    });
    _showErrorSnackBar(error.message);
  },
);
```

## 📦 필요한 의존성 추가

```yaml
dependencies:
  # 기존 의존성들...
  
  # 새로 추가할 의존성들
  flutter_secure_storage: ^9.0.0  # 보안 저장소
  crypto: ^3.0.3                  # 암호화
  # provider: ^6.1.1              # 상태 관리 (선택사항)
```

## 🚨 주의사항

### 1. 데이터 마이그레이션
- 기존 SharedPreferences 데이터를 새로운 보안 저장소로 마이그레이션 필요
- API 키 재암호화 필요
- PIN 해시 재생성 필요 (salt 추가)

### 2. API 호환성
- 기존 API 호출 방식 유지하면서 점진적 마이그레이션
- 테스트 모드 기능 보존
- 할당량 최적화 기능 강화

### 3. UI/UX 일관성
- 기존 UI 디자인 보존
- 에러 메시지 한국어 지원
- 로딩 상태 개선

## 🔥 핫픽스 (즉시 적용 가능)

### 1. API 할당량 최적화
```dart
// 기존: search API (100 units)
await YouTubeService.searchChannels(query);

// 개선: playlistItems API (1 unit) 우선 사용
await YouTubeRepository.getChannelVideos(channelId);
```

### 2. 기본적인 에러 처리 개선
```dart
// 기존
catch (e) {
  print('Error: $e');
}

// 개선
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('오류가 발생했습니다: ${e.toString()}')),
  );
}
```

### 3. PIN 보안 강화
```dart
// 기존: 4자리 PIN
static bool isValidPin(String pin) {
  return pin.length == 4;
}

// 개선: 6자리 + 복잡성 검사
static bool isValidPin(String pin) {
  return PinSecurityUtils.isValidPin(pin);
}
```

## 📈 성능 개선 효과 예상

| 항목 | 기존 (v1.0.0) | 개선 (v2.0.0) | 개선율 |
|------|---------------|---------------|---------|
| API 할당량 사용 | ~200 units/session | ~20 units/session | **90% 절약** |
| 앱 로딩 속도 | 3-5초 | 1-2초 | **60% 개선** |
| 메모리 사용량 | 50-70MB | 30-50MB | **30% 절약** |
| 에러 발생률 | 15-20% | 5-8% | **60% 감소** |

## 🚀 마이그레이션 실행 명령어

```bash
# 1. 의존성 추가
flutter pub add flutter_secure_storage crypto

# 2. 새로운 구조로 파일 이동
mkdir -p lib/core/{cache,errors,network,security,di}
mkdir -p lib/data/{datasources,repositories}
mkdir -p lib/presentation/{screens,widgets}

# 3. 기존 파일 점진적 마이그레이션
# (수동으로 한 파일씩 처리)

# 4. 테스트 실행
flutter test

# 5. 빌드 테스트
flutter build apk --debug
```

## ✅ 마이그레이션 체크리스트

### Phase 1: 기초 설정
- [x] 새로운 폴더 구조 생성
- [x] 핵심 인프라 파일 생성
- [x] 의존성 주입 시스템 구축
- [ ] pubspec.yaml 의존성 추가

### Phase 2: 데이터 레이어
- [ ] YouTubeApiClient 구현
- [ ] YouTubeRepository 완성
- [ ] StorageService → SecureStorage 마이그레이션
- [ ] 캐싱 시스템 연동

### Phase 3: UI 레이어
- [ ] 에러 처리 UI 개선
- [ ] 로딩 상태 관리 개선
- [ ] 공통 위젯 분리
- [ ] 화면별 마이그레이션

### Phase 4: 테스트 및 배포
- [ ] 유닛 테스트 작성
- [ ] 통합 테스트 구현
- [ ] 성능 테스트
- [ ] 프로덕션 배포

---

**다음 단계:** Phase 2 - 데이터 레이어 리팩토링 시작