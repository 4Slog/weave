import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';

/// Service for handling storage operations
class StorageService {
  /// Save user progress to storage
  Future<void> saveUserProgress(UserProgress userProgress) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(userProgress.toJson());
    await prefs.setString('user_progress_${userProgress.userId}', json);
  }
  
  /// Get user progress from storage
  Future<UserProgress?> getUserProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('user_progress_$userId');
    
    if (json == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      return UserProgress.fromJson(data);
    } catch (e) {
      print('Error loading user progress: $e');
      return null;
    }
  }
  
  /// Save a value to storage
  Future<void> saveValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
  
  /// Get a value from storage
  Future<String?> getValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  
  /// Save a boolean value to storage
  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
  
  /// Get a boolean value from storage
  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }
  
  /// Save an integer value to storage
  Future<void> saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
  
  /// Get an integer value from storage
  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }
  
  /// Save a double value to storage
  Future<void> saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }
  
  /// Get a double value from storage
  Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }
  
  /// Save a list of strings to storage
  Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }
  
  /// Get a list of strings from storage
  Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }
  
  /// Remove a value from storage
  Future<void> removeValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
  
  /// Clear all values from storage
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  /// Check if a key exists in storage
  Future<bool> hasKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
  
  /// Get all keys in storage
  Future<Set<String>> getAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys();
  }
  
  /// Get all keys with a specific prefix
  Future<List<String>> getKeysWithPrefix(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys()
        .where((key) => key.startsWith(prefix))
        .toList();
  }
  
  /// Save a JSON object to storage
  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(json);
    await prefs.setString(key, jsonString);
  }
  
  /// Get a JSON object from storage
  Future<Map<String, dynamic>?> getJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) {
      return null;
    }
    
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error decoding JSON: $e');
      return null;
    }
  }
  
  /// Save a list of JSON objects to storage
  Future<void> saveJsonList(String key, List<Map<String, dynamic>> jsonList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(key, jsonString);
  }
  
  /// Get a list of JSON objects from storage
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) {
      return null;
    }
    
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error decoding JSON list: $e');
      return null;
    }
  }
}
