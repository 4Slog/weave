import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Removed unused import: storage_service.dart

/// Service for providing cultural context information
class CulturalDataService {
  // Storage service is used in _loadChallenges method
  // Keeping it for future implementation

  /// Random number generator for selecting random cultural info
  final Random _random = Random();

  /// Cache for patterns cultural information
  List<Map<String, dynamic>>? _patternsInfo;

  /// Cache for symbols cultural information
  List<Map<String, dynamic>>? _symbolsInfo;

  /// Cache for colors cultural information
  List<Map<String, dynamic>>? _colorsInfo;

  /// Cache for regional information
  List<Map<String, dynamic>>? _regionalInfo;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new CulturalDataService
  CulturalDataService();

  /// Initialize the service by loading cultural data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load cultural data from asset files
      await _loadPatternsInfo();
      await _loadSymbolsInfo();
      await _loadColorsInfo();
      await _loadRegionalInfo();

      _isInitialized = true;
      debugPrint('CulturalDataService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize CulturalDataService: $e');
      throw Exception('Failed to initialize CulturalDataService: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Load patterns cultural information from asset file
  Future<void> _loadPatternsInfo() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/patterns_cultural_info.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _patternsInfo = jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading patterns info: $e');
      // Create a minimal default set if loading fails
      _patternsInfo = [
        {
          'name': 'Adweneasa',
          'description': 'This pattern symbolizes excellence, creativity, and authenticity in Kente weaving.',
          'significance': 'Worn by royalty and those of high status to signify their excellence and creativity.',
          'region': 'Ashanti Region, Ghana',
          'codingConcept': 'Pattern recognition'
        }
      ];
    }
  }

  /// Load symbols cultural information from asset file
  Future<void> _loadSymbolsInfo() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/symbols_cultural_info.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _symbolsInfo = jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading symbols info: $e');
      // Create a minimal default set if loading fails
      _symbolsInfo = [
        {
          'name': 'Sankofa',
          'description': 'A symbol depicting a bird looking backward, representing the importance of learning from the past.',
          'significance': 'Teaches the importance of learning from history to build a successful future.',
          'codingConcept': 'Recursion and reflection'
        }
      ];
    }
  }

  /// Load colors cultural information from asset file
  Future<void> _loadColorsInfo() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/colors_cultural_info.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _colorsInfo = jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading colors info: $e');
      // Create a minimal default set if loading fails
      _colorsInfo = [
        {
          'color': 'Gold',
          'description': 'Represents wealth, royalty, and spiritual purity.',
          'significance': 'Used in royal garments and for special occasions.',
          'codingConcept': 'Value and importance'
        }
      ];
    }
  }

  /// Load regional information from asset file
  Future<void> _loadRegionalInfo() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/regional_info.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _regionalInfo = jsonData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading regional info: $e');
      // Create a minimal default set if loading fails
      _regionalInfo = [
        {
          'region': 'Ashanti Region',
          'description': 'Home to the Ashanti people, known for their rich cultural heritage and Kente weaving traditions.',
          'significance': 'The Ashanti people are renowned for their Kente cloth, which is woven on a horizontal treadle loom.',
          'codingConcept': 'Cultural algorithms and patterns'
        }
      ];
    }
  }

  /// Get all colors with their cultural meanings
  Future<List<Map<String, dynamic>>> getAllColors() async {
    await _ensureInitialized();
    return _colorsInfo ?? [];
  }

  /// Get all patterns with their cultural meanings
  Future<List<Map<String, dynamic>>> getAllPatterns() async {
    await _ensureInitialized();
    return _patternsInfo ?? [];
  }

  /// Get a random piece of cultural information
  Future<Map<String, dynamic>> getRandomCulturalInfo() async {
    await _ensureInitialized();

    // Combine all cultural info into one list
    final allInfo = [
      ...?_patternsInfo,
      ...?_symbolsInfo,
      ...?_colorsInfo,
      ...?_regionalInfo,
    ];

    // If no info is available, return a default
    if (allInfo.isEmpty) {
      return {
        'description': 'Kente weaving is a traditional craft in Ghana that uses patterns to tell stories and convey cultural values.',
        'codingConcept': 'Pattern recognition'
      };
    }

    // Return a random item from the combined list
    return allInfo[_random.nextInt(allInfo.length)];
  }

  /// Get cultural information related to a specific coding concept
  Future<Map<String, dynamic>> getCulturalInfoForConcept(String concept) async {
    await _ensureInitialized();

    // Combine all cultural info into one list
    final allInfo = [
      ...?_patternsInfo,
      ...?_symbolsInfo,
      ...?_colorsInfo,
      ...?_regionalInfo,
    ];

    // Find items related to the concept
    final relatedInfo = allInfo.where((info) =>
      info['codingConcept']?.toString().toLowerCase().contains(concept.toLowerCase()) ?? false
    ).toList();

    // If no related info is found, return a random item
    if (relatedInfo.isEmpty) {
      return await getRandomCulturalInfo();
    }

    // Return a random item from the related info
    return relatedInfo[_random.nextInt(relatedInfo.length)];
  }
}

