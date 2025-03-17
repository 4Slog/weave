// filepath: c:\Users\sowup\dev\weave\lib\models\block_model.dart
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_type.dart';
import 'package:kente_codeweaver/models/connection_types.dart';
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
  
  /// Creates a connection point with the specified properties
  BlockConnection({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.connectedToId,
    this.connectedToPointId,
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
    };
  }
  
  /// Check if this connection can connect to another connection
  bool canConnectTo(BlockConnection other) {
    return type.canConnectTo(other.type);
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
  
  /// Creates a block with the specified properties
  BlockModel({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.size,
    required this.connections,
    this.properties = const {},
    this.metadata = const {},
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
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
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
}
