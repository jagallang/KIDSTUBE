
/// Generic cached data wrapper with expiration and metadata
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  final int viewCount;
  final Map<String, dynamic>? metadata;

  const CachedData({
    required this.data,
    required this.timestamp,
    required this.ttl,
    this.viewCount = 0,
    this.metadata,
  });

  /// Check if cached data is still valid
  bool get isValid {
    final now = DateTime.now();
    return now.difference(timestamp) < ttl;
  }

  /// Check if data is expired
  bool get isExpired => !isValid;

  /// Get age of cached data
  Duration get age => DateTime.now().difference(timestamp);

  /// Get remaining time until expiration
  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return ttl - age;
  }

  /// Create a copy with updated view count
  CachedData<T> withIncrementedViewCount() {
    return CachedData(
      data: data,
      timestamp: timestamp,
      ttl: ttl,
      viewCount: viewCount + 1,
      metadata: metadata,
    );
  }

  /// Create a copy with updated metadata
  CachedData<T> withMetadata(Map<String, dynamic> newMetadata) {
    return CachedData(
      data: data,
      timestamp: timestamp,
      ttl: ttl,
      viewCount: viewCount,
      metadata: {...?metadata, ...newMetadata},
    );
  }

  /// Convert to JSON map for storage
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inMilliseconds,
      'viewCount': viewCount,
      'metadata': metadata,
    };
  }

  /// Create from JSON map with data deserializer
  static CachedData<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic) dataDeserializer,
  ) {
    return CachedData<T>(
      data: dataDeserializer(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
      viewCount: json['viewCount'] ?? 0,
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  @override
  String toString() {
    return 'CachedData(valid: $isValid, age: ${age.inMinutes}min, viewCount: $viewCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedData<T> &&
        other.data == data &&
        other.timestamp == timestamp &&
        other.ttl == ttl;
  }

  @override
  int get hashCode {
    return data.hashCode ^ timestamp.hashCode ^ ttl.hashCode;
  }
}

/// Utility class for working with cached data in SharedPreferences
class CacheStorage {
  /// Save cached data to SharedPreferences as JSON string
  static Future<void> save<T>(
    String key,
    CachedData<T> cachedData,
    String Function(T) dataSerializer,
  ) async {
    final jsonMap = cachedData.toJson();
    jsonMap['data'] = dataSerializer(cachedData.data);
    
    // Implementation will be injected via dependency
  }

  /// Load cached data from SharedPreferences
  static Future<CachedData<T>?> load<T>(
    String key,
    T Function(dynamic) dataDeserializer,
  ) async {
    // Implementation will be injected via dependency
    return null;
  }

  /// Check if cache exists and is valid
  static Future<bool> isValid(String key) async {
    try {
      final cachedData = await load<dynamic>(key, (data) => data);
      return cachedData?.isValid ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Remove cached data
  static Future<void> remove(String key) async {
    // Implementation will be injected via dependency
  }

  /// Clear all cache data
  static Future<void> clear() async {
    // Implementation will be injected via dependency
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    return {
      'totalKeys': 0,
      'totalSize': 0,
      'hitRate': 0.0,
      'missRate': 0.0,
    };
  }
}