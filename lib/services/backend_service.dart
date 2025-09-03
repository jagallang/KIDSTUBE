import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../core/interfaces/i_backend_service.dart';
import '../models/user.dart';
import '../models/family.dart';
import '../models/auth_response.dart';
import '../models/video.dart';
import '../models/channel.dart';

class BackendService implements IBackendService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final String _baseUrl;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  BackendService({
    required String baseUrl,
  }) : _baseUrl = baseUrl,
       _dio = Dio(),
       _secureStorage = const FlutterSecureStorage() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Accept'] = 'application/json';

    // Request interceptor for adding auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            // Retry the original request
            final opts = error.requestOptions;
            final token = await _secureStorage.read(key: _accessTokenKey);
            opts.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await _dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry also fails, continue with original error
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post('/api/v1/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        await _storeTokens(authResponse.tokens);
        return true;
      }
    } catch (e) {
      // Refresh failed, clear tokens
      await _clearTokens();
    }
    return false;
  }

  Future<void> _storeTokens(AuthTokens tokens) async {
    await _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken);
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String familyName,
  }) async {
    final response = await _dio.post('/api/v1/signup', data: {
      'user': {
        'email': email,
        'password': password,
        'name': name,
      },
      'family_name': familyName,
    });

    final authResponse = AuthResponse.fromJson(response.data);
    await _storeTokens(authResponse.tokens);
    return authResponse;
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/api/v1/login', data: {
      'user': {
        'email': email,
        'password': password,
      },
    });

    final authResponse = AuthResponse.fromJson(response.data);
    await _storeTokens(authResponse.tokens);
    return authResponse;
  }

  @override
  Future<void> signOut() async {
    try {
      await _dio.delete('/api/v1/logout');
    } finally {
      await _clearTokens();
    }
  }

  @override
  Future<AuthResponse?> refreshToken() async {
    final success = await _tryRefreshToken();
    if (!success) return null;

    // Get current user info after refresh
    try {
      final response = await _dio.get('/api/v1/family');
      final family = Family.fromJson(response.data);
      final user = family.users?.first;
      
      if (user != null) {
        final token = await _secureStorage.read(key: _accessTokenKey);
        final refreshTokenStr = await _secureStorage.read(key: _refreshTokenKey);
        
        return AuthResponse(
          user: user,
          tokens: AuthTokens(
            accessToken: token!,
            refreshToken: refreshTokenStr!,
          ),
        );
      }
    } catch (e) {
      await _clearTokens();
    }
    return null;
  }

  @override
  Future<Family> getFamily() async {
    final response = await _dio.get('/api/v1/family');
    return Family.fromJson(response.data);
  }

  @override
  Future<Family> updateFamily({
    String? name,
    Map<String, dynamic>? settings,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (settings != null) data['settings'] = settings;

    final response = await _dio.patch('/api/v1/family', data: {
      'family': data,
    });

    return Family.fromJson(response.data);
  }

  @override
  Future<User> addFamilyMember({
    required String email,
    required String name,
    required String password,
    String? pin,
  }) async {
    final data = <String, dynamic>{
      'member': {
        'email': email,
        'name': name,
        'password': password,
      },
    };
    if (pin != null) {
      data['pin'] = pin;
    }

    final response = await _dio.post('/api/v1/family/members', data: data);
    return User.fromJson(response.data);
  }

  @override
  Future<void> removeFamilyMember(String userId) async {
    await _dio.delete('/api/v1/family/members/$userId');
  }

  @override
  Future<List<Channel>> searchChannels(String query) async {
    final response = await _dio.get('/api/v1/channels/search', 
      queryParameters: {'query': query});

    final List<dynamic> channelsData = response.data['channels'];
    return channelsData.map((json) => Channel.fromJson(json)).toList();
  }

  @override
  Future<void> subscribeToChannel({
    required String channelId,
    required String channelTitle,
    String? channelThumbnail,
    String? channelDescription,
  }) async {
    await _dio.post('/api/v1/subscriptions', data: {
      'subscription': {
        'channel_id': channelId,
        'channel_title': channelTitle,
        'channel_thumbnail': channelThumbnail,
        'channel_description': channelDescription,
      },
    });
  }

  @override
  Future<void> unsubscribeFromChannel(String channelId) async {
    await _dio.delete('/api/v1/subscriptions/$channelId');
  }

  @override
  Future<List<Channel>> getSubscriptions() async {
    final response = await _dio.get('/api/v1/subscriptions');
    final List<dynamic> subscriptionsData = response.data;
    
    return subscriptionsData.map((json) => Channel(
      id: json['channel_id'] as String,
      title: json['channel_title'] as String,
      thumbnail: (json['channel_thumbnail'] as String?) ?? '',
      subscriberCount: '0', // Not provided by backend subscription
      uploadsPlaylistId: '', // Not needed for subscriptions
      category: '랜덤', // Default category
    )).toList();
  }

  @override
  Future<List<Video>> getFeed({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get('/api/v1/feed', 
      queryParameters: {
        'page': page,
        'per_page': perPage,
      });

    final List<dynamic> videosData = response.data['videos'];
    return videosData.map((json) => Video.fromCacheJson(json)).toList();
  }

  @override
  Future<List<Video>> getTrendingVideos() async {
    final response = await _dio.get('/api/v1/trending');
    final List<dynamic> videosData = response.data['videos'];
    return videosData.map((json) => Video.fromCacheJson(json)).toList();
  }

  @override
  Future<void> recordWatchHistory({
    required String videoId,
    required int durationSeconds,
    DateTime? watchedAt,
  }) async {
    await _dio.post('/api/v1/watch_histories', data: {
      'watch': {
        'video_id': videoId,
        'duration_seconds': durationSeconds,
        'watched_at': watchedAt?.toIso8601String(),
      },
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getWatchHistory({
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _dio.get('/api/v1/watch_histories', 
      queryParameters: {
        'page': page,
        'per_page': perPage,
      });

    return List<Map<String, dynamic>>.from(response.data['histories']);
  }

  @override
  Future<Map<String, dynamic>> getWatchStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (userId != null) queryParams['user_id'] = userId;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await _dio.get('/api/v1/statistics/watch', 
      queryParameters: queryParams);

    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> blockContent({
    required String contentType,
    required String value,
    String? reason,
  }) async {
    await _dio.post('/api/v1/family/block_content', data: {
      'blocked_content': {
        'content_type': contentType,
        'value': value,
        'reason': reason,
      },
    });
  }

  // Helper methods for token validation
  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null) return false;

    try {
      final isExpired = Jwt.isExpired(token);
      return !isExpired;
    } catch (e) {
      return false;
    }
  }

  Future<User?> getCurrentUserFromToken() async {
    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token == null) return null;

      final payload = Jwt.parseJwt(token);
      final userId = payload['sub'] as String?;
      
      if (userId != null) {
        // Get user info from family endpoint
        final family = await getFamily();
        return family.users?.firstWhere((user) => user.id == userId);
      }
    } catch (e) {
      await _clearTokens();
    }
    return null;
  }
}