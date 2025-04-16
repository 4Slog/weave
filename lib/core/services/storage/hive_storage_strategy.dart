import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'storage_strategy.dart';

/// Hive implementation of the StorageStrategy interface.
/// 
/// This class provides a Hive-based storage mechanism that implements
/// the StorageStrategy interface for consistent storage behavior.
class HiveStorageStrategy implements StorageStrategy {
  final String boxName;
  Box? _box;
  bool _isInitialized = false;
  
  /// Creates a new HiveStorageStrategy.
  /// 
  /// [boxName] is the name of the Hive box to use for storage.
  HiveStorageStrategy(this.boxName);
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _box = await Hive.openBox(boxName);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing HiveStorageStrategy: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> saveData(String key, dynamic data) async {
    _checkInitialized();
    
    try {
      // Convert complex objects to JSON string
      final valueToStore = data is String ? data : 
                          (data is num || data is bool) ? data : 
                          jsonEncode(data);
      
      await _box!.put(key, valueToStore);
    } catch (e) {
      debugPrint('Error saving data to Hive: $e');
      rethrow;
    }
  }
  
  @override
  Future<dynamic> getData(String key) async {
    _checkInitialized();
    
    try {
      final data = _box!.get(key);
      
      if (data == null) return null;
      
      // If the data is a string that looks like JSON, try to parse it
      if (data is String && 
          (data.startsWith('{') && data.endsWith('}')) || 
          (data.startsWith('[') && data.endsWith(']'))) {
        try {
          return jsonDecode(data);
        } catch (_) {
          // If parsing fails, return the original string
          return data;
        }
      }
      
      return data;
    } catch (e) {
      debugPrint('Error getting data from Hive: $e');
      return null;
    }
  }
  
  @override
  Future<void> removeData(String key) async {
    _checkInitialized();
    
    try {
      await _box!.delete(key);
    } catch (e) {
      debugPrint('Error removing data from Hive: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<String>> getAllKeys() async {
    _checkInitialized();
    
    try {
      return _box!.keys.cast<String>().toList();
    } catch (e) {
      debugPrint('Error getting keys from Hive: $e');
      return [];
    }
  }
  
  @override
  Future<void> clear() async {
    _checkInitialized();
    
    try {
      await _box!.clear();
    } catch (e) {
      debugPrint('Error clearing Hive box: $e');
      rethrow;
    }
  }
  
  @override
  bool isInitialized() {
    return _isInitialized && _box != null && _box!.isOpen;
  }
  
  /// Ensures the storage is initialized before performing operations.
  /// 
  /// Throws an exception if the storage is not initialized.
  void _checkInitialized() {
    if (!isInitialized()) {
      throw StateError('HiveStorageStrategy not initialized. Call initialize() first.');
    }
  }
}
