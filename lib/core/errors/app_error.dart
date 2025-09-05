// 통합 에러 관리 시스템
abstract class AppError {
  final String message;
  final String code;
  final String? details;

  const AppError({
    required this.message,
    required this.code,
    this.details,
  });
}

// API 관련 에러
class ApiError extends AppError {
  final int? statusCode;
  final String? endpoint;

  const ApiError({
    required String message,
    required String code,
    String? details,
    this.statusCode,
    this.endpoint,
  }) : super(message: message, code: code, details: details);
}

// 네트워크 에러
class NetworkError extends AppError {
  const NetworkError({
    String message = '네트워크 연결을 확인해주세요',
    String code = 'NETWORK_ERROR',
    String? details,
  }) : super(message: message, code: code, details: details);
}

// 캐시 에러
class CacheError extends AppError {
  const CacheError({
    String message = '데이터 저장 중 오류가 발생했습니다',
    String code = 'CACHE_ERROR',
    String? details,
  }) : super(message: message, code: code, details: details);
}

// 인증 에러
class AuthError extends AppError {
  const AuthError({
    String message = '인증에 실패했습니다',
    String code = 'AUTH_ERROR',
    String? details,
  }) : super(message: message, code: code, details: details);
}

// API 할당량 초과 에러
class QuotaExceededError extends ApiError {
  const QuotaExceededError({
    String message = 'API 사용량이 초과되었습니다. 잠시 후 다시 시도해주세요',
    String code = 'QUOTA_EXCEEDED',
    String? details,
    int? statusCode,
    String? endpoint,
  }) : super(
          message: message,
          code: code,
          details: details,
          statusCode: statusCode,
          endpoint: endpoint,
        );
}