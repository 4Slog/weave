import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

/// Service for managing cultural data and information
class CulturalDataService {
  // Singleton implementation
  static final CulturalDataService _instance = CulturalDataService._internal();
  
  factory CulturalDataService() {
    return _instance;
  }
  
  CulturalDataService._internal();
  
  // Cached data
  Map<String, dynamic> _colorsData = {};
  Map<String, dynamic> _patternsData = {};
  Map<String, dynamic> _symbolsData = {};
  Map<String, dynamic> _regionalData = {};
  
  // Initialization state
  bool _isInitialized = false;
  
  // Asset paths
  static const String _colorsDataPath = 'assets/data/colors_cultural_info.json';
  static const String _patternsDataPath = 'assets/data/patterns_cultural_info.json';
  static const String _symbolsDataPath = 'assets/data/symbols_cultural_info.json';
  static const String _regionalDataPath = 'assets/data/regional_info.json';
  
  /// Initialize the service by loading all data files
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load all cultural data files
      _colorsData = await _loadJsonAsset(_colorsDataPath);
      _patternsData = await _loadJsonAsset(_patternsDataPath);
      _symbolsData = await _loadJsonAsset(_symbolsDataPath);
      _regionalData = await _loadJsonAsset(_regionalDataPath);
      
      _isInitialized = true;
      debugPrint('Cultural data service initialized');
    } catch (e) {
      debugPrint('Error initializing cultural data service: $e');
      rethrow;
    }
  }
  
  /// Load JSON data from an asset file
  Future<Map<String, dynamic>> _loadJsonAsset(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Error loading JSON asset $path: $e');
      return {};
    }
  }
  
  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Get color information by color name
  Future<Map<String, dynamic>?> getColorInfo(String colorName) async {
    await _ensureInitialized();
    
    if (_colorsData.containsKey('colors')) {
      final colorsList = _colorsData['colors'] as List<dynamic>;
      
      for (var color in colorsList) {
        if (color is Map<String, dynamic> && 
            color['name'].toString().toLowerCase() == colorName.toLowerCase()) {
          return color;
        }
      }
    }
    
    return null;
  }
  
  /// Get all available colors information
  Future<List<Map<String, dynamic>>> getAllColors() async {
    await _ensureInitialized();
    
    if (_colorsData.containsKey('colors')) {
      return List<Map<String, dynamic>>.from(_colorsData['colors']);
    }
    
    return [];
  }
  
  /// Get pattern information by pattern name
  Future<Map<String, dynamic>?> getPatternInfo(String patternName) async {
    await _ensureInitialized();
    
    if (_patternsData.containsKey('patterns')) {
      final patternsList = _patternsData['patterns'] as List<dynamic>;
      
      for (var pattern in patternsList) {
        if (pattern is Map<String, dynamic> && 
            pattern['name'].toString().toLowerCase() == patternName.toLowerCase()) {
          return pattern;
        }
      }
    }
    
    return null;
  }
  
  /// Get all available patterns information
  Future<List<Map<String, dynamic>>> getAllPatterns() async {
    await _ensureInitialized();
    
    if (_patternsData.containsKey('patterns')) {
      return List<Map<String, dynamic>>.from(_patternsData['patterns']);
    }
    
    return [];
  }
  
  /// Get symbol information by symbol name
  Future<Map<String, dynamic>?> getSymbolInfo(String symbolName) async {
    await _ensureInitialized();
    
    if (_symbolsData.containsKey('symbols')) {
      final symbolsList = _symbolsData['symbols'] as List<dynamic>;
      
      for (var symbol in symbolsList) {
        if (symbol is Map<String, dynamic> && 
            symbol['name'].toString().toLowerCase() == symbolName.toLowerCase()) {
          return symbol;
        }
      }
    }
    
    return null;
  }
  
  /// Get all available symbols information
  Future<List<Map<String, dynamic>>> getAllSymbols() async {
    await _ensureInitialized();
    
    if (_symbolsData.containsKey('symbols')) {
      return List<Map<String, dynamic>>.from(_symbolsData['symbols']);
    }
    
    return [];
  }
  
  /// Get regional information by region name
  Future<Map<String, dynamic>?> getRegionInfo(String regionName) async {
    await _ensureInitialized();
    
    if (_regionalData.containsKey('regions')) {
      final regionsList = _regionalData['regions'] as List<dynamic>;
      
      for (var region in regionsList) {
        if (region is Map<String, dynamic> && 
            region['name'].toString().toLowerCase() == regionName.toLowerCase()) {
          return region;
        }
      }
    }
    
    return null;
  }
  
  /// Get all available regions information
  Future<List<Map<String, dynamic>>> getAllRegions() async {
    await _ensureInitialized();
    
    if (_regionalData.containsKey('regions')) {
      return List<Map<String, dynamic>>.from(_regionalData['regions']);
    }
    
    return [];
  }
  
  /// Get a random cultural fact
  Future<String?> getRandomCulturalFact() async {
    await _ensureInitialized();
    
    List<String> facts = [];
    
    // Collect facts from all data sources
    if (_colorsData.containsKey('facts')) {
      facts.addAll(List<String>.from(_colorsData['facts']));
    }
    
    if (_patternsData.containsKey('facts')) {
      facts.addAll(List<String>.from(_patternsData['facts']));
    }
    
    if (_symbolsData.containsKey('facts')) {
      facts.addAll(List<String>.from(_symbolsData['facts']));
    }
    
    if (_regionalData.containsKey('facts')) {
      facts.addAll(List<String>.from(_regionalData['facts']));
    }
    
    if (facts.isEmpty) {
      return null;
    }
    
    // Return a random fact
    facts.shuffle();
    return facts.first;
  }
  
  /// Get cultural information for a specific block type
  Future<Map<String, dynamic>?> getBlockCulturalInfo(String blockType) async {
    await _ensureInitialized();
    
    // Check all data sources for information about this block type
    for (var dataSource in [_patternsData, _symbolsData, _colorsData]) {
      if (dataSource.containsKey('blockTypes')) {
        final blockTypes = dataSource['blockTypes'] as Map<String, dynamic>?;
        if (blockTypes != null && blockTypes.containsKey(blockType)) {
          return blockTypes[blockType];
        }
      }
    }
    
    return null;
  }
  
  /// Get story context for a region
  Future<Map<String, dynamic>?> getRegionalStoryContext(String regionName) async {
    await _ensureInitialized();
    
    final regionInfo = await getRegionInfo(regionName);
    if (regionInfo != null && regionInfo.containsKey('storyContext')) {
      return regionInfo['storyContext'];
    }
    
    return null;
  }
  
  /// Search for cultural information across all data
  Future<List<Map<String, dynamic>>> searchCulturalData(String query) async {
    await _ensureInitialized();
    
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();
    
    // Search in colors
    if (_colorsData.containsKey('colors')) {
      final colorsList = List<Map<String, dynamic>>.from(_colorsData['colors']);
      
      for (var color in colorsList) {
        if (color['name'].toString().toLowerCase().contains(lowerQuery) ||
            color['meaning'].toString().toLowerCase().contains(lowerQuery)) {
          results.add({
            'type': 'color',
            'data': color,
          });
        }
      }
    }
    
    // Search in patterns
    if (_patternsData.containsKey('patterns')) {
      final patternsList = List<Map<String, dynamic>>.from(_patternsData['patterns']);
      
      for (var pattern in patternsList) {
        if (pattern['name'].toString().toLowerCase().contains(lowerQuery) ||
            pattern['description'].toString().toLowerCase().contains(lowerQuery)) {
          results.add({
            'type': 'pattern',
            'data': pattern,
          });
        }
      }
    }
    
    // Search in symbols
    if (_symbolsData.containsKey('symbols')) {
      final symbolsList = List<Map<String, dynamic>>.from(_symbolsData['symbols']);
      
      for (var symbol in symbolsList) {
        if (symbol['name'].toString().toLowerCase().contains(lowerQuery) ||
            symbol['meaning'].toString().toLowerCase().contains(lowerQuery)) {
          results.add({
            'type': 'symbol',
            'data': symbol,
          });
        }
      }
    }
    
    // Search in regions
    if (_regionalData.containsKey('regions')) {
      final regionsList = List<Map<String, dynamic>>.from(_regionalData['regions']);
      
      for (var region in regionsList) {
        if (region['name'].toString().toLowerCase().contains(lowerQuery) ||
            region['description'].toString().toLowerCase().contains(lowerQuery)) {
          results.add({
            'type': 'region',
            'data': region,
          });
        }
      }
    }
    
    return results;
  }
}