import 'package:flutter/foundation.dart';
import '../../../models/education/cs_standard.dart';
import '../base_repository.dart';
import '../storage_strategy.dart';

/// Repository for managing CS standards.
/// 
/// This repository handles the storage and retrieval of Computer Science
/// Teachers Association (CSTA) standards.
class CSStandardsRepository implements BaseRepository {
  final StorageStrategy _storage;
  static const String _standardKeyPrefix = 'cs_standard_';
  static const String _allStandardsKey = 'all_cs_standards';
  
  /// Creates a new CSStandardsRepository.
  /// 
  /// [storage] is the storage strategy to use for data persistence.
  CSStandardsRepository(this._storage);
  
  @override
  StorageStrategy get storage => _storage;
  
  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }
  
  /// Save a CS standard.
  /// 
  /// [standard] is the CS standard to save.
  Future<void> saveStandard(CSStandard standard) async {
    final key = _standardKeyPrefix + standard.id;
    await _storage.saveData(key, standard.toJson());
    
    // Update the list of all standards
    await _updateStandardsList(standard.id);
  }
  
  /// Get a CS standard by ID.
  /// 
  /// [standardId] is the ID of the standard to retrieve.
  /// Returns the standard if found, or null if not found.
  Future<CSStandard?> getStandard(String standardId) async {
    final key = _standardKeyPrefix + standardId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return CSStandard.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing CS standard: $e');
      return null;
    }
  }
  
  /// Get all CS standards.
  /// 
  /// Returns a list of all CS standards.
  Future<List<CSStandard>> getAllStandards() async {
    final standardIds = await _getStandardIds();
    final standards = <CSStandard>[];
    
    for (final id in standardIds) {
      final standard = await getStandard(id);
      if (standard != null) {
        standards.add(standard);
      }
    }
    
    return standards;
  }
  
  /// Get CS standards by grade level.
  /// 
  /// [gradeLevel] is the grade level to filter by (e.g., "K-2", "3-5").
  /// Returns a list of standards for the specified grade level.
  Future<List<CSStandard>> getStandardsByGradeLevel(String gradeLevel) async {
    final allStandards = await getAllStandards();
    return allStandards.where((standard) => standard.gradeLevel == gradeLevel).toList();
  }
  
  /// Get CS standards by concept area.
  /// 
  /// [conceptArea] is the concept area to filter by (e.g., "Algorithms and Programming").
  /// Returns a list of standards for the specified concept area.
  Future<List<CSStandard>> getStandardsByConceptArea(String conceptArea) async {
    final allStandards = await getAllStandards();
    return allStandards.where((standard) => standard.conceptArea == conceptArea).toList();
  }
  
  /// Get CS standards by concept.
  /// 
  /// [concept] is the concept to filter by (e.g., "Variables").
  /// Returns a list of standards for the specified concept.
  Future<List<CSStandard>> getStandardsByConcept(String concept) async {
    final allStandards = await getAllStandards();
    return allStandards.where((standard) => standard.concept == concept).toList();
  }
  
  /// Delete a CS standard.
  /// 
  /// [standardId] is the ID of the standard to delete.
  Future<void> deleteStandard(String standardId) async {
    final key = _standardKeyPrefix + standardId;
    await _storage.removeData(key);
    
    // Update the list of all standards
    await _removeFromStandardsList(standardId);
  }
  
  /// Import a list of CS standards.
  /// 
  /// [standards] is the list of standards to import.
  /// Returns the number of standards imported.
  Future<int> importStandards(List<CSStandard> standards) async {
    int count = 0;
    
    for (final standard in standards) {
      await saveStandard(standard);
      count++;
    }
    
    return count;
  }
  
  /// Helper method to update the list of all standards.
  Future<void> _updateStandardsList(String standardId) async {
    final standardIds = await _getStandardIds();
    
    if (!standardIds.contains(standardId)) {
      standardIds.add(standardId);
      await _storage.saveData(_allStandardsKey, standardIds);
    }
  }
  
  /// Helper method to remove a standard from the list of all standards.
  Future<void> _removeFromStandardsList(String standardId) async {
    final standardIds = await _getStandardIds();
    
    if (standardIds.contains(standardId)) {
      standardIds.remove(standardId);
      await _storage.saveData(_allStandardsKey, standardIds);
    }
  }
  
  /// Helper method to get the list of all standard IDs.
  Future<List<String>> _getStandardIds() async {
    final data = await _storage.getData(_allStandardsKey);
    
    if (data == null) return [];
    
    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing CS standards list: $e');
      return [];
    }
  }
}
