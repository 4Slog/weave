import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kente_codeweaver/models/pattern_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling data persistence using Hive
class StorageService {
  // Singleton implementation
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() {
    return _instance;
  }
  
  StorageService._internal();
  
  // Hive box names
  static const String _patternsBoxName = 'patterns';
  static const String _userProgressBoxName = 'user_progress';
  static const String _settingsBoxName = 'settings';
  static const String _cacheBoxName = 'app_cache';
  static const String _progressBoxName = 'user_progress';
  static const String _progressKey = 'user_progress_';
  static const String _settingsKey = 'app_settings';
  static const String _blocksKey = 'saved_blocks_';
  
  // Initialization state
  bool _isInitialized = false;
  bool _initialized = false;
  
  /// Initialize storage system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize Hive
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);
      
      // Register adapters (if using TypeAdapters)
      // Note: For simplicity we're using JSON serialization instead of TypeAdapters
      
      // Open boxes
      await Hive.openBox(_patternsBoxName);
      await Hive.openBox(_userProgressBoxName);
      await Hive.openBox(_settingsBoxName);
      await Hive.openBox(_cacheBoxName);
      await Hive.openBox(_progressBoxName);
      
      _isInitialized = true;
      _initialized = true;
      debugPrint('Storage service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing storage service: $e');
      rethrow;
    }
  }
  
  /// Ensure storage is initialized before operations
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Get a Hive box by name
  Box _getBox(String boxName) {
    return Hive.box(boxName);
  }
  
  /// Save a pattern to storage
  Future<void> savePattern(PatternModel pattern) async {
    await _ensureInitialized();
    
    try {
      final patternsBox = _getBox(_patternsBoxName);
      
      // Convert pattern to JSON
      final patternJson = pattern.toJson();
      
      // Key format: userId_patternId
      final key = '${pattern.userId}_${pattern.id}';
      
      // Store in Hive
      await patternsBox.put(key, jsonEncode(patternJson));
      
      // Also store pattern ID in a list for this user
      final userPatternsKey = 'user_patterns_${pattern.userId}';
      List<String> userPatterns = [];
      
      if (patternsBox.containsKey(userPatternsKey)) {
        final patternsJson = jsonDecode(patternsBox.get(userPatternsKey));
        userPatterns = List<String>.from(patternsJson);
      }
      
      if (!userPatterns.contains(pattern.id)) {
        userPatterns.add(pattern.id);
        await patternsBox.put(userPatternsKey, jsonEncode(userPatterns));
      }
      
      debugPrint('Pattern saved: ${pattern.id}');
    } catch (e) {
      debugPrint('Error saving pattern: $e');
      rethrow;
    }
  }
  
  /// Get a pattern by ID
  Future<PatternModel?> getPattern(String userId, String patternId) async {
    await _ensureInitialized();
    
    try {
      final patternsBox = _getBox(_patternsBoxName);
      final key = '${userId}_$patternId';
      
      if (!patternsBox.containsKey(key)) {
        return null;
      }
      
      final patternJson = jsonDecode(patternsBox.get(key));
      return PatternModel.fromJson(patternJson);
    } catch (e) {
      debugPrint('Error getting pattern: $e');
      return null;
    }
  }
  
  /// Delete a pattern
  Future<void> deletePattern(String userId, String patternId) async {
    await _ensureInitialized();
    
    try {
      final patternsBox = _getBox(_patternsBoxName);
      final key = '${userId}_$patternId';
      
      // Remove pattern
      await patternsBox.delete(key);
      
      // Update user patterns list
      final userPatternsKey = 'user_patterns_$userId';
      if (patternsBox.containsKey(userPatternsKey)) {
        final patternsJson = jsonDecode(patternsBox.get(userPatternsKey));
        List<String> userPatterns = List<String>.from(patternsJson);
        userPatterns.remove(patternId);
        await patternsBox.put(userPatternsKey, jsonEncode(userPatterns));
      }
      
      debugPrint('Pattern deleted: $patternId');
    } catch (e) {
      debugPrint('Error deleting pattern: $e');
      rethrow;
    }
  }
  
  /// Get all patterns for a user
  Future<List<PatternModel>> getUserPatterns(String userId) async {
    await _ensureInitialized();
    
    try {
      final patternsBox = _getBox(_patternsBoxName);
      final userPatternsKey = 'user_patterns_$userId';
      
      if (!patternsBox.containsKey(userPatternsKey)) {
        return [];
      }
      
      final patternsJson = jsonDecode(patternsBox.get(userPatternsKey));
      List<String> patternIds = List<String>.from(patternsJson);
      
      List<PatternModel> patterns = [];
      for (final patternId in patternIds) {
        final pattern = await getPattern(userId, patternId);
        if (pattern != null) {
          patterns.add(pattern);
        }
      }
      
      return patterns;
    } catch (e) {
      debugPrint('Error getting user patterns: $e');
      return [];
    }
  }
  
  /// Get the number of patterns created by a user
  Future<int> getUserPatternCount(String userId) async {
    await _ensureInitialized();
    
    try {
      final patternsBox = _getBox(_patternsBoxName);
      final userPatternsKey = 'user_patterns_$userId';
      
      if (!patternsBox.containsKey(userPatternsKey)) {
        return 0;
      }
      
      final patternsJson = jsonDecode(patternsBox.get(userPatternsKey));
      List<String> patternIds = List<String>.from(patternsJson);
      
      return patternIds.length;
    } catch (e) {
      debugPrint('Error getting user pattern count: $e');
      return 0;
    }
  }
  
  /// Save user progress
  Future<void> saveUserProgress(UserProgress progress) async {
    await _ensureInitialized();
    
    try {
      final userBox = _getBox(_userProgressBoxName);
      final progressJson = progress.toJson();
      
      await userBox.put(progress.userId, jsonEncode(progressJson));
      debugPrint('User progress saved for user: ${progress.userId}');
    } catch (e) {
      debugPrint('Error saving user progress: $e');
      rethrow;
    }
  }
  
  /// Get user progress
  Future<UserProgress?> getUserProgress(String userId) async {
    await _ensureInitialized();
    
    try {
      final userBox = _getBox(_userProgressBoxName);
      
      if (!userBox.containsKey(userId)) {
        return null;
      }
      
      final progressJson = jsonDecode(userBox.get(userId));
      return UserProgress.fromJson(progressJson);
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return null;
    }
  }
  
  /// Get all stored user progress entries
  Future<List<UserProgress>> getAllUserProgress() async {
    await _ensureInitialized();
    
    final List<UserProgress> result = [];
    
    try {
      for (var key in _getBox(_userProgressBoxName).keys) {
        final jsonString = _getBox(_userProgressBoxName).get(key);
        if (jsonString != null) {
          final jsonData = jsonDecode(jsonString);
          result.add(UserProgress.fromJson(jsonData));
        }
      }
    } catch (e) {
      debugPrint('Error getting all user progress: $e');
    }
    
    return result;
  }
  
  /// Delete user progress
  Future<void> deleteUserProgress(String userId) async {
    await _ensureInitialized();
    
    try {
      await _getBox(_userProgressBoxName).delete(userId);
    } catch (e) {
      debugPrint('Error deleting user progress: $e');
      rethrow;
    }
  }
  
  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureInitialized();
    
    try {
      final settingsBox = _getBox(_settingsBoxName);
      
      if (value is String ||
          value is int ||
          value is double ||
          value is bool) {
        await settingsBox.put(key, value);
      } else {
        await settingsBox.put(key, jsonEncode(value));
      }
      
      debugPrint('Setting saved: $key');
    } catch (e) {
      debugPrint('Error saving setting: $e');
      rethrow;
    }
  }
  
  /// Get a setting
  dynamic getSetting(String key, {dynamic defaultValue}) {
    if (!_isInitialized) {
      return defaultValue;
    }
    
    try {
      final settingsBox = _getBox(_settingsBoxName);
      return settingsBox.get(key, defaultValue: defaultValue);
    } catch (e) {
      debugPrint('Error getting setting: $e');
      return defaultValue;
    }
  }
  
  /// Save app settings as JSON
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await saveSetting('app_settings', settings);
  }
  
  /// Get app settings
  Map<String, dynamic>? getAppSettings() {
    final settingsJson = getSetting('app_settings');
    if (settingsJson == null) return null;
    
    try {
      if (settingsJson is String) {
        return jsonDecode(settingsJson);
      } else {
        return settingsJson;
      }
    } catch (e) {
      debugPrint('Error parsing app settings: $e');
      return null;
    }
  }
  
  /// Delete setting
  Future<void> deleteSetting(String key) async {
    await _ensureInitialized();
    
    try {
      await _getBox(_settingsBoxName).delete(key);
    } catch (e) {
      debugPrint('Error deleting setting: $e');
      rethrow;
    }
  }
  
  /// Save cache item - for temporary data that persists between sessions
  Future<void> saveToCache(String key, dynamic value, {Duration? expiry}) async {
    await _ensureInitialized();
    
    try {
      final Map<String, dynamic> cacheEntry = {
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': expiry?.inMilliseconds,
      };
      
      final jsonString = jsonEncode(cacheEntry);
      await _getBox(_cacheBoxName).put(key, jsonString);
    } catch (e) {
      debugPrint('Error saving to cache: $e');
      rethrow;
    }
  }
  
  /// Get cache item
  Future<dynamic> getFromCache(String key) async {
    await _ensureInitialized();
    
    try {
      final jsonString = _getBox(_cacheBoxName).get(key);
      if (jsonString == null) return null;
      
      final cacheEntry = jsonDecode(jsonString);
      
      // Check expiry
      final expiryMs = cacheEntry['expiry'];
      if (expiryMs != null) {
        final timestamp = cacheEntry['timestamp'];
        final now = DateTime.now().millisecondsSinceEpoch;
        
        if (now - timestamp > expiryMs) {
          // Cache expired
          await _getBox(_cacheBoxName).delete(key);
          return null;
        }
      }
      
      return cacheEntry['value'];
    } catch (e) {
      debugPrint('Error getting from cache: $e');
      return null;
    }
  }
  
  /// Clear expired cache items
  Future<void> clearExpiredCache() async {
    await _ensureInitialized();
    
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (var key in _getBox(_cacheBoxName).keys) {
        final jsonString = _getBox(_cacheBoxName).get(key);
        if (jsonString != null) {
          final cacheEntry = jsonDecode(jsonString);
          final expiryMs = cacheEntry['expiry'];
          
          if (expiryMs != null) {
            final timestamp = cacheEntry['timestamp'];
            
            if (now - timestamp > expiryMs) {
              await _getBox(_cacheBoxName).delete(key);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing expired cache: $e');
    }
  }
  
  /// Clear all data in a specific box
  Future<void> clearBox(String boxName) async {
    await _ensureInitialized();
    
    try {
      switch (boxName) {
        case _userProgressBoxName:
          await _getBox(_userProgressBoxName).clear();
          break;
        case _patternsBoxName:
          await _getBox(_patternsBoxName).clear();
          break;
        case _settingsBoxName:
          await _getBox(_settingsBoxName).clear();
          break;
        case _cacheBoxName:
          await _getBox(_cacheBoxName).clear();
          break;
        default:
          throw ArgumentError('Invalid box name: $boxName');
      }
    } catch (e) {
      debugPrint('Error clearing box $boxName: $e');
      rethrow;
    }
  }
  
  /// Clear all user data (used for logout)
  Future<void> clearUserData(String userId) async {
    await _ensureInitialized();
    
    try {
      // Get user pattern IDs
      final patternsBox = _getBox(_patternsBoxName);
      final userPatternsKey = 'user_patterns_$userId';
      
      if (patternsBox.containsKey(userPatternsKey)) {
        final patternsJson = jsonDecode(patternsBox.get(userPatternsKey));
        List<String> patternIds = List<String>.from(patternsJson);
        
        // Delete each pattern
        for (final patternId in patternIds) {
          await patternsBox.delete('${userId}_$patternId');
        }
        
        // Delete pattern list
        await patternsBox.delete(userPatternsKey);
      }
      
      // Delete user progress
      final userBox = _getBox(_userProgressBoxName);
      await userBox.delete(userId);
      
      debugPrint('User data cleared for: $userId');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
      rethrow;
    }
  }
  
  /// Close storage (call when app is closing)
  Future<void> close() async {
    if (!_isInitialized) return;
    
    await Hive.close();
    _isInitialized = false;
    debugPrint('Storage service closed');
  }

  /// Save user progress
  Future<void> saveProgress(String userId, UserProgress progress) async {
    await _ensureInitialized();
    
    // Convert to JSON
    final jsonData = progress.toJson();
    
    // Save in Hive if available, otherwise use SharedPreferences
    try {
      final box = Hive.box(_progressBoxName);
      await box.put('$_progressKey$userId', jsonEncode(jsonData));
    } catch (e) {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_progressKey$userId', jsonEncode(jsonData));
    }
  }
  
  /// Get user progress
  Future<UserProgress?> getProgress(String userId) async {
    await _ensureInitialized();
    
    String? jsonString;
    
    // Try to get from Hive, fallback to SharedPreferences
    try {
      final box = Hive.box(_progressBoxName);
      jsonString = box.get('$_progressKey$userId');
    } catch (e) {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString('$_progressKey$userId');
    }
    
    if (jsonString == null) return null;
    
    try {
      final jsonData = jsonDecode(jsonString);
      return UserProgress.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing user progress: $e');
      return null;
    }
  }
  
  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();
    
    // Save in Hive if available, otherwise use SharedPreferences
    try {
      final box = Hive.box(_progressBoxName);
      await box.put(_settingsKey, jsonEncode(settings));
    } catch (e) {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings));
    }
  }
  
  /// Get app settings
  Future<Map<String, dynamic>> getSettings() async {
    await _ensureInitialized();
    
    String? jsonString;
    
    // Try to get from Hive, fallback to SharedPreferences
    try {
      final box = Hive.box(_progressBoxName);
      jsonString = box.get(_settingsKey);
    } catch (e) {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString(_settingsKey);
    }
    
    if (jsonString == null) return {};
    
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Error parsing settings: $e');
      return {};
    }
  }
  
  /// Save blocks for a user
  Future<void> saveBlocks(String userId, String workspaceId, Map<String, dynamic> blocksData) async {
    await _ensureInitialized();
    
    try {
      final box = Hive.box(_progressBoxName);
      await box.put('$_blocksKey${userId}_$workspaceId', jsonEncode(blocksData));
    } catch (e) {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_blocksKey${userId}_$workspaceId', jsonEncode(blocksData));
    }
  }
  
  /// Get saved blocks for a user
  Future<Map<String, dynamic>?> getBlocks(String userId, String workspaceId) async {
    await _ensureInitialized();
    
    String? jsonString;
    
    try {
      final box = Hive.box(_progressBoxName);
      jsonString = box.get('$_blocksKey${userId}_$workspaceId');
    } catch (e) {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString('$_blocksKey${userId}_$workspaceId');
    }
    
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Error parsing blocks: $e');
      return null;
    }
  }
  
  /// Clear all stored data (for testing/debugging)
  Future<void> clearAll() async {
    await _ensureInitialized();
    
    try {
      final box = Hive.box(_progressBoxName);
      await box.clear();
    } catch (e) {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}