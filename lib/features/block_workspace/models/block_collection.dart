import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/features/block_workspace/models/connection_types.dart';

/// Represents a collection of blocks that form a pattern
class BlockCollection {
  /// Blocks in this collection
  final List<BlockModel> blocks;

  /// Metadata for the collection
  final Map<String, dynamic> metadata;

  /// Cached validation result
  bool? _validationResult;

  /// Flag indicating if the collection has been modified since last validation
  bool _isDirty = true;

  /// Name of the pattern
  final String name;

  /// Description of the pattern
  final String description;

  /// Difficulty level of the pattern
  final PatternDifficulty difficulty;

  /// Cultural region associated with this pattern
  final String? region;

  /// Tags for categorization
  final List<String> tags;

  /// Creator of the pattern
  final String? creator;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modified timestamp
  final DateTime modifiedAt;

  /// Constructor
  BlockCollection({
    required this.blocks,
    this.metadata = const {},
    this.name = 'Untitled Pattern',
    this.description = '',
    this.difficulty = PatternDifficulty.basic,
    this.region,
    this.tags = const [],
    this.creator,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    modifiedAt = modifiedAt ?? DateTime.now();

  /// Create from JSON
  factory BlockCollection.fromJson(Map<String, dynamic> json) {
    final blockList = (json['blocks'] as List<dynamic>)
        .map((blockJson) => BlockModel.fromJson(blockJson))
        .toList();

    return BlockCollection(
      blocks: blockList,
      metadata: json['metadata'] ?? {},
      name: json['name'] ?? 'Untitled Pattern',
      description: json['description'] ?? '',
      difficulty: _parseDifficulty(json['difficulty']),
      region: json['region'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : <String>[],
      creator: json['creator'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'metadata': metadata,
      'name': name,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'region': region,
      'tags': tags,
      'creator': creator,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Helper method to parse difficulty from string
  static PatternDifficulty _parseDifficulty(dynamic difficultyValue) {
    if (difficultyValue == null) return PatternDifficulty.basic;

    if (difficultyValue is int) {
      // Convert numeric difficulty to enum
      switch (difficultyValue) {
        case 1: return PatternDifficulty.basic;
        case 2: return PatternDifficulty.beginner;
        case 3: return PatternDifficulty.intermediate;
        case 4: return PatternDifficulty.advanced;
        case 5: return PatternDifficulty.master;
        default: return PatternDifficulty.basic;
      }
    }

    if (difficultyValue is String) {
      try {
        return PatternDifficulty.values.firstWhere(
          (d) => d.toString().split('.').last.toLowerCase() == difficultyValue.toLowerCase(),
          orElse: () => PatternDifficulty.basic,
        );
      } catch (_) {
        return PatternDifficulty.basic;
      }
    }

    return PatternDifficulty.basic;
  }

  /// Find a block by ID
  BlockModel? findBlockById(String id) {
    try {
      return blocks.firstWhere((block) => block.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all blocks of a specific type
  List<BlockModel> getBlocksByType(BlockType type) {
    return blocks.where((block) => block.type == type).toList();
  }

  /// Get blocks that match a property value
  List<BlockModel> getBlocksByProperty(String propertyName, dynamic propertyValue) {
    return blocks.where((block) =>
      block.properties.containsKey(propertyName) &&
      block.properties[propertyName] == propertyValue
    ).toList();
  }

  /// Count the number of blocks in the collection
  int get blockCount => blocks.length;

  /// Count the number of blocks of a specific type
  int countBlocksByType(BlockType type) {
    return getBlocksByType(type).length;
  }

  /// Validate all connections in the pattern
  bool validateConnections() {
    // If not dirty and we have a cached result, use it
    if (!_isDirty && _validationResult != null) {
      return _validationResult!;
    }

    // Check for empty collection
    if (blocks.isEmpty) {
      _validationResult = true;
      _isDirty = false;
      return true;
    }

    // Validate each block's connections
    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          // Try to find the connected block
          final connectedBlock = findBlockById(connection.connectedToId!);
          if (connectedBlock == null) {
            // Connected to a non-existent block
            _validationResult = false;
            _isDirty = false;
            return false;
          }

          // Check if there's a reciprocal connection
          final hasReciprocal = connectedBlock.connections.any(
            (otherConn) =>
              otherConn.connectedToId == block.id &&
              otherConn.connectedToPointId == connection.id
          );

          if (!hasReciprocal) {
            // Connection is one-way
            _validationResult = false;
            _isDirty = false;
            return false;
          }

          // Check if connection types are compatible
          final connectingPoint = connectedBlock.findConnectionById(connection.connectedToPointId!);
          if (connectingPoint == null) {
            // Connection points to invalid connection ID
            _validationResult = false;
            _isDirty = false;
            return false;
          }

          // Verify connection type compatibility
          if (!_areConnectionTypesCompatible(connection.type, connectingPoint.type)) {
            // Incompatible connection types
            _validationResult = false;
            _isDirty = false;
            return false;
          }
        }
      }
    }

    // All connections are valid
    _validationResult = true;
    _isDirty = false;
    return true;
  }

  /// Check if two connection types are compatible
  bool _areConnectionTypesCompatible(ConnectionType type1, ConnectionType type2) {
    // Input can connect to output, output can connect to input, bidirectional can connect to anything
    if (type1 == ConnectionType.bidirectional || type2 == ConnectionType.bidirectional) {
      return true;
    }

    return (type1 == ConnectionType.input && type2 == ConnectionType.output) ||
           (type1 == ConnectionType.output && type2 == ConnectionType.input);
  }

  /// Validate that the pattern forms a valid structure
  bool isValidPattern() {
    // First validate connections
    if (!validateConnections()) {
      return false;
    }

    // Must have at least one block
    if (blocks.isEmpty) {
      return false;
    }

    // Check if the pattern meets minimum complexity requirements
    if (blocks.length < 2) {
      return false; // Need at least two blocks to form a pattern
    }

    // Check for required block types
    bool hasPatternBlock = blocks.any((block) => block.type == BlockType.pattern);
    if (!hasPatternBlock) {
      return false; // A valid Kente pattern must have at least one pattern block
    }

    // Check for disconnected blocks (all blocks should be connected)
    for (final block in blocks) {
      bool isConnected = block.connections.any((conn) => conn.connectedToId != null);

      if (!isConnected) {
        // Look for connections from other blocks to this one
        bool hasIncomingConnections = false;
        for (final otherBlock in blocks) {
          if (otherBlock.id != block.id) {
            hasIncomingConnections = otherBlock.connections.any(
              (conn) => conn.connectedToId == block.id
            );
            if (hasIncomingConnections) break;
          }
        }

        if (!hasIncomingConnections) {
          return false; // This block is disconnected from the pattern
        }
      }
    }

    // All checks passed
    return true;
  }

  /// Count the number of connections
  int countConnections() {
    int connectionCount = 0;

    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          connectionCount++;
        }
      }
    }

    // Since each connection is counted twice (once from each block),
    // divide by 2 to get the actual number of connections
    return connectionCount ~/ 2;
  }

  /// Check if collection contains a block of a specific type
  bool containsBlockType(BlockType blockType) {
    return blocks.any((block) => block.type == blockType);
  }

  /// Check if collection contains a block with a specific type name
  bool containsBlockTypeName(String blockTypeName) {
    // Convert string to BlockType
    try {
      final blockType = BlockType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == blockTypeName.toLowerCase(),
        orElse: () => throw Exception('Invalid block type: $blockTypeName'),
      );
      return containsBlockType(blockType);
    } catch (_) {
      return false;
    }
  }

  /// Check if collection contains a specific connection
  bool containsConnection(Map<String, dynamic> connectionSpec) {
    // If sourceType and targetType are provided, check for a connection between those types
    if (connectionSpec.containsKey('sourceType') && connectionSpec.containsKey('targetType')) {
      final sourceType = _parseBlockType(connectionSpec['sourceType']);
      final targetType = _parseBlockType(connectionSpec['targetType']);

      for (final block in blocks) {
        if (block.type == sourceType) {
          for (final connection in block.connections) {
            if (connection.connectedToId != null) {
              final targetBlock = findBlockById(connection.connectedToId!);
              if (targetBlock != null && targetBlock.type == targetType) {
                return true;
              }
            }
          }
        }
      }

      return false;
    }

    // If source and target IDs are provided, check for a direct connection
    if (connectionSpec.containsKey('sourceId') && connectionSpec.containsKey('targetId')) {
      final sourceId = connectionSpec['sourceId'];
      final targetId = connectionSpec['targetId'];

      final sourceBlock = findBlockById(sourceId);
      if (sourceBlock == null) return false;

      return sourceBlock.connections.any((conn) => conn.connectedToId == targetId);
    }

    // If connection type is provided, check for any connection of that type
    if (connectionSpec.containsKey('connectionType')) {
      final connectionType = _parseConnectionType(connectionSpec['connectionType']);

      for (final block in blocks) {
        for (final connection in block.connections) {
          if (connection.type == connectionType && connection.connectedToId != null) {
            return true;
          }
        }
      }

      return false;
    }

    // If pattern property is provided, check for a connection involving a specific pattern
    if (connectionSpec.containsKey('patternProperty') &&
        connectionSpec.containsKey('patternValue')) {
      final property = connectionSpec['patternProperty'];
      final value = connectionSpec['patternValue'];

      for (final block in blocks) {
        if (block.properties.containsKey(property) &&
            block.properties[property] == value) {
          for (final connection in block.connections) {
            if (connection.connectedToId != null) {
              return true;
            }
          }
        }
      }

      return false;
    }

    // If we get here, we didn't find a match for the specified connection
    return false;
  }

  /// Helper method to parse BlockType from string
  BlockType _parseBlockType(String typeStr) {
    try {
      return BlockType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => BlockType.pattern,
      );
    } catch (e) {
      return BlockType.pattern; // Default
    }
  }

  /// Helper method to parse ConnectionType from string
  ConnectionType _parseConnectionType(String typeStr) {
    try {
      return ConnectionType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => ConnectionType.bidirectional,
      );
    } catch (e) {
      return ConnectionType.bidirectional; // Default
    }
  }

