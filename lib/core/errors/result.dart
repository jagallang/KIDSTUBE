// Result 패턴으로 안전한 에러 처리
import 'app_error.dart';

// Result 추상 클래스
abstract class Result<T> {
  const Result();
}

// 성공 결과
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

// 실패 결과
class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

// Result 확장 메서드
extension ResultExtension<T> on Result<T> {
  // 성공 여부 확인
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  // 데이터 가져오기 (안전)
  T? get dataOrNull {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  // 에러 가져오기 (안전)
  AppError? get errorOrNull {
    if (this is Failure<T>) {
      return (this as Failure<T>).error;
    }
    return null;
  }

  // fold 패턴 (함수형 프로그래밍)
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as Failure<T>).error);
    }
  }

  // map 변환 (성공 시에만)
  Result<R> map<R>(R Function(T data) transform) {
    if (this is Success<T>) {
      try {
        return Success(transform((this as Success<T>).data));
      } catch (e) {
        return Failure(ApiError(
          message: '데이터 변환 중 오류가 발생했습니다',
          code: 'TRANSFORM_ERROR',
          details: e.toString(),
        ));
      }
    }
    return Failure((this as Failure<T>).error);
  }
}