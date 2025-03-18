import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/block_type.dart';

/// Service for managing cultural data and information related to Kente weaving traditions.
/// 
/// This service provides access to cultural information about patterns, colors, symbols,
/// regions, and makes connections between coding blocks and their cultural significance.
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
  
  // Block cultural relationships
  Map<String, Map<String, dynamic>> _blockCulturalMapping = {};
  
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
      await Future.wait([
        _loadColorsData(),
        _loadPatternsData(), 
        _loadSymbolsData(),
        _loadRegionalData(),
      ]);
      
      // Build block cultural mappings once all data is loaded
      _buildBlockCulturalMappings();
      
      _isInitialized = true;
      debugPrint('Cultural data service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing cultural data service: $e');
      rethrow;
    }
  }
  
  /// Load colors data from assets
  Future<void> _loadColorsData() async {
    try {
      final jsonString = await rootBundle.loadString(_colorsDataPath);
      _colorsData = jsonDecode(jsonString);
      debugPrint('Colors data loaded: ${_colorsData.length} entries');
    } catch (e) {
      debugPrint('Error loading colors data: $e');
      _colorsData = {'colors': []};
    }
  }
  
  /// Load patterns data from assets
  Future<void> _loadPatternsData() async {
    try {
      final jsonString = await rootBundle.loadString(_patternsDataPath);
      _patternsData = jsonDecode(jsonString);
      debugPrint('Patterns data loaded: ${_patternsData.length} entries');
    } catch (e) {
      debugPrint('Error loading patterns data: $e');
      _patternsData = {'patterns': []};
    }
  }
  
  /// Load symbols data from assets
  Future<void> _loadSymbolsData() async {
    try {
      final jsonString = await rootBundle.loadString(_symbolsDataPath);
      _symbolsData = jsonDecode(jsonString);
      debugPrint('Symbols data loaded: ${_symbolsData.length} entries');
    } catch (e) {
      debugPrint('Error loading symbols data: $e');
      _symbolsData = {'symbols': []};
    }
  }
  
  /// Load regional data from assets
  Future<void> _loadRegionalData() async {
    try {
      final jsonString = await rootBundle.loadString(_regionalDataPath);
      _regionalData = jsonDecode(jsonString);
      debugPrint('Regional data loaded: ${_regionalData.length} entries');
    } catch (e) {
      debugPrint('Error loading regional data: $e');
      _regionalData = {'regions': []};
    }
  }
  
  /// Build mappings between block types and cultural information
  void _buildBlockCulturalMappings() {
    // Map pattern blocks to pattern cultural information
    if (_patternsData.containsKey('patterns')) {
      for (var pattern in _patternsData['patterns']) {
        final patternId = pattern['id'] ?? '';
        if (patternId.isNotEmpty) {
          _blockCulturalMapping['pattern_$patternId'] = {
            'type': 'pattern',
            'name': pattern['name'] ?? '',
            'englishName': pattern['englishName'] ?? '',
            'culturalSignificance': pattern['culturalSignificance'] ?? '',
            'region': pattern['region'] ?? '',
            'historicalContext': pattern['historicalContext'] ?? '',
            'codingConcept': _mapPatternToCodingConcept(patternId),
          };
        }
      }
    }
    
    // Map color blocks to color cultural information
    if (_colorsData.containsKey('colors')) {
      for (var color in _colorsData['colors']) {
        final colorId = color['id'] ?? '';
        if (colorId.isNotEmpty) {
          _blockCulturalMapping['color_$colorId'] = {
            'type': 'color',
            'name': color['name'] ?? '',
            'englishName': color['englishName'] ?? '',
            'culturalMeaning': color['culturalMeaning'] ?? '',
            'traditionalSources': color['traditionalSources'] ?? [],
            'traditionalUses': color['traditionalUses'] ?? [],
            'codingConcept': 'variables',
          };
        }
      }
    }
    
    // Map structure blocks to appropriate cultural information
    _blockCulturalMapping['structure_grid'] = {
      'type': 'structure',
      'name': 'Grid Structure',
      'englishName': 'Grid Layout',
      'culturalSignificance': 'Represents the loom structure that forms the foundation of Kente weaving. The grid is essential for organizing patterns and maintaining consistency.',
      'codingConcept': 'data structures',
    };
    
    // Map loop blocks to cultural repetition patterns
    _blockCulturalMapping['loop_repeat'] = {
      'type': 'loop',
      'name': 'Nkyinkyim',
      'englishName': 'Repeating Pattern',
      'culturalSignificance': 'In Kente weaving, repeated patterns symbolize life\'s continuity and the cyclic nature of existence. The repetition of motifs strengthens the symbolic meaning.',
      'codingConcept': 'loops and iteration',
    };
    
    // Add more mappings as needed
    _blockCulturalMapping['column_block'] = {
      'type': 'column',
      'name': 'Nsaka',
      'englishName': 'Column Structure',
      'culturalSignificance': 'Vertical strips in Kente cloth represent strength and social structure. The alignment of elements supports the overall pattern integrity.',
      'codingConcept': 'arrays and sequences',
    };
  }
  
  /// Map pattern types to coding concepts
  String _mapPatternToCodingConcept(String patternId) {
    switch (patternId.toLowerCase()) {
      case 'checker_pattern':
        return 'conditionals';
      case 'zigzag_pattern':
        return 'loops';
      case 'diamond_pattern':
        return 'nested structures';
      case 'stripes_pattern':
        return 'arrays';
      default:
        return 'patterns';
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
            (color['name'].toString().toLowerCase() == colorName.toLowerCase() ||
             color['id'].toString().toLowerCase() == colorName.toLowerCase() ||
             color['englishName'].toString().toLowerCase() == colorName.toLowerCase())) {
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
            (pattern['name'].toString().toLowerCase() == patternName.toLowerCase() ||
             pattern['id'].toString().toLowerCase() == patternName.toLowerCase() ||
             pattern['englishName'].toString().toLowerCase() == patternName.toLowerCase())) {
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
            (symbol['name'].toString().toLowerCase() == symbolName.toLowerCase() ||
             symbol['id'].toString().toLowerCase() == symbolName.toLowerCase() ||
             symbol['englishName'].toString().toLowerCase() == symbolName.toLowerCase())) {
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
            (region['name'].toString().toLowerCase() == regionName.toLowerCase() ||
             region['id'].toString().toLowerCase() == regionName.toLowerCase() ||
             region['englishName'].toString().toLowerCase() == regionName.toLowerCase())) {
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
    for (var dataSource in [_colorsData, _patternsData, _symbolsData, _regionalData]) {
      if (dataSource.containsKey('facts')) {
        facts.addAll(List<String>.from(dataSource['facts']));
      }
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
    
    // Check the block cultural mapping
    if (_blockCulturalMapping.containsKey(blockType)) {
      return _blockCulturalMapping[blockType];
    }
    
    return null;
  }
  
  /// Get cultural context for a specific block
  Future<Map<String, dynamic>?> getBlockCultureContext(BlockModel block) async {
    await _ensureInitialized();
    
    String mappingKey = '';
    
    // Build the mapping key based on block type and properties
    switch (block.type) {
      case BlockType.pattern:
        final patternType = block.properties['patternType'] ?? 'checker';
        mappingKey = 'pattern_${patternType}_pattern';
        break;
      case BlockType.color:
        final color = block.properties['color'] ?? 'black';
        mappingKey = 'color_$color';
        break;
      case BlockType.structure:
        final structureType = block.properties['structureType'] ?? 'grid';
        mappingKey = 'structure_$structureType';
        break;
      case BlockType.loop:
        mappingKey = 'loop_repeat';
        break;
      case BlockType.column:
        mappingKey = 'column_block';
        break;
      default:
        mappingKey = 'unknown';
    }
    
    // Try exact match first
    if (_blockCulturalMapping.containsKey(mappingKey)) {
      return _blockCulturalMapping[mappingKey];
    }
    
    // Try more generic match
    final genericKey = mappingKey.split('_')[0];
    for (var key in _blockCulturalMapping.keys) {
      if (key.startsWith(genericKey)) {
        return _blockCulturalMapping[key];
      }
    }
    
    return null;
  }
  
  /// Get coding concept for a block
  Future<String?> getBlockCodingConcept(BlockModel block) async {
    final culturalContext = await getBlockCultureContext(block);
    if (culturalContext != null && culturalContext.containsKey('codingConcept')) {
      return culturalContext['codingConcept'] as String?;
    }
    
    // Return default concepts if none found in cultural mapping
    switch (block.type) {
      case BlockType.pattern:
        return 'patterns and sequences';
      case BlockType.color:
        return 'variables and values';
      case BlockType.structure:
        return 'data structures';
      case BlockType.loop:
        return 'loops and iteration';
      case BlockType.column:
        return 'arrays and sequences';
      default:
        return 'coding concepts';
    }
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
            color['englishName'].toString().toLowerCase().contains(lowerQuery) ||
            color['culturalMeaning'].toString().toLowerCase().contains(lowerQuery)) {
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
            pattern['englishName'].toString().toLowerCase().contains(lowerQuery) ||
            pattern['description'].toString().toLowerCase().contains(lowerQuery) ||
            pattern['culturalSignificance'].toString().toLowerCase().contains(lowerQuery)) {
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
            symbol['englishName'].toString().toLowerCase().contains(lowerQuery) ||
            symbol['description'].toString().toLowerCase().contains(lowerQuery) ||
            symbol['culturalSignificance'].toString().toLowerCase().contains(lowerQuery)) {
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
            region['englishName'].toString().toLowerCase().contains(lowerQuery) ||
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
  
  /// Generate learning prompt that connects block type with cultural context and coding concept
  Future<String> generateCulturalLearningPrompt(BlockModel block) async {
    final culturalContext = await getBlockCultureContext(block);
    if (culturalContext == null) {
      return "This block represents an important element in Kente weaving.";
    }
    
    final blockType = block.type.toString().split('.').last;
    final culturalSignificance = culturalContext['culturalSignificance'] ?? 
                               culturalContext['culturalMeaning'] ?? 
                               "represents an element of traditional Kente weaving";
    final codingConcept = culturalContext['codingConcept'] ?? "coding concept";
    final name = culturalContext['name'] ?? culturalContext['englishName'] ?? blockType;
    
    return "This $blockType block represents \"$name\" in Kente weaving tradition. "
           "$culturalSignificance "
           "In coding, this connects to the $codingConcept concept, showing how "
           "traditional craft wisdom and computational thinking share similar patterns.";
  }
  
  /// Generate a hint about a block's cultural significance
  Future<String> generateCulturalHint(BlockModel block) async {
    final culturalContext = await getBlockCultureContext(block);
    if (culturalContext == null) {
      return "Try exploring how this block relates to Kente weaving traditions.";
    }
    
    final type = culturalContext['type'] ?? block.type.toString().split('.').last;
    final name = culturalContext['name'] ?? culturalContext['englishName'] ?? type;
    
    switch (block.type) {
      case BlockType.pattern:
        return "The \"$name\" pattern in Kente weaving symbolizes ${_getTruncatedSignificance(culturalContext)}";
      case BlockType.color:
        return "In Kente cloth, the color \"$name\" represents ${_getTruncatedSignificance(culturalContext)}";
      case BlockType.loop:
        return "Repetition in Kente weaving, represented by the \"$name\" concept, symbolizes continuity and ${_getTruncatedSignificance(culturalContext)}";
      case BlockType.structure:
        return "The structure you're creating mirrors how Kente weavers organize their patterns to ${_getTruncatedSignificance(culturalContext)}";
      case BlockType.column:
        return "Vertical elements in Kente weaving, like \"$name\", create rhythm and ${_getTruncatedSignificance(culturalContext)}";
      default:
        return "This element connects to how Kente weavers express meaning through pattern and structure.";
    }
  }
  
  /// Extract a truncated cultural significance description for use in hints
  String _getTruncatedSignificance(Map<String, dynamic> context) {
    final significance = context['culturalSignificance'] ?? 
                       context['culturalMeaning'] ?? 
                       "important cultural values.";
    
    if (significance.length <= 100) {
      return significance;
    }
    
    // Truncate to first sentence or 100 characters
    final firstSentenceMatch = RegExp(r'^[^.!?]*[.!?]').firstMatch(significance);
    if (firstSentenceMatch != null) {
      return firstSentenceMatch.group(0) ?? significance.substring(0, 100) + "...";
    }
    
    return significance.substring(0, 100) + "...";
  }
  
  /// Get facts related to a specific domain (patterns, colors, etc.)
  Future<List<String>> getFactsByDomain(String domain) async {
    await _ensureInitialized();
    
    switch (domain.toLowerCase()) {
      case 'colors':
        return _colorsData.containsKey('facts') 
            ? List<String>.from(_colorsData['facts']) 
            : [];
      case 'patterns':
        return _patternsData.containsKey('facts') 
            ? List<String>.from(_patternsData['facts']) 
            : [];
      case 'symbols':
        return _symbolsData.containsKey('facts') 
            ? List<String>.from(_symbolsData['facts']) 
            : [];
      case 'regions':
      case 'regional':
        return _regionalData.containsKey('facts') 
            ? List<String>.from(_regionalData['facts']) 
            : [];
      default:
        // Combine facts from all domains
        final allFacts = <String>[];
        for (var dataSource in [_colorsData, _patternsData, _symbolsData, _regionalData]) {
          if (dataSource.containsKey('facts')) {
            allFacts.addAll(List<String>.from(dataSource['facts']));
          }
        }
        return allFacts;
    }
  }
  
  /// Get suggested connections between blocks based on cultural significance
  Future<List<Map<String, dynamic>>> getSuggestedBlockConnections(List<BlockModel> blocks) async {
    await _ensureInitialized();
    
    final suggestions = <Map<String, dynamic>>[];
    
    // If fewer than 2 blocks, can't suggest connections
    if (blocks.length < 2) {
      return suggestions;
    }
    
    // Build cultural contexts for all blocks
    final blockContexts = <String, Map<String, dynamic>>{};
    for (var block in blocks) {
      final context = await getBlockCultureContext(block);
      if (context != null) {
        blockContexts[block.id] = context;
      }
    }
    
    // Find complementary colors
    final colorBlocks = blocks.where((b) => b.type == BlockType.color).toList();
    for (var i = 0; i < colorBlocks.length; i++) {
      for (var j = i + 1; j < colorBlocks.length; j++) {
        final color1Id = colorBlocks[i].id;
        final color2Id = colorBlocks[j].id;
        
        if (blockContexts.containsKey(color1Id) && blockContexts.containsKey(color2Id)) {
          final color1 = blockContexts[color1Id]!;
          final color2 = blockContexts[color2Id]!;
          
          final color1Name = color1['name'] ?? color1['englishName'] ?? '';
          final color2Name = color2['name'] ?? color2['englishName'] ?? '';
          
          // Check if colors are complementary
          if (color1.containsKey('complementaryColors') && 
              List<String>.from(color1['complementaryColors']).contains(color2['id'])) {
            suggestions.add({
              'blockId1': color1Id,
              'blockId2': color2Id,
              'reason': 'In Kente weaving, $color1Name and $color2Name are often used together to create visual harmony and cultural meaning.',
              'significance': 'Color pairing',
            });
          }
        }
      }
    }
    
    // Find pattern-color traditional combinations
    final patternBlocks = blocks.where((b) => b.type == BlockType.pattern).toList();
    for (var pattern in patternBlocks) {
      for (var color in colorBlocks) {
        final patternId = pattern.id;
        final colorId = color.id;
        
        if (blockContexts.containsKey(patternId) && blockContexts.containsKey(colorId)) {
          final patternContext = blockContexts[patternId]!;
          final colorContext = blockContexts[colorId]!;
          
          final patternName = patternContext['name'] ?? patternContext['englishName'] ?? '';
          final colorName = colorContext['name'] ?? colorContext['englishName'] ?? '';
          
          // Check if this color is traditionally used with this pattern
          if (patternContext.containsKey('traditionalColors') && 
              List<String>.from(patternContext['traditionalColors']).contains(colorContext['id'])) {
            suggestions.add({
              'blockId1': patternId,
              'blockId2': colorId,
              'reason': 'Traditionally, the $patternName pattern is often woven using $colorName to symbolize ${patternContext['meaning'] ?? "cultural values"}.',
              'significance': 'Traditional combination',
            });
          }
        }
      }
    }
    
    // Find pattern-structure relationships
    final structureBlocks = blocks.where((b) => b.type == BlockType.structure || b.type == BlockType.column).toList();
    for (var pattern in patternBlocks) {
      for (var structure in structureBlocks) {
        final patternContext = blockContexts[pattern.id];
        if (patternContext != null && patternContext.containsKey('complexity')) {
          final complexity = patternContext['complexity'];
          
          // Suggest complex patterns with appropriate structures
          if (complexity == 'complex' && structure.type == BlockType.structure) {
            suggestions.add({
              'blockId1': pattern.id,
              'blockId2': structure.id,
              'reason': 'Complex patterns like ${patternContext['name'] ?? "this"} benefit from clear structure to organize their elements.',
              'significance': 'Structural support',
            });
          }
        }
      }
    }
    
    // Find loop-pattern relationships
    final loopBlocks = blocks.where((b) => b.type == BlockType.loop).toList();
    for (var pattern in patternBlocks) {
      for (var loop in loopBlocks) {
        final patternContext = blockContexts[pattern.id];
        if (patternContext != null && patternContext.containsKey('repeating') && patternContext['repeating'] == true) {
          suggestions.add({
            'blockId1': pattern.id,
            'blockId2': loop.id,
            'reason': 'The ${patternContext['name'] ?? "pattern"} is traditionally created through repetition, which connects to the concept of loops in coding.',
            'significance': 'Repetition pattern',
          });
        }
      }
    }
    
    return suggestions;
  }
}