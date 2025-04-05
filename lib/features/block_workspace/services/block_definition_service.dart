import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/features/block_workspace/models/connection_types.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:uuid/uuid.dart';

/// Service to load and manage block definitions from JSON
class BlockDefinitionService {
  /// List of parsed blocks
  final List<BlockModel> _parsedBlocks = [];
  
  /// Getter for all available blocks
  List<BlockModel> get allBlocks => _parsedBlocks;
  
  /// Load block definitions from JSON asset file
  Future<void> loadBlockDefinitions() async {
    try {
      final String jsonData = await rootBundle.loadString('assets/data/blocks.json');
      final List<dynamic> jsonList = jsonDecode(jsonData) as List<dynamic>;
      
      _parsedBlocks.clear();
      
      for (final blockJson in jsonList) {
        final BlockModel block = _parseBlock(blockJson);
        _parsedBlocks.add(block);
      }
    } catch (e) {
      print('Error loading block definitions: $e');
      // Create some default blocks if loading fails
      _createDefaultBlocks();
    }
  }
  
  /// Create default blocks if loading fails
  void _createDefaultBlocks() {
    _parsedBlocks.clear();
    
    // Add a pattern block
    _parsedBlocks.add(
      BlockModel(
        id: const Uuid().v4(),
        name: 'Checker Pattern',
        type: BlockType.pattern,
        position: const Offset(100, 100),
        size: const Size(150, 100),
        connections: [
          BlockConnection(
            id: const Uuid().v4(),
            name: 'Input',
            type: ConnectionType.input,
            position: const Offset(0, 50),
          ),
          BlockConnection(
            id: const Uuid().v4(),
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(150, 50),
          ),
        ],
        properties: {
          'patternType': 'checker',
          'description': 'Creates a checker pattern',
        },
        metadata: {
          'culturalContext': 'The checker pattern represents balance and duality in Kente weaving.',
          'difficulty': PatternDifficulty.basic.toString().split('.').last,
        },
      ),
    );
    
    // Add a color block
    _parsedBlocks.add(
      BlockModel(
        id: const Uuid().v4(),
        name: 'Color Block',
        type: BlockType.color,
        position: const Offset(300, 100),
        size: const Size(120, 80),
        connections: [
          BlockConnection(
            id: const Uuid().v4(),
            name: 'Input',
            type: ConnectionType.input,
            position: const Offset(0, 40),
          ),
          BlockConnection(
            id: const Uuid().v4(),
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(120, 40),
          ),
        ],
        properties: {
          'color': 'red',
          'description': 'Defines the color for patterns',
        },
      ),
    );
  }
  
  /// Parse block from JSON
  BlockModel _parseBlock(Map<String, dynamic> blockData) {
    final connections = <BlockConnection>[];
    
    if (blockData['connections'] != null) {
      for (final connData in (blockData['connections'] as List<dynamic>)) {
        connections.add(_parseConnection(connData));
      }
    }
    
    return BlockModel(
      id: blockData['id'] ?? const Uuid().v4(),
      name: blockData['name'],
      type: _parseBlockType(blockData['type'] ?? 'pattern'),
      position: _parseOffset(blockData['position']),
      size: _parseSize(blockData['size']),
      connections: connections,
      properties: Map<String, dynamic>.from(blockData['properties'] ?? {}),
      metadata: Map<String, dynamic>.from(blockData['metadata'] ?? {}),
    );
  }

  /// Parse connection from JSON
  BlockConnection _parseConnection(Map<String, dynamic> connData) {
    return BlockConnection(
      id: connData['id'] ?? const Uuid().v4(),
      name: connData['name'] ?? 'Connection',
      type: _parseConnectionType(connData['type'] ?? 'input'),
      position: _parseOffset(connData['position']),
      connectedToId: connData['connectedToId'],
      connectedToPointId: connData['connectedToPointId'],
    );
  }

  /// Parse BlockType from string
  BlockType _parseBlockType(String typeStr) {
    try {
      return BlockType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => BlockType.pattern,
      );
    } catch (e) {
      print('Error parsing BlockType: $e');
      return BlockType.pattern;
    }
  }

  /// Parse ConnectionType from string
  ConnectionType _parseConnectionType(String typeStr) {
    try {
      return ConnectionTypeExtension.fromString(typeStr);
    } catch (e) {
      print('Error parsing ConnectionType: $e');
      return ConnectionType.input;
    }
  }

  /// Parse Offset from JSON
  Offset _parseOffset(dynamic data) {
    if (data == null) return const Offset(0, 0);
    
    return Offset(
      (data['x'] as num? ?? 0).toDouble(),
      (data['y'] as num? ?? 0).toDouble(),
    );
  }

  /// Parse Size from JSON
  Size _parseSize(dynamic data) {
    if (data == null) return const Size(100, 100);
    
    return Size(
      (data['width'] as num? ?? 100).toDouble(),
      (data['height'] as num? ?? 100).toDouble(),
    );
  }
  
  /// Check if two blocks can connect on specific connection points
  bool canBlocksConnect(BlockModel block1, String connectionId1, BlockModel block2, String connectionId2) {
    final connection1 = block1.findConnectionById(connectionId1);
    final connection2 = block2.findConnectionById(connectionId2);
    
    if (connection1 == null || connection2 == null) {
      return false;
    }
    
    return connection1.canConnectTo(connection2);
  }
  
  /// Find a block by ID
  BlockModel? findBlockById(String id) {
    try {
      return _parsedBlocks.firstWhere((block) => block.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get blocks of a specific type
  List<BlockModel> getBlocksByType(BlockType type) {
    return _parsedBlocks.where((block) => block.type == type).toList();
  }
}
