import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/block_workspace/models/pattern_difficulty.dart';
import 'package:kente_codeweaver/features/block_workspace/models/connection_types.dart';
import 'package:kente_codeweaver/features/patterns/models/pattern_model.dart';
import 'package:kente_codeweaver/features/block_workspace/services/block_definition_service.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing blocks in the visual programming workspace
/// with improved state management, connection tracking, pattern validation,
/// and methods for saving and loading user-created patterns.
class BlockProvider with ChangeNotifier {
  final BlockDefinitionService _blockDefinitionService = BlockDefinitionService();
  final StorageService _storageService = StorageService();

  /// List of blocks in the workspace
  List<BlockModel> _blocks = [];

  /// Available block types for the current challenge
  List<BlockType> _availableBlockTypes = [];

  /// Current workspace ID
  String _workspaceId = 'default_workspace';

  /// Current user ID
  String _userId = 'current_user';

  /// Connection history for undo/redo
  List<Map<String, dynamic>> _connectionHistory = [];

  /// Current position in connection history
  int _historyPosition = -1;

  /// Maximum history size
  static const int _maxHistorySize = 50;

  /// Flag indicating if the workspace has been modified since last save
  bool _isDirty = false;

  /// Currently selected block ID
  String? _selectedBlockId;

  /// Currently highlighted connection ID
  String? _highlightedConnectionId;

  /// Pattern validation result cache
  final Map<String, bool> _validationCache = {};

  /// Recently used patterns
  List<BlockCollection> _recentPatterns = [];

  /// Maximum number of recent patterns to track
  static const int _maxRecentPatterns = 10;

  /// Get all blocks in the workspace
  List<BlockModel> get blocks => _blocks;

  /// Get available block types
  List<BlockType> get availableBlockTypes => _availableBlockTypes;

  /// Get current workspace ID
  String get workspaceId => _workspaceId;

  /// Get current user ID
  String get userId => _userId;

  /// Get selected block ID
  String? get selectedBlockId => _selectedBlockId;

  /// Get highlighted connection ID
  String? get highlightedConnectionId => _highlightedConnectionId;

  /// Get whether the workspace has been modified
  bool get isDirty => _isDirty;

  /// Get whether undo is available
  bool get canUndo => _historyPosition > 0;

  /// Get whether redo is available
  bool get canRedo => _historyPosition < _connectionHistory.length - 1;

  /// Get recent patterns
  List<BlockCollection> get recentPatterns => _recentPatterns;

  /// Initialize with default available blocks
  BlockProvider() {
    // Default to all block types
    _availableBlockTypes = BlockType.values.toList();

    // Load block definitions
    _loadBlockDefinitions();
  }

  /// Initialize with user ID and workspace ID
  Future<void> initialize(String userId, String workspaceId) async {
    _userId = userId;
    _workspaceId = workspaceId;

    // Load block definitions
    await _loadBlockDefinitions();

    // Load saved blocks if available
    await loadWorkspace();

    // Load recent patterns
    await _loadRecentPatterns();
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
    _isDirty = true;
    _saveHistoryState();
    notifyListeners();
  }

  /// Create and add a block from a block type string
  /// Returns the ID of the newly created block
  String addBlockFromType(String blockTypeStr) {
    try {
      // Convert string to enum
      final blockType = BlockType.values.firstWhere(
        (type) => type.toString().split('.').last == blockTypeStr,
        orElse: () => BlockType.loop,
      );

      // Create a new block with default properties
      final newBlock = BlockModel(
        id: 'block_${DateTime.now().millisecondsSinceEpoch}',
        name: '${blockTypeStr.substring(0, 1).toUpperCase()}${blockTypeStr.substring(1)} Block',
        type: blockType,
        position: const Offset(100, 100),
        size: const Size(100, 100),
        connections: _getDefaultConnectionsForType(blockType),
      );

      // Add the block to the workspace
      addBlock(newBlock);

      return newBlock.id;
    } catch (e) {
      debugPrint('Error creating block from type: $e');
      return '';
    }
  }