  /// Get a list of all block types in this collection
  List<BlockType> get blockTypes {
    return blocks.map((block) => block.type).toSet().toList();
  }

  /// Add a block to the collection
  void addBlock(BlockModel block) {
    blocks.add(block);
    _isDirty = true;
  }

  /// Remove a block from the collection
  void removeBlock(String blockId) {
    // Find the block to remove
    final blockIndex = blocks.indexWhere((b) => b.id == blockId);
    if (blockIndex < 0) return; // Block not found

    // Remove connections to this block from other blocks
    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId == blockId) {
          connection.connectedToId = null;
          connection.connectedToPointId = null;
        }
      }
    }

    // Remove the block itself
    blocks.removeAt(blockIndex);
    _isDirty = true;
  }

  /// Create a copy of this collection
  BlockCollection copy() {
    return BlockCollection(
      blocks: blocks.map((block) => block.copy()).toList(),
      metadata: Map.from(metadata),
    );
  }

  /// Connect blocks
  bool connectBlocks(
    String sourceBlockId,
    String sourceConnId,
    String targetBlockId,
    String targetConnId
  ) {
    // Find the blocks
    final sourceBlock = findBlockById(sourceBlockId);
    final targetBlock = findBlockById(targetBlockId);

    if (sourceBlock == null || targetBlock == null) {
      return false; // One or both blocks not found
    }

    // Find the connections
    final sourceConn = sourceBlock.findConnectionById(sourceConnId);
    final targetConn = targetBlock.findConnectionById(targetConnId);

    if (sourceConn == null || targetConn == null) {
      return false; // One or both connections not found
    }

    // Check if connections are already used
    if (sourceConn.connectedToId != null || targetConn.connectedToId != null) {
      return false; // Already connected
    }

    // Check if connection types are compatible
    if (!_areConnectionTypesCompatible(sourceConn.type, targetConn.type)) {
      return false; // Incompatible connection types
    }

    // Check if block types can connect
    if (!canBlockTypesConnect(sourceBlock.type, targetBlock.type)) {
      return false; // Incompatible block types
    }

    // Connect them
    sourceConn.connectedToId = targetBlockId;
    sourceConn.connectedToPointId = targetConnId;

    targetConn.connectedToId = sourceBlockId;
    targetConn.connectedToPointId = sourceConnId;

    _isDirty = true;
    return true;
  }

  /// Disconnect blocks
  bool disconnectBlocks(String blockId1, String connId1, String blockId2, String connId2) {
    // Find the blocks
    final block1 = findBlockById(blockId1);
    final block2 = findBlockById(blockId2);

    if (block1 == null || block2 == null) {
      return false; // One or both blocks not found
    }

    // Find the connections
    final conn1 = block1.findConnectionById(connId1);
    final conn2 = block2.findConnectionById(connId2);

    if (conn1 == null || conn2 == null) {
      return false; // One or both connections not found
    }

    // Check if they're actually connected to each other
    if (conn1.connectedToId != blockId2 || conn2.connectedToId != blockId1) {
      return false; // Not connected to each other
    }

    // Disconnect them
    conn1.connectedToId = null;
    conn1.connectedToPointId = null;

    conn2.connectedToId = null;
    conn2.connectedToPointId = null;

    _isDirty = true;
    return true;
  }

  /// Disconnect all connections for a block
  void disconnectAllConnections(String blockId) {
    // Find the block
    final block = findBlockById(blockId);
    if (block == null) return;

    // Disconnect its connections from other blocks
    for (final conn in block.connections) {
      if (conn.connectedToId != null) {
        final connectedBlock = findBlockById(conn.connectedToId!);
        if (connectedBlock != null) {
          for (final otherConn in connectedBlock.connections) {
            if (otherConn.connectedToId == blockId) {
              otherConn.connectedToId = null;
              otherConn.connectedToPointId = null;
            }
          }
        }

        // Disconnect this connection
        conn.connectedToId = null;
        conn.connectedToPointId = null;
      }
    }

    _isDirty = true;
  }

  /// Check if block types can connect
  bool canBlockTypesConnect(BlockType type1, BlockType type2) {
    // Define connection rules based on block types
    switch (type1) {
      case BlockType.pattern:
        return type2 == BlockType.color ||
               type2 == BlockType.structure ||
               type2 == BlockType.loop;

      case BlockType.color:
        return type2 == BlockType.pattern ||
               type2 == BlockType.loop;

      case BlockType.structure:
        return type2 == BlockType.pattern ||
               type2 == BlockType.column;

      case BlockType.loop:
        return type2 == BlockType.pattern ||
               type2 == BlockType.color;

      case BlockType.column:
        return type2 == BlockType.structure;
    }
  }

  /// Find all connected blocks from a starting block
  List<BlockModel> findConnectedBlocks(String startBlockId) {
    final result = <BlockModel>[];
    final visited = <String>{};

    void traverse(String blockId) {
      if (visited.contains(blockId)) return;

      visited.add(blockId);
      final block = findBlockById(blockId);
      if (block == null) return;

      result.add(block);

      // Traverse outgoing connections
      for (final conn in block.connections) {
        if (conn.connectedToId != null) {
          traverse(conn.connectedToId!);
        }
      }

      // Check for incoming connections
      for (final otherBlock in blocks) {
        if (!visited.contains(otherBlock.id)) {
          for (final conn in otherBlock.connections) {
            if (conn.connectedToId == blockId) {
              traverse(otherBlock.id);
              break;
            }
          }
        }
      }
    }

    // Start traversal
    traverse(startBlockId);

    return result;
  }

  /// Check if the pattern is symmetric around a vertical axis
  bool isSymmetric() {
    // This is a simplified version that just checks if we have
    // an even number of blocks with balanced structure

    if (blocks.length < 2 || blocks.length % 2 != 0) {
      return false; // Need even number of blocks for symmetry
    }

    // Count block types
    final typeCounts = <BlockType, int>{};
    for (final block in blocks) {
      typeCounts[block.type] = (typeCounts[block.type] ?? 0) + 1;
    }

    // Check if each type has an even count
    for (final count in typeCounts.values) {
      if (count % 2 != 0) {
        return false; // Uneven block type distribution
      }
    }

    // This is a simplified check - a real implementation would
    // need to analyze the actual pattern structure in more detail
    return true;
  }

  /// Extract cultural context from the pattern
  Map<String, dynamic> extractCulturalContext() {
    // Extract pattern types
    final patternTypes = blocks
        .where((block) => block.type == BlockType.pattern)
        .map((block) => block.properties['patternType']?.toString() ?? 'basic')
        .toSet()
        .toList();

    // Extract color values
    final colorValues = blocks
        .where((block) => block.type == BlockType.color)
        .map((block) => block.properties['color']?.toString() ?? 'black')
        .toSet()
        .toList();

    // Extract subtypes for more specific categorization
    final subtypes = blocks
        .map((block) => block.subtype)
        .where((subtype) => subtype.isNotEmpty)
        .toSet()
        .toList();

    // Calculate complexity based on block count and connections
    final complexity = _calculateComplexity();

    // Determine pattern style based on block composition
    final style = _determinePatternStyle();

    // Extract cultural significance from blocks
    final culturalElements = blocks
        .where((block) => block.metadata.containsKey('culturalSignificance'))
        .map((block) => block.metadata['culturalSignificance'])
        .toSet()
        .toList();

    // Create cultural context map
    return {
      'patterns': patternTypes,
      'colors': colorValues,
      'subtypes': subtypes,
      'complexity': complexity,
      'style': style,
      'blockCount': blocks.length,
      'connectionCount': countConnections(),
      'symmetric': isSymmetric(),
      'hasLoop': containsBlockType(BlockType.loop),
      'culturalElements': culturalElements,
      'region': region,
      'difficulty': difficulty.toString().split('.').last,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Calculate pattern complexity (1-5)
  int _calculateComplexity() {
    // Base complexity on block count
    if (blocks.length <= 3) {
      return 1;
    } else if (blocks.length <= 6) {
      return 2;
    } else if (blocks.length <= 10) {
      return 3;
    } else if (blocks.length <= 15) {
      return 4;
    } else {
      return 5;
    }
  }

  /// Determine pattern style based on block composition
  String _determinePatternStyle() {
    // Check for specific style indicators

    // If mostly pattern blocks, it's a traditional style
    final patternBlockCount = blocks.where((b) => b.type == BlockType.pattern).length;
    if (patternBlockCount > blocks.length / 2) {
      return 'traditional';
    }

    // If contains loops, it's a repetition style
    if (containsBlockType(BlockType.loop)) {
      return 'repetition';
    }

    // If has columns, it's a structured style
    if (containsBlockType(BlockType.column)) {
      return 'structured';
    }

    // If has many color blocks, it's a colorful style
    final colorBlockCount = blocks.where((b) => b.type == BlockType.color).length;
    if (colorBlockCount > blocks.length / 3) {
      return 'colorful';
    }

    // Default to basic
    return 'basic';
  }

  /// Check if the pattern has a loop structure
  bool hasLoopStructure() {
    // A simple check for at least one loop block
    return containsBlockType(BlockType.loop);
  }

  /// Get a graph representation of the pattern connections
  Map<String, List<String>> getConnectionGraph() {
    final graph = <String, List<String>>{};

    for (final block in blocks) {
      graph[block.id] = [];

      for (final conn in block.connections) {
        if (conn.connectedToId != null) {
          graph[block.id]!.add(conn.connectedToId!);
        }
      }
    }

    return graph;
  }

  /// Find cycles in the pattern connection structure
  List<List<String>> findCycles() {
    final cycles = <List<String>>[];
    final graph = getConnectionGraph();

    for (final startId in graph.keys) {
      final visited = <String>{};
      final path = <String>[];

      void dfs(String currentId, String parentId) {
        visited.add(currentId);
        path.add(currentId);

        for (final neighborId in graph[currentId] ?? []) {
          // Skip parent to avoid trivial cycles
          if (neighborId == parentId) continue;

          if (!visited.contains(neighborId)) {
            dfs(neighborId, currentId);
          } else if (path.contains(neighborId)) {
            // Found a cycle
            final cycleStart = path.indexOf(neighborId);
            cycles.add(path.sublist(cycleStart));
          }
        }

        path.removeLast();
      }

      dfs(startId, '');
    }

    return cycles;
  }

  /// Create a copy with updated properties
  BlockCollection copyWith({
    List<BlockModel>? blocks,
    Map<String, dynamic>? metadata,
    String? name,
    String? description,
    PatternDifficulty? difficulty,
    String? region,
    List<String>? tags,
    String? creator,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return BlockCollection(
      blocks: blocks ?? List.from(this.blocks),
      metadata: metadata ?? Map.from(this.metadata),
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      region: region ?? this.region,
      tags: tags ?? List.from(this.tags),
      creator: creator ?? this.creator,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  /// Validate the pattern against cultural rules
  bool validateCulturalPattern() {
    // First check basic pattern validity
    if (!isValidPattern()) {
      return false;
    }

    // Check if all pattern blocks have valid cultural patterns
    final patternBlocks = blocks.where((block) => block.type == BlockType.pattern);
    for (final block in patternBlocks) {
      if (!block.hasValidCulturalPattern()) {
        return false;
      }
    }

    // Check for cultural color combinations
    if (!_hasValidColorCombination()) {
      return false;
    }

    // Check for cultural structure validity
    if (!_hasValidCulturalStructure()) {
      return false;
    }

    return true;
  }

  /// Check if the pattern has valid color combinations according to cultural rules
  bool _hasValidColorCombination() {
    // Get all color blocks
    final colorBlocks = blocks.where((block) => block.type == BlockType.color);
    final colorValues = colorBlocks
        .map((block) => block.properties['color']?.toString() ?? '')
        .where((color) => color.isNotEmpty)
        .toSet()
        .toList();

    // In a real implementation, this would check against cultural color combination rules
    // For now, we'll just check if we have at least one color
    return colorValues.isNotEmpty;
  }

  /// Check if the pattern has a valid cultural structure
  bool _hasValidCulturalStructure() {
    // In a real implementation, this would check against cultural structure rules
    // For now, we'll just check if we have a valid pattern structure
    return isValidPattern();
  }

  /// Calculate the cultural significance score of this pattern (0-100)
  int calculateCulturalSignificanceScore() {
    int score = 0;

    // Check for traditional pattern types
    final patternTypes = blocks
        .where((block) => block.type == BlockType.pattern)
        .map((block) => block.properties['patternType']?.toString() ?? '')
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();

    // Award points for each traditional pattern
    score += patternTypes.length * 10;

    // Check for traditional color combinations
    if (_hasValidColorCombination()) {
      score += 20;
    }

    // Check for symmetry
    if (isSymmetric()) {
      score += 15;
    }

    // Check for complexity
    score += _calculateComplexity() * 5;

    // Check for cultural structure
    if (_hasValidCulturalStructure()) {
      score += 20;
    }

    // Cap at 100
    return score > 100 ? 100 : score;
  }

  /// Get the recommended difficulty level for this pattern
  PatternDifficulty calculateRecommendedDifficulty() {
    // Base on complexity
    final complexity = _calculateComplexity();

    switch (complexity) {
      case 1:
        return PatternDifficulty.basic;
      case 2:
        return PatternDifficulty.beginner;
      case 3:
        return PatternDifficulty.intermediate;
      case 4:
        return PatternDifficulty.advanced;
      case 5:
        return PatternDifficulty.master;
      default:
        return PatternDifficulty.basic;
    }
  }

  /// Get educational concepts represented in this pattern
  List<String> getEducationalConcepts() {
    final concepts = <String>{};

    // Check for loops
    if (containsBlockType(BlockType.loop)) {
      concepts.add('loops');

      // Check for nested loops
      if (_hasNestedLoops()) {
        concepts.add('nested_loops');
      }
    }

    // Check for structure
    if (containsBlockType(BlockType.structure)) {
      concepts.add('structure');

      // Check for complex structures
      if (_hasComplexStructure()) {
        concepts.add('advanced_structures');
      }
    }

    // Check for color variables
    if (containsBlockType(BlockType.color)) {
      concepts.add('variables');

      // Check for variable reuse
      if (_hasVariableReuse()) {
        concepts.add('variable_reuse');
      }
    }

    // Check for pattern sequences
    if (containsBlockType(BlockType.pattern)) {
      concepts.add('sequences');

      // Check for pattern complexity
      if (_hasComplexPatterns()) {
        concepts.add('complex_sequences');
      }
    }

    // Check for columns (arrays)
    if (containsBlockType(BlockType.column)) {
      concepts.add('arrays');

      // Check for multi-dimensional arrays
      if (_hasMultiDimensionalArrays()) {
        concepts.add('multi_dimensional_arrays');
      }
    }

    // Check for complex patterns
    if (findCycles().isNotEmpty) {
      concepts.add('recursion');
    }

    // Check for conditional logic
    if (_hasConditionalLogic()) {
      concepts.add('conditionals');
    }

    // Check for function-like patterns
    if (_hasFunctionLikePatterns()) {
      concepts.add('functions');
    }

    return concepts.toList();
  }

  /// Check if the pattern has nested loops
  bool _hasNestedLoops() {
    // Get all loop blocks
    final loopBlocks = blocks.where((block) => block.type == BlockType.loop).toList();

    // Check for connections between loop blocks
    for (final loopBlock in loopBlocks) {
      for (final conn in loopBlock.connections) {
        if (conn.connectedToId != null) {
          // Find the connected block
          final connectedBlock = findBlockById(conn.connectedToId!);
          if (connectedBlock != null && connectedBlock.type == BlockType.loop) {
            return true; // Found a connection between loop blocks
          }
        }
      }
    }

    return false;
  }

  /// Check if the pattern has complex structures
  bool _hasComplexStructure() {
    // Get all structure blocks
    final structureBlocks = blocks.where((block) => block.type == BlockType.structure).toList();

    // Check if we have multiple structure blocks
    if (structureBlocks.length > 1) {
      return true;
    }

    // Check for connections to multiple pattern blocks
    for (final structureBlock in structureBlocks) {
      int connectedPatternCount = 0;

      for (final conn in structureBlock.connections) {
        if (conn.connectedToId != null) {
          final connectedBlock = findBlockById(conn.connectedToId!);
          if (connectedBlock != null && connectedBlock.type == BlockType.pattern) {
            connectedPatternCount++;
          }
        }
      }

      if (connectedPatternCount > 2) {
        return true; // Connected to multiple pattern blocks
      }
    }

    return false;
  }

  /// Check if the pattern has variable reuse
  bool _hasVariableReuse() {
    // Get all color blocks
    final colorBlocks = blocks.where((block) => block.type == BlockType.color).toList();

    // Check if any color block is connected to multiple pattern blocks
    for (final colorBlock in colorBlocks) {
      int connectedPatternCount = 0;

      // Count direct connections
      for (final conn in colorBlock.connections) {
        if (conn.connectedToId != null) {
          final connectedBlock = findBlockById(conn.connectedToId!);
          if (connectedBlock != null && connectedBlock.type == BlockType.pattern) {
            connectedPatternCount++;
          }
        }
      }

      // Count incoming connections
      for (final block in blocks) {
        if (block.type == BlockType.pattern) {
          for (final conn in block.connections) {
            if (conn.connectedToId == colorBlock.id) {
              connectedPatternCount++;
            }
          }
        }
      }

      if (connectedPatternCount > 1) {
        return true; // Color block is reused
      }
    }

    return false;
  }

  /// Check if the pattern has complex patterns
  bool _hasComplexPatterns() {
    // Get all pattern blocks
    final patternBlocks = blocks.where((block) => block.type == BlockType.pattern).toList();

    // Check for complex pattern types
    for (final patternBlock in patternBlocks) {
      final patternType = patternBlock.properties['patternType']?.toString() ?? '';
      if (patternType == 'diamond' || patternType == 'zigzag') {
        return true; // Complex pattern type
      }
    }

    // Check for pattern blocks with multiple connections
    for (final patternBlock in patternBlocks) {
      int connectionCount = 0;

      // Count connections
      for (final conn in patternBlock.connections) {
        if (conn.connectedToId != null) {
          connectionCount++;
        }
      }

      if (connectionCount > 2) {
        return true; // Pattern block has multiple connections
      }
    }

    return false;
  }

  /// Check if the pattern has multi-dimensional arrays
  bool _hasMultiDimensionalArrays() {
    // Get all column blocks
    final columnBlocks = blocks.where((block) => block.type == BlockType.column).toList();

    // Check for connections between column blocks
    for (final columnBlock in columnBlocks) {
      for (final conn in columnBlock.connections) {
        if (conn.connectedToId != null) {
          final connectedBlock = findBlockById(conn.connectedToId!);
          if (connectedBlock != null && connectedBlock.type == BlockType.column) {
            return true; // Found a connection between column blocks
          }
        }
      }
    }

    return false;
  }

  /// Check if the pattern has conditional logic
  bool _hasConditionalLogic() {
    // In a real implementation, this would check for conditional blocks
    // For now, we'll check for a specific pattern that represents conditionals

    // Check for a pattern block connected to multiple different pattern blocks
    for (final block in blocks) {
      if (block.type == BlockType.pattern) {
        final connectedPatternTypes = <String>{};

        for (final conn in block.connections) {
          if (conn.connectedToId != null) {
            final connectedBlock = findBlockById(conn.connectedToId!);
            if (connectedBlock != null && connectedBlock.type == BlockType.pattern) {
              final patternType = connectedBlock.properties['patternType']?.toString() ?? '';
              connectedPatternTypes.add(patternType);
            }
          }
        }

        if (connectedPatternTypes.length > 1) {
          return true; // Connected to multiple different pattern types
        }
      }
    }

    return false;
  }

  /// Check if the pattern has function-like patterns
  bool _hasFunctionLikePatterns() {
    // In a real implementation, this would check for function blocks
    // For now, we'll check for a specific pattern that represents functions

    // Check for a structure block that forms a self-contained unit
    for (final block in blocks) {
      if (block.type == BlockType.structure) {
        // Get all blocks connected to this structure block
        final connectedBlocks = <BlockModel>{};

        for (final conn in block.connections) {
          if (conn.connectedToId != null) {
            final connectedBlock = findBlockById(conn.connectedToId!);
            if (connectedBlock != null) {
              connectedBlocks.add(connectedBlock);
            }
          }
        }

        // Check if this structure forms a self-contained unit
        if (connectedBlocks.length >= 3 &&
            connectedBlocks.any((b) => b.type == BlockType.pattern) &&
            connectedBlocks.any((b) => b.type == BlockType.color)) {
          return true; // Structure forms a self-contained unit with pattern and color
        }
      }
    }

    return false;
  }

  /// Export the pattern to a shareable format
  Map<String, dynamic> exportPattern() {
    return {
      'version': '1.0',
      'type': 'kente_pattern',
      'name': name,
      'description': description,
      'difficulty': difficulty.toString().split('.').last,
      'region': region,
      'tags': tags,
      'creator': creator,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'metadata': metadata,
      'culturalContext': extractCulturalContext(),
      'educationalConcepts': getEducationalConcepts(),
    };
  }

  /// Import a pattern from a shareable format
  static BlockCollection importPattern(Map<String, dynamic> data) {
    // Validate the data
    if (data['type'] != 'kente_pattern') {
      throw Exception('Invalid pattern format');
    }

    // Parse blocks
    final blockList = (data['blocks'] as List<dynamic>)
        .map((blockJson) => BlockModel.fromJson(blockJson))
        .toList();

    // Create the collection
    return BlockCollection(
      blocks: blockList,
      metadata: data['metadata'] ?? {},
      name: data['name'] ?? 'Imported Pattern',
      description: data['description'] ?? '',
      difficulty: _parseDifficulty(data['difficulty']),
      region: data['region'],
      tags: data['tags'] != null
          ? List<String>.from(data['tags'])
          : <String>[],
      creator: data['creator'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      modifiedAt: data['modifiedAt'] != null
          ? DateTime.parse(data['modifiedAt'])
          : DateTime.now(),
    );
  }

  /// Get a thumbnail representation of this pattern
  Map<String, dynamic> getThumbnail() {
    return {
      'name': name,
      'difficulty': difficulty.toString().split('.').last,
      'blockCount': blocks.length,
      'connectionCount': countConnections(),
      'style': _determinePatternStyle(),
      'complexity': _calculateComplexity(),
      'hasLoop': containsBlockType(BlockType.loop),
      'region': region,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Check if this pattern is suitable for the given age
  bool isSuitableForAge(int age) {
    return age >= difficulty.recommendedMinAge;
  }

  /// Get a list of cultural elements used in this pattern
  List<String> getCulturalElements() {
    final elements = <String>{};

    // Extract from pattern blocks
    for (final block in blocks) {
      if (block.metadata.containsKey('culturalElement')) {
        elements.add(block.metadata['culturalElement'].toString());
      }

      if (block.properties.containsKey('culturalElement')) {
        elements.add(block.properties['culturalElement'].toString());
      }
    }

    // Extract from metadata
    if (metadata.containsKey('culturalElements')) {
      final metadataElements = metadata['culturalElements'];
      if (metadataElements is List) {
        for (final element in metadataElements) {
          elements.add(element.toString());
        }
      }
    }

    return elements.toList();
  }
}

