import 'package:flutter/foundation.dart';
import '../../../models/education/k12_framework_element.dart';
import '../base_repository.dart';
import '../storage_strategy.dart';

/// Repository for managing K-12 CS Framework elements.
/// 
/// This repository handles the storage and retrieval of K-12 Computer Science
/// Framework elements.
class K12FrameworkRepository implements BaseRepository {
  final StorageStrategy _storage;
  static const String _elementKeyPrefix = 'k12_framework_';
  static const String _allElementsKey = 'all_k12_framework_elements';
  
  /// Creates a new K12FrameworkRepository.
  /// 
  /// [storage] is the storage strategy to use for data persistence.
  K12FrameworkRepository(this._storage);
  
  @override
  StorageStrategy get storage => _storage;
  
  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }
  
  /// Save a K-12 CS Framework element.
  /// 
  /// [element] is the framework element to save.
  Future<void> saveElement(K12CSFrameworkElement element) async {
    final key = _elementKeyPrefix + element.id;
    await _storage.saveData(key, element.toJson());
    
    // Update the list of all elements
    await _updateElementsList(element.id);
  }
  
  /// Get a K-12 CS Framework element by ID.
  /// 
  /// [elementId] is the ID of the element to retrieve.
  /// Returns the element if found, or null if not found.
  Future<K12CSFrameworkElement?> getElement(String elementId) async {
    final key = _elementKeyPrefix + elementId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return K12CSFrameworkElement.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing K-12 CS Framework element: $e');
      return null;
    }
  }
  
  /// Get all K-12 CS Framework elements.
  /// 
  /// Returns a list of all framework elements.
  Future<List<K12CSFrameworkElement>> getAllElements() async {
    final elementIds = await _getElementIds();
    final elements = <K12CSFrameworkElement>[];
    
    for (final id in elementIds) {
      final element = await getElement(id);
      if (element != null) {
        elements.add(element);
      }
    }
    
    return elements;
  }
  
  /// Get K-12 CS Framework elements by core concept.
  /// 
  /// [coreConcept] is the core concept to filter by (e.g., "Computing Systems").
  /// Returns a list of elements for the specified core concept.
  Future<List<K12CSFrameworkElement>> getElementsByCoreConcept(String coreConcept) async {
    final allElements = await getAllElements();
    return allElements.where((element) => element.coreConcept == coreConcept).toList();
  }
  
  /// Get K-12 CS Framework elements by subconcept.
  /// 
  /// [subconcept] is the subconcept to filter by (e.g., "Devices").
  /// Returns a list of elements for the specified subconcept.
  Future<List<K12CSFrameworkElement>> getElementsBySubconcept(String subconcept) async {
    final allElements = await getAllElements();
    return allElements.where((element) => element.subconcept == subconcept).toList();
  }
  
  /// Get K-12 CS Framework elements by grade band.
  /// 
  /// [gradeBand] is the grade band to filter by (e.g., "K-2", "3-5").
  /// Returns a list of elements for the specified grade band.
  Future<List<K12CSFrameworkElement>> getElementsByGradeBand(String gradeBand) async {
    final allElements = await getAllElements();
    return allElements.where((element) => element.gradeBand == gradeBand).toList();
  }
  
  /// Delete a K-12 CS Framework element.
  /// 
  /// [elementId] is the ID of the element to delete.
  Future<void> deleteElement(String elementId) async {
    final key = _elementKeyPrefix + elementId;
    await _storage.removeData(key);
    
    // Update the list of all elements
    await _removeFromElementsList(elementId);
  }
  
  /// Import a list of K-12 CS Framework elements.
  /// 
  /// [elements] is the list of elements to import.
  /// Returns the number of elements imported.
  Future<int> importElements(List<K12CSFrameworkElement> elements) async {
    int count = 0;
    
    for (final element in elements) {
      await saveElement(element);
      count++;
    }
    
    return count;
  }
  
  /// Helper method to update the list of all elements.
  Future<void> _updateElementsList(String elementId) async {
    final elementIds = await _getElementIds();
    
    if (!elementIds.contains(elementId)) {
      elementIds.add(elementId);
      await _storage.saveData(_allElementsKey, elementIds);
    }
  }
  
  /// Helper method to remove an element from the list of all elements.
  Future<void> _removeFromElementsList(String elementId) async {
    final elementIds = await _getElementIds();
    
    if (elementIds.contains(elementId)) {
      elementIds.remove(elementId);
      await _storage.saveData(_allElementsKey, elementIds);
    }
  }
  
  /// Helper method to get the list of all element IDs.
  Future<List<String>> _getElementIds() async {
    final data = await _storage.getData(_allElementsKey);
    
    if (data == null) return [];
    
    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing K-12 CS Framework elements list: $e');
      return [];
    }
  }
}
