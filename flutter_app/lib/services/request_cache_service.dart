import 'dart:async';
import 'package:logger/logger.dart';

final _logger = Logger();

/// In-memory request cache with TTL and deduplication
class RequestCacheService {
  static final RequestCacheService _instance = RequestCacheService._internal();
  factory RequestCacheService() => _instance;
  RequestCacheService._internal();

  // Cache storage: key -> (data, timestamp)
  final Map<String, _CacheEntry> _cache = {};

  // In-flight requests to prevent duplicate calls
  final Map<String, Future<dynamic>> _inflightRequests = {};

  /// Get cached data if valid, otherwise return null
  T? get<T>(String key, {Duration ttl = const Duration(minutes: 5)}) {
    final entry = _cache[key];
    if (entry == null) return null;

    final age = DateTime.now().difference(entry.timestamp);
    if (age > ttl) {
      // Stale data - remove from cache
      _cache.remove(key);
      return null;
    }

    _logger.d('Cache HIT: $key (age: ${age.inSeconds}s)');
    return entry.data as T;
  }

  /// Store data in cache
  void set(String key, dynamic data) {
    _cache[key] = _CacheEntry(data, DateTime.now());
    _logger.d('Cache SET: $key');
  }

  /// Execute request with deduplication and caching
  /// If same request is in-flight, returns the existing future
  /// If cached data is valid, returns cached data
  /// Otherwise executes the request and caches the result
  Future<T> deduplicate<T>(
    String key,
    Future<T> Function() request, {
    Duration ttl = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = get<T>(key, ttl: ttl);
      if (cached != null) {
        return cached;
      }
    }

    // Check if request is already in-flight
    if (_inflightRequests.containsKey(key)) {
      _logger.d('Request DEDUPLICATED: $key (reusing in-flight request)');
      return await _inflightRequests[key] as T;
    }

    // Execute new request
    _logger.d('Request EXECUTING: $key');
    final future = request();
    _inflightRequests[key] = future;

    try {
      final result = await future;
      // Cache the result
      set(key, result);
      return result;
    } finally {
      // Remove from in-flight
      _inflightRequests.remove(key);
    }
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    _logger.d('Cache INVALIDATED: $key');
  }

  /// Invalidate cache entries matching pattern
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((k) => regex.hasMatch(k)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    _logger.d('Cache INVALIDATED pattern: $pattern (${keysToRemove.length} entries)');
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _logger.d('Cache CLEARED');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'entries': _cache.length,
      'in_flight': _inflightRequests.length,
      'oldest_entry': _cache.values
          .map((e) => e.timestamp)
          .reduce((a, b) => a.isBefore(b) ? a : b)
          .toIso8601String(),
    };
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}

/// Global instance
final requestCache = RequestCacheService();
