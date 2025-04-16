import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/features/cultural_context/models/cultural_tradition.dart';

/// Service for managing multiple cultural traditions
class CulturalTraditionService {
  /// Storage service for caching tradition data
  final StorageService _storageService;

  /// Available cultural traditions
  final List<CulturalTradition> _traditions = [];

  /// Currently active tradition
  CulturalTradition? _activeTradition;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new cultural tradition service
  CulturalTraditionService({
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load available traditions
      await _loadTraditions();

      // Load active tradition
      await _loadActiveTradition();

      _isInitialized = true;
      debugPrint('CulturalTraditionService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize CulturalTraditionService: $e');
      throw Exception('Failed to initialize CulturalTraditionService: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Load available traditions
  Future<void> _loadTraditions() async {
    try {
      // In a real app, this would load from a server or asset file
      // For now, we'll just add the Kente tradition as a default

      final kente = CulturalTradition(
        id: 'kente',
        name: 'Kente Weaving',
        region: 'Ghana',
        description: 'Traditional cloth weaving from the Akan people of Ghana',
        historicalContext: 'Kente cloth originated with the Ashanti people in the 17th century and has become a symbol of African cultural heritage worldwide.',
        primaryCraft: 'Weaving',
        keyElements: ['patterns', 'colors', 'symbols'],
        keyValues: ['excellence', 'creativity', 'wisdom', 'unity'],
        iconPath: 'assets/images/cultural/kente_icon.png',
        primaryColor: const Color(0xFFFFD700), // Gold color
        secondaryColor: Colors.black,
        dataFilePaths: {
          'patterns': 'assets/data/patterns_cultural_info.json',
          'symbols': 'assets/data/symbols_cultural_info.json',
          'colors': 'assets/data/colors_cultural_info.json',
          'regions': 'assets/data/regional_info.json',
          'mappings': 'assets/data/cultural_coding_mappings.json',
        },
      );

      _traditions.add(kente);

      // Example of another tradition that could be added in the future
      /*
      final batik = CulturalTradition(
        id: 'batik',
        name: 'Batik',
        region: 'Indonesia',
        description: 'Traditional cloth dyeing using wax-resist methods',
        historicalContext: 'Batik has been practiced for centuries in Indonesia, with each region developing distinctive patterns and techniques.',
        primaryCraft: 'Dyeing',
        keyElements: ['patterns', 'colors', 'motifs'],
        keyValues: ['harmony', 'balance', 'nature', 'spirituality'],
        iconPath: 'assets/images/cultural/batik_icon.png',
        primaryColor: Colors.indigo,
        secondaryColor: Colors.brown,
        dataFilePaths: {
          'patterns': 'assets/data/batik_patterns_info.json',
          'motifs': 'assets/data/batik_motifs_info.json',
          'colors': 'assets/data/batik_colors_info.json',
          'regions': 'assets/data/indonesia_regions_info.json',
          'mappings': 'assets/data/batik_coding_mappings.json',
        },
      );

      _traditions.add(batik);
      */
    } catch (e) {
      debugPrint('Error loading traditions: $e');
      // Create a minimal default if loading fails
      if (_traditions.isEmpty) {
        final defaultTradition = CulturalTradition(
          id: 'kente',
          name: 'Kente Weaving',
          region: 'Ghana',
          description: 'Traditional cloth weaving from the Akan people of Ghana',
          historicalContext: 'Kente cloth originated with the Ashanti people in the 17th century.',
          primaryCraft: 'Weaving',
          keyElements: ['patterns', 'colors'],
          keyValues: ['excellence', 'creativity'],
          iconPath: 'assets/images/cultural/kente_icon.png',
          primaryColor: Colors.amber,
          secondaryColor: Colors.black,
          dataFilePaths: {
            'patterns': 'assets/data/patterns_cultural_info.json',
            'symbols': 'assets/data/symbols_cultural_info.json',
            'colors': 'assets/data/colors_cultural_info.json',
          },
        );

        _traditions.add(defaultTradition);
      }
    }
  }

  /// Load the active tradition
  Future<void> _loadActiveTradition() async {
    try {
      // Check if there's a saved active tradition
      final activeId = await _storageService.getCachedData('active_cultural_tradition');

      if (activeId != null && _traditions.isNotEmpty) {
        // Find the tradition with this ID
        _activeTradition = _traditions.firstWhere(
          (t) => t.id == activeId,
          orElse: () => _traditions.first,
        );
      } else if (_traditions.isNotEmpty) {
        // Default to the first tradition
        _activeTradition = _traditions.first;
      }
    } catch (e) {
      debugPrint('Error loading active tradition: $e');
      // Default to the first tradition if available
      if (_traditions.isNotEmpty) {
        _activeTradition = _traditions.first;
      }
    }
  }

  /// Get all available traditions
  Future<List<CulturalTradition>> getAllTraditions() async {
    await _ensureInitialized();
    return List<CulturalTradition>.from(_traditions);
  }

  /// Get the active tradition
  Future<CulturalTradition?> getActiveTradition() async {
    await _ensureInitialized();
    return _activeTradition;
  }

  /// Set the active tradition
  Future<void> setActiveTradition(String traditionId) async {
    await _ensureInitialized();

    // Find the tradition with this ID
    final tradition = _traditions.firstWhere(
      (t) => t.id == traditionId,
      orElse: () => throw Exception('Tradition not found: $traditionId'),
    );

    // Set as active
    _activeTradition = tradition;

    // Save to storage
    await _storageService.cacheData('active_cultural_tradition', traditionId);

    // Notify listeners (in a real app, this would use a state management solution)
    debugPrint('Active tradition set to: ${tradition.name}');
  }

  /// Get a tradition by ID
  Future<CulturalTradition?> getTraditionById(String traditionId) async {
    await _ensureInitialized();

    try {
      return _traditions.firstWhere((t) => t.id == traditionId);
    } catch (e) {
      return null;
    }
  }

  /// Get cultural elements for the active tradition
  Future<List<CulturalElement>> getElementsForActiveTradition(String elementType) async {
    await _ensureInitialized();

    if (_activeTradition == null) {
      return [];
    }

    // Get the file path for this element type
    final filePath = _activeTradition!.dataFilePaths[elementType];
    if (filePath == null) {
      return [];
    }

    try {
      // Load the data from the asset file
      final jsonString = await rootBundle.loadString(filePath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Convert to cultural elements
      final elements = <CulturalElement>[];

      jsonData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          // Add the tradition ID to each element
          value['tradition'] = _activeTradition!.id;

          // Add a default image path if not present
          if (!value.containsKey('imagePath')) {
            value['imagePath'] = 'assets/images/cultural/${elementType}_$key.png';
          }

          // Add type if not present
          if (!value.containsKey('type')) {
            value['type'] = elementType;
          }

          try {
            elements.add(CulturalElement.fromJson(value));
          } catch (e) {
            debugPrint('Error parsing cultural element: $e');
          }
        }
      });

      return elements;
    } catch (e) {
      debugPrint('Error loading cultural elements: $e');
      return [];
    }
  }

  /// Get cultural elements for a specific tradition
  Future<List<CulturalElement>> getElementsForTradition(
    String traditionId,
    String elementType,
  ) async {
    await _ensureInitialized();

    // Get the tradition
    final tradition = await getTraditionById(traditionId);
    if (tradition == null) {
      return [];
    }

    // Get the file path for this element type
    final filePath = tradition.dataFilePaths[elementType];
    if (filePath == null) {
      return [];
    }

    try {
      // Load the data from the asset file
      final jsonString = await rootBundle.loadString(filePath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Convert to cultural elements
      final elements = <CulturalElement>[];

      jsonData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          // Add the tradition ID to each element
          value['tradition'] = tradition.id;

          // Add a default image path if not present
          if (!value.containsKey('imagePath')) {
            value['imagePath'] = 'assets/images/cultural/${elementType}_$key.png';
          }

          // Add type if not present
          if (!value.containsKey('type')) {
            value['type'] = elementType;
          }

          try {
            elements.add(CulturalElement.fromJson(value));
          } catch (e) {
            debugPrint('Error parsing cultural element: $e');
          }
        }
      });

      return elements;
    } catch (e) {
      debugPrint('Error loading cultural elements: $e');
      return [];
    }
  }

  /// Get cultural elements related to a coding concept
  Future<List<CulturalElement>> getElementsForCodingConcept(
    String conceptId,
    {String? traditionId}
  ) async {
    await _ensureInitialized();

    // Determine which tradition to use
    final tradition = traditionId != null
      ? await getTraditionById(traditionId)
      : _activeTradition;

    if (tradition == null) {
      return [];
    }

    // Get the mappings file path
    final mappingsPath = tradition.dataFilePaths['mappings'];
    if (mappingsPath == null) {
      return [];
    }

    try {
      // Load the mappings data
      final jsonString = await rootBundle.loadString(mappingsPath);
      final mappings = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check if this concept exists in the mappings
      if (!mappings.containsKey('concepts') ||
          !mappings['concepts'].containsKey(conceptId)) {
        return [];
      }

      final conceptData = mappings['concepts'][conceptId] as Map<String, dynamic>;

      // Get the related elements
      final patternIds = conceptData['patterns'] as List<dynamic>? ?? [];
      final symbolIds = conceptData['symbols'] as List<dynamic>? ?? [];
      final colorIds = conceptData['colors'] as List<dynamic>? ?? [];

      // Load the elements
      final elements = <CulturalElement>[];

      // Load patterns
      if (patternIds.isNotEmpty && tradition.dataFilePaths.containsKey('patterns')) {
        final patternsString = await rootBundle.loadString(tradition.dataFilePaths['patterns']!);
        final patternsData = jsonDecode(patternsString) as Map<String, dynamic>;

        for (final id in patternIds) {
          if (patternsData.containsKey(id)) {
            final patternData = patternsData[id] as Map<String, dynamic>;

            // Add required fields
            patternData['tradition'] = tradition.id;
            patternData['type'] = 'pattern';
            patternData['imagePath'] = patternData['imagePath'] ?? 'assets/images/cultural/pattern_$id.png';
            patternData['relatedConcepts'] = [conceptId];
            patternData['educationalValue'] = mappings['patterns'][id]?['educationalValue'] ?? '';

            try {
              elements.add(CulturalElement.fromJson(patternData));
            } catch (e) {
              debugPrint('Error parsing pattern: $e');
            }
          }
        }
      }

      // Load symbols
      if (symbolIds.isNotEmpty && tradition.dataFilePaths.containsKey('symbols')) {
        final symbolsString = await rootBundle.loadString(tradition.dataFilePaths['symbols']!);
        final symbolsData = jsonDecode(symbolsString) as Map<String, dynamic>;

        for (final id in symbolIds) {
          if (symbolsData.containsKey(id)) {
            final symbolData = symbolsData[id] as Map<String, dynamic>;

            // Add required fields
            symbolData['tradition'] = tradition.id;
            symbolData['type'] = 'symbol';
            symbolData['imagePath'] = symbolData['imagePath'] ?? 'assets/images/cultural/symbol_$id.png';
            symbolData['relatedConcepts'] = [conceptId];
            symbolData['educationalValue'] = mappings['symbols'][id]?['educationalValue'] ?? '';

            try {
              elements.add(CulturalElement.fromJson(symbolData));
            } catch (e) {
              debugPrint('Error parsing symbol: $e');
            }
          }
        }
      }

      // Load colors
      if (colorIds.isNotEmpty && tradition.dataFilePaths.containsKey('colors')) {
        final colorsString = await rootBundle.loadString(tradition.dataFilePaths['colors']!);
        final colorsData = jsonDecode(colorsString) as Map<String, dynamic>;

        for (final id in colorIds) {
          if (colorsData.containsKey(id)) {
            final colorData = colorsData[id] as Map<String, dynamic>;

            // Add required fields
            colorData['tradition'] = tradition.id;
            colorData['type'] = 'color';
            colorData['imagePath'] = colorData['imagePath'] ?? 'assets/images/cultural/color_$id.png';
            colorData['relatedConcepts'] = [conceptId];
            colorData['educationalValue'] = mappings['colors'][id]?['educationalValue'] ?? '';

            try {
              elements.add(CulturalElement.fromJson(colorData));
            } catch (e) {
              debugPrint('Error parsing color: $e');
            }
          }
        }
      }

      return elements;
    } catch (e) {
      debugPrint('Error loading elements for concept: $e');
      return [];
    }
  }

  /// Get the cultural connection for a coding concept
  Future<String> getCulturalConnectionForConcept(
    String conceptId,
    {String? traditionId}
  ) async {
    await _ensureInitialized();

    // Determine which tradition to use
    final tradition = traditionId != null
      ? await getTraditionById(traditionId)
      : _activeTradition;

    if (tradition == null) {
      return 'No cultural connection available.';
    }

    // Get the mappings file path
    final mappingsPath = tradition.dataFilePaths['mappings'];
    if (mappingsPath == null) {
      return 'No cultural connection available.';
    }

    try {
      // Load the mappings data
      final jsonString = await rootBundle.loadString(mappingsPath);
      final mappings = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check if this concept exists in the mappings
      if (!mappings.containsKey('concepts') ||
          !mappings['concepts'].containsKey(conceptId)) {
        return 'No cultural connection available for this concept.';
      }

      final conceptData = mappings['concepts'][conceptId] as Map<String, dynamic>;

      return conceptData['culturalConnection'] ?? 'No cultural connection available.';
    } catch (e) {
      debugPrint('Error loading cultural connection: $e');
      return 'Error loading cultural connection.';
    }
  }
}
