// filepath: c:\Users\sowup\dev\weave\lib\models\block_model.dart
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/models/connection_types.dart';
import 'package:kente_codeweaver/features/block_workspace/models/pattern_difficulty.dart';
import 'package:uuid/uuid.dart';

/// Represents a connection point on a block
class BlockConnection {
  /// Unique ID of the connection
  final String id;
  
  /// Display name of the connection
  final String name;
  
  /// Type of connection (input, output, bidirectional)
  final ConnectionType type;
  
  /// Position of the connection point relative to the block's top-left corner
  final Offset position;
  
  /// ID of the block this connection is connected to (if any)
  String? connectedToId;
  
  /// Connection point on the other block (if any)
  String? connectedToPointId;
  
  /// Visual style of the connection point
  final String? visualStyle;
  
  /// Cultural meaning of this connection point
  final String? culturalMeaning;
  
  /// Creates a connection point with the specified properties
  BlockConnection({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.connectedToId,
    this.connectedToPointId,
    this.visualStyle,
    this.culturalMeaning,
  });
  
  /// Create from JSON
  factory BlockConnection.fromJson(Map<String, dynamic> json) {
    return BlockConnection(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? 'Connection',
      type: ConnectionTypeExtension.fromString(json['type'] ?? 'bidirectional'),
      position: Offset(
        (json['position']?['x'] ?? 0.0).toDouble(),
        (json['position']?['y'] ?? 0.0).toDouble(),
      ),
      connectedToId: json['connectedToId'],
      connectedToPointId: json['connectedToPointId'],
      visualStyle: json['visualStyle'],
      culturalMeaning: json['culturalMeaning'],
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toStringValue(),
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'connectedToId': connectedToId,
      'connectedToPointId': connectedToPointId,
      'visualStyle': visualStyle,
      'culturalMeaning': culturalMeaning,
    };
  }
  
  /// Create a copy of this connection with optional changes
  BlockConnection copyWith({
    String? id,
    String? name,
    ConnectionType? type,
    Offset? position,
    String? connectedToId,
    String? connectedToPointId,
    String? visualStyle,
    String? culturalMeaning,
  }) {
    return BlockConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      connectedToId: connectedToId ?? this.connectedToId,
      connectedToPointId: connectedToPointId ?? this.connectedToPointId,
      visualStyle: visualStyle ?? this.visualStyle,
      culturalMeaning: culturalMeaning ?? this.culturalMeaning,
    );
  }
  
  /// Check if this connection can connect to another connection
  bool canConnectTo(BlockConnection other) {
    return type.canConnectTo(other.type);
  }
  
  /// Get the cultural description of this connection
  String getCulturalDescription() {
    if (culturalMeaning != null && culturalMeaning!.isNotEmpty) {
      return culturalMeaning!;
    }
    
    // Default descriptions based on connection type
    switch (type) {
      case ConnectionType.input:
        return 'Represents receiving thread in Kente weaving';
      case ConnectionType.output:
        return 'Represents outgoing thread in Kente weaving';
      case ConnectionType.bidirectional:
        return 'Represents a versatile connection point in Kente weaving';
    }
  }
}

/// Represents a block in the visual programming environment
class BlockModel {
  /// Unique identifier for the block
  final String id;
  
  /// Display name of the block
  final String name;
  
  /// Type of block (pattern, color, structure, etc.)
  final BlockType type;
  
  /// Subtype for more specific categorization
  final String subtype;
  
  /// Position of the block in the workspace
  Offset position;
  
  /// Size of the block in the workspace
  final Size size;
  
  /// Connection points available on this block
  final List<BlockConnection> connections;
  
  /// Additional properties for the block
  final Map<String, dynamic> properties;
  
  /// Cultural and educational metadata
  final Map<String, dynamic> metadata;
  
  /// Difficulty level of this block
  final PatternDifficulty difficulty;
  
  /// Path to the icon image for this block
  final String? iconPath;
  
  /// Color representation for this block
  final String? colorHex;
  
  /// Creates a block with the specified properties
  BlockModel({
    required this.id,
    required this.name,
    required this.type,
    this.subtype = '',
    required this.position,
    required this.size,
    required this.connections,
    this.properties = const {},
    this.metadata = const {},
    this.difficulty = PatternDifficulty.basic,
    this.iconPath,
    this.colorHex,
  });
  
  /// Create from JSON
  factory BlockModel.fromJson(Map<String, dynamic> json) {
    final List<BlockConnection> connectionsList = [];
    
    if (json['connections'] != null) {
      for (final connJson in (json['connections'] as List<dynamic>)) {
        connectionsList.add(BlockConnection.fromJson(connJson));
      }
    }
    
    return BlockModel(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? 'Block',
      type: _parseBlockType(json['type'] ?? 'pattern'),
      subtype: json['subtype'] ?? '',
      position: Offset(
        (json['position']?['x'] ?? 0.0).toDouble(),
        (json['position']?['y'] ?? 0.0).toDouble(),
      ),
      size: Size(
        (json['size']?['width'] ?? 100.0).toDouble(),
        (json['size']?['height'] ?? 100.0).toDouble(),
      ),
      connections: connectionsList,
      properties: json['properties'] ?? {},
      metadata: json['metadata'] ?? {},
      difficulty: _parseDifficulty(json['difficulty'] ?? 'basic'),
      iconPath: json['iconPath'],
      colorHex: json['colorHex'],
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'subtype': subtype,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'size': {
        'width': size.width,
        'height': size.height,
      },
      'connections': connections.map((conn) => conn.toJson()).toList(),
      'properties': properties,
      'metadata': metadata,
      'difficulty': difficulty.toString().split('.').last,
      'iconPath': iconPath,
      'colorHex': colorHex,
    };
  }
  
