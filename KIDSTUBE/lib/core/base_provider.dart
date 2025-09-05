import 'package:flutter/widgets.dart';

/// Base provider class implementing common state management patterns
/// Following Clean Architecture principles with proper error handling and loading states
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  bool _disposed = false;

  // Getters for state access
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isDisposed => _disposed;

  /// Executes an async operation with proper state management
  @protected
  Future<T> executeOperation<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    bool isRefresh = false,
    String? errorPrefix,
  }) async {
    if (_disposed) return Future.error('Provider disposed');

    _updateState(
      loading: showLoading,
      refreshing: isRefresh,
      error: null,
    );

    try {
      final result = await operation();
      if (!_disposed) {
        _updateState(
          loading: false,
          refreshing: false,
          error: null,
        );
      }
      return result;
    } catch (e) {
      if (!_disposed) {
        final errorMessage = errorPrefix != null 
          ? '$errorPrefix: ${e.toString()}'
          : e.toString();
        _updateState(
          loading: false,
          refreshing: false,
          error: errorMessage,
        );
      }
      rethrow;
    }
  }

  /// Batch state updates to minimize rebuilds
  @protected
  void _updateState({
    bool? loading,
    bool? refreshing,
    String? error,
  }) {
    if (_disposed) return;

    bool shouldNotify = false;

    if (loading != null && _isLoading != loading) {
      _isLoading = loading;
      shouldNotify = true;
    }

    if (refreshing != null && _isRefreshing != refreshing) {
      _isRefreshing = refreshing;
      shouldNotify = true;
    }

    if (error != _error) {
      _error = error;
      shouldNotify = true;
    }

    if (shouldNotify && !_disposed) {
      notifyListeners();
    }
  }

  /// Clear error state
  @protected
  void clearError() {
    if (_error != null) {
      _updateState(error: null);
    }
  }

  /// Set loading state
  @protected
  void setLoading(bool loading) {
    _updateState(loading: loading);
  }

  /// Set error state
  @protected
  void setError(String error) {
    _updateState(error: error);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Base provider for entities that can be cached
abstract class CacheableProvider<T> extends BaseProvider {
  DateTime? _lastUpdated;
  Duration _cacheTimeout = const Duration(minutes: 5);

  DateTime? get lastUpdated => _lastUpdated;
  Duration get cacheTimeout => _cacheTimeout;
  bool get isCacheExpired => _lastUpdated == null ||
      DateTime.now().difference(_lastUpdated!) > _cacheTimeout;

  @protected
  void updateCacheTimestamp() {
    _lastUpdated = DateTime.now();
  }

  @protected
  void setCacheTimeout(Duration timeout) {
    _cacheTimeout = timeout;
  }
}