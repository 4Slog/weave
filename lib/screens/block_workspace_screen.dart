import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:kente_codeweaver/providers/block_provider.dart';
import 'package:kente_codeweaver/services/block_definition_service.dart';
import 'package:kente_codeweaver/services/story_mentor_service.dart';
import 'package:kente_codeweaver/widgets/contextual_hint_widget.dart';
import 'package:kente_codeweaver/painters/connections_painter.dart';  // Add this import
import 'package:uuid/uuid.dart';
import 'dart:async';

/// Screen for the block workspace where users create patterns by connecting blocks
class BlockWorkspaceScreen extends StatefulWidget {
  /// Challenge context containing requirements, hints, and other metadata
  final Map<String, dynamic> challengeContext;
  
  /// The user's current progress information
  final UserProgress userProgress;
  
  /// Optional callback for when the user completes the challenge
  final Function(bool success)? onChallengeComplete;
  
  const BlockWorkspaceScreen({
    Key? key, 
    required this.challengeContext,
    required this.userProgress,
    this.onChallengeComplete,
  }) : super(key: key);

  @override
  _BlockWorkspaceScreenState createState() => _BlockWorkspaceScreenState();
}

class _BlockWorkspaceScreenState extends State<BlockWorkspaceScreen> with TickerProviderStateMixin {
  final StoryMentorService _mentorService = StoryMentorService();
  final BlockDefinitionService _blockService = BlockDefinitionService();
  final Uuid _uuid = Uuid(); // For generating unique block IDs
  
  Map<String, dynamic>? _currentHint;
  bool _isHintVisible = true;
  Timer? _inactivityTimer;
  int _timeSinceLastAction = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Set up the challenge context in the mentor service
    _mentorService.setCurrentChallengeContext(widget.challengeContext);
    
    // Initial loading of block definitions
    _initBlocks();
    
