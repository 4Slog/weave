import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';

/// Service for managing data persistence and caching
class StorageService {
  // Singleton implementation
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // Box names constants
  static const String _patternsBoxName = 'patterns';
  static const String _userProgressBoxName = 'user_progress';
  static const String _settingsBoxName = 'settings';
  static const String _cacheBoxName = 'app_cache';
  static const String _blockCollectionsBoxName = 'block_collections';
  static const String _badgesBoxName = 'badges';
  static const String _analyticsBoxName = 'analytics';

  // Key prefixes for namespacing
  static const String _progressKeyPrefix = 'user_progress_';
  static const String _settingsKey = 'app_settings';
  static const String _blocksKeyPrefix = 'saved_blocks_';
  static const String _patternsKeyPrefix = 'pattern_';
  static const String _userPatternsKeyPrefix = 'user_patterns_';
  static const String _userBadgesKeyPrefix = 'user_badges_';
  static const String _cacheKeyPrefix = 'cache_';

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

  // Shared preferences instance
  SharedPreferences? _prefs;

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
      }

      // Initialize shared preferences
      _prefs = await SharedPreferences.getInstance();

      _isInitialized = true;
      if (kDebugMode) {
        print('StorageService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing StorageService: $e');
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
  }

  /// Load user progress
  Future<UserProgress?> loadUserProgress(String userId) async {
    await _ensureInitialized();

    final String key = _progressKeyPrefix + userId;
    String? jsonData;

    if (_useHive && _userProgressBox != null) {
      jsonData = _userProgressBox!.get(key);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(key);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        return UserProgress.fromJson(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing user progress: $e');
        }
        return null;
      }
    }

    return null;
  }

  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();

    final String jsonData = jsonEncode(settings);

    if (_useHive && _settingsBox != null) {
      await _settingsBox!.put(_settingsKey, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(_settingsKey, jsonData);
    }
  }

  /// Load app settings
  Future<Map<String, dynamic>> loadSettings() async {
    await _ensureInitialized();

    String? jsonData;

    if (_useHive && _settingsBox != null) {
      jsonData = _settingsBox!.get(_settingsKey);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(_settingsKey);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        return jsonDecode(jsonData);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing settings: $e');
        }
        return {};
      }
    }

    return {};
  }

  /// Save a block collection
  Future<void> saveBlockCollection(String id, BlockCollection collection) async {
    await _ensureInitialized();

    final String key = _blocksKeyPrefix + id;
    final String jsonData = jsonEncode(collection.toJson());

    if (_useHive && _blockCollectionsBox != null) {
      await _blockCollectionsBox!.put(key, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(key, jsonData);
    }
  }

  /// Load a block collection
  Future<BlockCollection?> loadBlockCollection(String id) async {
    await _ensureInitialized();

    final String key = _blocksKeyPrefix + id;
    String? jsonData;

    if (_useHive && _blockCollectionsBox != null) {
      jsonData = _blockCollectionsBox!.get(key);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(key);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        return BlockCollection.fromJson(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing block collection: $e');
        }
        return null;
      }
    }

    return null;
  }

  /// Save a pattern
  Future<void> savePattern(PatternModel pattern) async {
    await _ensureInitialized();

    final String key = _patternsKeyPrefix + pattern.id;
    final String jsonData = jsonEncode(pattern.toJson());

    if (_useHive && _patternsBox != null) {
      await _patternsBox!.put(key, jsonData);

      // Update user patterns list
      await _updateUserPatternsList(pattern.userId, pattern.id, add: true);
    } else if (_prefs != null) {
      await _prefs!.setString(key, jsonData);
      await _updateUserPatternsList(pattern.userId, pattern.id, add: true);
    }
  }

  /// Load a pattern
  Future<PatternModel?> loadPattern(String id) async {
    await _ensureInitialized();

    final String key = _patternsKeyPrefix + id;
    String? jsonData;

    if (_useHive && _patternsBox != null) {
      jsonData = _patternsBox!.get(key);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(key);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        return PatternModel.fromJson(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing pattern: $e');
        }
        return null;
      }
    }

    return null;
  }

  /// Delete a pattern
  Future<void> deletePattern(String id, String userId) async {
    await _ensureInitialized();

    final String key = _patternsKeyPrefix + id;

    if (_useHive && _patternsBox != null) {
      await _patternsBox!.delete(key);
      await _updateUserPatternsList(userId, id, add: false);
    } else if (_prefs != null) {
      await _prefs!.remove(key);
      await _updateUserPatternsList(userId, id, add: false);
    }
  }

  /// Get all patterns for a user
  Future<List<PatternModel>> getUserPatterns(String userId) async {
    await _ensureInitialized();

    final List<String> patternIds = await _getUserPatternIds(userId);
    final List<PatternModel> patterns = [];

    for (final id in patternIds) {
      final pattern = await loadPattern(id);
      if (pattern != null) {
        patterns.add(pattern);
      }
    }

    return patterns;
  }

  /// Save a badge
  Future<void> saveBadge(BadgeModel badge, String userId) async {
    await _ensureInitialized();

    final String key = badge.id;
    final String jsonData = jsonEncode(badge.toJson());

    if (_useHive && _badgesBox != null) {
      await _badgesBox!.put(key, jsonData);
      await _updateUserBadgesList(userId, badge.id, add: true);
    } else if (_prefs != null) {
      await _prefs!.setString(key, jsonData);
      await _updateUserBadgesList(userId, badge.id, add: true);
    }
  }

  /// Load a badge
  Future<BadgeModel?> loadBadge(String id) async {
    await _ensureInitialized();

    String? jsonData;

    if (_useHive && _badgesBox != null) {
      jsonData = _badgesBox!.get(id);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(id);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        return BadgeModel.fromJson(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing badge: $e');
        }
        return null;
      }
    }

    return null;
  }

  /// Get all badges for a user
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    await _ensureInitialized();

    final List<String> badgeIds = await _getUserBadgeIds(userId);
    final List<BadgeModel> badges = [];

    for (final id in badgeIds) {
      final badge = await loadBadge(id);
      if (badge != null) {
        badges.add(badge);
      }
    }

    return badges;
  }

  /// Cache data with a key
  Future<void> cacheData(String key, dynamic data) async {
    await _ensureInitialized();

    final String fullKey = _cacheKeyPrefix + key;
    final String jsonData = jsonEncode(data);

    if (_useHive && _cacheBox != null) {
      await _cacheBox!.put(fullKey, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(fullKey, jsonData);
    }
  }

  /// Get cached data
  Future<dynamic> getCachedData(String key) async {
    await _ensureInitialized();

    final String fullKey = _cacheKeyPrefix + key;
    String? jsonData;

    if (_useHive && _cacheBox != null) {
      jsonData = _cacheBox!.get(fullKey);
    } else if (_prefs != null) {
      jsonData = _prefs!.getString(fullKey);
    }

    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        return jsonDecode(jsonData);
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

  /// Get analytics events
  Future<List<Map<String, dynamic>>> getAnalyticsEvents() async {
    await _ensureInitialized();

    final List<Map<String, dynamic>> events = [];

    if (_useHive && _analyticsBox != null) {
      final keys = _analyticsBox!.keys;
      for (final key in keys) {
        final jsonData = _analyticsBox!.get(key);
        if (jsonData != null) {
          try {
            events.add(jsonDecode(jsonData));
          } catch (e) {
            // Skip invalid data
          }
        }
      }
    }

    return events;
  }

  /// Clear all data (for testing or user account deletion)
  Future<void> clearAllData() async {
    await _ensureInitialized();

    if (_useHive) {
      if (_patternsBox != null) await _patternsBox!.clear();
      if (_userProgressBox != null) await _userProgressBox!.clear();
      if (_settingsBox != null) await _settingsBox!.clear();
      if (_cacheBox != null) await _cacheBox!.clear();
      if (_blockCollectionsBox != null) await _blockCollectionsBox!.clear();
      if (_badgesBox != null) await _badgesBox!.clear();
      if (_analyticsBox != null) await _analyticsBox!.clear();
    }

    if (_prefs != null) {
      await _prefs!.clear();
    }
  }

  // Helper methods

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Update the list of pattern IDs for a user
  Future<void> _updateUserPatternsList(String userId, String patternId, {required bool add}) async {
    final String key = _userPatternsKeyPrefix + userId;
    List<String> patternIds = [];

    // Get existing list
    if (_useHive && _patternsBox != null) {
      final String? jsonData = _patternsBox!.get(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        patternIds = List<String>.from(jsonDecode(jsonData));
      }
    } else if (_prefs != null) {
      final String? jsonData = _prefs!.getString(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        patternIds = List<String>.from(jsonDecode(jsonData));
      }
    }

    // Update list
    if (add && !patternIds.contains(patternId)) {
      patternIds.add(patternId);
    } else if (!add && patternIds.contains(patternId)) {
      patternIds.remove(patternId);
    }

    // Save updated list
    final String jsonData = jsonEncode(patternIds);
    if (_useHive && _patternsBox != null) {
      await _patternsBox!.put(key, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(key, jsonData);
    }
  }

  /// Get the list of pattern IDs for a user
  Future<List<String>> _getUserPatternIds(String userId) async {
    final String key = _userPatternsKeyPrefix + userId;
    List<String> patternIds = [];

    if (_useHive && _patternsBox != null) {
      final String? jsonData = _patternsBox!.get(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        patternIds = List<String>.from(jsonDecode(jsonData));
      }
    } else if (_prefs != null) {
      final String? jsonData = _prefs!.getString(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        patternIds = List<String>.from(jsonDecode(jsonData));
      }
    }

    return patternIds;
  }

  /// Update the list of badge IDs for a user
  Future<void> _updateUserBadgesList(String userId, String badgeId, {required bool add}) async {
    final String key = _userBadgesKeyPrefix + userId;
    List<String> badgeIds = [];

    // Get existing list
    if (_useHive && _badgesBox != null) {
      final String? jsonData = _badgesBox!.get(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        badgeIds = List<String>.from(jsonDecode(jsonData));
      }
    } else if (_prefs != null) {
      final String? jsonData = _prefs!.getString(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        badgeIds = List<String>.from(jsonDecode(jsonData));
      }
    }

    // Update list
    if (add && !badgeIds.contains(badgeId)) {
      badgeIds.add(badgeId);
    } else if (!add && badgeIds.contains(badgeId)) {
      badgeIds.remove(badgeId);
    }

    // Save updated list
    final String jsonData = jsonEncode(badgeIds);
    if (_useHive && _badgesBox != null) {
      await _badgesBox!.put(key, jsonData);
    } else if (_prefs != null) {
      await _prefs!.setString(key, jsonData);
    }
  }

  /// Get the list of badge IDs for a user
  Future<List<String>> _getUserBadgeIds(String userId) async {
    final String key = _userBadgesKeyPrefix + userId;
    List<String> badgeIds = [];

    if (_useHive && _badgesBox != null) {
      final String? jsonData = _badgesBox!.get(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        badgeIds = List<String>.from(jsonDecode(jsonData));
      }
    } else if (_prefs != null) {
      final String? jsonData = _prefs!.getString(key);
      if (jsonData != null && jsonData.isNotEmpty) {
        badgeIds = List<String>.from(jsonDecode(jsonData));
      }
    }

    return badgeIds;
  }

  /// Save blocks for a specific challenge
  Future<void> saveBlocks(String challengeId, String blocksJson) async {
    await _ensureInitialized();

    final String key = _blocksKeyPrefix + challengeId;

    if (_useHive && _blockCollectionsBox != null) {
      await _blockCollectionsBox!.put(key, blocksJson);
    } else if (_prefs != null) {
      await _prefs!.setString(key, blocksJson);
    }
  }

  /// Get blocks for a specific challenge
  Future<String?> getBlocks(String challengeId) async {
    await _ensureInitialized();

    final String key = _blocksKeyPrefix + challengeId;
    String? blocksJson;

    if (_useHive && _blockCollectionsBox != null) {
      blocksJson = _blockCollectionsBox!.get(key);
    } else if (_prefs != null) {
      blocksJson = _prefs!.getString(key);
    }

    return blocksJson;
  }

  /// Save progress data
  Future<void> saveProgress(String key, String data) async {
    await _ensureInitialized();

    final String fullKey = _progressKeyPrefix + key;

    if (_useHive && _userProgressBox != null) {
      await _userProgressBox!.put(fullKey, data);
    } else if (_prefs != null) {
      await _prefs!.setString(fullKey, data);
    }
  }

  /// Get progress data
  Future<String?> getProgress(String key) async {
    await _ensureInitialized();

    final String fullKey = _progressKeyPrefix + key;
    String? data;

    if (_useHive && _userProgressBox != null) {
      data = _userProgressBox!.get(fullKey);
    } else if (_prefs != null) {
      data = _prefs!.getString(fullKey);
    }

    return data;
  }

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    await _ensureInitialized();

    if (_useHive && _settingsBox != null) {
      await _settingsBox!.put(key, value);
    } else if (_prefs != null) {
      await _prefs!.setString(key, value);
    }
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    await _ensureInitialized();

    String? value;

    if (_useHive && _settingsBox != null) {
      value = _settingsBox!.get(key);
    } else if (_prefs != null) {
      value = _prefs!.getString(key);
    }

    return value;
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
    } else if (_prefs != null) {
      keys.addAll(_prefs!.getKeys());
    }

    return keys;
  }

  /// Remove progress data
  Future<void> removeProgress(String key) async {
    await _ensureInitialized();

    final String fullKey = _progressKeyPrefix + key;

    if (_useHive && _userProgressBox != null) {
      await _userProgressBox!.delete(fullKey);
    } else if (_prefs != null) {
      await _prefs!.remove(fullKey);
    }
  }
}