  /// Get default connections for a block type
  List<BlockConnection> _getDefaultConnectionsForType(BlockType type) {
    switch (type) {
      case BlockType.loop:
        return [
          BlockConnection(
            id: 'conn_${DateTime.now().millisecondsSinceEpoch}_1',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(100, 50),
          ),
        ];
      case BlockType.pattern:
        return [
          BlockConnection(
            id: 'conn_${DateTime.now().millisecondsSinceEpoch}_1',
            name: 'Input',
            type: ConnectionType.input,
            position: const Offset(0, 50),
          ),
        ];
      case BlockType.color:
        return [
          BlockConnection(
            id: 'conn_${DateTime.now().millisecondsSinceEpoch}_1',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(100, 50),
          ),
        ];
      case BlockType.structure:
        return [
          BlockConnection(
            id: 'conn_${DateTime.now().millisecondsSinceEpoch}_1',
            name: 'Input',
            type: ConnectionType.input,
            position: const Offset(0, 50),
          ),
          BlockConnection(
            id: 'conn_${DateTime.now().millisecondsSinceEpoch}_2',
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(100, 50),
          ),
        ];
      case BlockType.column:
        return [
          BlockConnection(
            id: 'conn_${DateTime.now().millisecondsSinceEpoch}_1',
            name: 'Input',
            type: ConnectionType.input,
            position: const Offset(0, 50),
          ),
        ];
      default:
        return [];
    }
  }

  /// Update a block in the workspace
  void updateBlock(BlockModel updatedBlock) {
    final index = _blocks.indexWhere((block) => block.id == updatedBlock.id);
    if (index != -1) {
      _blocks[index] = updatedBlock;
      _isDirty = true;
      _saveHistoryState();
      notifyListeners();
    }
  }

  /// Remove a block from the workspace
  void removeBlock(String blockId) {
    // Find the block to be removed
    final blockIndex = _blocks.indexWhere((b) => b.id == blockId);
    if (blockIndex < 0) return;

    // Disconnect any connections to this block from other blocks
    for (final otherBlock in _blocks) {
      for (final connection in otherBlock.connections) {
        if (connection.connectedToId == blockId) {
          connection.connectedToId = null;
          connection.connectedToPointId = null;
        }
      }
    }

    // Remove the block
    _blocks.removeAt(blockIndex);

    // Clear selection if this was the selected block
    if (_selectedBlockId == blockId) {
      _selectedBlockId = null;
    }

    _isDirty = true;
    _saveHistoryState();
    notifyListeners();
  }

  /// Update the position of a block
  void updateBlockPosition(String blockId, Offset position) {
    final index = _blocks.indexWhere((block) => block.id == blockId);
    if (index != -1) {
      final updatedBlock = _blocks[index].copyWith(position: position);
      _blocks[index] = updatedBlock;
      _isDirty = true;
      notifyListeners();
    }
  }

  /// Connect two blocks together
  bool connectBlocks(
    String sourceBlockId, String sourceConnectionId,
    String targetBlockId, String targetConnectionId,
  ) {
    // Find the source and target blocks
    BlockModel? sourceBlock;
    try {
      sourceBlock = _blocks.firstWhere((block) => block.id == sourceBlockId);
    } catch (e) {
      return false; // Source block not found
    }

    BlockModel? targetBlock;
    try {
      targetBlock = _blocks.firstWhere((block) => block.id == targetBlockId);
    } catch (e) {
      return false; // Target block not found
    }

    // Find the source and target connections
    final sourceConnection = sourceBlock.findConnectionById(sourceConnectionId);
    final targetConnection = targetBlock.findConnectionById(targetConnectionId);

    if (sourceConnection == null || targetConnection == null) return false;

    // Check if connections are already used
    if (sourceConnection.connectedToId != null || targetConnection.connectedToId != null) {
      // Disconnect existing connections first
      if (sourceConnection.connectedToId != null) {
        disconnectConnection(sourceBlockId, sourceConnectionId);
      }

      if (targetConnection.connectedToId != null) {
        disconnectConnection(targetBlockId, targetConnectionId);
      }
    }

    // Check if connections are compatible
    if (!sourceConnection.canConnectTo(targetConnection)) return false;

    // Update connections
    sourceConnection.connectedToId = targetBlockId;
    sourceConnection.connectedToPointId = targetConnectionId;

    targetConnection.connectedToId = sourceBlockId;
    targetConnection.connectedToPointId = sourceConnectionId;

    _isDirty = true;
    _saveHistoryState();

    // Clear validation cache since connections changed
    _validationCache.clear();

    notifyListeners();
    return true;
  }

