import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/pattern_model.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/models/badge_model.dart';

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
  static const String _patternKeyPrefix = 'pattern_';
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
  
  // SharedPreferences fallback
  SharedPreferences? _preferences;
  
  // Memory cache for frequent operations
  final Map<String, dynamic> _memoryCache = {};
  
  // Set of keys modified since last sync
  final Set<String> _dirtyKeys = {};
  
  // Timer for periodic sync
  Timer? _syncTimer;
  
  /// Initialize storage system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Hive
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);
      
      // Open boxes
      _patternsBox = await Hive.openBox(_patternsBoxName);
      _userProgressBox = await Hive.openBox(_userProgressBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      _cacheBox = await Hive.openBox(_cacheBoxName);
      _blockCollectionsBox = await Hive.openBox(_blockCollectionsBoxName);
      _badgesBox = await Hive.openBox(_badgesBoxName);
      _analyticsBox = await Hive.openBox(_analyticsBoxName);
      
      _useHive = true;
    } catch (e) {
      // Fallback to SharedPreferences if Hive fails
      debugPrint('Failed to initialize Hive, falling back to SharedPreferences: $e');
      _useHive = false;
      _preferences = await SharedPreferences.getInstance();
    }
    
    // Setup periodic background sync
    _setupSyncTimer();
    
    _isInitialized = true;
    debugPrint('Storage service initialized successfully. Using Hive: $_useHive');
  }
  
  /// Set up a periodic sync timer to ensure data is persisted
  void _setupSyncTimer() {
    // Cancel existing timer if any
    _syncTimer?.cancel();
    
    // Create a new timer to sync dirty keys every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncDirtyKeys();
    });
  }
  
  /// Sync all dirty keys to persistent storage
  Future<void> _syncDirtyKeys() async {
    if (_dirtyKeys.isEmpty) return;
    
    final keysToSync = Set<String>.from(_dirtyKeys);
    
    for (final key in keysToSync) {
      if (_memoryCache.containsKey(key)) {
        final value = _memoryCache[key];
        
        // Determine key type from prefix
        if (key.startsWith(_progressKeyPrefix)) {
          await _saveToStorage(key, value, box: _userProgressBox);
        } else if (key.startsWith(_patternKeyPrefix)) {
          await _saveToStorage(key, value, box: _patternsBox);
        } else if (key.startsWith(_blocksKeyPrefix)) {
          await _saveToStorage(key, value, box: _blockCollectionsBox);
        } else if (key.startsWith(_userBadgesKeyPrefix)) {
          await _saveToStorage(key, value, box: _badgesBox);
        } else if (key.startsWith(_cacheKeyPrefix)) {
          await _saveToStorage(key, value, box: _cacheBox);
        } else {
          await _saveToStorage(key, value, box: _settingsBox);
        }
        
        _dirtyKeys.remove(key);
      }
    }
  }
  
  /// Ensure the service is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Save a value to the appropriate storage
  Future<void> _saveToStorage(String key, dynamic value, {Box? box}) async {
    // Determine appropriate serialization based on value type
    String? serializedValue;
    
    if (value is String) {
      serializedValue = value;
    } else if (value is num || value is bool) {
      serializedValue = value.toString();
    } else {
      try {
        serializedValue = jsonEncode(value);
      } catch (e) {
        debugPrint('Error encoding value for key $key: $e');
        return;
      }
    }
    
    try {
      if (_useHive && box != null) {
        await box.put(key, serializedValue);
      } else if (_preferences != null) {
        await _preferences!.setString(key, serializedValue);
      }
    } catch (e) {
      debugPrint('Error saving data for key $key: $e');
    }
  }
  
  /// Load a value from the appropriate storage
  Future<dynamic> _loadFromStorage(String key, {Box? box}) async {
    try {
      if (_useHive && box != null) {
        return box.get(key);
      } else if (_preferences != null) {
        return _preferences!.getString(key);
      }
    } catch (e) {
      debugPrint('Error loading data for key $key: $e');
    }
    return null;
  }
  
  /// Parse a value from JSON if needed
  dynamic _parseValue(dynamic value) {
    if (value == null) return null;
    
    if (value is String && (value.startsWith('{') || value.startsWith('['))) {
      try {
        return jsonDecode(value);
      } catch (e) {
        return value;
      }
    }
    
    return value;
  }
  
  /// Save user progress
  Future<void> saveUserProgress(UserProgress userProgress) async {
    await _ensureInitialized();
    
    final key = '$_progressKeyPrefix${userProgress.userId}';
    final jsonData = userProgress.toJson();
    
    // Update memory cache
    _memoryCache[key] = jsonData;
    _dirtyKeys.add(key);
    
    // Save immediately for critical data
    await _saveToStorage(key, jsonData, box: _userProgressBox);
  }
  
  /// Get user progress
  Future<UserProgress?> getUserProgress(String userId) async {
    await _ensureInitialized();
    
    final key = '$_progressKeyPrefix$userId';
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final cachedData = _memoryCache[key];
      return UserProgress.fromJson(cachedData);
    }
    
    // Try to load from storage
    final savedData = await _loadFromStorage(key, box: _userProgressBox);
    if (savedData == null) return null;
    
    // Parse and cache the data
    final jsonData = _parseValue(savedData);
    _memoryCache[key] = jsonData;
    
    try {
      return UserProgress.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing user progress for user $userId: $e');
      return null;
    }
  }
  
  /// Get all user progress entries
  Future<List<UserProgress>> getAllUserProgress() async {
    await _ensureInitialized();
    
    final List<UserProgress> result = [];
    
    try {
      if (_useHive && _userProgressBox != null) {
        for (var key in _userProgressBox!.keys) {
          if (key.toString().startsWith(_progressKeyPrefix)) {
            final jsonString = _userProgressBox!.get(key);
            if (jsonString != null) {
              final jsonData = _parseValue(jsonString);
              try {
                result.add(UserProgress.fromJson(jsonData));
              } catch (e) {
                debugPrint('Error parsing user progress for key $key: $e');
              }
            }
          }
        }
      } else if (_preferences != null) {
        final allKeys = _preferences!.getKeys();
        for (var key in allKeys) {
          if (key.startsWith(_progressKeyPrefix)) {
            final jsonString = _preferences!.getString(key);
            if (jsonString != null) {
              final jsonData = _parseValue(jsonString);
              try {
                result.add(UserProgress.fromJson(jsonData));
              } catch (e) {
                debugPrint('Error parsing user progress for key $key: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting all user progress: $e');
    }
    
    return result;
  }
  
  /// Save a pattern
  Future<void> savePattern(PatternModel pattern) async {
    await _ensureInitialized();
    
    // Key for specific pattern
    final patternKey = '$_patternKeyPrefix${pattern.id}';
    
    // Key for user's patterns list
    final userPatternsKey = '$_userPatternsKeyPrefix${pattern.userId}';
    
    // Convert pattern to JSON
    final patternJson = pattern.toJson();
    
    // Update memory cache for the pattern
    _memoryCache[patternKey] = patternJson;
    _dirtyKeys.add(patternKey);
    
    // Save immediately for critical data
    await _saveToStorage(patternKey, patternJson, box: _patternsBox);
    
    // Update the user's pattern list
    List<String> userPatterns = [];
    
    // Try memory cache first
    if (_memoryCache.containsKey(userPatternsKey)) {
      userPatterns = List<String>.from(_memoryCache[userPatternsKey]);
    } else {
      // Load from storage
      final savedList = await _loadFromStorage(userPatternsKey, box: _patternsBox);
      if (savedList != null) {
        final parsedList = _parseValue(savedList);
        if (parsedList is List) {
          userPatterns = List<String>.from(parsedList);
        }
      }
    }
    
    // Add this pattern to the list if not already present
    if (!userPatterns.contains(pattern.id)) {
      userPatterns.add(pattern.id);
      
      // Update memory cache
      _memoryCache[userPatternsKey] = userPatterns;
      _dirtyKeys.add(userPatternsKey);
      
      // Save immediately
      await _saveToStorage(userPatternsKey, userPatterns, box: _patternsBox);
    }
  }
  
  /// Get a pattern by ID
  Future<PatternModel?> getPattern(String userId, String patternId) async {
    await _ensureInitialized();
    
    final key = '$_patternKeyPrefix$patternId';
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final cachedData = _memoryCache[key];
      return PatternModel.fromJson(cachedData);
    }
    
    // Try to load from storage
    final savedData = await _loadFromStorage(key, box: _patternsBox);
    if (savedData == null) return null;
    
    // Parse and cache the data
    final jsonData = _parseValue(savedData);
    _memoryCache[key] = jsonData;
    
    try {
      return PatternModel.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing pattern $patternId: $e');
      return null;
    }
  }
  
  /// Delete a pattern
  Future<void> deletePattern(String userId, String patternId) async {
    await _ensureInitialized();
    
    final patternKey = '$_patternKeyPrefix$patternId';
    final userPatternsKey = '$_userPatternsKeyPrefix$userId';
    
    // Remove from storage
    try {
      if (_useHive && _patternsBox != null) {
        await _patternsBox!.delete(patternKey);
      } else if (_preferences != null) {
        await _preferences!.remove(patternKey);
      }
    } catch (e) {
      debugPrint('Error deleting pattern $patternId: $e');
    }
    
    // Remove from memory cache
    _memoryCache.remove(patternKey);
    _dirtyKeys.remove(patternKey);
    
    // Update the user's pattern list
    List<String> userPatterns = [];
    
    // Try memory cache first
    if (_memoryCache.containsKey(userPatternsKey)) {
      userPatterns = List<String>.from(_memoryCache[userPatternsKey]);
    } else {
      // Load from storage
      final savedList = await _loadFromStorage(userPatternsKey, box: _patternsBox);
      if (savedList != null) {
        final parsedList = _parseValue(savedList);
        if (parsedList is List) {
          userPatterns = List<String>.from(parsedList);
        }
      }
    }
    
    // Remove this pattern from the list
    userPatterns.remove(patternId);
    
    // Update memory cache
    _memoryCache[userPatternsKey] = userPatterns;
    _dirtyKeys.add(userPatternsKey);
    
    // Save immediately
    await _saveToStorage(userPatternsKey, userPatterns, box: _patternsBox);
  }
  
  /// Get all patterns for a user
  Future<List<PatternModel>> getUserPatterns(String userId) async {
    await _ensureInitialized();
    
    final userPatternsKey = '$_userPatternsKeyPrefix$userId';
    List<String> patternIds = [];
    
    // Try memory cache first
    if (_memoryCache.containsKey(userPatternsKey)) {
      patternIds = List<String>.from(_memoryCache[userPatternsKey]);
    } else {
      // Load from storage
      final savedList = await _loadFromStorage(userPatternsKey, box: _patternsBox);
      if (savedList != null) {
        final parsedList = _parseValue(savedList);
        if (parsedList is List) {
          patternIds = List<String>.from(parsedList);
        }
      }
      
      // Cache the list
      _memoryCache[userPatternsKey] = patternIds;
    }
    
    // Load each pattern
    final patterns = <PatternModel>[];
    for (final patternId in patternIds) {
      final pattern = await getPattern(userId, patternId);
      if (pattern != null) {
        patterns.add(pattern);
      }
    }
    
    return patterns;
  }
  
  /// Get patterns by category or tag
  Future<List<PatternModel>> getPatternsByTags(String userId, List<String> tags) async {
    final allPatterns = await getUserPatterns(userId);
    
    // Filter patterns that have any of the specified tags
    return allPatterns.where((pattern) {
      return pattern.tags.any((tag) => tags.contains(tag));
    }).toList();
  }
  
  /// Get patterns by difficulty level
  Future<List<PatternModel>> getPatternsByDifficulty(String userId, int difficulty) async {
    final allPatterns = await getUserPatterns(userId);
    
    // Filter patterns by difficulty level
    return allPatterns.where((pattern) => 
      pattern.difficultyLevel == difficulty
    ).toList();
  }
  
  /// Get recently modified patterns
  Future<List<PatternModel>> getRecentPatterns(String userId, {int limit = 5}) async {
    final allPatterns = await getUserPatterns(userId);
    
    // Sort by modification date descending
    allPatterns.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    
    // Return the most recent patterns up to the limit
    return allPatterns.take(limit).toList();
  }
  
  /// Save app settings
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();
    
    // Update memory cache
    _memoryCache[_settingsKey] = settings;
    _dirtyKeys.add(_settingsKey);
    
    // Save immediately for critical data
    await _saveToStorage(_settingsKey, settings, box: _settingsBox);
  }
  
  /// Get app settings
  Future<Map<String, dynamic>> getAppSettings() async {
    await _ensureInitialized();
    
    // Check memory cache first
    if (_memoryCache.containsKey(_settingsKey)) {
      return Map<String, dynamic>.from(_memoryCache[_settingsKey]);
    }
    
    // Try to load from storage
    final savedData = await _loadFromStorage(_settingsKey, box: _settingsBox);
    if (savedData == null) return {};
    
    // Parse and cache the data
    final jsonData = _parseValue(savedData);
    if (jsonData is Map) {
      // Cache the settings
      _memoryCache[_settingsKey] = jsonData;
      return Map<String, dynamic>.from(jsonData);
    }
    
    return {};
  }
  
  /// Save a single setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureInitialized();
    
    // Get current settings
    final settings = await getAppSettings();
    
    // Update setting
    settings[key] = value;
    
    // Save all settings
    await saveAppSettings(settings);
  }
  
  /// Get a single setting
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    final settings = await getAppSettings();
    return settings[key] ?? defaultValue;
  }
  
  /// Save blocks for a user
  Future<void> saveBlocks(String userId, String workspaceId, BlockCollection blocks) async {
    await _ensureInitialized();
    
    final key = '$_blocksKeyPrefix${userId}_$workspaceId';
    final blocksJson = blocks.toJson();
    
    // Update memory cache
    _memoryCache[key] = blocksJson;
    _dirtyKeys.add(key);
    
    // Save to storage
    await _saveToStorage(key, blocksJson, box: _blockCollectionsBox);
  }
  
  /// Get saved blocks for a user
  Future<BlockCollection?> getBlocks(String userId, String workspaceId) async {
    await _ensureInitialized();
    
    final key = '$_blocksKeyPrefix${userId}_$workspaceId';
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final cachedData = _memoryCache[key];
      return BlockCollection.fromJson(cachedData);
    }
    
    // Try to load from storage
    final savedData = await _loadFromStorage(key, box: _blockCollectionsBox);
    if (savedData == null) return null;
    
    // Parse and cache the data
    final jsonData = _parseValue(savedData);
    _memoryCache[key] = jsonData;
    
    try {
      return BlockCollection.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing blocks for workspace $workspaceId: $e');
      return null;
    }
  }
  
  /// Save user badges
  Future<void> saveUserBadges(String userId, List<BadgeModel> badges) async {
    await _ensureInitialized();
    
    final key = '$_userBadgesKeyPrefix$userId';
    final badgesJson = badges.map((badge) => badge.toJson()).toList();
    
    // Update memory cache
    _memoryCache[key] = badgesJson;
    _dirtyKeys.add(key);
    
    // Save to storage
    await _saveToStorage(key, badgesJson, box: _badgesBox);
  }
  
  /// Get user badges
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    await _ensureInitialized();
    
    final key = '$_userBadgesKeyPrefix$userId';
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final cachedData = _memoryCache[key];
      if (cachedData is List) {
        return cachedData.map((json) => BadgeModel.fromJson(json)).toList();
      }
    }
    
    // Try to load from storage
    final savedData = await _loadFromStorage(key, box: _badgesBox);
    if (savedData == null) return [];
    
    // Parse and cache the data
    final jsonData = _parseValue(savedData);
    _memoryCache[key] = jsonData;
    
    if (jsonData is List) {
      try {
        return jsonData.map((json) => BadgeModel.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error parsing badges for user $userId: $e');
      }
    }
    
    return [];
  }
  
  /// Save to cache with expiry
  Future<void> saveToCache(String key, dynamic value, {Duration? expiry}) async {
    await _ensureInitialized();
    
    final cacheKey = '$_cacheKeyPrefix$key';
    
    // Create cache entry with expiry
    final cacheEntry = {
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    
    // Update memory cache
    _memoryCache[cacheKey] = cacheEntry;
    _dirtyKeys.add(cacheKey);
    
    // Save to storage if expiry is long enough (> 1 minute)
    if (expiry == null || expiry.inMinutes > 1) {
      await _saveToStorage(cacheKey, cacheEntry, box: _cacheBox);
    }
  }
  
  /// Get from cache
  Future<dynamic> getFromCache(String key) async {
    await _ensureInitialized();
    
    final cacheKey = '$_cacheKeyPrefix$key';
    
    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      final cachedData = _memoryCache[cacheKey];
      
      // Check expiry
      if (cachedData is Map && cachedData.containsKey('expiry') && cachedData['expiry'] != null) {
        final timestamp = cachedData['timestamp'] as int;
        final expiryMs = cachedData['expiry'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        if (now - timestamp > expiryMs) {
          // Cache expired
          _memoryCache.remove(cacheKey);
          _dirtyKeys.remove(cacheKey);
          
          // Remove from storage
          if (_useHive && _cacheBox != null) {
            await _cacheBox!.delete(cacheKey);
          } else if (_preferences != null) {
            await _preferences!.remove(cacheKey);
          }
          
          return null;
        }
      }
      
      // Return the cached value
      return cachedData['value'];
    }
    
    // Try to load from storage
    final savedData = await _loadFromStorage(cacheKey, box: _cacheBox);
    if (savedData == null) return null;
    
    // Parse the data
    final jsonData = _parseValue(savedData);
    
    // Check expiry
    if (jsonData is Map && jsonData.containsKey('expiry') && jsonData['expiry'] != null) {
      final timestamp = jsonData['timestamp'] as int;
      final expiryMs = jsonData['expiry'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - timestamp > expiryMs) {
        // Cache expired
        if (_useHive && _cacheBox != null) {
          await _cacheBox!.delete(cacheKey);
        } else if (_preferences != null) {
          await _preferences!.remove(cacheKey);
        }
        
        return null;
      }
    }
    
    // Cache in memory
    _memoryCache[cacheKey] = jsonData;
    
    // Return the value
    return jsonData['value'];
  }
  
  /// Clear cache item
  Future<void> clearCacheItem(String key) async {
    await _ensureInitialized();
    
    final cacheKey = '$_cacheKeyPrefix$key';
    
    // Remove from memory cache
    _memoryCache.remove(cacheKey);
    _dirtyKeys.remove(cacheKey);
    
    // Remove from storage
    if (_useHive && _cacheBox != null) {
      await _cacheBox!.delete(cacheKey);
    } else if (_preferences != null) {
      await _preferences!.remove(cacheKey);
    }
  }
  
  /// Clear all expired cache items
  Future<void> clearExpiredCache() async {
    await _ensureInitialized();
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <String>[];
    
    // Check memory cache first
    for (final key in _memoryCache.keys) {
      if (key.startsWith(_cacheKeyPrefix)) {
        final cacheEntry = _memoryCache[key];
        
        if (cacheEntry is Map && 
            cacheEntry.containsKey('timestamp') && 
            cacheEntry.containsKey('expiry') && 
            cacheEntry['expiry'] != null) {
          
          final timestamp = cacheEntry['timestamp'] as int;
          final expiryMs = cacheEntry['expiry'] as int;
          
          if (now - timestamp > expiryMs) {
            keysToRemove.add(key);
          }
        }
      }
    }
    
    // Remove expired entries from memory cache
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _dirtyKeys.remove(key);
    }
    
    // Clear expired entries from storage
    if (_useHive && _cacheBox != null) {
      for (final key in _cacheBox!.keys) {
        if (key.toString().startsWith(_cacheKeyPrefix)) {
          final jsonString = _cacheBox!.get(key);
          
          if (jsonString != null) {
            final cacheEntry = _parseValue(jsonString);
            
            if (cacheEntry is Map && 
                cacheEntry.containsKey('timestamp') && 
                cacheEntry.containsKey('expiry') && 
                cacheEntry['expiry'] != null) {
              
              final timestamp = cacheEntry['timestamp'] as int;
              final expiryMs = cacheEntry['expiry'] as int;
              
              if (now - timestamp > expiryMs) {
                await _cacheBox!.delete(key);
              }
            }
          }
        }
      }
    } else if (_preferences != null) {
      final allKeys = _preferences!.getKeys();
      
      for (final key in allKeys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          final jsonString = _preferences!.getString(key);
          
          if (jsonString != null) {
            final cacheEntry = _parseValue(jsonString);
            
            if (cacheEntry is Map && 
                cacheEntry.containsKey('timestamp') && 
                cacheEntry.containsKey('expiry') && 
                cacheEntry['expiry'] != null) {
              
              final timestamp = cacheEntry['timestamp'] as int;
              final expiryMs = cacheEntry['expiry'] as int;
              
              if (now - timestamp > expiryMs) {
                await _preferences!.remove(key);
              }
            }
          }
        }
      }
    }
  }
  
  /// Save progress data with string key (generic method)
  Future<void> saveProgress(String key, String data) async {
    await _ensureInitialized();
    
    // Update memory cache
    _memoryCache[key] = data;
    _dirtyKeys.add(key);
    
    // Save to user progress box
    await _saveToStorage(key, data, box: _userProgressBox);
  }
  
  /// Get progress data with string key (generic method)
  Future<String?> getProgress(String key) async {
    await _ensureInitialized();
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final cachedData = _memoryCache[key];
      if (cachedData is String) {
        return cachedData;
      }
      return jsonEncode(cachedData);
    }
    
    // Try to load from storage
    final savedData = await _loadFromStorage(key, box: _userProgressBox);
    if (savedData == null) return null;
    
    // Cache the data
    _memoryCache[key] = savedData;
    
    return savedData as String;
  }
  /// Log analytics event
  Future<void> logAnalyticsEvent(String userId, String eventType, Map<String, dynamic> eventData) async {
    await _ensureInitialized();
    
    final eventRecord = {
      'userId': userId,
      'eventType': eventType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': eventData,
    };
    
    final key = 'analytics_${DateTime.now().millisecondsSinceEpoch}_${eventType}';
    
    // Store in analytics box
    if (_useHive && _analyticsBox != null) {
      await _analyticsBox!.add(eventRecord);
    } else if (_preferences != null) {
      // For SharedPreferences, create a list of events or add to existing list
      final existingEventsJson = _preferences!.getString('analytics_events');
      List<dynamic> events = [];
      
      if (existingEventsJson != null) {
        events = jsonDecode(existingEventsJson);
      }
      
      events.add(eventRecord);
      
      // Store updated list
      await _preferences!.setString('analytics_events', jsonEncode(events));
    }
  }
  
  /// Get analytics events for a time period
  Future<List<Map<String, dynamic>>> getAnalyticsEvents(
    String userId, {
    DateTime? startTime,
    DateTime? endTime,
    String? eventType,
    int limit = 100,
  }) async {
    await _ensureInitialized();
    
    final now = DateTime.now();
    final startMillis = startTime?.millisecondsSinceEpoch ?? 0;
    final endMillis = endTime?.millisecondsSinceEpoch ?? now.millisecondsSinceEpoch;
    
    final events = <Map<String, dynamic>>[];
    
    if (_useHive && _analyticsBox != null) {
      // For Hive, scan through all events
      for (var i = 0; i < _analyticsBox!.length; i++) {
        final event = _analyticsBox!.getAt(i);
        
        if (event is Map && 
            event['userId'] == userId &&
            event['timestamp'] >= startMillis &&
            event['timestamp'] <= endMillis &&
            (eventType == null || event['eventType'] == eventType)) {
          
          events.add(Map<String, dynamic>.from(event));
          
          if (events.length >= limit) break;
        }
      }
    } else if (_preferences != null) {
      // For SharedPreferences, parse the events list
      final existingEventsJson = _preferences!.getString('analytics_events');
      
      if (existingEventsJson != null) {
        final allEvents = jsonDecode(existingEventsJson);
        
        if (allEvents is List) {
          for (final event in allEvents) {
            if (event is Map && 
                event['userId'] == userId &&
                event['timestamp'] >= startMillis &&
                event['timestamp'] <= endMillis &&
                (eventType == null || event['eventType'] == eventType)) {
              
              events.add(Map<String, dynamic>.from(event));
              
              if (events.length >= limit) break;
            }
          }
        }
      }
    }
    
    // Sort events by timestamp descending (newest first)
    events.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    
    return events;
  }
  
  /// Batch save multiple patterns
  Future<void> batchSavePatterns(String userId, List<PatternModel> patterns) async {
    await _ensureInitialized();
    
    // Process in batches to avoid excessive memory usage
    const batchSize = 20;
    
    for (var i = 0; i < patterns.length; i += batchSize) {
      final end = (i + batchSize < patterns.length) ? i + batchSize : patterns.length;
      final batch = patterns.sublist(i, end);
      
      // Process this batch
      final patternEntries = <String, dynamic>{};
      final patternIds = <String>[];
      
      for (final pattern in batch) {
        final patternKey = '$_patternKeyPrefix${pattern.id}';
        patternEntries[patternKey] = pattern.toJson();
        patternIds.add(pattern.id);
        
        // Update memory cache
        _memoryCache[patternKey] = pattern.toJson();
        _dirtyKeys.add(patternKey);
      }
      
      // Save pattern entries as batch
      if (_useHive && _patternsBox != null) {
        await _patternsBox!.putAll(patternEntries);
      } else if (_preferences != null) {
        // For SharedPreferences, save each entry individually
        for (final entry in patternEntries.entries) {
          await _preferences!.setString(entry.key, jsonEncode(entry.value));
        }
      }
      
      // Update user's pattern list for all patterns
      final userPatternsKey = '$_userPatternsKeyPrefix$userId';
      
      // Load existing pattern IDs
      List<String> existingPatternIds = [];
      
      // Check memory cache first
      if (_memoryCache.containsKey(userPatternsKey)) {
        existingPatternIds = List<String>.from(_memoryCache[userPatternsKey]);
      } else {
        // Load from storage
        final savedList = await _loadFromStorage(userPatternsKey, box: _patternsBox);
        if (savedList != null) {
          final parsedList = _parseValue(savedList);
          if (parsedList is List) {
            existingPatternIds = List<String>.from(parsedList);
          }
        }
      }
      
      // Add all pattern IDs that don't already exist
      bool listChanged = false;
      for (final patternId in patternIds) {
        if (!existingPatternIds.contains(patternId)) {
          existingPatternIds.add(patternId);
          listChanged = true;
        }
      }
      
      // Save updated list if changed
      if (listChanged) {
        // Update memory cache
        _memoryCache[userPatternsKey] = existingPatternIds;
        _dirtyKeys.add(userPatternsKey);
        
        // Save to storage
        await _saveToStorage(userPatternsKey, existingPatternIds, box: _patternsBox);
      }
    }
  }
  
  /// Backup all user data to a JSON string
  Future<String> backupUserData(String userId) async {
    await _ensureInitialized();
    
    final backup = <String, dynamic>{
      'userId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0',
    };
    
    // Backup user progress
    final userProgress = await getUserProgress(userId);
    if (userProgress != null) {
      backup['userProgress'] = userProgress.toJson();
    }
    
    // Backup user patterns
    final patterns = await getUserPatterns(userId);
    backup['patterns'] = patterns.map((p) => p.toJson()).toList();
    
    // Backup badges
    final badges = await getUserBadges(userId);
    backup['badges'] = badges.map((b) => b.toJson()).toList();
    
    // Backup settings
    final settings = await getAppSettings();
    final userSettings = <String, dynamic>{};
    
    // Filter settings that belong to this user
    for (final key in settings.keys) {
      if (key.contains(userId)) {
        userSettings[key] = settings[key];
      }
    }
    
    backup['settings'] = userSettings;
    
    // Create JSON string
    return jsonEncode(backup);
  }
  
  /// Restore user data from a backup JSON string
  Future<bool> restoreUserData(String backupJson) async {
    await _ensureInitialized();
    
    try {
      final backup = jsonDecode(backupJson);
      
      if (backup is! Map<String, dynamic> || !backup.containsKey('userId')) {
        debugPrint('Invalid backup format');
        return false;
      }
      
      final userId = backup['userId'] as String;
      
      // Restore user progress
      if (backup.containsKey('userProgress')) {
        final userProgress = UserProgress.fromJson(backup['userProgress']);
        await saveUserProgress(userProgress);
      }
      
      // Restore patterns
      if (backup.containsKey('patterns') && backup['patterns'] is List) {
        final patternsList = backup['patterns'] as List;
        final patterns = patternsList.map((p) => PatternModel.fromJson(p)).toList();
        await batchSavePatterns(userId, patterns);
      }
      
      // Restore badges
      if (backup.containsKey('badges') && backup['badges'] is List) {
        final badgesList = backup['badges'] as List;
        final badges = badgesList.map((b) => BadgeModel.fromJson(b)).toList();
        await saveUserBadges(userId, badges);
      }
      
      // Restore settings
      if (backup.containsKey('settings') && backup['settings'] is Map) {
        final userSettings = backup['settings'] as Map<String, dynamic>;
        final currentSettings = await getAppSettings();
        
        // Merge settings
        currentSettings.addAll(userSettings);
        
        await saveAppSettings(currentSettings);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error restoring data: $e');
      return false;
    }
  }
  
  /// Clear all user data for a specific user
  Future<void> clearUserData(String userId) async {
    await _ensureInitialized();
    
    // Clear user progress
    final progressKey = '$_progressKeyPrefix$userId';
    if (_useHive && _userProgressBox != null) {
      await _userProgressBox!.delete(progressKey);
    } else if (_preferences != null) {
      await _preferences!.remove(progressKey);
    }
    _memoryCache.remove(progressKey);
    _dirtyKeys.remove(progressKey);
    
    // Get user's pattern IDs
    final userPatternsKey = '$_userPatternsKeyPrefix$userId';
    List<String> patternIds = [];
    
    // Check memory cache first
    if (_memoryCache.containsKey(userPatternsKey)) {
      patternIds = List<String>.from(_memoryCache[userPatternsKey]);
    } else {
      // Load from storage
      final savedList = await _loadFromStorage(userPatternsKey, box: _patternsBox);
      if (savedList != null) {
        final parsedList = _parseValue(savedList);
        if (parsedList is List) {
          patternIds = List<String>.from(parsedList);
        }
      }
    }
    
    // Delete each pattern
    for (final patternId in patternIds) {
      final patternKey = '$_patternKeyPrefix$patternId';
      if (_useHive && _patternsBox != null) {
        await _patternsBox!.delete(patternKey);
      } else if (_preferences != null) {
        await _preferences!.remove(patternKey);
      }
      _memoryCache.remove(patternKey);
      _dirtyKeys.remove(patternKey);
    }
    
    // Clear pattern list
    if (_useHive && _patternsBox != null) {
      await _patternsBox!.delete(userPatternsKey);
    } else if (_preferences != null) {
      await _preferences!.remove(userPatternsKey);
    }
    _memoryCache.remove(userPatternsKey);
    _dirtyKeys.remove(userPatternsKey);
    
    // Clear badges
    final userBadgesKey = '$_userBadgesKeyPrefix$userId';
    if (_useHive && _badgesBox != null) {
      await _badgesBox!.delete(userBadgesKey);
    } else if (_preferences != null) {
      await _preferences!.remove(userBadgesKey);
    }
    _memoryCache.remove(userBadgesKey);
    _dirtyKeys.remove(userBadgesKey);
    
    // Clear blocks
    if (_useHive && _blockCollectionsBox != null) {
      for (final key in _blockCollectionsBox!.keys) {
        if (key.toString().startsWith('$_blocksKeyPrefix$userId')) {
          await _blockCollectionsBox!.delete(key);
          _memoryCache.remove(key.toString());
          _dirtyKeys.remove(key.toString());
        }
      }
    } else if (_preferences != null) {
      final allKeys = _preferences!.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('$_blocksKeyPrefix$userId')) {
          await _preferences!.remove(key);
          _memoryCache.remove(key);
          _dirtyKeys.remove(key);
        }
      }
    }
    
    // Sync to ensure all changes are persisted
    await _syncDirtyKeys();
  }
  
  /// Clear specific box
  Future<void> clearBox(String boxName) async {
    await _ensureInitialized();
    
    Box? box;
    switch (boxName) {
      case _patternsBoxName:
        box = _patternsBox;
        break;
      case _userProgressBoxName:
        box = _userProgressBox;
        break;
      case _settingsBoxName:
        box = _settingsBox;
        break;
      case _cacheBoxName:
        box = _cacheBox;
        break;
      case _blockCollectionsBoxName:
        box = _blockCollectionsBox;
        break;
      case _badgesBoxName:
        box = _badgesBox;
        break;
      case _analyticsBoxName:
        box = _analyticsBox;
        break;
      default:
        debugPrint('Invalid box name: $boxName');
        return;
    }
    
    try {
      if (_useHive && box != null) {
        await box.clear();
      } else if (_preferences != null) {
        final allKeys = _preferences!.getKeys();
        for (final key in allKeys) {
          if (key.startsWith(_getKeyPrefixForBox(boxName))) {
            await _preferences!.remove(key);
          }
        }
      }
      
      // Clear memory cache for this box
      final keyPrefix = _getKeyPrefixForBox(boxName);
      final keysToRemove = <String>[];
      
      for (final key in _memoryCache.keys) {
        if (key.startsWith(keyPrefix)) {
          keysToRemove.add(key);
        }
      }
      
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
        _dirtyKeys.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing box $boxName: $e');
    }
  }
  
  /// Get key prefix for a box name
  String _getKeyPrefixForBox(String boxName) {
    switch (boxName) {
      case _patternsBoxName:
        return _patternKeyPrefix;
      case _userProgressBoxName:
        return _progressKeyPrefix;
      case _cacheBoxName:
        return _cacheKeyPrefix;
      case _blockCollectionsBoxName:
        return _blocksKeyPrefix;
      case _badgesBoxName:
        return _userBadgesKeyPrefix;
      default:
        return '';
    }
  }
  
  /// Clear all stored data (for testing or user request)
  Future<void> clearAll() async {
    await _ensureInitialized();
    
    try {
      if (_useHive) {
        // Clear all Hive boxes
        if (_patternsBox != null) await _patternsBox!.clear();
        if (_userProgressBox != null) await _userProgressBox!.clear();
        if (_settingsBox != null) await _settingsBox!.clear();
        if (_cacheBox != null) await _cacheBox!.clear();
        if (_blockCollectionsBox != null) await _blockCollectionsBox!.clear();
        if (_badgesBox != null) await _badgesBox!.clear();
        if (_analyticsBox != null) await _analyticsBox!.clear();
      } else if (_preferences != null) {
        await _preferences!.clear();
      }
      
      // Clear memory cache
      _memoryCache.clear();
      _dirtyKeys.clear();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }
  
  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    await _ensureInitialized();
    
    final stats = <String, dynamic>{
      'memoryCache': {
        'keys': _memoryCache.length,
        'dirtyKeys': _dirtyKeys.length,
      },
    };
    
    if (_useHive) {
      // Get stats for each Hive box
      if (_patternsBox != null) {
        stats['patternsBox'] = {
          'keys': _patternsBox!.keys.length,
          'isOpen': _patternsBox!.isOpen,
        };
      }
      
      if (_userProgressBox != null) {
        stats['userProgressBox'] = {
          'keys': _userProgressBox!.keys.length,
          'isOpen': _userProgressBox!.isOpen,
        };
      }
      
      if (_settingsBox != null) {
        stats['settingsBox'] = {
          'keys': _settingsBox!.keys.length,
          'isOpen': _settingsBox!.isOpen,
        };
      }
      
      if (_cacheBox != null) {
        stats['cacheBox'] = {
          'keys': _cacheBox!.keys.length,
          'isOpen': _cacheBox!.isOpen,
        };
      }
      
      if (_blockCollectionsBox != null) {
        stats['blockCollectionsBox'] = {
          'keys': _blockCollectionsBox!.keys.length,
          'isOpen': _blockCollectionsBox!.isOpen,
        };
      }
      
      if (_badgesBox != null) {
        stats['badgesBox'] = {
          'keys': _badgesBox!.keys.length,
          'isOpen': _badgesBox!.isOpen,
        };
      }
      
      if (_analyticsBox != null) {
        stats['analyticsBox'] = {
          'keys': _analyticsBox!.keys.length,
          'isOpen': _analyticsBox!.isOpen,
        };
      }
    } else if (_preferences != null) {
      stats['sharedPreferences'] = {
        'keys': _preferences!.getKeys().length,
      };
      
      // Group keys by type
      final keyGroups = <String, int>{};
      
      for (final key in _preferences!.getKeys()) {
        String group;
        if (key.startsWith(_progressKeyPrefix)) {
          group = 'userProgress';
        } else if (key.startsWith(_patternKeyPrefix)) {
          group = 'patterns';
        } else if (key.startsWith(_blocksKeyPrefix)) {
          group = 'blocks';
        } else if (key.startsWith(_userBadgesKeyPrefix)) {
          group = 'badges';
        } else if (key.startsWith(_cacheKeyPrefix)) {
          group = 'cache';
        } else {
          group = 'other';
        }
        
        keyGroups[group] = (keyGroups[group] ?? 0) + 1;
      }
      
      stats['keyGroups'] = keyGroups;
    }
    
    return stats;
  }
  
  /// Check if a key exists in storage
  Future<bool> exists(String key) async {
    await _ensureInitialized();
    
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      return true;
    }
    
    // Determine which box to check based on key prefix
    Box? box;
    
    if (key.startsWith(_progressKeyPrefix)) {
      box = _userProgressBox;
    } else if (key.startsWith(_patternKeyPrefix)) {
      box = _patternsBox;
    } else if (key.startsWith(_blocksKeyPrefix)) {
      box = _blockCollectionsBox;
    } else if (key.startsWith(_userBadgesKeyPrefix)) {
      box = _badgesBox;
    } else if (key.startsWith(_cacheKeyPrefix)) {
      box = _cacheBox;
    } else {
      box = _settingsBox;
    }
    
    // Check storage
    if (_useHive && box != null) {
      return box.containsKey(key);
    } else if (_preferences != null) {
      return _preferences!.containsKey(key);
    }
    
    return false;
  }
  
  /// Manually trigger sync of dirty keys
  Future<void> sync() async {
    return _syncDirtyKeys();
  }
  
  /// Dispose resources
  void dispose() {
    // Sync any remaining dirty keys
    _syncDirtyKeys();
    
    // Cancel sync timer
    _syncTimer?.cancel();
    
    // Close Hive boxes
    if (_useHive) {
      _patternsBox?.close();
      _userProgressBox?.close();
      _settingsBox?.close();
      _cacheBox?.close();
      _blockCollectionsBox?.close();
      _badgesBox?.close();
      _analyticsBox?.close();
    }
    
    // Clear memory cache
    _memoryCache.clear();
    _dirtyKeys.clear();
  }
}