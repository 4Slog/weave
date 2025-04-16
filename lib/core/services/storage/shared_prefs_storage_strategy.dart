import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_strategy.dart';

/// SharedPreferences implementation of the StorageStrategy interface.
///
/// This class provides a SharedPreferences-based storage mechanism that implements
/// the StorageStrategy interface for consistent storage behavior.
class SharedPrefsStorageStrategy implements StorageStrategy {
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing SharedPrefsStorageStrategy: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveData(String key, dynamic data) async {
    _checkInitialized();

    try {
      if (data is String) {
        await _prefs!.setString(key, data);
      } else if (data is int) {
        await _prefs!.setInt(key, data);
      } else if (data is double) {
        await _prefs!.setDouble(key, data);
      } else if (data is bool) {
        await _prefs!.setBool(key, data);
      } else if (data is List<String>) {
        await _prefs!.setStringList(key, data);
      } else {
        // For complex objects, convert to JSON string
        final jsonString = jsonEncode(data);
        await _prefs!.setString(key, jsonString);
      }
    } catch (e) {
      debugPrint('Error saving data to SharedPreferences: $e');
      rethrow;
    }
  }

  @override
  Future<dynamic> getData(String key) async {
    _checkInitialized();

    try {
      final data = _prefs!.get(key);

      if (data == null) return null;

      // If the data is a string that looks like JSON, try to parse it
      if (data is String &&
          ((data.startsWith('{') && data.endsWith('}')) ||
          (data.startsWith('[') && data.endsWith(']')))) {
        try {
          return jsonDecode(data);
        } catch (_) {
          // If parsing fails, return the original string
          return data;
        }
      }

      return data;
    } catch (e) {
      debugPrint('Error getting data from SharedPreferences: $e');
      return null;
    }
  }

  @override
  Future<void> removeData(String key) async {
    _checkInitialized();

    try {
      await _prefs!.remove(key);
    } catch (e) {
      debugPrint('Error removing data from SharedPreferences: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getAllKeys() async {
    _checkInitialized();

    try {
      return _prefs!.getKeys().toList();
    } catch (e) {
      debugPrint('Error getting keys from SharedPreferences: $e');
      return [];
    }
  }

  @override
  Future<void> clear() async {
    _checkInitialized();

    try {
      await _prefs!.clear();
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
      rethrow;
    }
  }

  @override
  bool isInitialized() {
    return _isInitialized && _prefs != null;
  }

  /// Ensures the storage is initialized before performing operations.
  ///
  /// Throws an exception if the storage is not initialized.
  void _checkInitialized() {
    if (!isInitialized()) {
      throw StateError('SharedPrefsStorageStrategy not initialized. Call initialize() first.');
    }
  }
}