  /// Disconnect a specific connection
  void disconnectConnection(String blockId, String connectionId) {
    // Find the block
    BlockModel? block;
    try {
      block = _blocks.firstWhere((block) => block.id == blockId);
    } catch (e) {
      return; // Block not found
    }

    // Find the connection
    final connection = block.findConnectionById(connectionId);
    if (connection == null || connection.connectedToId == null) return;

    // Find the connected block
    final connectedBlockId = connection.connectedToId!;
    BlockModel? connectedBlock;
    try {
      connectedBlock = _blocks.firstWhere((block) => block.id == connectedBlockId);
    } catch (e) {
      // Connected block not found, just disconnect this side
      connection.connectedToId = null;
      connection.connectedToPointId = null;
      return;
    }

    // Find the connected connection
    final connectedPointId = connection.connectedToPointId!;
    final connectedConnection = connectedBlock.findConnectionById(connectedPointId);

    if (connectedConnection != null) {
      // Disconnect both sides
      connectedConnection.connectedToId = null;
      connectedConnection.connectedToPointId = null;
    }

    connection.connectedToId = null;
    connection.connectedToPointId = null;

    _isDirty = true;
    _saveHistoryState();

    // Clear validation cache since connections changed
    _validationCache.clear();

    notifyListeners();
  }

  /// Disconnect two blocks
  void disconnectBlocks(String blockId1, String connectionId1, String blockId2, String connectionId2) {
    // Find the blocks
    BlockModel? block1;
    try {
      block1 = _blocks.firstWhere((block) => block.id == blockId1);
    } catch (e) {
      return; // Block not found
    }

    BlockModel? block2;
    try {
      block2 = _blocks.firstWhere((block) => block.id == blockId2);
    } catch (e) {
      return; // Block not found
    }

    // Find the connections
    final connection1 = block1.findConnectionById(connectionId1);
    final connection2 = block2.findConnectionById(connectionId2);

    if (connection1 == null || connection2 == null) return;

    // Disconnect
    connection1.connectedToId = null;
    connection1.connectedToPointId = null;

    connection2.connectedToId = null;
    connection2.connectedToPointId = null;

    _isDirty = true;
    _saveHistoryState();

    // Clear validation cache since connections changed
    _validationCache.clear();

    notifyListeners();
  }

  /// Clear all blocks from the workspace
  void clearBlocks() {
    if (_blocks.isEmpty) return;

    _blocks.clear();
    _selectedBlockId = null;
    _highlightedConnectionId = null;
    _isDirty = true;
    _saveHistoryState();

    // Clear validation cache
    _validationCache.clear();

    notifyListeners();
  }

