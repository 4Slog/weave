import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_model.dart';
// Import only one BlockType definition
import 'package:kente_codeweaver/models/block_type.dart';

/// Represents a collection of blocks that form a pattern
class BlockCollection {
  /// Blocks in this collection
  final List<BlockModel> blocks;
  final Map<String, dynamic> metadata;
  
  /// Constructor
  BlockCollection({
    required this.blocks,
    this.metadata = const {},
  });
  
  /// Create from JSON
  factory BlockCollection.fromJson(Map<String, dynamic> json) {
    final blockList = (json['blocks'] as List<dynamic>)
        .map((blockJson) => BlockModel.fromJson(blockJson))
        .toList();
    
    return BlockCollection(blocks: blockList, metadata: json['metadata'] ?? {});
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'metadata': metadata,
    };
  }
  
  /// Find a block by ID
  BlockModel? findBlockById(String id) {
    try {
      return blocks.firstWhere((block) => block.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Validate all connections in the pattern
  bool validateConnections() {
    for (final block in blocks) {
      for (final connection in block.connections) {
        if (connection.connectedToId != null) {
          final connectedBlock = findBlockById(connection.connectedToId!);
          if (connectedBlock == null) {
            // Connected to a non-existent block
            return false;
          }
          
          // Check if there's a reciprocal connection
          final hasReciprocal = connectedBlock.connections.any(
            (otherConn) => otherConn.connectedToId == block.id
          );
          
          if (!hasReciprocal) {
            // Connection is one-way
            return false;
          }
        }
      }
    }
    
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
  
  /// Check if collection contains a specific connection
  bool containsConnection(Map<String, dynamic> connectionSpec) {
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
  
  /// Get a list of all block types in this collection
  List<BlockType> get blockTypes {
    return blocks.map((block) => block.type).toSet().toList();
  }
  
  /// Add a block to the collection
  void addBlock(BlockModel block) {
    blocks.add(block);
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
        }
      }
    }
    
    // Remove the block itself
    blocks.removeAt(blockIndex);
  }
  
  /// Create a copy of this collection
  BlockCollection copy() {
    final blocksCopy = blocks.map((block) => block.copy()).toList();
    return BlockCollection(blocks: blocksCopy, metadata: Map.from(metadata));
  }
  
  /// Connect blocks
  bool connectBlocks(
    String sourceBlockId, 
    String sourceConnId, 
    String targetBlockId, 
    String targetConnId
  ) {
    // Find the blocks
    final sourceBlock = blocks.firstWhere(
      (b) => b.id == sourceBlockId,
      orElse: () => throw Exception('Source block not found'),
    );
    
    final targetBlock = blocks.firstWhere(
      (b) => b.id == targetBlockId,
      orElse: () => throw Exception('Target block not found'),
    );
    
    // Find the connections
    final sourceConn = sourceBlock.connections.firstWhere(
      (c) => c.id == sourceConnId,
      orElse: () => throw Exception('Source connection not found'),
    );
    
    final targetConn = targetBlock.connections.firstWhere(
      (c) => c.id == targetConnId,
      orElse: () => throw Exception('Target connection not found'),
    );
    
    // Check if connections are already used
    if (sourceConn.connectedToId != null || targetConn.connectedToId != null) {
      return false; // Already connected
    }
    
    // Connect them
    sourceConn.connectedToId = targetConnId;
    targetConn.connectedToId = sourceConnId;
    
    return true;
  }
}