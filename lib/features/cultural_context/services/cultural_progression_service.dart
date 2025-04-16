import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/cultural_context/models/cultural_progression.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_data_service.dart';

/// Service for tracking and managing a user's progression through cultural elements
class CulturalProgressionService {
  /// Storage service for persisting progression data
  final StorageService _storageService;
  
  /// Cultural data service for retrieving cultural information
  final CulturalDataService _culturalDataService;
  
  /// Cache of user progressions
  final Map<String, CulturalProgression> _progressionCache = {};
  
  /// Flag indicating if the service is initialized
  bool _isInitialized = false;
  
  /// Create a new cultural progression service
  CulturalProgressionService({
    StorageService? storageService,
    CulturalDataService? culturalDataService,
  }) : 
    _storageService = storageService ?? StorageService(),
    _culturalDataService = culturalDataService ?? CulturalDataService();
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _culturalDataService.initialize();
    
    _isInitialized = true;
    debugPrint('CulturalProgressionService initialized successfully');
  }
  
  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// Get a user's cultural progression
  Future<CulturalProgression> getUserProgression(String userId) async {
    await _ensureInitialized();
    
    // Check cache first
    if (_progressionCache.containsKey(userId)) {
      return _progressionCache[userId]!;
    }
    
    // Check storage
    final key = 'cultural_progression_$userId';
    final data = await _storageService.getCachedData(key);
    
    if (data != null) {
      final progression = CulturalProgression.fromJson(Map<String, dynamic>.from(data));
      _progressionCache[userId] = progression;
      return progression;
    }
    
    // Create a new progression if none exists
    final newProgression = CulturalProgression(userId: userId);
    _progressionCache[userId] = newProgression;
    
    // Save to storage
    await _storageService.cacheData(key, newProgression.toJson());
    
    return newProgression;
  }
  
  /// Save a user's cultural progression
  Future<void> saveUserProgression(CulturalProgression progression) async {
    await _ensureInitialized();
    
    // Update cache
    _progressionCache[progression.userId] = progression;
    
    // Save to storage
    final key = 'cultural_progression_$progression.userId';
    await _storageService.cacheData(key, progression.toJson());
  }
  
  /// Record exposure to a pattern
  Future<void> recordPatternExposure(String userId, String patternId) async {
    final progression = await getUserProgression(userId);
    final updatedProgression = progression.recordPatternExposure(patternId);
    await saveUserProgression(updatedProgression);
  }
  
  /// Record exposure to a symbol
  Future<void> recordSymbolExposure(String userId, String symbolId) async {
    final progression = await getUserProgression(userId);
    final updatedProgression = progression.recordSymbolExposure(symbolId);
    await saveUserProgression(updatedProgression);
  }
  
  /// Record exposure to a color
  Future<void> recordColorExposure(String userId, String colorId) async {
    final progression = await getUserProgression(userId);
    final updatedProgression = progression.recordColorExposure(colorId);
    await saveUserProgression(updatedProgression);
  }
  
  /// Record exposure to a region
  Future<void> recordRegionExposure(String userId, String regionId) async {
    final progression = await getUserProgression(userId);
    final updatedProgression = progression.recordRegionExposure(regionId);
    await saveUserProgression(updatedProgression);
  }
  
  /// Record teaching a concept with a cultural element
  Future<void> recordConceptTeaching(String userId, String conceptId, String elementId) async {
    final progression = await getUserProgression(userId);
    final updatedProgression = progression.recordConceptTeaching(conceptId, elementId);
    await saveUserProgression(updatedProgression);
  }
  
  /// Get the best pattern to teach a concept
  Future<Map<String, dynamic>> getBestPatternForConcept(String userId, String conceptId) async {
    await _ensureInitialized();
    
    // Get patterns related to this concept
    final patterns = await _culturalDataService.getPatternsForConcept(conceptId);
    if (patterns.isEmpty) {
      return {};
    }
    
    // Get user's progression
    final progression = await getUserProgression(userId);
    
    // Get pattern IDs
    final patternIds = patterns.map((p) => p['id'].toString()).toList();
    
    // Find the least exposed pattern
    final leastExposedId = progression.getLeastExposedPattern(patternIds);
    if (leastExposedId == null) {
      return patterns.first;
    }
    
    // Find the pattern with this ID
    final bestPattern = patterns.firstWhere(
      (p) => p['id'].toString() == leastExposedId,
      orElse: () => patterns.first,
    );
    
    return bestPattern;
  }
  
  /// Get the best symbol to teach a concept
  Future<Map<String, dynamic>> getBestSymbolForConcept(String userId, String conceptId) async {
    await _ensureInitialized();
    
    // Get symbols related to this concept
    final symbols = await _culturalDataService.getSymbolsForConcept(conceptId);
    if (symbols.isEmpty) {
      return {};
    }
    
    // Get user's progression
    final progression = await getUserProgression(userId);
    
    // Get symbol IDs
    final symbolIds = symbols.map((s) => s['id'].toString()).toList();
    
    // Find the least exposed symbol
    final leastExposedId = progression.getLeastExposedSymbol(symbolIds);
    if (leastExposedId == null) {
      return symbols.first;
    }
    
    // Find the symbol with this ID
    final bestSymbol = symbols.firstWhere(
      (s) => s['id'].toString() == leastExposedId,
      orElse: () => symbols.first,
    );
    
    return bestSymbol;
  }
  
  /// Get the best color to teach a concept
  Future<Map<String, dynamic>> getBestColorForConcept(String userId, String conceptId) async {
    await _ensureInitialized();
    
    // Get colors related to this concept
    final colors = await _culturalDataService.getColorsForConcept(conceptId);
    if (colors.isEmpty) {
      return {};
    }
    
    // Get user's progression
    final progression = await getUserProgression(userId);
    
    // Get color IDs
    final colorIds = colors.map((c) => c['id'].toString()).toList();
    
    // Find the least exposed color
    final leastExposedId = progression.getLeastExposedColor(colorIds);
    if (leastExposedId == null) {
      return colors.first;
    }
    
    // Find the color with this ID
    final bestColor = colors.firstWhere(
      (c) => c['id'].toString() == leastExposedId,
      orElse: () => colors.first,
    );
    
    return bestColor;
  }
  
  /// Get cultural elements to teach a concept
  Future<Map<String, dynamic>> getCulturalElementsForConcept(String userId, String conceptId) async {
    await _ensureInitialized();
    
    final bestPattern = await getBestPatternForConcept(userId, conceptId);
    final bestSymbol = await getBestSymbolForConcept(userId, conceptId);
    final bestColor = await getBestColorForConcept(userId, conceptId);
    
    final culturalConnection = await _culturalDataService.getCulturalConnectionForConcept(conceptId);
    
    return {
      'pattern': bestPattern,
      'symbol': bestSymbol,
      'color': bestColor,
      'culturalConnection': culturalConnection,
    };
  }
  
  /// Get a user's cultural diversity score
  Future<double> getUserCulturalDiversityScore(String userId) async {
    final progression = await getUserProgression(userId);
    return progression.getCulturalDiversityScore();
  }
  
  /// Get a user's total cultural exposure count
  Future<int> getUserTotalExposureCount(String userId) async {
    final progression = await getUserProgression(userId);
    return progression.getTotalExposureCount();
  }
  
  /// Get a summary of a user's cultural progression
  Future<Map<String, dynamic>> getUserProgressionSummary(String userId) async {
    final progression = await getUserProgression(userId);
    
    return {
      'totalExposure': progression.getTotalExposureCount(),
      'diversityScore': progression.getCulturalDiversityScore(),
      'patternCount': progression.patternExposure.length,
      'symbolCount': progression.symbolExposure.length,
      'colorCount': progression.colorExposure.length,
      'regionCount': progression.regionExposure.length,
      'conceptCount': progression.conceptTeachingHistory.length,
    };
  }
}