  /// Load blocks from a predefined template
  Future<void> loadTemplate(String templateId) async {
    try {
      // In a real implementation, this would load a template from a service
      // For now, we'll just create a simple template based on the template ID

      // Clear current workspace
      clearBlocks();

      // Create some sample blocks based on template ID
      if (templateId == 'basic_pattern') {
        // Create a basic pattern with a few blocks
        final patternBlock = BlockModel(
          id: 'block_${DateTime.now().millisecondsSinceEpoch}_1',
          name: 'Pattern Block',
          type: BlockType.pattern,
          position: const Offset(100, 100),
          size: const Size(100, 100),
          connections: [
            BlockConnection(
              id: 'conn_1',
              name: 'Output',
              type: ConnectionType.output,
              position: const Offset(100, 50),
            ),
          ],
        );

        final colorBlock = BlockModel(
          id: 'block_${DateTime.now().millisecondsSinceEpoch}_2',
          name: 'Color Block',
          type: BlockType.color,
          position: const Offset(250, 100),
          size: const Size(100, 100),
          connections: [
            BlockConnection(
              id: 'conn_2',
              name: 'Input',
              type: ConnectionType.input,
              position: const Offset(0, 50),
            ),
          ],
        );

        // Add blocks to workspace
        addBlock(patternBlock);
        addBlock(colorBlock);

        // Connect blocks
        connectBlocks(
          patternBlock.id, 'conn_1',
          colorBlock.id, 'conn_2',
        );
      } else if (templateId == 'loop_pattern') {
        // Create a loop pattern
        final loopBlock = BlockModel(
          id: 'block_${DateTime.now().millisecondsSinceEpoch}_1',
          name: 'Loop Block',
          type: BlockType.loop,
          position: const Offset(100, 100),
          size: const Size(100, 100),
          connections: [
            BlockConnection(
              id: 'conn_1',
              name: 'Output',
              type: ConnectionType.output,
              position: const Offset(100, 50),
            ),
          ],
        );

        final patternBlock = BlockModel(
          id: 'block_${DateTime.now().millisecondsSinceEpoch}_2',
          name: 'Pattern Block',
          type: BlockType.pattern,
          position: const Offset(250, 100),
          size: const Size(100, 100),
          connections: [
            BlockConnection(
              id: 'conn_2',
              name: 'Input',
              type: ConnectionType.input,
              position: const Offset(0, 50),
            ),
          ],
        );

        // Add blocks to workspace
        addBlock(loopBlock);
        addBlock(patternBlock);

        // Connect blocks
        connectBlocks(
          loopBlock.id, 'conn_1',
          patternBlock.id, 'conn_2',
        );
      }

      _isDirty = true;
      _saveHistoryState();

      // Clear validation cache
      _validationCache.clear();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading template: $e');
    }
  }




  /// Export the current workspace as a serializable object
  Map<String, dynamic> exportWorkspace() {
    return {
      'blocks': _blocks.map((block) => block.toJson()).toList(),
      'workspaceId': _workspaceId,
      'userId': _userId,
      'timestamp': DateTime.now().toIso8601String(),
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

        // Update workspace ID if provided
        if (data.containsKey('workspaceId')) {
          _workspaceId = data['workspaceId'] as String;
        }

        _isDirty = true;
        _saveHistoryState();

        // Clear validation cache
        _validationCache.clear();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error importing workspace: $e');
    }
  }

