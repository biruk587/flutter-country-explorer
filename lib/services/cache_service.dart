// Simple in-memory cache with a 5-minute time-to-live (TTL).
// Bonus: Local Caching (+5 marks)

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  CacheEntry({required this.data, required this.timestamp});

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 5);
}

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  final Map<String, CacheEntry<dynamic>> _cache = {};

  // Store data with a key
  void put<T>(String key, T data) {
    _cache[key] = CacheEntry<T>(data: data, timestamp: DateTime.now());
  }

  // Get cached data if it exists and is not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  // Check if valid (non-expired) cache exists for this key
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }
}
