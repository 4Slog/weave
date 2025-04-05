import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart';

/// Enhanced version of BlockProvider with additional functionality
class BlockProviderEnhanced extends BlockProvider {
  /// Map of block types to their availability status
  final Map<BlockType, bool> _availableBlockTypes = {};

  /// Whether to show real-time validation feedback
  bool _showRealtimeValidation = true;

  /// Get whether real-time validation is enabled
  bool get showRealtimeValidation => _showRealtimeValidation;

  /// Set whether to show real-time validation
  set showRealtimeValidation(bool value) {
    _showRealtimeValidation = value;
    notifyListeners();
  }

  /// Initialize the provider with user and workspace IDs
  @override
  Future<void> initialize(String userId, String workspaceId) async {
    await super.initialize(userId, workspaceId);

    // Set default available block types
    for (final type in BlockType.values) {
      _availableBlockTypes[type] = true;
    }

    notifyListeners();
  }

  /// Check if a specific block type is available
  @override
  bool hasBlockType(String typeStr) {
    // Convert string type to enum if possible
    BlockType? type;
    try {
      type = BlockType.values.firstWhere(
        (t) => t.toString().split('.').last.toLowerCase() == typeStr.toLowerCase()
      );
    } catch (e) {
      debugPrint('Unknown block type string: $typeStr');
      return false;
    }

    return _availableBlockTypes[type] ?? false;
  }

  /// Set available block types
  @override
  void setAvailableBlockTypes(List<BlockType> types) {
    // First, set all types to false
    for (final type in BlockType.values) {
      _availableBlockTypes[type] = false;
    }

    // Then enable only the specified types
    for (final type in types) {
      _availableBlockTypes[type] = true;
    }

    notifyListeners();
  }

  /// Add a block of the specified type to the workspace
  @override
  String addBlockFromType(String typeStr) {
    // Convert string type to enum if possible
    BlockType? type;
    try {
      type = BlockType.values.firstWhere(
        (t) => t.toString().split('.').last.toLowerCase() == typeStr.toLowerCase()
      );
    } catch (e) {
      debugPrint('Unknown block type string: $typeStr');
      return '';
    }

    // Create block at default position
    final block = _createBlockFromType(type);
    if (block != null) {
      addBlock(block);
      return block.id;
    }

    return '';
  }

  /// Add a block of the specified type at a specific position
  BlockModel? addBlockFromTypeAtPosition(BlockType type, {Offset? position}) {
    // Check if this block type is available
    if (!(_availableBlockTypes[type] ?? false)) {
      debugPrint('Block type $type is not available');
      return null;
    }

    // Create a new block based on the type
    final block = _createBlockFromType(type, position: position);
    if (block != null) {
      addBlock(block);
      return block;
    }

    return null;
  }

  /// Create a new block of the specified type
  BlockModel? _createBlockFromType(BlockType type, {Offset? position}) {
    // Default position if none provided
    final pos = position ?? const Offset(100, 100);

    // Create block based on type
    switch (type) {
      case BlockType.pattern:
        return BlockModel(
          id: generateUniqueId(),
          name: 'Pattern Block',
          type: BlockType.pattern,
          position: pos,
          size: const Size(120, 80),
          colorHex: '#4CAF50',
          connections: [],
          properties: {},
        );
      case BlockType.color:
        return BlockModel(
          id: generateUniqueId(),
          name: 'Color Block',
          type: BlockType.color,
          position: pos,
          size: const Size(100, 60),
          colorHex: '#2196F3',
          connections: [],
          properties: {},
        );
      case BlockType.structure:
        return BlockModel(
          id: generateUniqueId(),
          name: 'Structure Block',
          type: BlockType.structure,
          position: pos,
          size: const Size(140, 100),
          colorHex: '#9C27B0',
          connections: [],
          properties: {},
        );
      case BlockType.loop:
        return BlockModel(
          id: generateUniqueId(),
          name: 'Loop Block',
          type: BlockType.loop,
          position: pos,
          size: const Size(120, 80),
          colorHex: '#FF9800',
          connections: [],
          properties: {},
        );
      case BlockType.column:
        return BlockModel(
          id: generateUniqueId(),
          name: 'Column Block',
          type: BlockType.column,
          position: pos,
          size: const Size(80, 120),
          colorHex: '#F44336',
          connections: [],
          properties: {},
        );

    }
  }

  /// Generate a unique ID for a new block
  String generateUniqueId() {
    // Simple implementation - in a real app, use UUID
    return 'block_${DateTime.now().millisecondsSinceEpoch}_${blocks.length}';
  }

  /// Check if the current workspace matches a target pattern
  bool matchesPattern(List<BlockModel> targetPattern) {
    // This is a simplified implementation
    // A real implementation would check block types, connections, and positions

    // Check if we have the same number of blocks
    if (blocks.length != targetPattern.length) {
      return false;
    }

    // Count blocks by type in current workspace
    final Map<BlockType, int> currentTypeCounts = {};
    for (final block in blocks) {
      currentTypeCounts[block.type] = (currentTypeCounts[block.type] ?? 0) + 1;
    }

    // Count blocks by type in target pattern
    final Map<BlockType, int> targetTypeCounts = {};
    for (final block in targetPattern) {
      targetTypeCounts[block.type] = (targetTypeCounts[block.type] ?? 0) + 1;
    }

    // Compare counts
    for (final type in BlockType.values) {
      if (currentTypeCounts[type] != targetTypeCounts[type]) {
        return false;
      }
    }

    // For a more accurate comparison, we would also check connections and positions
    return true;
  }
}
