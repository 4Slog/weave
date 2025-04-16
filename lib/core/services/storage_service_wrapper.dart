import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';
import 'storage/storage_service_refactored.dart' as refactored;

/// Wrapper for the refactored StorageService.
///
/// This class provides the same public API as the original StorageService
/// while delegating to the new refactored implementation.
class StorageServiceWrapper {
  final refactored.StorageService _storageService;

  // Singleton implementation
  static final StorageServiceWrapper _instance = StorageServiceWrapper._internal();

  factory StorageServiceWrapper() {
    return _instance;
  }

  StorageServiceWrapper._internal() : _storageService = refactored.StorageService();

  /// Initialize the storage service
  Future<void> initialize() async {
    await _storageService.initialize();
  }

  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    await _storageService.cacheData('user_progress_${progress.userId}', progress.toJson());
  }

  /// Load user progress
  Future<UserProgress?> loadUserProgress(String userId) async {
    final data = await _storageService.getCachedData('user_progress_$userId');

    if (data != null) {
      try {
        return UserProgress.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing user progress: $e');
        return null;
      }
    }

    return null;
  }

  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _storageService.cacheData('app_settings', settings);
  }

  /// Load app settings
  Future<Map<String, dynamic>> loadSettings() async {
    final data = await _storageService.getCachedData('app_settings');
    return data != null ? Map<String, dynamic>.from(data) : {};
  }

  /// Save a block collection
  Future<void> saveBlockCollection(String id, BlockCollection collection) async {
    await _storageService.cacheData('saved_blocks_$id', collection.toJson());
  }

  /// Load a block collection
  Future<BlockCollection?> loadBlockCollection(String id) async {
    final data = await _storageService.getCachedData('saved_blocks_$id');

    if (data != null) {
      try {
        return BlockCollection.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing block collection: $e');
        return null;
      }
    }

    return null;
  }

  /// Save a pattern
  Future<void> savePattern(PatternModel pattern) async {
    await _storageService.cacheData('pattern_${pattern.id}', pattern.toJson());

    // Update user patterns list
    await _updateUserPatternsList(pattern.userId, pattern.id, add: true);
  }

  /// Load a pattern
  Future<PatternModel?> loadPattern(String id) async {
    final data = await _storageService.getCachedData('pattern_$id');

    if (data != null) {
      try {
        return PatternModel.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing pattern: $e');
        return null;
      }
    }

    return null;
  }

  /// Delete a pattern
  Future<void> deletePattern(String id, String userId) async {
    await _storageService.removeCachedData('pattern_$id');
    await _updateUserPatternsList(userId, id, add: false);
  }

  /// Get all patterns for a user
  Future<List<PatternModel>> getUserPatterns(String userId) async {
    final patternIds = await _getUserPatternIds(userId);
    final patterns = <PatternModel>[];

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
    await _storageService.cacheData(badge.id, badge.toJson());
    await _updateUserBadgesList(userId, badge.id, add: true);
  }

  /// Load a badge
  Future<BadgeModel?> loadBadge(String id) async {
    final data = await _storageService.getCachedData(id);

    if (data != null) {
      try {
        return BadgeModel.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing badge: $e');
        return null;
      }
    }

    return null;
  }

  /// Get all badges for a user
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    final badgeIds = await _getUserBadgeIds(userId);
    final badges = <BadgeModel>[];

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
    await _storageService.cacheData(key, data);
  }

  /// Get cached data
  Future<dynamic> getCachedData(String key) async {
    return await _storageService.getCachedData(key);
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _storageService.clearCache();
  }

  /// Log analytics event
  Future<void> logAnalyticsEvent(String eventName, Map<String, dynamic> data) async {
    final eventData = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': eventName,
      'data': data,
    };

    await _storageService.cacheData(
      '${eventName}_${DateTime.now().millisecondsSinceEpoch}',
      eventData
    );
  }

  /// Get analytics events
  Future<List<Map<String, dynamic>>> getAnalyticsEvents() async {
    final allKeys = await _storageService.getAllKeys();
    final eventKeys = allKeys.where((key) => key.contains('_event_')).toList();

    final events = <Map<String, dynamic>>[];
    for (final key in eventKeys) {
      final data = await _storageService.getCachedData(key);
      if (data != null) {
        try {
          events.add(Map<String, dynamic>.from(data));
        } catch (e) {
          // Skip invalid data
        }
      }
    }

    return events;
  }

  /// Clear all data (for testing or user account deletion)
  Future<void> clearAllData() async {
    await _storageService.clearCache();
  }

  /// Save blocks for a specific challenge
  Future<void> saveBlocks(String challengeId, String blocksJson) async {
    await _storageService.cacheData('saved_blocks_$challengeId', blocksJson);
  }

  /// Get blocks for a specific challenge
  Future<String?> getBlocks(String challengeId) async {
    final data = await _storageService.getCachedData('saved_blocks_$challengeId');
    return data is String ? data : null;
  }

  /// Save progress data
  Future<void> saveProgress(String key, String data) async {
    await _storageService.cacheData('user_progress_$key', data);
  }

  /// Get progress data
  Future<String?> getProgress(String key) async {
    final data = await _storageService.getCachedData('user_progress_$key');
    return data is String ? data : null;
  }

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    await _storageService.cacheData(key, value);
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    final data = await _storageService.getCachedData(key);
    return data is String ? data : null;
  }

  /// Get all keys
  Future<List<String>> getAllKeys() async {
    return await _storageService.getAllKeys();
  }

  /// Remove progress data
  Future<void> removeProgress(String key) async {
    await _storageService.removeCachedData('user_progress_$key');
  }

  // Helper methods

  /// Update the list of pattern IDs for a user
  Future<void> _updateUserPatternsList(String userId, String patternId, {required bool add}) async {
    final key = 'user_patterns_$userId';
    List<String> patternIds = [];

    // Get existing list
    final data = await _storageService.getCachedData(key);
    if (data != null) {
      try {
        patternIds = List<String>.from(data);
      } catch (e) {
        debugPrint('Error parsing pattern IDs: $e');
      }
    }

    // Update list
    if (add && !patternIds.contains(patternId)) {
      patternIds.add(patternId);
    } else if (!add && patternIds.contains(patternId)) {
      patternIds.remove(patternId);
    }

    // Save updated list
    await _storageService.cacheData(key, patternIds);
  }

  /// Get the list of pattern IDs for a user
  Future<List<String>> _getUserPatternIds(String userId) async {
    final key = 'user_patterns_$userId';
    List<String> patternIds = [];

    final data = await _storageService.getCachedData(key);
    if (data != null) {
      try {
        patternIds = List<String>.from(data);
      } catch (e) {
        debugPrint('Error parsing pattern IDs: $e');
      }
    }

    return patternIds;
  }

  /// Update the list of badge IDs for a user
  Future<void> _updateUserBadgesList(String userId, String badgeId, {required bool add}) async {
    final key = 'user_badges_$userId';
    List<String> badgeIds = [];

    // Get existing list
    final data = await _storageService.getCachedData(key);
    if (data != null) {
      try {
        badgeIds = List<String>.from(data);
      } catch (e) {
        debugPrint('Error parsing badge IDs: $e');
      }
    }

    // Update list
    if (add && !badgeIds.contains(badgeId)) {
      badgeIds.add(badgeId);
    } else if (!add && badgeIds.contains(badgeId)) {
      badgeIds.remove(badgeId);
    }

    // Save updated list
    await _storageService.cacheData(key, badgeIds);
  }

  /// Get the list of badge IDs for a user
  Future<List<String>> _getUserBadgeIds(String userId) async {
    final key = 'user_badges_$userId';
    List<String> badgeIds = [];

    final data = await _storageService.getCachedData(key);
    if (data != null) {
      try {
        badgeIds = List<String>.from(data);
      } catch (e) {
        debugPrint('Error parsing badge IDs: $e');
      }
    }

    return badgeIds;
  }
}
