import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/block_type.dart';
import 'package:kente_codeweaver/services/block_definition_service.dart';

/// Provider for managing blocks in the visual programming workspace
class BlockProvider with ChangeNotifier {
  final BlockDefinitionService _blockDefinitionService = BlockDefinitionService();
  
  /// List of blocks in the workspace
  List<BlockModel> _blocks = [];
  
  /// Available block types for the current challenge
  List<BlockType> _availableBlockTypes = [];
  
  /// Get all blocks in the workspace
  List<BlockModel> get blocks => _blocks;
  
  /// Get available block types
  List<BlockType> get availableBlockTypes => _availableBlockTypes;
  
  /// Initialize with default available blocks
  BlockProvider() {
    // Default to all block types
    _availableBlockTypes = BlockType.values.toList();
    
    // Load block definitions
    _loadBlockDefinitions();
  }
  
  /// Load block definitions from service
  Future<void> _loadBlockDefinitions() async {
    try {
      await _blockDefinitionService.loadBlockDefinitions();
    } catch (e) {
      debugPrint('Error loading block definitions: $e');
    }
  }
  
  /// Set available block types for the current challenge
  void setAvailableBlockTypes(List<BlockType> blockTypes) {
    _availableBlockTypes = blockTypes;
    notifyListeners();
  }
  
  /// Add a block to the workspace
  void addBlock(BlockModel block) {
    _blocks.add(block);
    notifyListeners();
  }
  
  /// Update a block in the workspace
  void updateBlock(BlockModel updatedBlock) {
    final index = _blocks.indexWhere((block) => block.id == updatedBlock.id);
    if (index != -1) {
      _blocks[index] = updatedBlock;
      notifyListeners();
    }
  }
  
  /// Remove a block from the workspace
  void removeBlock(String blockId) {
    // Find the block to be removed
    final block = _blocks.firstWhere((b) => b.id == blockId, orElse: () => null as BlockModel);
    if (block == null) return;
    
    // Disconnect any connections to this block
    for (final otherBlock in _blocks) {
      for (final connection in otherBlock.connections) {
        if (connection.connectedToId == blockId) {
          connection.connectedToId = null;
          connection.connectedToPointId = null;
        }
      }
    }
    
    // Remove the block
    _blocks.removeWhere((b) => b.id == blockId);
    notifyListeners();
  }
  
  /// Update the position of a block
  void updateBlockPosition(String blockId, Offset position) {
    final index = _blocks.indexWhere((block) => block.id == blockId);
    if (index != -1) {
      final updatedBlock = _blocks[index];
      updatedBlock.position = position;
      notifyListeners();
    }
  }
  
  /// Connect two blocks together
  void connectBlocks(
    String sourceBlockId, String sourceConnectionId,
    String targetBlockId, String targetConnectionId,
  ) {
    // Find the source and target blocks
    final sourceBlock = _blocks.firstWhere(
      (block) => block.id == sourceBlockId,
      orElse: () => null as BlockModel,
    );
    final targetBlock = _blocks.firstWhere(
      (block) => block.id == targetBlockId,
      orElse: () => null as BlockModel,
    );
    
    if (sourceBlock == null || targetBlock == null) return;
    
    // Find the source and target connections
    final sourceConnection = sourceBlock.findConnectionById(sourceConnectionId);
    final targetConnection = targetBlock.findConnectionById(targetConnectionId);
    
    if (sourceConnection == null || targetConnection == null) return;
    
    // Check if connections are compatible
    if (!sourceConnection.canConnectTo(targetConnection)) return;
    
    // Update connections
    sourceConnection.connectedToId = targetBlockId;
    sourceConnection.connectedToPointId = targetConnectionId;
    
    targetConnection.connectedToId = sourceBlockId;
    targetConnection.connectedToPointId = sourceConnectionId;
    
    notifyListeners();
  }
  
  /// Disconnect two blocks
  void disconnectBlocks(String blockId1, String connectionId1, String blockId2, String connectionId2) {
    // Find the blocks
    final block1 = _blocks.firstWhere(
      (block) => block.id == blockId1,
      orElse: () => null as BlockModel,
    );
    final block2 = _blocks.firstWhere(
      (block) => block.id == blockId2,
      orElse: () => null as BlockModel,
    );
    
    if (block1 == null || block2 == null) return;
    
    // Find the connections
    final connection1 = block1.findConnectionById(connectionId1);
    final connection2 = block2.findConnectionById(connectionId2);
    
    if (connection1 == null || connection2 == null) return;
    
    // Disconnect
    connection1.connectedToId = null;
    connection1.connectedToPointId = null;
    
    connection2.connectedToId = null;
    connection2.connectedToPointId = null;
    
    notifyListeners();
  }
  
  /// Clear all blocks from the workspace
  void clearBlocks() {
    _blocks.clear();
    notifyListeners();
  }
  
  /// Load blocks from a predefined template
  void loadTemplate(String templateId) {
    // This would load a predefined arrangement of blocks
    // For now, just clear and add some sample blocks
    clearBlocks();
    
    // In a real implementation, we would load the template from a service
    
    notifyListeners();
  }
  
  /// Export the current workspace as a serializable object
  Map<String, dynamic> exportWorkspace() {
    return {
      'blocks': _blocks.map((block) => block.toJson()).toList(),
    };
  }
  
  /// Import a workspace from a serializable object
  void importWorkspace(Map<String, dynamic> data) {
    try {
      if (data.containsKey('blocks')) {
        final blockList = data['blocks'] as List<dynamic>;
        _blocks = blockList.map((blockJson) => 
          BlockModel.fromJson(blockJson)
        ).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error importing workspace: $e');
    }
  }
  
  /// Get blocks of a specific type
  List<BlockModel> getBlocksByType(BlockType type) {
    return _blocks.where((block) => block.type == type).toList();
  }
  
  /// Create a copy of a block
  void duplicateBlock(String blockId) {
    final block = _blocks.firstWhere(
      (block) => block.id == blockId,
      orElse: () => null as BlockModel,
    );
    
    if (block == null) return;
    
    // Clone the block JSON and generate a new ID
    final blockJson = block.toJson();
    final newId = 'block_${DateTime.now().millisecondsSinceEpoch}';
    blockJson['id'] = newId;
    
    // Offset the position slightly
    blockJson['position'] = {
      'x': block.position.dx + 20,
      'y': block.position.dy + 20,
    };
    
    // Reset connections
    if (blockJson.containsKey('connections')) {
      final connections = blockJson['connections'] as List<dynamic>;
      for (final conn in connections) {
        conn['connectedToId'] = null;
        conn['connectedToPointId'] = null;
      }
    }
    
    // Create and add the new block
    final newBlock = BlockModel.fromJson(blockJson);
    addBlock(newBlock);
  }
  
  /// Check if a block is connected to any other block
  bool isBlockConnected(String blockId) {
    final block = _blocks.firstWhere(
      (b) => b.id == blockId,
      orElse: () => null as BlockModel,
    );
    
    if (block == null) return false;
    
    // Check if any of the block's connections are connected
    for (final connection in block.connections) {
      if (connection.connectedToId != null) {
        return true;
      }
    }
    
    // Check if any other block is connected to this block
    for (final otherBlock in _blocks) {
      for (final connection in otherBlock.connections) {
        if (connection.connectedToId == blockId) {
          return true;
        }
      }
    }
    
    return false;
  }
}