  /// Save the current workspace
  Future<void> saveWorkspace() async {
    if (!_isDirty) return;

    try {
      // Create a block collection
      final collection = BlockCollection(
        blocks: _blocks,
        name: 'Workspace $_workspaceId',
        description: 'Saved workspace',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Save to storage
      final String blocksJson = jsonEncode(collection.toJson());
      await _storageService.saveBlocks('${_userId}_$_workspaceId', blocksJson);

      _isDirty = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving workspace: $e');
    }
  }

  /// Load the current workspace
  Future<void> loadWorkspace() async {
    try {
      // Load from storage
      final String? blocksJson = await _storageService.getBlocks('${_userId}_$_workspaceId');

      if (blocksJson != null) {
        final Map<String, dynamic> data = jsonDecode(blocksJson);
        final BlockCollection collection = BlockCollection.fromJson(data);

        _blocks = collection.blocks;
        _isDirty = false;
        _saveHistoryState();

        // Clear validation cache
        _validationCache.clear();

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading workspace: $e');
    }
  }

  /// Save the current workspace as a pattern
  Future<void> saveAsPattern(String name, String description, {
    PatternDifficulty difficulty = PatternDifficulty.basic,
    String? region,
    List<String> tags = const [],
  }) async {
    try {
      // Validate the pattern first
      if (!validatePattern()) {
        throw Exception('Cannot save invalid pattern');
      }

      // Create a unique ID for the pattern
      final patternId = 'pattern_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}';

      // Create a block collection
      final collection = BlockCollection(
        blocks: _blocks,
        name: name,
        description: description,
        difficulty: difficulty,
        region: region,
        tags: tags,
        creator: _userId,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        metadata: {'patternId': patternId},
      );

      // Save to storage
      await _storageService.savePattern(PatternModel(
        id: patternId,
        userId: _userId,
        name: name,
        description: description,
        tags: tags,
        blockCollection: collection,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      ));

      // Add to recent patterns
      await _addToRecentPatterns(collection);

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving pattern: $e');
      rethrow;
    }
  }

  /// Load a saved pattern
  Future<void> loadPattern(String patternId) async {
    try {
      // Load pattern from storage
      final PatternModel? pattern = await _storageService.loadPattern(patternId);

      if (pattern != null) {
        // Clear current workspace
        clearBlocks();

        // Add blocks from pattern
        _blocks = pattern.blockCollection.blocks.map((block) => block.copy()).toList();

        _isDirty = true;
        _saveHistoryState();

        // Clear validation cache
        _validationCache.clear();

        // Add to recent patterns
        await _addToRecentPatterns(pattern.blockCollection);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading pattern: $e');
    }
  }

  /// Get blocks of a specific type
  List<BlockModel> getBlocksByType(BlockType type) {
    return _blocks.where((block) => block.type == type).toList();
  }

  /// Check if a specific block type is available
  bool hasBlockType(String blockTypeStr) {
    try {
      // Convert string to enum
      final blockType = BlockType.values.firstWhere(
        (type) => type.toString().split('.').last == blockTypeStr,
        orElse: () => BlockType.loop,
      );

      // Check if this block type is in the available types
      return _availableBlockTypes.contains(blockType);
    } catch (e) {
      debugPrint('Error checking block type: $e');
      return false;
    }
  }

  /// Create a copy of a block
  void duplicateBlock(String blockId) {
    BlockModel? block;
    try {
      block = _blocks.firstWhere((block) => block.id == blockId);
    } catch (e) {
      return; // Block not found
    }

    // Create a new block with a new ID
    final newBlock = block.copyWithNewId();

    // Offset the position slightly
    newBlock.position = Offset(
      block.position.dx + 20,
      block.position.dy + 20,
    );

    // Add the new block
    addBlock(newBlock);
  }

  /// Check if a block is connected to any other block
  bool isBlockConnected(String blockId) {
    BlockModel? block;
    try {
      block = _blocks.firstWhere((b) => b.id == blockId);
    } catch (e) {
      return false; // Block not found
    }

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

  /// Select a block
  void selectBlock(String blockId) {
    _selectedBlockId = blockId;
    notifyListeners();
  }

  /// Deselect the current block
  void deselectBlock() {
    _selectedBlockId = null;
    notifyListeners();
  }

  /// Highlight a connection
  void highlightConnection(String connectionId) {
    _highlightedConnectionId = connectionId;
    notifyListeners();
  }

  /// Clear connection highlight
  void clearConnectionHighlight() {
    _highlightedConnectionId = null;
    notifyListeners();
  }

  /// Undo the last action
  void undo() {
    if (!canUndo) return;

    _historyPosition--;
    _loadHistoryState(_historyPosition);
    notifyListeners();
  }

  /// Redo the last undone action
  void redo() {
    if (!canRedo) return;

    _historyPosition++;
    _loadHistoryState(_historyPosition);
    notifyListeners();
  }

  /// Save the current state to history
  void _saveHistoryState() {
    // If we're not at the end of the history, truncate it
    if (_historyPosition < _connectionHistory.length - 1) {
      _connectionHistory = _connectionHistory.sublist(0, _historyPosition + 1);
    }

    // Add the current state to history
    _connectionHistory.add({
      'blocks': _blocks.map((block) => block.toJson()).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Limit history size
    if (_connectionHistory.length > _maxHistorySize) {
      _connectionHistory.removeAt(0);
    }

    // Update position
    _historyPosition = _connectionHistory.length - 1;
  }

  /// Load a state from history
  void _loadHistoryState(int position) {
    if (position < 0 || position >= _connectionHistory.length) return;

    final state = _connectionHistory[position];
    final blockList = state['blocks'] as List<dynamic>;

    _blocks = blockList.map((blockJson) =>
      BlockModel.fromJson(blockJson)
    ).toList();

    // Clear validation cache
    _validationCache.clear();
  }

  /// Validate the current pattern
  bool validatePattern() {
    // Create a unique key for the current pattern
    final patternKey = _getPatternKey();

    // Check cache first
    if (_validationCache.containsKey(patternKey)) {
      return _validationCache[patternKey]!;
    }

    // Create a block collection for validation
    final collection = BlockCollection(blocks: _blocks);

    // Validate the pattern
    final isValid = collection.isValidPattern();

    // Cache the result
    _validationCache[patternKey] = isValid;

    return isValid;
  }

  /// Get a unique key for the current pattern
  String _getPatternKey() {
    // Create a key based on block IDs and connections
    final buffer = StringBuffer();

    // Sort blocks by ID for consistency
    final sortedBlocks = List<BlockModel>.from(_blocks)
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final block in sortedBlocks) {
      buffer.write('${block.id}:${block.type}:');

      // Add connections
      for (final conn in block.connections) {
        if (conn.connectedToId != null) {
          buffer.write('${conn.id}->${conn.connectedToId}:${conn.connectedToPointId};');
        }
      }
    }

    return buffer.toString();
  }

  /// Get all connections in the workspace
  List<Map<String, dynamic>> getAllConnections() {
    final connections = <Map<String, dynamic>>[];

    for (final block in _blocks) {
      for (final conn in block.connections) {
        if (conn.connectedToId != null) {
          connections.add({
            'sourceBlockId': block.id,
            'sourceConnectionId': conn.id,
            'targetBlockId': conn.connectedToId,
            'targetConnectionId': conn.connectedToPointId,
          });
        }
      }
    }

    return connections;
  }

  /// Get all user-saved patterns
  Future<List<BlockCollection>> getUserPatterns() async {
    try {
      final List<PatternModel> patterns = await _storageService.getUserPatterns(_userId);

      // Extract BlockCollection from PatternModel
      return patterns.map((pattern) {
        // Add pattern ID to metadata
        final blockCollection = pattern.blockCollection;
        final updatedMetadata = Map<String, dynamic>.from(blockCollection.metadata)
          ..['patternId'] = pattern.id;

        return BlockCollection(
          blocks: blockCollection.blocks,
          name: pattern.name,
          description: pattern.description,
          difficulty: blockCollection.difficulty,
          region: blockCollection.region,
          tags: pattern.tags,
          creator: pattern.userId,
          createdAt: pattern.createdAt,
          modifiedAt: pattern.modifiedAt,
          metadata: updatedMetadata,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user patterns: $e');
      return [];
    }
  }

  /// Get patterns by tag
  Future<List<BlockCollection>> getPatternsByTag(String tag) async {
    try {
      // Get all patterns for the user
      final List<PatternModel> allPatterns = await _storageService.getUserPatterns(_userId);

      // Filter by tag
      final List<PatternModel> patterns = allPatterns.where((pattern) => pattern.tags.contains(tag)).toList();

      // Extract BlockCollection from PatternModel
      return patterns.map((pattern) {
        // Add pattern ID to metadata
        final blockCollection = pattern.blockCollection;
        final updatedMetadata = Map<String, dynamic>.from(blockCollection.metadata)
          ..['patternId'] = pattern.id;

        return BlockCollection(
          blocks: blockCollection.blocks,
          name: pattern.name,
          description: pattern.description,
          difficulty: blockCollection.difficulty,
          region: blockCollection.region,
          tags: pattern.tags,
          creator: pattern.userId,
          createdAt: pattern.createdAt,
          modifiedAt: pattern.modifiedAt,
          metadata: updatedMetadata,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting patterns by tag: $e');
      return [];
    }
  }

  /// Get patterns by difficulty
  Future<List<BlockCollection>> getPatternsByDifficulty(PatternDifficulty difficulty) async {
    try {
      // Use the value property from the enum
      int difficultyValue = difficulty.value;

      // Get all patterns for the user
      final List<PatternModel> allPatterns = await _storageService.getUserPatterns(_userId);

      // Filter by difficulty
      final List<PatternModel> patterns = allPatterns.where((pattern) => pattern.difficultyLevel == difficultyValue).toList();

      // Extract BlockCollection from PatternModel
      return patterns.map((pattern) {
        // Add pattern ID to metadata
        final blockCollection = pattern.blockCollection;
        final updatedMetadata = Map<String, dynamic>.from(blockCollection.metadata)
          ..['patternId'] = pattern.id;

        return BlockCollection(
          blocks: blockCollection.blocks,
          name: pattern.name,
          description: pattern.description,
          difficulty: blockCollection.difficulty,
          region: blockCollection.region,
          tags: pattern.tags,
          creator: pattern.userId,
          createdAt: pattern.createdAt,
          modifiedAt: pattern.modifiedAt,
          metadata: updatedMetadata,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting patterns by difficulty: $e');
      return [];
    }
  }

  /// Delete a saved pattern
  Future<void> deletePattern(String patternId) async {
    try {
      await _storageService.deletePattern(_userId, patternId);

      // Remove from recent patterns if present
      _recentPatterns.removeWhere((pattern) =>
        pattern.metadata.containsKey('patternId') &&
        pattern.metadata['patternId'] == patternId
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting pattern: $e');
    }
  }

  /// Load recent patterns
  Future<void> _loadRecentPatterns() async {
    try {
      // Get all patterns for the user
      final List<PatternModel> allPatterns = await _storageService.getUserPatterns(_userId);

      // Sort by modified date (newest first) and limit
      allPatterns.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      final List<PatternModel> recentPatterns = allPatterns.take(_maxRecentPatterns).toList();

      // Extract BlockCollection from PatternModel
      _recentPatterns = recentPatterns.map((pattern) {
        // Add pattern ID to metadata
        final blockCollection = pattern.blockCollection;
        final updatedMetadata = Map<String, dynamic>.from(blockCollection.metadata)
          ..['patternId'] = pattern.id;

        return BlockCollection(
          blocks: blockCollection.blocks,
          name: pattern.name,
          description: pattern.description,
          difficulty: blockCollection.difficulty,
          region: blockCollection.region,
          tags: pattern.tags,
          creator: pattern.userId,
          createdAt: pattern.createdAt,
          modifiedAt: pattern.modifiedAt,
          metadata: updatedMetadata,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading recent patterns: $e');
    }
  }

  /// Add a pattern to recent patterns
  Future<void> _addToRecentPatterns(BlockCollection pattern) async {
    // Check if pattern is already in recent patterns
    final existingIndex = _recentPatterns.indexWhere((p) =>
      p.metadata.containsKey('patternId') &&
      p.metadata['patternId'] == pattern.metadata['patternId']
    );

    if (existingIndex != -1) {
      // Remove existing entry
      _recentPatterns.removeAt(existingIndex);
    }

    // Add to beginning of list
    _recentPatterns.insert(0, pattern);

    // Limit size
    if (_recentPatterns.length > _maxRecentPatterns) {
      _recentPatterns = _recentPatterns.sublist(0, _maxRecentPatterns);
    }
  }

  /// Check if the pattern meets specific requirements
  bool patternMeetsRequirements(Map<String, dynamic> requirements) {
    // Check for minimum connections
    if (requirements.containsKey('minConnections')) {
      final minConnections = requirements['minConnections'] as int;
      final connectionCount = getAllConnections().length;

      if (connectionCount < minConnections) {
        return false;
      }
    }

      // Check for required block types
      if (requirements.containsKey('requiresBlockType')) {
        final requiredTypes = requirements['requiresBlockType'] as List<dynamic>;

        for (final typeStr in requiredTypes) {
          if (!_containsBlockTypeName(typeStr.toString())) {
            return false;
          }
        }
      }

    // Check for specific connections
    if (requirements.containsKey('requiresConnection')) {
      final requiredConnections = requirements['requiresConnection'] as List<dynamic>;

      for (final connSpec in requiredConnections) {
        if (!_checkConnectionRequirement(connSpec as Map<String, dynamic>)) {
          return false;
        }
      }
    }

    // Check for pattern structure
    if (requirements.containsKey('requiresStructure')) {
      final requiredStructure = requirements['requiresStructure'] as String;

      if (requiredStructure == 'loop' && !_hasLoopStructure()) {
        return false;
      } else if (requiredStructure == 'sequence' && !_hasSequenceStructure()) {
        return false;
      } else if (requiredStructure == 'conditional' && !_hasConditionalStructure()) {
        return false;
      }
    }

    return true;
  }

  /// Check if the pattern contains a specific connection
  bool _checkConnectionRequirement(Map<String, dynamic> connectionSpec) {
    // Create a block collection for validation
    final collection = BlockCollection(blocks: _blocks);

    return collection.containsConnection(connectionSpec);
  }

  /// Check if the pattern has a loop structure
  bool _hasLoopStructure() {
    // Check for loop blocks
    if (_containsBlockType(BlockType.loop)) {
      return true;
    }

    // Check for cycles in the connection graph
    final collection = BlockCollection(blocks: _blocks);
    return collection.findCycles().isNotEmpty;
  }

  /// Check if the pattern has a sequence structure
  bool _hasSequenceStructure() {
    // Check for at least 3 blocks connected in sequence
    final collection = BlockCollection(blocks: _blocks);

    // Get connection graph
    final graph = collection.getConnectionGraph();

    // Check for a path of length at least 3
    for (final startId in graph.keys) {
      final visited = <String>{};
      final path = <String>[];

      void dfs(String currentId) {
        visited.add(currentId);
        path.add(currentId);

        if (path.length >= 3) {
          return; // Found a sequence of at least 3 blocks
        }

        for (final neighborId in graph[currentId] ?? []) {
          if (!visited.contains(neighborId)) {
            dfs(neighborId);
          }
        }

        path.removeLast();
      }

      dfs(startId);

      if (path.length >= 3) {
        return true;
      }
    }

    return false;
  }

  /// Check if the pattern has a conditional structure
  bool _hasConditionalStructure() {
    // In a real implementation, this would check for conditional blocks
    // For now, we'll just return false
    return false;
  }

  /// Check if the pattern contains a block of a specific type
  bool _containsBlockType(BlockType blockType) {
    return _blocks.any((block) => block.type == blockType);
  }

  /// Check if the pattern contains a block with a specific type name
  bool _containsBlockTypeName(String blockTypeName) {
    // Convert string to BlockType
    try {
      final blockType = BlockType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == blockTypeName.toLowerCase(),
        orElse: () => throw Exception('Invalid block type: $blockTypeName'),
      );
      return _containsBlockType(blockType);
    } catch (_) {
      return false;
    }
  }

  /// Get a block by ID
  BlockModel? getBlockById(String id) {
    try {
      return _blocks.firstWhere((block) => block.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Try to connect two blocks
  bool tryConnect(String blockId, String connectionId) {
    // Get the source block and connection
    final sourceBlock = getBlockById(blockId);
    if (sourceBlock == null) return false;

    // Find the connection in the source block
    final sourceConnection = sourceBlock.connections.firstWhere(
      (conn) => conn.id == connectionId,
      orElse: () => BlockConnection(
        id: '',
        name: '',
        type: ConnectionType.input,
        position: const Offset(0, 0),
      ),
    );

    if (sourceConnection.id.isEmpty) return false;

    // If there's a selected block, try to connect to it
    if (_selectedBlockId != null && _selectedBlockId != blockId) {
      final targetBlock = getBlockById(_selectedBlockId!);
      if (targetBlock == null) return false;

      // Find a compatible connection in the target block
      final compatibleConnection = targetBlock.connections.firstWhere(
        (conn) => _areConnectionsCompatible(sourceConnection, conn),
        orElse: () => BlockConnection(
          id: '',
          name: '',
          type: ConnectionType.input,
          position: const Offset(0, 0),
        ),
      );

      if (compatibleConnection.id.isEmpty) return false;

      // Create the connection
      return connectBlocks(
        sourceBlock.id, sourceConnection.id,
        targetBlock.id, compatibleConnection.id,
      );
    }

    return false;
  }

  /// Check if two connections are compatible
  bool _areConnectionsCompatible(BlockConnection conn1, BlockConnection conn2) {
    // Input can connect to output and vice versa
    return (conn1.type == ConnectionType.input && conn2.type == ConnectionType.output) ||
           (conn1.type == ConnectionType.output && conn2.type == ConnectionType.input);
  }

  /// Update block properties
  void updateBlockProperties(String blockId, Map<String, dynamic> properties) {
    final block = getBlockById(blockId);
    if (block == null) return;

    // Create updated block with new properties
    final updatedBlock = BlockModel(
      id: block.id,
      name: block.name,
      type: block.type,
      position: block.position,
      size: block.size,
      properties: properties,
      connections: block.connections,
    );

    // Update the block
    updateBlock(updatedBlock);
  }
}

