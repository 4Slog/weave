import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kente_codeweaver/core/utils/memory_utils.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';

/// Enhanced service for managing data persistence and caching with adaptive memory management
class EnhancedStorageService {
  // Singleton implementation
  static final EnhancedStorageService _instance = EnhancedStorageService._internal();

  factory EnhancedStorageService() {
    return _instance;
  }

  EnhancedStorageService._internal();

  // Box names
  static const String _patternsBoxName = 'patterns';
  static const String _userProgressBoxName = 'user_progress';
  static const String _settingsBoxName = 'settings';
  static const String _cacheBoxName = 'cache';
  static const String _blockCollectionsBoxName = 'block_collections';
  static const String _badgesBoxName = 'badges';
  static const String _analyticsBoxName = 'analytics';
  static const String _priorityCacheBoxName = 'priority_cache';

  // Key prefixes for namespacing
  static const String _progressKeyPrefix = 'user_progress_';
  static const String _cacheKeyPrefix = 'cache_';
  static const String _priorityCacheKeyPrefix = 'priority_cache_';

  // Initialization state
  bool _isInitialized = false;
  bool _useHive = true;

  // Hive box references for performance
  Box? _patternsBox;
  Box? _userProgressBox;
  Box? _settingsBox;
  Box? _cacheBox;
  Box? _blockCollectionsBox;
  Box? _badgesBox;
  Box? _analyticsBox;
  Box? _priorityCacheBox;

  // Shared preferences instance
  SharedPreferences? _prefs;

  // Memory management
  int _maxCacheSize = 10 * 1024 * 1024; // 10 MB default
  int _currentCacheSize = 0;
  final Map<String, int> _cacheSizes = {};

  // In-memory caches for frequently accessed data
  final LRUCache<String, dynamic> _memoryCache = LRUCache<String, dynamic>(maxSize: 100);
  final PriorityCache<String, dynamic> _priorityMemoryCache = PriorityCache<String, dynamic>(maxSize: 50);

  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // Memory pressure monitoring
  Timer? _memoryMonitorTimer;
  bool _isUnderMemoryPressure = false;

  /// Initialize the storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      if (_useHive) {
        await Hive.initFlutter();

