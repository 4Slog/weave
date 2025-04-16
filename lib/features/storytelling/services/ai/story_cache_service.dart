import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';

/// Service for caching AI-generated stories
///
/// This service provides methods to cache and retrieve AI-generated stories
/// using a FIFO (First-In-First-Out) caching strategy.
class StoryCacheService {
  /// Storage service for persistent storage
  final StorageService _storageService;

  /// In-memory cache for stories
  final Map<String, StoryModel> _storyCache = {};

  /// In-memory cache for story branches
  final Map<String, List<StoryBranchModel>> _branchCache = {};

  /// Maximum number of stories to keep in memory cache
  final int _maxStoryCacheSize;

  /// Maximum number of branch sets to keep in memory cache
  final int _maxBranchCacheSize;

  /// Order of keys in the story cache (for FIFO)
  final List<String> _storyCacheOrder = [];

  /// Order of keys in the branch cache (for FIFO)
  final List<String> _branchCacheOrder = [];

  /// Create a new StoryCacheService
  StoryCacheService({
    StorageService? storageService,
    int maxStoryCacheSize = 20,
    int maxBranchCacheSize = 10,
  }) :
    _storageService = storageService ?? StorageService(),
    _maxStoryCacheSize = maxStoryCacheSize,
    _maxBranchCacheSize = maxBranchCacheSize;

  /// Cache a story in memory and persistent storage
  ///
  /// Parameters:
  /// - `cacheKey`: Key to identify the story
  /// - `story`: Story to cache
  Future<void> cacheStory(String cacheKey, StoryModel story) async {
    // Add to memory cache
    _storyCache[cacheKey] = story;

    // Update cache order
    _storyCacheOrder.remove(cacheKey);
    _storyCacheOrder.add(cacheKey);

    // Trim cache if it exceeds maximum size (FIFO)
    _trimStoryCache();

    // Save to persistent storage
    try {
      await _storageService.saveProgress(
        'story_cache_$cacheKey',
        jsonEncode(story.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving story to cache: $e');
    }
  }

  /// Get a cached story if available
  ///
  /// Parameters:
  /// - `cacheKey`: Key to identify the story
  ///
  /// Returns the cached story or null if not found
  Future<StoryModel?> getCachedStory(String cacheKey) async {
    // Check memory cache first
    if (_storyCache.containsKey(cacheKey)) {
      // Move to end of cache order (most recently used)
      _storyCacheOrder.remove(cacheKey);
      _storyCacheOrder.add(cacheKey);

      return _storyCache[cacheKey];
    }

    // Check persistent storage
    try {
      final cachedData = await _storageService.getProgress('story_cache_$cacheKey');
      if (cachedData != null) {
        final storyData = jsonDecode(cachedData) as Map<String, dynamic>;
        final story = StoryModel.fromJson(storyData);

        // Add to memory cache
        _storyCache[cacheKey] = story;
        _storyCacheOrder.add(cacheKey);

        // Trim cache if it exceeds maximum size
        _trimStoryCache();

        return story;
      }
    } catch (e) {
      debugPrint('Error retrieving cached story: $e');
    }

    return null;
  }

  /// Cache story branches in memory and persistent storage
  ///
  /// Parameters:
  /// - `cacheKey`: Key to identify the branches
  /// - `branches`: Branches to cache
  Future<void> cacheBranches(String cacheKey, List<StoryBranchModel> branches) async {
    // Add to memory cache
    _branchCache[cacheKey] = branches;

    // Update cache order
    _branchCacheOrder.remove(cacheKey);
    _branchCacheOrder.add(cacheKey);

    // Trim cache if it exceeds maximum size (FIFO)
    _trimBranchCache();

    // Save to persistent storage
    try {
      await _storageService.saveProgress(
        'branch_cache_$cacheKey',
        jsonEncode(branches.map((b) => b.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving branches to cache: $e');
    }
  }

  /// Get cached branches if available
  ///
  /// Parameters:
  /// - `cacheKey`: Key to identify the branches
  ///
  /// Returns the cached branches or null if not found
  Future<List<StoryBranchModel>?> getCachedBranches(String cacheKey) async {
    // Check memory cache first
    if (_branchCache.containsKey(cacheKey)) {
      // Move to end of cache order (most recently used)
      _branchCacheOrder.remove(cacheKey);
      _branchCacheOrder.add(cacheKey);

      return _branchCache[cacheKey];
    }

    // Check persistent storage
    try {
      final cachedData = await _storageService.getProgress('branch_cache_$cacheKey');
      if (cachedData != null) {
        final branchesData = jsonDecode(cachedData) as List<dynamic>;
        final branches = branchesData
            .map((data) => StoryBranchModel.fromJson(data))
            .toList();

        // Add to memory cache
        _branchCache[cacheKey] = branches;
        _branchCacheOrder.add(cacheKey);

        // Trim cache if it exceeds maximum size
        _trimBranchCache();

        return branches;
      }
    } catch (e) {
      debugPrint('Error retrieving cached branches: $e');
    }

    return null;
  }

  /// Clear all cached stories and branches
  Future<void> clearCache() async {
    // Clear memory caches
    _storyCache.clear();
    _branchCache.clear();
    _storyCacheOrder.clear();
    _branchCacheOrder.clear();

    // Clear persistent storage
    // Note: This is a simplified approach; in a real app, you might want to
    // only clear specific keys related to stories and branches
    try {
      final keys = await _storageService.getAllKeys();
      for (final key in keys) {
        if (key.startsWith('story_cache_') || key.startsWith('branch_cache_')) {
          await _storageService.removeProgress(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Clear old cached stories (older than the specified age)
  ///
  /// Parameters:
  /// - `maxAgeInDays`: Maximum age of cached stories in days
  Future<void> clearOldCachedStories(int maxAgeInDays) async {
    try {
      final keys = await _storageService.getAllKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.startsWith('story_cache_') || key.startsWith('branch_cache_')) {
          // Get the timestamp from the metadata
          final metadata = await _storageService.getProgress('${key}_metadata');
          if (metadata != null) {
            final metadataMap = jsonDecode(metadata) as Map<String, dynamic>;
            final timestamp = DateTime.parse(metadataMap['timestamp'] as String);

            // Calculate age in days
            final age = now.difference(timestamp).inDays;

            // Remove if older than maxAgeInDays
            if (age > maxAgeInDays) {
              await _storageService.removeProgress(key);
              await _storageService.removeProgress('${key}_metadata');

              // Remove from memory cache if present
              final cacheKey = key.replaceFirst('story_cache_', '').replaceFirst('branch_cache_', '');
              _storyCache.remove(cacheKey);
              _branchCache.remove(cacheKey);
              _storyCacheOrder.remove(cacheKey);
              _branchCacheOrder.remove(cacheKey);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing old cached stories: $e');
    }
  }



  /// Trim the story cache if it exceeds the maximum size
  void _trimStoryCache() {
    while (_storyCacheOrder.length > _maxStoryCacheSize) {
      final oldestKey = _storyCacheOrder.removeAt(0);
      _storyCache.remove(oldestKey);
    }
  }

  /// Trim the branch cache if it exceeds the maximum size
  void _trimBranchCache() {
    while (_branchCacheOrder.length > _maxBranchCacheSize) {
      final oldestKey = _branchCacheOrder.removeAt(0);
      _branchCache.remove(oldestKey);
    }
  }
}
