import 'package:flutter/foundation.dart';
import '../../../models/education/iste_standard.dart';
import '../base_repository.dart';
import '../storage_strategy.dart';

/// Repository for managing ISTE standards.
/// 
/// This repository handles the storage and retrieval of International Society
/// for Technology in Education (ISTE) standards.
class ISTEStandardsRepository implements BaseRepository {
  final StorageStrategy _storage;
  static const String _standardKeyPrefix = 'iste_standard_';
  static const String _allStandardsKey = 'all_iste_standards';
  
  /// Creates a new ISTEStandardsRepository.
  /// 
  /// [storage] is the storage strategy to use for data persistence.
  ISTEStandardsRepository(this._storage);
  
  @override
  StorageStrategy get storage => _storage;
  
  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }
  
  /// Save an ISTE standard.
  /// 
  /// [standard] is the ISTE standard to save.
  Future<void> saveStandard(ISTEStandard standard) async {
    final key = _standardKeyPrefix + standard.id;
    await _storage.saveData(key, standard.toJson());
    
    // Update the list of all standards
    await _updateStandardsList(standard.id);
  }
  
  /// Get an ISTE standard by ID.
  /// 
  /// [standardId] is the ID of the standard to retrieve.
  /// Returns the standard if found, or null if not found.
  Future<ISTEStandard?> getStandard(String standardId) async {
    final key = _standardKeyPrefix + standardId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return ISTEStandard.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing ISTE standard: $e');
      return null;
    }
  }
  
  /// Get all ISTE standards.
  /// 
  /// Returns a list of all ISTE standards.
  Future<List<ISTEStandard>> getAllStandards() async {
    final standardIds = await _getStandardIds();
    final standards = <ISTEStandard>[];
    
    for (final id in standardIds) {
      final standard = await getStandard(id);
      if (standard != null) {
        standards.add(standard);
      }
    }
    
    return standards;
  }
  
  /// Get ISTE standards by category.
  /// 
  /// [category] is the category to filter by (e.g., "Empowered Learner").
  /// Returns a list of standards for the specified category.
  Future<List<ISTEStandard>> getStandardsByCategory(String category) async {
    final allStandards = await getAllStandards();
    return allStandards.where((standard) => standard.category == category).toList();
  }
  
  /// Get ISTE standards by category number.
  /// 
  /// [categoryNumber] is the category number to filter by (1-7).
  /// Returns a list of standards for the specified category number.
  Future<List<ISTEStandard>> getStandardsByCategoryNumber(int categoryNumber) async {
    final allStandards = await getAllStandards();
    return allStandards.where((standard) => standard.categoryNumber == categoryNumber).toList();
  }
  
  /// Get ISTE standards by age range.
  /// 
  /// [ageRange] is the age range to filter by (e.g., "5-8", "8-11").
  /// Returns a list of standards for the specified age range.
  Future<List<ISTEStandard>> getStandardsByAgeRange(String ageRange) async {
    final allStandards = await getAllStandards();
    return allStandards.where((standard) => standard.ageRange == ageRange).toList();
  }
  
  /// Delete an ISTE standard.
  /// 
  /// [standardId] is the ID of the standard to delete.
  Future<void> deleteStandard(String standardId) async {
    final key = _standardKeyPrefix + standardId;
    await _storage.removeData(key);
    
    // Update the list of all standards
    await _removeFromStandardsList(standardId);
  }
  
  /// Import a list of ISTE standards.
  /// 
  /// [standards] is the list of standards to import.
  /// Returns the number of standards imported.
  Future<int> importStandards(List<ISTEStandard> standards) async {
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
      debugPrint('Error parsing ISTE standards list: $e');
      return [];
    }
  }
}