    // Set up inactivity timer to track time without user actions
    _inactivityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _timeSinceLastAction += 5;
      });
      
      // Update the mentor service
      _mentorService.updateTimeWithoutProgress(5);
      
      // Show a new hint if user has been inactive for a while
      if (_timeSinceLastAction >= 30 && (_timeSinceLastAction % 30 == 0)) {
        _updateHint();
      }
    });
  }
  
  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _initBlocks() async {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    
    // Set initial blocks from challenge if provided
    if (widget.challengeContext.containsKey('initialBlocks')) {
      blockProvider.clearBlocks();
      
      // Add each initial block to the workspace
      final initialBlocks = widget.challengeContext['initialBlocks'] as List;
      for (var blockData in initialBlocks) {
        final block = BlockModel.fromJson({
          ...blockData,
          'id': _uuid.v4(), // Ensure unique ID for each block
        });
        blockProvider.addBlock(block);
      }
    }
    
    // Set available block types based on the challenge
    if (widget.challengeContext.containsKey('availableBlockTypes')) {
      blockProvider.setAvailableBlockTypes(
        List<String>.from(widget.challengeContext['availableBlockTypes'])
      );
    }
    
    // Request initial hint
    _updateHint();
  }
  
  /// Updates the current hint based on workspace state
  void _updateHint() {
    // Get the current blocks from provider
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    
    // Create a BlockCollection from the current blocks
    final currentCollection = BlockCollection(blocks: blockProvider.blocks);
    
    // Get contextual hint
    setState(() {
      _currentHint = _mentorService.getContextualHint(
        currentCollection, 
        widget.userProgress,
      );
      _isHintVisible = true;
    });
  }
  
  /// Records a user action and updates hints
  void _recordAction({
    required String actionType,
    required bool wasSuccessful,
    String? blockId,
    String? errorType,
  }) {
    _mentorService.recordUserAction(
      actionType: actionType,
      wasSuccessful: wasSuccessful,
      blockId: blockId,
      errorType: errorType,
    );
    
    // Reset inactivity timer
    setState(() {
      _timeSinceLastAction = 0;
    });
    
    // Update hint after action
    _updateHint();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challengeContext['title'] ?? 'Block Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _updateHint,
            tooltip: 'Get Hint',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _validatePattern,
            tooltip: 'Validate Pattern',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main workspace content
          Column(
            children: [
              // Block workspace area
              Expanded(
                flex: 3,
                child: _buildBlockWorkspace(),
              ),
              
              // Block palette
              Expanded(
                flex: 1,
                child: _buildBlockPalette(),
              ),
            ],
          ),
          
          // Contextual hint overlay
          if (_isHintVisible && _currentHint != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: ContextualHintWidget(
                hintText: _currentHint!['text'],
                tone: _currentHint!['tone'],
                imagePath: _currentHint!['imagePath'],
                isImportant: _currentHint!['isImportant'],
                onDismiss: () {
                  setState(() {
                    _isHintVisible = false;
                  });
                },
              ),
            ),
            
          // Loading overlay during validation
          if (_isValidating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Builds the main block workspace where blocks can be connected
  Widget _buildBlockWorkspace() {
    return Consumer<BlockProvider>(
      builder: (context, blockProvider, child) {
        return Stack(
          children: [
            // The grid background
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                backgroundBlendMode: BlendMode.multiply,
                image: const DecorationImage(
                  image: AssetImage('assets/images/grid_background.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
            
            // The connection lines between blocks
            CustomPaint(
              painter: ConnectionsPainter(blocks: blockProvider.blocks),
              size: Size.infinite,
            ),
            
            // The blocks
            ...blockProvider.blocks.map((block) {
              return _buildDraggableBlock(block, blockProvider);
            }).toList(),
            
            // Drop target for adding new blocks
            DragTarget<BlockModel>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: Colors.transparent,
                );
              },
              onAccept: (block) {
                // When a block is dragged from the palette to the workspace
                if (!blockProvider.blocks.any((b) => b.id == block.id)) {
                  // This is a new block from the palette
                  final newBlock = block.copy(id: _uuid.v4());
                  blockProvider.addBlock(newBlock);
                  
                  _recordAction(
                    actionType: 'addBlock',
                    wasSuccessful: true,
                    blockId: newBlock.id,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  /// Builds a draggable block in the workspace
  Widget _buildDraggableBlock(BlockModel block, BlockProvider blockProvider) {
    return Positioned(
      left: block.position.dx,
      top: block.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final newPosition = Offset(
            block.position.dx + details.delta.dx,
            block.position.dy + details.delta.dy,
          );
          blockProvider.updateBlockPosition(block.id, newPosition);
        },
        onPanEnd: (_) {
          _attemptConnections(block, blockProvider);
          
          _recordAction(
            actionType: 'moveBlock',
            wasSuccessful: true,
            blockId: block.id,
          );
        },
        child: _buildBlockWidget(block),
      ),
    );
  }
  
  /// Attempts to connect blocks when they are positioned close to each other
  void _attemptConnections(BlockModel block, BlockProvider blockProvider) {
    // Get the current block collection
    final collection = BlockCollection(blocks: blockProvider.blocks);
    
    // Check each connection point on this block
    for (var conn in block.connections) {
      // Skip if already connected
      if (conn.connectedToId != null) continue;
      
      // Get the global position of this connection point
      final connGlobalPos = Offset(
        block.position.dx + conn.position.dx,
        block.position.dy + conn.position.dy,
      );
      
      // Check all other blocks for potential connections
      for (var otherBlock in blockProvider.blocks) {
        // Skip self
        if (otherBlock.id == block.id) continue;
        
        for (var otherConn in otherBlock.connections) {
          // Skip if already connected
          if (otherConn.connectedToId != null) continue;
          
          // Calculate the position of the other connection
          final otherConnGlobalPos = Offset(
            otherBlock.position.dx + otherConn.position.dx,
            otherBlock.position.dy + otherConn.position.dy,
          );
          
          // Check if connections are close enough
          final distance = (connGlobalPos - otherConnGlobalPos).distance;
          if (distance < 20) {  // 20 pixels connection distance threshold
            // Try to connect
            bool connected = collection.connectBlocks(
              block.id, conn.id, 
              otherBlock.id, otherConn.id
            );
            
            if (connected) {
              // Update blocks in the provider
              blockProvider.importBlocksFromJson(collection.toJson());
              
              _recordAction(
                actionType: 'connectBlocks',
                wasSuccessful: true,
                blockId: block.id,
              );
              
              return;  // One connection at a time
            }
          }
        }
      }
    }
  }
  
  /// Builds the visual representation of a block
  Widget _buildBlockWidget(BlockModel block) {
    return Container(
      width: block.size.width,
      height: block.size.height,
      decoration: BoxDecoration(
        color: Color(int.parse(block.colorHex.substring(1), radix: 16) + 0xFF000000),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Block content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon if available
                if (block.iconPath.isNotEmpty)
                  Image.asset(
                    block.iconPath,
                    width: 40,
                    height: 40,
                  )
                else
                  Icon(
                    _getIconForBlockType(block.type),
                    size: 40,
                    color: Colors.white,
                  ),
                
                // Block name
                Text(
                  block.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Connection points
          ...block.connections.map((conn) {
            return Positioned(
              left: conn.position.dx - 5,
              top: conn.position.dy - 5,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: conn.connectedToId != null ? Colors.green : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black54,
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  /// Builds the block palette at the bottom of the screen
  Widget _buildBlockPalette() {
    return Consumer<BlockProvider>(
      builder: (context, blockProvider, child) {
        // Get available blocks based on the provider's availableBlockTypes
        final availableBlocks = _blockService.allBlocks.where(
          (block) => blockProvider.availableBlockTypes.contains(block.type)
        ).toList();
        
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: availableBlocks.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final block = availableBlocks[index];
              return _buildPaletteBlock(block);
            },
          ),
        );
      },
    );
  }
  
  /// Builds a palette block that can be dragged to the workspace
  Widget _buildPaletteBlock(BlockModel block) {
    return Draggable<BlockModel>(
      data: block,
      feedback: _buildBlockWidget(block),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _buildBlockWidget(block),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildBlockWidget(block),
      ),
    );
  }
  
  /// Gets an appropriate icon for the block type
  IconData _getIconForBlockType(BlockType type) {
    switch (type) {
      case BlockType.pattern:
        return Icons.pattern;
      case BlockType.color:
        return Icons.palette;
      case BlockType.structure:
        return Icons.architecture;
      case BlockType.loop:
        return Icons.loop;
      case BlockType.row:
        return Icons.table_rows;
      case BlockType.column:
        return Icons.view_column;
      default:
        return Icons.widgets;
    }
  }
  
  /// Validates the current pattern against the challenge requirements
  void _validatePattern() {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    
    // Create a collection from the current blocks
    final currentCollection = BlockCollection(blocks: blockProvider.blocks);
    
    // Validate it
    final isValid = _mentorService.validatePatternForChallenge(currentCollection);
    
    // Record the action
    _recordAction(
      actionType: 'validatePattern',
      wasSuccessful: isValid,
    );
    
    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isValid 
              ? 'Excellent! Your pattern is correct!'
              : 'Not quite right. Try again with the hints.',
        ),
        backgroundColor: isValid ? Colors.green : Colors.orange,
      ),
    );
    
    // If valid, add navigation to next step
    if (isValid) {
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Challenge Completed!'),
          content: const Text('You\'ve successfully completed this challenge. Ready to continue the story?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to the next step in the story
                // This would be implemented based on the app's navigation flow
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }
}