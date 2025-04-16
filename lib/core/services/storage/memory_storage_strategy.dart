import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_strategy.dart';

/// In-memory implementation of the StorageStrategy interface.
/// 
/// This class provides an in-memory storage mechanism that implements
/// the StorageStrategy interface. It's primarily used for testing
/// and development purposes.
class MemoryStorageStrategy implements StorageStrategy {
  final Map<String, dynamic> _storage = {};
  bool _isInitialized = false;
  
  /// Creates a new MemoryStorageStrategy.
  MemoryStorageStrategy();
  
  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }
  
  @override
  Future<void> saveData(String key, dynamic data) async {
    _checkInitialized();
    
    try {
      // Convert complex objects to JSON string
      final valueToStore = data is String ? data : 
                          (data is num || data is bool) ? data : 
                          jsonEncode(data);
      
      _storage[key] = valueToStore;
    } catch (e) {
      debugPrint('Error saving data to memory: $e');
      rethrow;
    }
  }
  
  @override
  Future<dynamic> getData(String key) async {
    _checkInitialized();
    
    try {
      final value = _storage[key];
      
      if (value == null) return null;
      
      // Try to parse as JSON if it's a string
      if (value is String) {
        try {
          return jsonDecode(value);
        } catch (_) {
          // If not valid JSON, return as is
          return value;
        }
      }
      
      return value;
    } catch (e) {
      debugPrint('Error getting data from memory: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> removeData(String key) async {
    _checkInitialized();
    
    try {
      _storage.remove(key);
    } catch (e) {
      debugPrint('Error removing data from memory: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<String>> getAllKeys() async {
    _checkInitialized();
    
    try {
      return _storage.keys.toList();
    } catch (e) {
      debugPrint('Error getting all keys from memory: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> clear() async {
    _checkInitialized();
    
    try {
      _storage.clear();
    } catch (e) {
      debugPrint('Error clearing memory storage: $e');
      rethrow;
    }
  }
  
  @override
  bool isInitialized() {
    return _isInitialized;
  }
  
  /// Checks if the storage is initialized and throws an exception if not.
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('MemoryStorageStrategy not initialized. Call initialize() first.');
    }
  }
}
