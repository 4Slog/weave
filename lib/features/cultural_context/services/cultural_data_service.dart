import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Cache for cultural-coding mappings
  Map<String, dynamic>? _culturalCodingMappings;

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
      await _loadCulturalCodingMappings();

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
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // Convert map to list of maps
      _patternsInfo = jsonMap.entries.map((entry) {
        final Map<String, dynamic> value = entry.value;
        // Add the key as id if not present
        if (!value.containsKey('id')) {
          value['id'] = entry.key;
        }
        return value;
      }).toList();
    } catch (e) {
      debugPrint('Error loading patterns info: $e');
      // Create a minimal default set if loading fails
      _patternsInfo = [
        {
          'id': 'adweneasa',
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
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // Convert map to list of maps
      _symbolsInfo = jsonMap.entries.map((entry) {
        final Map<String, dynamic> value = entry.value;
        // Add the key as id if not present
        if (!value.containsKey('id')) {
          value['id'] = entry.key;
        }
        return value;
      }).toList();
    } catch (e) {
      debugPrint('Error loading symbols info: $e');
      // Create a minimal default set if loading fails
      _symbolsInfo = [
        {
          'id': 'sankofa',
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
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // Convert map to list of maps
      _colorsInfo = jsonMap.entries.map((entry) {
        final Map<String, dynamic> value = entry.value;
        // Add the key as id if not present
        if (!value.containsKey('id')) {
          value['id'] = entry.key;
        }
        return value;
      }).toList();
    } catch (e) {
      debugPrint('Error loading colors info: $e');
      // Create a minimal default set if loading fails
      _colorsInfo = [
        {
          'id': 'gold',
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
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // Convert map to list of maps
      _regionalInfo = jsonMap.entries.map((entry) {
        final Map<String, dynamic> value = entry.value;
        // Add the key as id if not present
        if (!value.containsKey('id')) {
          value['id'] = entry.key;
        }
        return value;
      }).toList();
    } catch (e) {
      debugPrint('Error loading regional info: $e');
      // Create a minimal default set if loading fails
      _regionalInfo = [
        {
          'id': 'ashanti',
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

  /// Load cultural-coding mappings from asset file
  Future<void> _loadCulturalCodingMappings() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/cultural_coding_mappings.json');
      _culturalCodingMappings = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading cultural-coding mappings: $e');
      // Create a minimal default mapping if loading fails
      _culturalCodingMappings = {
        'concepts': {},
        'patterns': {},
        'symbols': {},
        'colors': {}
      };
    }
  }

  /// Get cultural information related to a specific coding concept
  Future<Map<String, dynamic>> getCulturalInfoForConcept(String concept) async {
    await _ensureInitialized();

    // Check if we have mappings for this concept
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['concepts'] != null &&
        _culturalCodingMappings!['concepts'][concept] != null) {

      return _culturalCodingMappings!['concepts'][concept];
    }

    // If no mapping exists, use the old method as fallback
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

  /// Get patterns related to a specific coding concept
  Future<List<Map<String, dynamic>>> getPatternsForConcept(String concept) async {
    await _ensureInitialized();

    // Check if we have mappings for this concept
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['concepts'] != null &&
        _culturalCodingMappings!['concepts'][concept] != null) {

      final conceptData = _culturalCodingMappings!['concepts'][concept];
      final patternIds = conceptData['patterns'] as List<dynamic>? ?? [];

      // Get full pattern data for each pattern ID
      final patterns = <Map<String, dynamic>>[];
      for (final patternId in patternIds) {
        final patternData = await getPatternById(patternId);
        if (patternData.isNotEmpty) {
          patterns.add(patternData);
        }
      }

      return patterns;
    }

    // Fallback to searching by concept mention
    return (_patternsInfo ?? []).where((pattern) =>
      pattern['codingConcept']?.toString().toLowerCase().contains(concept.toLowerCase()) ?? false
    ).toList();
  }

  /// Get symbols related to a specific coding concept
  Future<List<Map<String, dynamic>>> getSymbolsForConcept(String concept) async {
    await _ensureInitialized();

    // Check if we have mappings for this concept
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['concepts'] != null &&
        _culturalCodingMappings!['concepts'][concept] != null) {

      final conceptData = _culturalCodingMappings!['concepts'][concept];
      final symbolIds = conceptData['symbols'] as List<dynamic>? ?? [];

      // Get full symbol data for each symbol ID
      final symbols = <Map<String, dynamic>>[];
      for (final symbolId in symbolIds) {
        final symbolData = await getSymbolById(symbolId);
        if (symbolData.isNotEmpty) {
          symbols.add(symbolData);
        }
      }

      return symbols;
    }

    // Fallback to searching by concept mention
    return (_symbolsInfo ?? []).where((symbol) =>
      symbol['codingConcept']?.toString().toLowerCase().contains(concept.toLowerCase()) ?? false
    ).toList();
  }

  /// Get colors related to a specific coding concept
  Future<List<Map<String, dynamic>>> getColorsForConcept(String concept) async {
    await _ensureInitialized();

    // Check if we have mappings for this concept
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['concepts'] != null &&
        _culturalCodingMappings!['concepts'][concept] != null) {

      final conceptData = _culturalCodingMappings!['concepts'][concept];
      final colorIds = conceptData['colors'] as List<dynamic>? ?? [];

      // Get full color data for each color ID
      final colors = <Map<String, dynamic>>[];
      for (final colorId in colorIds) {
        final colorData = await getColorById(colorId);
        if (colorData.isNotEmpty) {
          colors.add(colorData);
        }
      }

      return colors;
    }

    // Fallback to searching by concept mention
    return (_colorsInfo ?? []).where((color) =>
      color['codingConcept']?.toString().toLowerCase().contains(concept.toLowerCase()) ?? false
    ).toList();
  }

  /// Get pattern by ID
  Future<Map<String, dynamic>> getPatternById(String id) async {
    await _ensureInitialized();

    // Convert patterns info to a map for easier lookup
    final patternsMap = {};
    for (final pattern in _patternsInfo ?? []) {
      if (pattern['id'] != null) {
        patternsMap[pattern['id']] = pattern;
      }
    }

    return patternsMap[id] ?? {};
  }

  /// Get symbol by ID
  Future<Map<String, dynamic>> getSymbolById(String id) async {
    await _ensureInitialized();

    // Convert symbols info to a map for easier lookup
    final symbolsMap = {};
    for (final symbol in _symbolsInfo ?? []) {
      if (symbol['id'] != null) {
        symbolsMap[symbol['id']] = symbol;
      }
    }

    return symbolsMap[id] ?? {};
  }

  /// Get color by ID
  Future<Map<String, dynamic>> getColorById(String id) async {
    await _ensureInitialized();

    // Convert colors info to a map for easier lookup
    final colorsMap = {};
    for (final color in _colorsInfo ?? []) {
      if (color['id'] != null) {
        colorsMap[color['id']] = color;
      }
    }

    return colorsMap[id] ?? {};
  }

  /// Get coding concepts related to a specific pattern
  Future<List<Map<String, dynamic>>> getConceptsForPattern(String patternId) async {
    await _ensureInitialized();

    // Check if we have mappings for this pattern
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['patterns'] != null &&
        _culturalCodingMappings!['patterns'][patternId] != null) {

      final patternData = _culturalCodingMappings!['patterns'][patternId];
      final conceptIds = patternData['concepts'] as List<dynamic>? ?? [];

      // Get full concept data for each concept ID
      final concepts = <Map<String, dynamic>>[];
      for (final conceptId in conceptIds) {
        if (_culturalCodingMappings!['concepts'][conceptId] != null) {
          concepts.add(_culturalCodingMappings!['concepts'][conceptId]);
        }
      }

      return concepts;
    }

    return [];
  }

  /// Get coding concepts related to a specific symbol
  Future<List<Map<String, dynamic>>> getConceptsForSymbol(String symbolId) async {
    await _ensureInitialized();

    // Check if we have mappings for this symbol
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['symbols'] != null &&
        _culturalCodingMappings!['symbols'][symbolId] != null) {

      final symbolData = _culturalCodingMappings!['symbols'][symbolId];
      final conceptIds = symbolData['concepts'] as List<dynamic>? ?? [];

      // Get full concept data for each concept ID
      final concepts = <Map<String, dynamic>>[];
      for (final conceptId in conceptIds) {
        if (_culturalCodingMappings!['concepts'][conceptId] != null) {
          concepts.add(_culturalCodingMappings!['concepts'][conceptId]);
        }
      }

      return concepts;
    }

    return [];
  }

  /// Get coding concepts related to a specific color
  Future<List<Map<String, dynamic>>> getConceptsForColor(String colorId) async {
    await _ensureInitialized();

    // Check if we have mappings for this color
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['colors'] != null &&
        _culturalCodingMappings!['colors'][colorId] != null) {

      final colorData = _culturalCodingMappings!['colors'][colorId];
      final conceptIds = colorData['concepts'] as List<dynamic>? ?? [];

      // Get full concept data for each concept ID
      final concepts = <Map<String, dynamic>>[];
      for (final conceptId in conceptIds) {
        if (_culturalCodingMappings!['concepts'][conceptId] != null) {
          concepts.add(_culturalCodingMappings!['concepts'][conceptId]);
        }
      }

      return concepts;
    }

    return [];
  }

  /// Get educational value of a pattern for a specific coding concept
  Future<String> getPatternEducationalValue(String patternId) async {
    await _ensureInitialized();

    // Check if we have mappings for this pattern
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['patterns'] != null &&
        _culturalCodingMappings!['patterns'][patternId] != null) {

      final patternData = _culturalCodingMappings!['patterns'][patternId];
      return patternData['educationalValue'] ?? 'No educational value information available.';
    }

    return 'No educational value information available.';
  }

  /// Get educational value of a symbol for a specific coding concept
  Future<String> getSymbolEducationalValue(String symbolId) async {
    await _ensureInitialized();

    // Check if we have mappings for this symbol
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['symbols'] != null &&
        _culturalCodingMappings!['symbols'][symbolId] != null) {

      final symbolData = _culturalCodingMappings!['symbols'][symbolId];
      return symbolData['educationalValue'] ?? 'No educational value information available.';
    }

    return 'No educational value information available.';
  }

  /// Get educational value of a color for a specific coding concept
  Future<String> getColorEducationalValue(String colorId) async {
    await _ensureInitialized();

    // Check if we have mappings for this color
    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['colors'] != null &&
        _culturalCodingMappings!['colors'][colorId] != null) {

      final colorData = _culturalCodingMappings!['colors'][colorId];
      return colorData['educationalValue'] ?? 'No educational value information available.';
    }

    return 'No educational value information available.';
  }

  /// Get all available coding concepts
  Future<List<Map<String, dynamic>>> getAllCodingConcepts() async {
    await _ensureInitialized();

    if (_culturalCodingMappings != null && _culturalCodingMappings!['concepts'] != null) {
      final concepts = <Map<String, dynamic>>[];

      _culturalCodingMappings!['concepts'].forEach((key, value) {
        concepts.add({
          'id': key,
          ...value,
        });
      });

      return concepts;
    }

    return [];
  }

  /// Get cultural connection for a specific coding concept
  Future<String> getCulturalConnectionForConcept(String conceptId) async {
    await _ensureInitialized();

    if (_culturalCodingMappings != null &&
        _culturalCodingMappings!['concepts'] != null &&
        _culturalCodingMappings!['concepts'][conceptId] != null) {

      return _culturalCodingMappings!['concepts'][conceptId]['culturalConnection'] ??
             'No cultural connection information available.';
    }

    return 'No cultural connection information available.';
  }
}