        // Open boxes
        _patternsBox = await Hive.openBox(_patternsBoxName);
        _userProgressBox = await Hive.openBox(_userProgressBoxName);
        _settingsBox = await Hive.openBox(_settingsBoxName);
        _cacheBox = await Hive.openBox(_cacheBoxName);
        _blockCollectionsBox = await Hive.openBox(_blockCollectionsBoxName);
        _badgesBox = await Hive.openBox(_badgesBoxName);
        _analyticsBox = await Hive.openBox(_analyticsBoxName);
        _priorityCacheBox = await Hive.openBox(_priorityCacheBoxName);
      }

      // Initialize shared preferences
      _prefs = await SharedPreferences.getInstance();

      // Set adaptive cache size based on device capabilities
      _maxCacheSize = MemoryUtils.getRecommendedCacheSize() * 1024; // Convert KB to bytes

      // Start memory monitoring
      _startMemoryMonitoring();

      // Calculate current cache size
      await _calculateCacheSize();

      _isInitialized = true;
      if (kDebugMode) {
        print('EnhancedStorageService initialized successfully');
        print('Max cache size: ${(_maxCacheSize / 1024 / 1024).toStringAsFixed(2)} MB');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing EnhancedStorageService: $e');
      }
      // Fall back to shared preferences only
      _useHive = false;
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    await _ensureInitialized();

    final String key = _progressKeyPrefix + progress.userId;
    final String jsonData = jsonEncode(progress.toJson());

    if (_useHive && _userProgressBox != null) {
      await _userProgressBox!.put(key, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(key, jsonData);
    }

    // Update memory cache
    _memoryCache.put(key, progress);
  }

  /// Get user progress
  Future<UserProgress?> getUserProgress(String userId) async {
    await _ensureInitialized();

    final String key = _progressKeyPrefix + userId;

    // Check memory cache first
    final cachedProgress = _memoryCache.get(key);
    if (cachedProgress != null) {
      _cacheHits++;
      return cachedProgress as UserProgress;
    }

    _cacheMisses++;
    String? jsonData;

    if (_useHive && _userProgressBox != null) {
      jsonData = _userProgressBox!.get(key);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(key);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        final progress = UserProgress.fromJson(data);

        // Cache for future use
        _memoryCache.put(key, progress);

        return progress;
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing user progress: $e');
        }
        return null;
      }
    }

    return null;
  }

  /// Cache data with a key
  Future<void> cacheData(String key, dynamic data) async {
    await _ensureInitialized();

    final String fullKey = _cacheKeyPrefix + key;
    final String jsonData = jsonEncode(data);

    // Check if we need to make room in the cache
    final int dataSize = jsonData.length;
    if (_currentCacheSize + dataSize > _maxCacheSize) {
      await _evictCacheEntries(dataSize);
    }

    if (_useHive && _cacheBox != null) {
      await _cacheBox!.put(fullKey, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(fullKey, jsonData);
    }

    // Update cache size tracking
    _cacheSizes[fullKey] = dataSize;
    _currentCacheSize += dataSize;

    // Update memory cache
    _memoryCache.put(key, data);
  }

  /// Cache high-priority data that should be kept in memory
  Future<void> cachePriorityData(String key, dynamic data, {int priority = 1}) async {
    await _ensureInitialized();

    final String fullKey = _priorityCacheKeyPrefix + key;
    final String jsonData = jsonEncode({
      'data': data,
      'priority': priority,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_useHive && _priorityCacheBox != null) {
      await _priorityCacheBox!.put(fullKey, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(fullKey, jsonData);
    }

    // Update priority memory cache
    _priorityMemoryCache.put(key, data, priority: priority);
  }

  /// Get cached data
  Future<dynamic> getCachedData(String key) async {
    await _ensureInitialized();

    final String fullKey = _cacheKeyPrefix + key;

    // Check memory cache first
    final cachedData = _memoryCache.get(key);
    if (cachedData != null) {
      _cacheHits++;
      return cachedData;
    }

    _cacheMisses++;
    String? jsonData;

    if (_useHive && _cacheBox != null) {
      jsonData = _cacheBox!.get(fullKey);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(fullKey);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        final data = jsonDecode(jsonData);

        // Cache for future use
        _memoryCache.put(key, data);

        return data;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Get high-priority cached data
  Future<dynamic> getPriorityCachedData(String key) async {
    await _ensureInitialized();

    final String fullKey = _priorityCacheKeyPrefix + key;

    // Check priority memory cache first
    final cachedData = _priorityMemoryCache.get(key);
    if (cachedData != null) {
      _cacheHits++;
      return cachedData;
    }

    _cacheMisses++;
    String? jsonData;

    if (_useHive && _priorityCacheBox != null) {
      jsonData = _priorityCacheBox!.get(fullKey);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(fullKey);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        final result = data['data'];
        final priority = data['priority'] as int? ?? 1;

        // Cache for future use
        _priorityMemoryCache.put(key, result, priority: priority);

        return result;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _ensureInitialized();

    if (_useHive && _cacheBox != null) {
      await _cacheBox!.clear();
    } else if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await _prefs!.remove(key);
        }
      }
    }

    // Clear memory cache
    _memoryCache.clear();

    // Reset cache size tracking
    _cacheSizes.clear();
    _currentCacheSize = 0;
  }

  /// Clear specific cache entries
  Future<void> clearCacheEntries(List<String> keys) async {
    await _ensureInitialized();

    for (final key in keys) {
      final String fullKey = _cacheKeyPrefix + key;

      if (_useHive && _cacheBox != null) {
        await _cacheBox!.delete(fullKey);
      } else if (_prefs != null) {
        await _prefs!.remove(fullKey);
      }

      // Update cache size tracking
      final int dataSize = _cacheSizes[fullKey] ?? 0;
      _cacheSizes.remove(fullKey);
      _currentCacheSize -= dataSize;

      // Remove from memory cache
      _memoryCache.remove(key);
    }
  }

  /// Log analytics event
  Future<void> logAnalyticsEvent(String eventName, Map<String, dynamic> data) async {
    await _ensureInitialized();

    final String key = '${eventName}_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> eventData = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': eventName,
      'data': data,
    };

    final String jsonData = jsonEncode(eventData);

    if (_useHive && _analyticsBox != null) {
      await _analyticsBox!.put(key, jsonData);
    }
  }

  /// Get all keys
  Future<List<String>> getAllKeys() async {
    await _ensureInitialized();

    List<String> keys = [];

    if (_useHive) {
      if (_settingsBox != null) keys.addAll(_settingsBox!.keys.cast<String>());
      if (_userProgressBox != null) keys.addAll(_userProgressBox!.keys.cast<String>());
      if (_cacheBox != null) keys.addAll(_cacheBox!.keys.cast<String>());
      if (_blockCollectionsBox != null) keys.addAll(_blockCollectionsBox!.keys.cast<String>());
      if (_patternsBox != null) keys.addAll(_patternsBox!.keys.cast<String>());
      if (_badgesBox != null) keys.addAll(_badgesBox!.keys.cast<String>());
      if (_analyticsBox != null) keys.addAll(_analyticsBox!.keys.cast<String>());
      if (_priorityCacheBox != null) keys.addAll(_priorityCacheBox!.keys.cast<String>());
    } else if (_prefs != null) {
      keys.addAll(_prefs!.getKeys());
    }

    return keys;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'max_cache_size_bytes': _maxCacheSize,
      'current_cache_size_bytes': _currentCacheSize,
      'cache_utilization_percent': _maxCacheSize > 0 ? (_currentCacheSize / _maxCacheSize * 100).round() : 0,
      'memory_cache_size': _memoryCache.size,
      'priority_cache_size': _priorityMemoryCache.size,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_ratio_percent': _cacheHits + _cacheMisses > 0 ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).round() : 0,
      'is_under_memory_pressure': _isUnderMemoryPressure,
    };
  }

  // Helper methods

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkMemoryPressure(),
    );
  }

  /// Check for memory pressure
  Future<void> _checkMemoryPressure() async {
    // This is a simplified implementation
    // In a real app, you would use platform-specific code to check memory usage

    // For now, randomly simulate memory pressure occasionally
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    final newMemoryPressure = random < 2; // 20% chance of memory pressure

    // If memory pressure state changed
    if (newMemoryPressure != _isUnderMemoryPressure) {
      _isUnderMemoryPressure = newMemoryPressure;

      if (_isUnderMemoryPressure) {
        // Under memory pressure, reduce cache size
        await _reduceMemoryCacheSize();
      }
    }
  }

  /// Reduce memory cache size under pressure
  Future<void> _reduceMemoryCacheSize() async {
    // Clear non-priority memory cache
    _memoryCache.clear();

    // Keep only high-priority items in priority cache
    final keysToRemove = <String>[];
    for (final key in _priorityMemoryCache.keys) {
      final entry = _priorityMemoryCache.get(key);
      if (entry != null && entry is Map<String, dynamic> && (entry['priority'] as int? ?? 0) < 3) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _priorityMemoryCache.remove(key);
    }

    if (kDebugMode) {
      print('Reduced memory cache size due to memory pressure');
      print('Removed ${keysToRemove.length} low-priority items');
    }
  }

  /// Calculate the current cache size
  Future<void> _calculateCacheSize() async {
    _currentCacheSize = 0;
    _cacheSizes.clear();

    if (_useHive && _cacheBox != null) {
      for (final key in _cacheBox!.keys) {
        final value = _cacheBox!.get(key);
        if (value != null && value is String) {
          final size = value.length;
          _cacheSizes[key.toString()] = size;
          _currentCacheSize += size;
        }
      }
    } else if (_prefs != null) {
      for (final key in _prefs!.getKeys()) {
        if (key.startsWith(_cacheKeyPrefix)) {
          final value = _prefs!.getString(key);
          if (value != null) {
            final size = value.length;
            _cacheSizes[key] = size;
            _currentCacheSize += size;
          }
        }
      }
    }

    if (kDebugMode) {
      print('Current cache size: ${(_currentCacheSize / 1024 / 1024).toStringAsFixed(2)} MB');
    }
  }

  /// Evict cache entries to make room for new data
  Future<void> _evictCacheEntries(int neededSpace) async {
    if (_useHive && _cacheBox != null) {
      // Sort cache entries by size (largest first)
      final entries = _cacheSizes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      int freedSpace = 0;
      final keysToRemove = <String>[];

      // Remove entries until we have enough space
      for (final entry in entries) {
        // Skip priority cache entries
        if (entry.key.startsWith(_priorityCacheKeyPrefix)) {
          continue;
        }

        keysToRemove.add(entry.key);
        freedSpace += entry.value;

        if (freedSpace >= neededSpace) {
          break;
        }
      }

      // Remove the entries
      for (final key in keysToRemove) {
        if (_useHive && _cacheBox != null) {
          await _cacheBox!.delete(key);
        } else if (_prefs != null) {
          await _prefs!.remove(key);
        }

        // Update cache size tracking
        _currentCacheSize -= _cacheSizes[key] ?? 0;
        _cacheSizes.remove(key);

        // Remove from memory cache
        final memoryKey = key.replaceFirst(_cacheKeyPrefix, '');
        _memoryCache.remove(memoryKey);
      }

      if (kDebugMode && keysToRemove.isNotEmpty) {
        debugPrint('Evicted ${keysToRemove.length} cache entries, freed ${(freedSpace / 1024).toStringAsFixed(2)} KB');
      }
    }
  }
}
