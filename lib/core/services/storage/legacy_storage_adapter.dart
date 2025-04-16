import 'storage_service_refactored.dart';

/// Adapter class that provides backward compatibility with the original StorageService.
///
/// This class implements the same public API as the original StorageService
/// while delegating to the new refactored implementation.
@Deprecated('Use StorageService directly instead')
class LegacyStorageAdapter {
  final StorageService _storageService;

  // Singleton implementation
  static final LegacyStorageAdapter _instance = LegacyStorageAdapter._internal();

  factory LegacyStorageAdapter() {
    return _instance;
  }

  LegacyStorageAdapter._internal() : _storageService = StorageService();

  /// Initialize the storage service
  Future<void> initialize() async {
    await _storageService.initialize();
  }

  /// Save user progress
  Future<void> saveUserProgress(dynamic progress) async {
    await _storageService.cacheData('user_progress_${progress.userId}', progress.toJson());
  }

  /// Load user progress
  Future<dynamic> loadUserProgress(String userId) async {
    return await _storageService.getCachedData('user_progress_$userId');
  }

  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _storageService.saveSettings(settings);
  }

  /// Load app settings
  Future<Map<String, dynamic>> loadSettings() async {
    return await _storageService.loadSettings();
  }

  /// Save a block collection
  Future<void> saveBlockCollection(String id, dynamic collection) async {
    await _storageService.saveBlockCollection(id, collection);
  }

  /// Load a block collection
  Future<dynamic> loadBlockCollection(String id) async {
    return await _storageService.loadBlockCollection(id);
  }

  /// Save a pattern
  Future<void> savePattern(dynamic pattern) async {
    await _storageService.savePattern(pattern);
  }

  /// Load a pattern
  Future<dynamic> loadPattern(String id) async {
    return await _storageService.loadPattern(id);
  }

  /// Delete a pattern
  Future<void> deletePattern(String id, String userId) async {
    await _storageService.deletePattern(id, userId);
  }

  /// Get all patterns for a user
  Future<List<dynamic>> getUserPatterns(String userId) async {
    // This is a simplified implementation
    final allKeys = await _storageService.getAllKeys();
    final patternKeys = allKeys.where((key) =>
        key.startsWith('pattern_') &&
        key.contains(userId)
    ).toList();

    final patterns = <dynamic>[];
    for (final key in patternKeys) {
      final pattern = await _storageService.getCachedData(key);
      if (pattern != null) {
        patterns.add(pattern);
      }
    }

    return patterns;
  }

  /// Save a badge
  Future<void> saveBadge(dynamic badge, String userId) async {
    await _storageService.saveBadge(badge, userId);
  }

  /// Load a badge
  Future<dynamic> loadBadge(String id) async {
    return await _storageService.loadBadge(id);
  }

  /// Get all badges for a user
  Future<List<dynamic>> getUserBadges(String userId) async {
    // This is a simplified implementation
    final allKeys = await _storageService.getAllKeys();
    final badgeKeys = allKeys.where((key) =>
        key.startsWith('user_badges_$userId')
    ).toList();

    final badges = <dynamic>[];
    for (final key in badgeKeys) {
      final badge = await _storageService.getCachedData(key);
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
    await _storageService.cacheData(
      '${eventName}_${DateTime.now().millisecondsSinceEpoch}',
      {
        'timestamp': DateTime.now().toIso8601String(),
        'event': eventName,
        'data': data,
      }
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
    await _storageService.clearAllData();
  }

  /// Save blocks for a specific challenge
  Future<void> saveBlocks(String challengeId, String blocksJson) async {
    await _storageService.saveBlocks(challengeId, blocksJson);
  }

  /// Get blocks for a specific challenge
  Future<String?> getBlocks(String challengeId) async {
    return await _storageService.getBlocks(challengeId);
  }

  /// Save progress data
  Future<void> saveProgress(String key, String data) async {
    await _storageService.saveProgress(key, data);
  }

  /// Get progress data
  Future<String?> getProgress(String key) async {
    return await _storageService.getProgress(key);
  }

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    await _storageService.saveSetting(key, value);
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    return await _storageService.getSetting(key);
  }

  /// Get all keys
  Future<List<String>> getAllKeys() async {
    return await _storageService.getAllKeys();
  }

  /// Remove progress data
  Future<void> removeProgress(String key) async {
    await _storageService.removeProgress(key);
  }
}
