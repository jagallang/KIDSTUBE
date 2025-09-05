// 안전한 데이터 저장소
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../errors/result.dart';
import '../errors/app_error.dart';

abstract class SecureStorage {
  Future<Result<String?>> read(String key);
  Future<Result<void>> write(String key, String value);
  Future<Result<void>> delete(String key);
  Future<Result<void>> deleteAll();
}

// 기본 보안 저장소 (향후 flutter_secure_storage로 교체 가능)
class DefaultSecureStorage implements SecureStorage {
  static const String _keyPrefix = 'secure_';
  static const String _encryptionKey = 'kids_tube_secure_key_2025';

  @override
  Future<Result<String?>> read(String key) async {
    try {
      // 여기서는 SharedPreferences 사용 (나중에 flutter_secure_storage로 교체)
      final encryptedValue = await _getFromSharedPrefs('$_keyPrefix$key');
      if (encryptedValue == null) {
        return const Success(null);
      }
      
      final decryptedValue = _decrypt(encryptedValue);
      return Success(decryptedValue);
    } catch (e) {
      return Failure(AuthError(
        message: '보안 데이터 읽기 실패',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Result<void>> write(String key, String value) async {
    try {
      final encryptedValue = _encrypt(value);
      await _saveToSharedPrefs('$_keyPrefix$key', encryptedValue);
      return const Success(null);
    } catch (e) {
      return Failure(AuthError(
        message: '보안 데이터 저장 실패',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Result<void>> delete(String key) async {
    try {
      await _removeFromSharedPrefs('$_keyPrefix$key');
      return const Success(null);
    } catch (e) {
      return Failure(AuthError(
        message: '보안 데이터 삭제 실패',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Result<void>> deleteAll() async {
    try {
      await _clearAllSecureData();
      return const Success(null);
    } catch (e) {
      return Failure(AuthError(
        message: '모든 보안 데이터 삭제 실패',
        details: e.toString(),
      ));
    }
  }

  // 간단한 XOR 암호화 (실제로는 더 강력한 암호화 사용 권장)
  String _encrypt(String plainText) {
    final keyBytes = utf8.encode(_encryptionKey);
    final textBytes = utf8.encode(plainText);
    final encryptedBytes = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      encryptedBytes.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encryptedBytes);
  }

  String _decrypt(String encryptedText) {
    final keyBytes = utf8.encode(_encryptionKey);
    final encryptedBytes = base64.decode(encryptedText);
    final decryptedBytes = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(decryptedBytes);
  }

  // SharedPreferences 래퍼 메서드들 (임시 구현)
  Future<String?> _getFromSharedPrefs(String key) async {
    // TODO: SharedPreferences 구현
    return null;
  }

  Future<void> _saveToSharedPrefs(String key, String value) async {
    // TODO: SharedPreferences 구현
  }

  Future<void> _removeFromSharedPrefs(String key) async {
    // TODO: SharedPreferences 구현
  }

  Future<void> _clearAllSecureData() async {
    // TODO: SharedPreferences secure data clearing 구현
  }
}

// PIN 관련 보안 유틸리티
class PinSecurityUtils {
  static const int minPinLength = 6;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  // 강화된 PIN 검증
  static bool isValidPin(String pin) {
    if (pin.length < minPinLength) return false;
    
    // 연속된 숫자 확인 (123456, 654321)
    if (_hasConsecutiveNumbers(pin)) return false;
    
    // 반복된 숫자 확인 (111111, 222222)
    if (_hasRepeatedNumbers(pin)) return false;
    
    // 일반적인 PIN 패턴 확인
    if (_isCommonPin(pin)) return false;
    
    return true;
  }

  static bool _hasConsecutiveNumbers(String pin) {
    for (int i = 0; i < pin.length - 2; i++) {
      final first = int.parse(pin[i]);
      final second = int.parse(pin[i + 1]);
      final third = int.parse(pin[i + 2]);
      
      if (second == first + 1 && third == second + 1) return true;
      if (second == first - 1 && third == second - 1) return true;
    }
    return false;
  }

  static bool _hasRepeatedNumbers(String pin) {
    final firstDigit = pin[0];
    return pin.split('').every((digit) => digit == firstDigit);
  }

  static bool _isCommonPin(String pin) {
    const commonPins = [
      '123456', '654321', '000000', '111111',
      '123123', '456456', '789789', '147258',
      '741852', '987654',
    ];
    return commonPins.contains(pin);
  }

  // PIN 해시 생성 (salt 추가)
  static String generatePinHash(String pin) {
    final salt = _generateSalt();
    final combined = pin + salt;
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return '$salt:${hash.toString()}';
  }

  // PIN 검증
  static bool verifyPin(String pin, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      final combined = pin + salt;
      final bytes = utf8.encode(combined);
      final computedHash = sha256.convert(bytes).toString();
      
      return computedHash == hash;
    } catch (e) {
      return false;
    }
  }

  static String _generateSalt() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }
}

// 보안 키 관리
class SecurityKeys {
  static const String apiKey = 'youtube_api_key';
  static const String pinHash = 'pin_hash';
  static const String failedAttempts = 'failed_attempts';
  static const String lastFailedTime = 'last_failed_time';
}