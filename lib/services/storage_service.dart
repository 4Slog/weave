import 'package:hive/hive.dart';

class StorageService {
  Future<void> saveProgress(String key, String value) async {
    final box = await Hive.openBox('progressBox');
    await box.put(key, value);
  }
  
  Future<String?> getProgress(String key) async {
    final box = await Hive.openBox('progressBox');
    return box.get(key);
  }
  
  Future<void> deleteProgress(String key) async {
    final box = await Hive.openBox('progressBox');
    await box.delete(key);
  }
  
  Future<Map<String, dynamic>> getAllProgress() async {
    final box = await Hive.openBox('progressBox');
    Map<String, dynamic> result = {};
    
    for (var key in box.keys) {
      result[key.toString()] = box.get(key);
    }
    
    return result;
  }
  
  Future<void> clearAll() async {
    final box = await Hive.openBox('progressBox');
    await box.clear();
  }
}