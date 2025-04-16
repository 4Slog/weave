import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Utility class for memory management
class MemoryUtils {
  /// Get the recommended cache size based on available memory
  ///
  /// This is a simplified implementation. In a real app, you would use
  /// platform-specific code to get actual memory information.
  static int getRecommendedCacheSize({
    int minSizeKB = 5 * 1024, // 5 MB minimum
    int maxSizeKB = 50 * 1024, // 50 MB maximum
    double memoryFraction = 0.1, // Use 10% of available memory
  }) {
    // For now, return a value between min and max based on device tier
    // In a real implementation, you would get actual memory info
    final deviceTier = _estimateDeviceTier();

    switch (deviceTier) {
      case DeviceTier.low:
        return minSizeKB;
      case DeviceTier.medium:
        return (minSizeKB + (maxSizeKB - minSizeKB) * 0.3).round();
      case DeviceTier.high:
        return (minSizeKB + (maxSizeKB - minSizeKB) * 0.7).round();
      case DeviceTier.premium:
        return maxSizeKB;
    }
  }

  /// Estimate the device tier based on available information
  ///
  /// This is a simplified implementation. In a real app, you would use
  /// platform-specific code to get actual device information.
  static DeviceTier _estimateDeviceTier() {
    if (kIsWeb) {
      // For web, assume medium tier
      return DeviceTier.medium;
    }

    // For now, return a random tier for testing
    // In a real implementation, you would check actual device specs
    final random = Random();
    final value = random.nextDouble();

    if (value < 0.2) {
      return DeviceTier.low;
    } else if (value < 0.5) {
      return DeviceTier.medium;
    } else if (value < 0.8) {
      return DeviceTier.high;
    } else {
      return DeviceTier.premium;
    }
  }
}

/// Represents the tier of a device based on its capabilities
enum DeviceTier {
  /// Low-end devices with limited memory and processing power
  low,

  /// Mid-range devices with moderate capabilities
  medium,

  /// High-end devices with good performance
  high,

  /// Premium devices with excellent performance
  premium,
}

/// A cache implementation with LRU (Least Recently Used) eviction policy
class LRUCache<K, V> {
  /// Maximum number of items in the cache
  final int maxSize;

  /// Internal linked hash map for O(1) access and ordering
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  /// Create a new LRU cache with the specified maximum size
  LRUCache({required this.maxSize});

  /// Get a value from the cache
  V? get(K key) {
    final value = _cache[key];
    if (value != null) {
      // Move to the end (most recently used)
      _cache.remove(key);
      _cache[key] = value;
    }
    return value;
  }

  /// Put a value in the cache
  void put(K key, V value) {
    // If key exists, remove it first
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }

    // If cache is full, remove least recently used item
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    // Add new item
    _cache[key] = value;
  }

  /// Remove a value from the cache
  V? remove(K key) {
    return _cache.remove(key);
  }

  /// Clear the cache
  void clear() {
    _cache.clear();
  }

  /// Get the current size of the cache
  int get size => _cache.length;

  /// Check if the cache contains a key
  bool containsKey(K key) => _cache.containsKey(key);

  /// Get all keys in the cache
  Iterable<K> get keys => _cache.keys;

  /// Get all values in the cache
  Iterable<V> get values => _cache.values;
}

/// A cache implementation with time-based expiration
class ExpiringCache<K, V> {
  /// Maximum age of items in the cache
  final Duration maxAge;

  /// Internal map for storing values and their expiration times
  final Map<K, _CacheEntry<V>> _cache = {};

  /// Timer for periodic cleanup
  Timer? _cleanupTimer;

  /// Create a new expiring cache with the specified maximum age
  ExpiringCache({
    required this.maxAge,
    Duration? cleanupInterval,
  }) {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      cleanupInterval ?? Duration(minutes: 5),
      (_) => _cleanup(),
    );
  }

  /// Get a value from the cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Put a value in the cache
  void put(K key, V value) {
    final expirationTime = DateTime.now().add(maxAge);
    _cache[key] = _CacheEntry<V>(value, expirationTime);
  }

  /// Remove a value from the cache
  V? remove(K key) {
    final entry = _cache.remove(key);
    return entry?.value;
  }

  /// Clear the cache
  void clear() {
    _cache.clear();
  }

  /// Get the current size of the cache
  int get size => _cache.length;

  /// Check if the cache contains a key
  bool containsKey(K key) => _cache.containsKey(key) && !_cache[key]!.isExpired;

  /// Dispose the cache and stop the cleanup timer
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _cache.clear();
  }

  /// Clean up expired entries
  void _cleanup() {
    final keysToRemove = <K>[];

    // Find expired entries
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    // Remove expired entries
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
}

/// A cache entry with an expiration time
class _CacheEntry<V> {
  /// The cached value
  final V value;

  /// The expiration time
  final DateTime expirationTime;

  /// Create a new cache entry
  _CacheEntry(this.value, this.expirationTime);

  /// Check if the entry is expired
  bool get isExpired => DateTime.now().isAfter(expirationTime);
}

/// A priority cache that evicts items based on priority
class PriorityCache<K, V> {
  /// Maximum size of the cache
  final int maxSize;

  /// Internal map for storing values and their priorities
  final Map<K, _PriorityCacheEntry<V>> _cache = {};

  /// Create a new priority cache with the specified maximum size
  PriorityCache({required this.maxSize});

  /// Get a value from the cache
  V? get(K key) {
    final entry = _cache[key];
    return entry?.value;
  }

  /// Put a value in the cache with the specified priority
  void put(K key, V value, {int priority = 0}) {
    // If key exists, update it
    if (_cache.containsKey(key)) {
      _cache[key] = _PriorityCacheEntry<V>(value, priority);
      return;
    }

    // If cache is full, remove lowest priority item
    if (_cache.length >= maxSize) {
      _evictLowestPriority();
    }

    // Add new item
    _cache[key] = _PriorityCacheEntry<V>(value, priority);
  }

  /// Remove a value from the cache
  V? remove(K key) {
    final entry = _cache.remove(key);
    return entry?.value;
  }

  /// Clear the cache
  void clear() {
    _cache.clear();
  }

  /// Get the current size of the cache
  int get size => _cache.length;

  /// Check if the cache contains a key
  bool containsKey(K key) => _cache.containsKey(key);

  /// Get all keys in the cache
  Iterable<K> get keys => _cache.keys;

  /// Evict the item with the lowest priority
  void _evictLowestPriority() {
    if (_cache.isEmpty) return;

    K? keyToRemove;
    int lowestPriority = 9999999;

    // Find the item with the lowest priority
    for (final entry in _cache.entries) {
      if (entry.value.priority < lowestPriority) {
        lowestPriority = entry.value.priority;
        keyToRemove = entry.key;
      }
    }

    // Remove the item
    if (keyToRemove != null) {
      _cache.remove(keyToRemove);
    }
  }
}

/// A cache entry with a priority
class _PriorityCacheEntry<V> {
  /// The cached value
  final V value;

  /// The priority (higher values are higher priority)
  final int priority;

  /// Create a new priority cache entry
  _PriorityCacheEntry(this.value, this.priority);
}
