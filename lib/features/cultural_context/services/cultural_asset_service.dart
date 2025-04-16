import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/services/optimized_asset_loader.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';

/// Service for managing cultural assets
class CulturalAssetService {
  // Singleton implementation
  static final CulturalAssetService _instance = CulturalAssetService._internal();

  factory CulturalAssetService() {
    return _instance;
  }

  CulturalAssetService._internal();
  
  // Dependencies
  late final OptimizedAssetLoader _assetLoader;
  
  // Cache for cultural data
  Map<String, dynamic>? _colorsData;
  Map<String, dynamic>? _patternsData;
  Map<String, dynamic>? _symbolsData;
  Map<String, dynamic>? _regionalData;
  Map<String, dynamic>? _culturalCodingMappings;
  
  // Initialization state
  bool _isInitialized = false;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get dependencies
      _assetLoader = ServiceProvider.get<OptimizedAssetLoader>();
      
      // Load all cultural data
      await Future.wait([
        _loadColorsData(),
        _loadPatternsData(),
        _loadSymbolsData(),
        _loadRegionalData(),
        _loadCulturalCodingMappings(),
      ]);
      
      _isInitialized = true;
      debugPrint('CulturalAssetService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize CulturalAssetService: $e');
    }
  }
  
  /// Load colors cultural data
  Future<void> _loadColorsData() async {
    final data = await _assetLoader.loadJson('assets/data/colors_cultural_info.json');
    _colorsData = data;
  }
  
  /// Load patterns cultural data
  Future<void> _loadPatternsData() async {
    final data = await _assetLoader.loadJson('assets/data/patterns_cultural_info.json');
    _patternsData = data;
  }
  
  /// Load symbols cultural data
  Future<void> _loadSymbolsData() async {
    final data = await _assetLoader.loadJson('assets/data/symbols_cultural_info.json');
    _symbolsData = data;
  }
  
  /// Load regional cultural data
  Future<void> _loadRegionalData() async {
    final data = await _assetLoader.loadJson('assets/data/regional_info.json');
    _regionalData = data;
  }
  
  /// Load cultural coding mappings
  Future<void> _loadCulturalCodingMappings() async {
    final data = await _assetLoader.loadJson('assets/data/cultural_coding_mappings.json');
    _culturalCodingMappings = data;
  }
  
  /// Get color information by ID
  Map<String, dynamic>? getColorInfo(String colorId) {
    if (_colorsData == null) return null;
    
    final colors = _colorsData!['colors'] as List<dynamic>;
    try {
      return colors.firstWhere(
        (color) => color['id'] == colorId,
      ) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Get pattern information by ID
  Map<String, dynamic>? getPatternInfo(String patternId) {
    if (_patternsData == null) return null;
    
    final patterns = _patternsData!['patterns'] as List<dynamic>;
    try {
      return patterns.firstWhere(
        (pattern) => pattern['id'] == patternId,
      ) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Get cultural coding mapping for a concept
  Map<String, dynamic>? getCulturalCodingForConcept(String conceptId) {
    if (_culturalCodingMappings == null) return null;
    
    final concepts = _culturalCodingMappings!['concepts'] as Map<String, dynamic>;
    return concepts[conceptId] as Map<String, dynamic>?;
  }
  
  /// Get pattern image path
  String getPatternImagePath(String patternId) {
    return 'assets/images/patterns/${patternId}.png';
  }
  
  /// Get cultural concepts related to a pattern
  List<String> getConceptsForPattern(String patternId) {
    if (_culturalCodingMappings == null) return [];
    
    final patterns = _culturalCodingMappings!['patterns'] as Map<String, dynamic>;
    final patternData = patterns[patternId] as Map<String, dynamic>?;
    
    if (patternData == null) return [];
    
    return List<String>.from(patternData['concepts'] as List<dynamic>);
  }
  
  /// Get educational value for a pattern
  String? getEducationalValueForPattern(String patternId) {
    if (_culturalCodingMappings == null) return null;
    
    final patterns = _culturalCodingMappings!['patterns'] as Map<String, dynamic>;
    final patternData = patterns[patternId] as Map<String, dynamic>?;
    
    if (patternData == null) return null;
    
    return patternData['educationalValue'] as String?;
  }
  
  /// Get all pattern IDs
  List<String> getAllPatternIds() {
    if (_patternsData == null) return [];
    
    final patterns = _patternsData!['patterns'] as List<dynamic>;
    return patterns.map((pattern) => pattern['id'] as String).toList();
  }
  
  /// Get all color IDs
  List<String> getAllColorIds() {
    if (_colorsData == null) return [];
    
    final colors = _colorsData!['colors'] as List<dynamic>;
    return colors.map((color) => color['id'] as String).toList();
  }
  
  /// Get all concept IDs
  List<String> getAllConceptIds() {
    if (_culturalCodingMappings == null) return [];
    
    final concepts = _culturalCodingMappings!['concepts'] as Map<String, dynamic>;
    return concepts.keys.toList();
  }
  
  /// Preload all pattern images
  Future<void> preloadAllPatternImages() async {
    final patternIds = getAllPatternIds();
    
    for (final patternId in patternIds) {
      final imagePath = getPatternImagePath(patternId);
      await _assetLoader.loadImage(imagePath);
    }
  }
}
