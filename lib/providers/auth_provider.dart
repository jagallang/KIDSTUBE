import 'package:flutter/foundation.dart';
import '../core/base_provider.dart';
import '../core/interfaces/i_backend_service.dart';
import '../models/user.dart';
import '../models/family.dart';
import '../models/auth_response.dart';

class AuthProvider extends BaseProvider {
  final IBackendService _backendService;

  User? _currentUser;
  Family? _currentFamily;
  AuthState _state = AuthState.initial;
  String? _errorMessage;

  AuthProvider({required IBackendService backendService})
      : _backendService = backendService;

  // Getters
  User? get currentUser => _currentUser;
  Family? get currentFamily => _currentFamily;
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(AuthState.error);
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String familyName,
  }) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    try {
      final authResponse = await _backendService.signUp(
        email: email,
        password: password,
        name: name,
        familyName: familyName,
      );

      _currentUser = authResponse.user;
      await _loadFamilyData();
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);
    _errorMessage = null;

    try {
      final authResponse = await _backendService.signIn(
        email: email,
        password: password,
      );

      _currentUser = authResponse.user;
      await _loadFamilyData();
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _backendService.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error during sign out: $e');
      }
    } finally {
      _currentUser = null;
      _currentFamily = null;
      _errorMessage = null;
      _setState(AuthState.unauthenticated);
    }
  }

  Future<bool> checkAuthenticationStatus() async {
    _setState(AuthState.loading);

    try {
      final authResponse = await _backendService.refreshToken();
      if (authResponse != null) {
        _currentUser = authResponse.user;
        await _loadFamilyData();
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      _setState(AuthState.unauthenticated);
      return false;
    }
  }

  Future<void> _loadFamilyData() async {
    try {
      _currentFamily = await _backendService.getFamily();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading family data: $e');
      }
    }
  }

  Future<bool> updateFamily({
    String? name,
    Map<String, dynamic>? settings,
  }) async {
    if (!isAuthenticated) return false;

    try {
      _currentFamily = await _backendService.updateFamily(
        name: name,
        settings: settings,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> addFamilyMember({
    required String email,
    required String name,
    required String password,
    String? pin,
  }) async {
    if (!isAuthenticated || _currentUser?.role != UserRole.parent) {
      _setError('부모 권한이 필요합니다.');
      return false;
    }

    try {
      await _backendService.addFamilyMember(
        email: email,
        name: name,
        password: password,
        pin: pin,
      );
      
      // Reload family data to get updated member list
      await _loadFamilyData();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> removeFamilyMember(String userId) async {
    if (!isAuthenticated || _currentUser?.role != UserRole.parent) {
      _setError('부모 권한이 필요합니다.');
      return false;
    }

    try {
      await _backendService.removeFamilyMember(userId);
      
      // Reload family data to get updated member list
      await _loadFamilyData();
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  Future<bool> blockContent({
    required String contentType,
    required String value,
    String? reason,
  }) async {
    if (!isAuthenticated || _currentUser?.role != UserRole.parent) {
      _setError('부모 권한이 필요합니다.');
      return false;
    }

    try {
      await _backendService.blockContent(
        contentType: contentType,
        value: value,
        reason: reason,
      );
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _setState(_currentUser != null ? AuthState.authenticated : AuthState.unauthenticated);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('401')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    } else if (error.toString().contains('422')) {
      return '입력 정보가 올바르지 않습니다.';
    } else if (error.toString().contains('409')) {
      return '이미 존재하는 이메일입니다.';
    } else if (error.toString().contains('500')) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    } else if (error.toString().contains('network')) {
      return '네트워크 연결을 확인해주세요.';
    }
    return '알 수 없는 오류가 발생했습니다.';
  }
}

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}