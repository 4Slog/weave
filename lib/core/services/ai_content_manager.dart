import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/enhanced_storage_service.dart';
import 'package:kente_codeweaver/core/utils/connectivity_utils.dart';
import 'package:kente_codeweaver/core/utils/memory_utils.dart';

/// Service for managing AI-generated content with memory optimization
class AIContentManager {
  // Singleton implementation
  static final AIContentManager _instance = AIContentManager._internal();

  factory AIContentManager() {
    return _instance;
  }

  AIContentManager._internal();

  // Dependencies
  final EnhancedStorageService _storageService = EnhancedStorageService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();

  // Content caches
  final LRUCache<String, dynamic> _storyCache = LRUCache<String, dynamic>(maxSize: 20);
  final LRUCache<String, dynamic> _hintCache = LRUCache<String, dynamic>(maxSize: 50);
  final LRUCache<String, dynamic> _feedbackCache = LRUCache<String, dynamic>(maxSize: 30);

  // Content expiration
  final ExpiringCache<String, dynamic> _expiringContentCache = ExpiringCache<String, dynamic>(
    maxAge: Duration(days: 7),
    cleanupInterval: Duration(hours: 12),
  );

  // Content usage tracking
  final Map<String, int> _contentUsageCount = {};
  final Map<String, DateTime> _contentLastAccessed = {};

  // Initialization state
  bool _isInitialized = false;

  // Memory monitoring
  Timer? _memoryMonitorTimer;
  bool _isUnderMemoryPressure = false;

  /// Initialize the AI content manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Ensure storage service is initialized
      await _storageService.initialize();

      // Start memory monitoring
      _startMemoryMonitoring();

      // Load content usage statistics
      await _loadContentUsageStats();