  /// Find a connection point by ID
  BlockConnection? findConnectionById(String connectionId) {
    try {
      return connections.firstWhere((conn) => conn.id == connectionId);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if this block is connected to another block
  bool isConnectedTo(String blockId) {
    return connections.any((conn) => conn.connectedToId == blockId);
  }
  
  /// Update the position of the block
  void moveTo(Offset newPosition) {
    position = newPosition;
  }
  
  /// Create a copy of this block
  BlockModel copy() {
    return BlockModel(
      id: id,
      name: name,
      type: type,
      subtype: subtype,
      position: Offset(position.dx, position.dy),
      size: Size(size.width, size.height),
      connections: connections.map((conn) => conn.copyWith()).toList(),
      properties: Map.from(properties),
      metadata: Map.from(metadata),
      difficulty: difficulty,
      iconPath: iconPath,
      colorHex: colorHex,
    );
  }
  
  /// Create a copy of this block with optional changes
  BlockModel copyWith({
    String? id,
    String? name,
    BlockType? type,
    String? subtype,
    Offset? position,
    Size? size,
    List<BlockConnection>? connections,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? metadata,
    PatternDifficulty? difficulty,
    String? iconPath,
    String? colorHex,
  }) {
    return BlockModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      position: position ?? this.position,
      size: size ?? this.size,
      connections: connections ?? this.connections.map((conn) => conn.copyWith()).toList(),
      properties: properties ?? Map.from(this.properties),
      metadata: metadata ?? Map.from(this.metadata),
      difficulty: difficulty ?? this.difficulty,
      iconPath: iconPath ?? this.iconPath,
      colorHex: colorHex ?? this.colorHex,
    );
  }
  
  /// Create a copy with a new ID
  BlockModel copyWithNewId() {
    return BlockModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
      subtype: subtype,
      position: Offset(position.dx, position.dy),
      size: Size(size.width, size.height),
      connections: connections.map((conn) => conn.copyWith(id: const Uuid().v4())).toList(),
      properties: Map.from(properties),
      metadata: Map.from(metadata),
      difficulty: difficulty,
      iconPath: iconPath,
      colorHex: colorHex,
    );
  }
  
  /// Get the cultural significance of this block
  String getCulturalSignificance() {
    // Check if we have cultural significance in metadata
    if (metadata.containsKey('culturalSignificance')) {
      return metadata['culturalSignificance'].toString();
    }
    
    // Check if we have it in properties
    if (properties.containsKey('culturalSignificance')) {
      return properties['culturalSignificance'].toString();
    }
    
    // Default descriptions based on block type
    switch (type) {
      case BlockType.pattern:
        return 'Represents a traditional Kente pattern element';
      case BlockType.color:
        return 'Represents a color with cultural meaning in Kente weaving';
      case BlockType.structure:
        return 'Represents the structural organization of a Kente cloth';
      case BlockType.loop:
        return 'Represents repetition in Kente patterns, symbolizing continuity';
      case BlockType.column:
        return 'Represents vertical alignment in Kente cloth, symbolizing strength';
      default:
        return 'A building block of Kente patterns';
    }
  }
  
  /// Get the educational concept this block represents
  String getEducationalConcept() {
    // Check if we have educational concept in metadata
    if (metadata.containsKey('educationalConcept')) {
      return metadata['educationalConcept'].toString();
    }
    
    // Default concepts based on block type
    switch (type) {
      case BlockType.pattern:
        return 'Visual patterns and sequences';
      case BlockType.color:
        return 'Variables and values';
      case BlockType.structure:
        return 'Program structure and organization';
      case BlockType.loop:
        return 'Loops and iteration';
      case BlockType.column:
        return 'Arrays and data structures';
      default:
        return 'Basic programming concepts';
    }
  }
  
  /// Check if this block is suitable for the given age
  bool isSuitableForAge(int age) {
    return age >= difficulty.recommendedMinAge;
  }
  
  /// Helper method to parse BlockType from string
  static BlockType _parseBlockType(String typeStr) {
    try {
      return BlockType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => BlockType.pattern,
      );
    } catch (e) {
      return BlockType.pattern; // Default
    }
  }
  
  /// Helper method to parse PatternDifficulty from string
  static PatternDifficulty _parseDifficulty(String difficultyStr) {
    try {
      return PatternDifficulty.values.firstWhere(
        (diff) => diff.toString().split('.').last.toLowerCase() == difficultyStr.toLowerCase(),
        orElse: () => PatternDifficulty.basic,
      );
    } catch (e) {
      return PatternDifficulty.basic; // Default
    }
  }
  
  /// Get a unique hash for this block's structure (ignoring position)
  String getStructuralHash() {
    final buffer = StringBuffer();
    buffer.write('$type:$subtype:');
    
    // Add connection types in a consistent order
    final connectionTypes = connections
        .map((c) => c.type.toString())
        .toList()
      ..sort();
    buffer.write(connectionTypes.join(','));
    
    // Add key properties that affect structure
    if (properties.containsKey('patternType')) {
      buffer.write(':${properties['patternType']}');
    }
    
    return buffer.toString();
  }
  
  /// Check if this block has a valid cultural pattern
  bool hasValidCulturalPattern() {
    // Check if this is a pattern block
    if (type != BlockType.pattern) return true; // Non-pattern blocks are always valid
    
    // Check if we have a valid pattern type
    if (!properties.containsKey('patternType')) return false;
    
    // In a real implementation, this would check against a database of valid patterns
    // For now, we'll just check if it's not empty
    return properties['patternType'] != null && 
           properties['patternType'].toString().isNotEmpty;
  }
}