      _isInitialized = true;
      debugPrint('AIContentManager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AIContentManager: $e');
    }
  }

  /// Save AI-generated story content
  Future<void> saveStory(String storyId, Map<String, dynamic> storyData) async {
    await _ensureInitialized();

    // Add metadata
    final contentWithMetadata = {
      'content': storyData,
      'timestamp': DateTime.now().toIso8601String(),
      'content_type': 'story',
    };

    // Save to storage
    await _storageService.cachePriorityData('ai_story_$storyId', contentWithMetadata, priority: 2);

    // Add to memory cache
    _storyCache.put(storyId, storyData);

    // Update usage statistics
    _updateContentUsage(storyId, 'story');
  }

  /// Get AI-generated story content
  Future<Map<String, dynamic>?> getStory(String storyId) async {
    await _ensureInitialized();

    // Check memory cache first
    final cachedStory = _storyCache.get(storyId);
    if (cachedStory != null) {
      // Update usage statistics
      _updateContentUsage(storyId, 'story');
      return cachedStory as Map<String, dynamic>;
    }

    // Try to get from storage
    final data = await _storageService.getPriorityCachedData('ai_story_$storyId');

    if (data != null && data is Map<String, dynamic> && data['content'] != null) {
      final storyData = data['content'] as Map<String, dynamic>;

      // Add to memory cache
      _storyCache.put(storyId, storyData);

      // Update usage statistics
      _updateContentUsage(storyId, 'story');

      return storyData;
    }

    return null;
  }

  /// Save AI-generated hint content
  Future<void> saveHint(String hintId, String hintText) async {
    await _ensureInitialized();

    // Add metadata
    final contentWithMetadata = {
      'content': hintText,
      'timestamp': DateTime.now().toIso8601String(),
      'content_type': 'hint',
    };

    // Save to storage
    await _storageService.cacheData('ai_hint_$hintId', contentWithMetadata);

    // Add to memory cache
    _hintCache.put(hintId, hintText);

    // Update usage statistics
    _updateContentUsage(hintId, 'hint');
  }

  /// Get AI-generated hint content
  Future<String?> getHint(String hintId) async {
    await _ensureInitialized();

    // Check memory cache first
    final cachedHint = _hintCache.get(hintId);
    if (cachedHint != null) {
      // Update usage statistics
      _updateContentUsage(hintId, 'hint');
      return cachedHint as String;
    }

    // Try to get from storage
    final data = await _storageService.getCachedData('ai_hint_$hintId');

    if (data != null && data is Map<String, dynamic> && data['content'] != null) {
      final hintText = data['content'] as String;

      // Add to memory cache
      _hintCache.put(hintId, hintText);

      // Update usage statistics
      _updateContentUsage(hintId, 'hint');

      return hintText;
    }

    return null;
  }

  /// Save AI-generated feedback content
  Future<void> saveFeedback(String feedbackId, Map<String, dynamic> feedbackData) async {
    await _ensureInitialized();

    // Add metadata
    final contentWithMetadata = {
      'content': feedbackData,
      'timestamp': DateTime.now().toIso8601String(),
      'content_type': 'feedback',
    };

    // Save to storage
    await _storageService.cacheData('ai_feedback_$feedbackId', contentWithMetadata);

    // Add to memory cache
    _feedbackCache.put(feedbackId, feedbackData);

    // Update usage statistics
    _updateContentUsage(feedbackId, 'feedback');
  }

  /// Get AI-generated feedback content
  Future<Map<String, dynamic>?> getFeedback(String feedbackId) async {
    await _ensureInitialized();

    // Check memory cache first
    final cachedFeedback = _feedbackCache.get(feedbackId);
    if (cachedFeedback != null) {
      // Update usage statistics
      _updateContentUsage(feedbackId, 'feedback');
      return cachedFeedback as Map<String, dynamic>;
    }

    // Try to get from storage
    final data = await _storageService.getCachedData('ai_feedback_$feedbackId');

    if (data != null && data is Map<String, dynamic> && data['content'] != null) {
      final feedbackData = data['content'] as Map<String, dynamic>;

      // Add to memory cache
      _feedbackCache.put(feedbackId, feedbackData);

      // Update usage statistics
      _updateContentUsage(feedbackId, 'feedback');

      return feedbackData;
    }

    return null;
  }

  /// Save content with expiration
  Future<void> saveExpiringContent(String key, dynamic content, {Duration? expiration}) async {
    await _ensureInitialized();

    // Add to expiring cache
    _expiringContentCache.put(key, content);

    // Add metadata
    final contentWithMetadata = {
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'expiration': expiration != null
          ? DateTime.now().add(expiration).toIso8601String()
          : null,
      'content_type': 'expiring',
    };

    // Save to storage
    await _storageService.cacheData('ai_expiring_$key', contentWithMetadata);
  }

  /// Get content with expiration check
  Future<dynamic> getExpiringContent(String key) async {
    await _ensureInitialized();

    // Check expiring cache first
    final cachedContent = _expiringContentCache.get(key);
    if (cachedContent != null) {
      return cachedContent;
    }

    // Try to get from storage
    final data = await _storageService.getCachedData('ai_expiring_$key');

    if (data != null && data is Map<String, dynamic> && data['content'] != null) {
      // Check expiration
      if (data['expiration'] != null) {
        final expiration = DateTime.parse(data['expiration'] as String);
        if (DateTime.now().isAfter(expiration)) {
          // Content has expired
          await _storageService.clearCacheEntries(['ai_expiring_$key']);
          return null;
        }
      }

      final content = data['content'];

      // Add to expiring cache
      _expiringContentCache.put(key, content);

      return content;
    }

    return null;
  }

  /// Clear all AI content caches
  Future<void> clearAllContent() async {
    await _ensureInitialized();

    // Clear memory caches
    _storyCache.clear();
    _hintCache.clear();
    _feedbackCache.clear();
    _expiringContentCache.clear();

    // Clear storage
    final keys = await _storageService.getAllKeys();
    final aiContentKeys = keys.where((key) =>
      key.startsWith('cache_ai_story_') ||
      key.startsWith('cache_ai_hint_') ||
      key.startsWith('cache_ai_feedback_') ||
      key.startsWith('cache_ai_expiring_')
    ).map((key) => key.replaceFirst('cache_', '')).toList();

    await _storageService.clearCacheEntries(aiContentKeys);

    // Clear usage statistics
    _contentUsageCount.clear();
    _contentLastAccessed.clear();

    // Save empty usage statistics
    await _saveContentUsageStats();

    debugPrint('All AI content cleared');
  }

  /// Clear old or unused content
  Future<void> clearOldContent({Duration? olderThan}) async {
    await _ensureInitialized();

    final cutoffDate = DateTime.now().subtract(olderThan ?? Duration(days: 30));
    final keysToRemove = <String>[];

    // Find old content
    for (final entry in _contentLastAccessed.entries) {
      if (entry.value.isBefore(cutoffDate)) {
        keysToRemove.add(entry.key);
      }
    }

    // Remove from memory caches
    for (final key in keysToRemove) {
      if (key.startsWith('story_')) {
        _storyCache.remove(key.replaceFirst('story_', ''));
      } else if (key.startsWith('hint_')) {
        _hintCache.remove(key.replaceFirst('hint_', ''));
      } else if (key.startsWith('feedback_')) {
        _feedbackCache.remove(key.replaceFirst('feedback_', ''));
      }

      // Remove from usage statistics
      _contentUsageCount.remove(key);
      _contentLastAccessed.remove(key);
    }

    // Remove from storage
    final storageKeysToRemove = keysToRemove.map((key) {
      if (key.startsWith('story_')) {
        return 'ai_story_${key.replaceFirst('story_', '')}';
      } else if (key.startsWith('hint_')) {
        return 'ai_hint_${key.replaceFirst('hint_', '')}';
      } else if (key.startsWith('feedback_')) {
        return 'ai_feedback_${key.replaceFirst('feedback_', '')}';
      }
      return '';
    }).where((key) => key.isNotEmpty).toList();

    await _storageService.clearCacheEntries(storageKeysToRemove);

    // Save updated usage statistics
    await _saveContentUsageStats();

    debugPrint('Cleared ${keysToRemove.length} old AI content items');
  }

  /// Get content usage statistics
  Map<String, dynamic> getContentStats() {
    final contentTypeCount = <String, int>{
      'story': 0,
      'hint': 0,
      'feedback': 0,
      'expiring': 0,
    };

    // Count by content type
    for (final key in _contentUsageCount.keys) {
      if (key.startsWith('story_')) {
        contentTypeCount['story'] = (contentTypeCount['story'] ?? 0) + 1;
      } else if (key.startsWith('hint_')) {
        contentTypeCount['hint'] = (contentTypeCount['hint'] ?? 0) + 1;
      } else if (key.startsWith('feedback_')) {
        contentTypeCount['feedback'] = (contentTypeCount['feedback'] ?? 0) + 1;
      } else if (key.startsWith('expiring_')) {
        contentTypeCount['expiring'] = (contentTypeCount['expiring'] ?? 0) + 1;
      }
    }

    return {
      'total_items': _contentUsageCount.length,
      'by_type': contentTypeCount,
      'memory_cache_items': _storyCache.size + _hintCache.size + _feedbackCache.size,
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
      const Duration(minutes: 5),
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
    // Clear least used content from memory caches
    _clearLeastUsedContent();

    debugPrint('Reduced AI content memory cache size due to memory pressure');
  }

  /// Clear least used content from memory caches
  void _clearLeastUsedContent() {
    // Sort content by usage count (ascending)
    final sortedContent = _contentUsageCount.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Clear bottom 30% of content
    final clearCount = (sortedContent.length * 0.3).round();

    for (int i = 0; i < clearCount && i < sortedContent.length; i++) {
      final key = sortedContent[i].key;

      if (key.startsWith('story_')) {
        _storyCache.remove(key.replaceFirst('story_', ''));
      } else if (key.startsWith('hint_')) {
        _hintCache.remove(key.replaceFirst('hint_', ''));
      } else if (key.startsWith('feedback_')) {
        _feedbackCache.remove(key.replaceFirst('feedback_', ''));
      }
    }

    debugPrint('Cleared $clearCount least used content items from memory cache');
  }

  /// Update content usage statistics
  void _updateContentUsage(String id, String contentType) {
    final key = '${contentType}_$id';

    // Update usage count
    _contentUsageCount[key] = (_contentUsageCount[key] ?? 0) + 1;

    // Update last accessed time
    _contentLastAccessed[key] = DateTime.now();

    // Periodically save usage statistics
    if (_contentUsageCount.length % 10 == 0) {
      _saveContentUsageStats();
    }
  }

  /// Save content usage statistics
  Future<void> _saveContentUsageStats() async {
    try {
      final usageStats = {
        'usage_count': _contentUsageCount,
        'last_accessed': _contentLastAccessed.map(
          (key, value) => MapEntry(key, value.toIso8601String())
        ),
      };

      await _storageService.cacheData('ai_content_usage_stats', usageStats);
    } catch (e) {
      debugPrint('Error saving content usage stats: $e');
    }
  }

  /// Load content usage statistics
  Future<void> _loadContentUsageStats() async {
    try {
      final data = await _storageService.getCachedData('ai_content_usage_stats');

      if (data != null && data is Map<String, dynamic>) {
        // Load usage count
        if (data['usage_count'] != null) {
          final usageCount = data['usage_count'] as Map<String, dynamic>;
          _contentUsageCount.clear();

          for (final entry in usageCount.entries) {
            _contentUsageCount[entry.key] = entry.value as int;
          }
        }

        // Load last accessed times
        if (data['last_accessed'] != null) {
          final lastAccessed = data['last_accessed'] as Map<String, dynamic>;
          _contentLastAccessed.clear();

          for (final entry in lastAccessed.entries) {
            _contentLastAccessed[entry.key] = DateTime.parse(entry.value as String);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading content usage stats: $e');
    }
  }
}
