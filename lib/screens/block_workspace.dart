import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/block_type.dart';
import 'package:kente_codeweaver/models/connection_types.dart';
import 'package:kente_codeweaver/providers/block_provider.dart';
import 'package:kente_codeweaver/widgets/block_widget.dart';
import 'package:kente_codeweaver/widgets/contextual_hint_widget.dart';
import 'package:kente_codeweaver/services/story_mentor_service.dart';
import 'package:kente_codeweaver/services/adaptive_learning_service.dart';
import 'package:uuid/uuid.dart';

/// An enhanced workspace for creating and manipulating code blocks.
///
/// This workspace allows users to drag and drop blocks to create patterns
/// and solve challenges. It includes adaptive learning features and
/// contextual hints to guide users.
class BlockWorkspace extends StatefulWidget {
  /// The current story context
  final String storyContext;
  
  /// The coding concept being taught
  final String codingConcept;
  
  /// The user ID
  final String userId;
  
  /// The challenge ID if this workspace is part of a challenge
  final String? challengeId;
  
  const BlockWorkspace({
    Key? key,
    this.storyContext = 'Kente pattern creation',
    this.codingConcept = 'patterns',
    this.userId = 'default',
    this.challengeId,
  }) : super(key: key);

  @override
  _BlockWorkspaceState createState() => _BlockWorkspaceState();
}

class _BlockWorkspaceState extends State<BlockWorkspace> {
  final Uuid _uuid = Uuid();
  final double _gridSize = 20.0; // Size of grid cells
  final StoryMentorService _mentorService = StoryMentorService();
  final AdaptiveLearningService _learningService = AdaptiveLearningService();
  
  bool _showingHint = false;
  String _feedback = '';
  bool _showFeedback = false;
  BlockModel? _selectedBlock;
  
  // Colors for different block types
  final Map<BlockType, Color> _blockColors = {
    BlockType.pattern: Colors.deepPurple,
    BlockType.color: Colors.amber,
    BlockType.structure: Colors.cyan,
    BlockType.loop: Colors.orange,
    BlockType.column: Colors.teal,
  };
  
  @override
  void initState() {
    super.initState();
    // Initialize adaptive learning service with user data
    _initializeUserData();
  }
  
  /// Initialize user data and skill level
  Future<void> _initializeUserData() async {
    try {
      final level = await _learningService.getUserSkillLevel(widget.userId);
      debugPrint('User skill level: $level');
    } catch (e) {
      debugPrint('Error getting user skill level: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              Provider.of<BlockProvider>(context, listen: false).clearBlocks();
              setState(() {
                _selectedBlock = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _validateWorkspace,
          ),
          IconButton(
            icon: Icon(_showingHint ? Icons.lightbulb : Icons.lightbulb_outline),
            onPressed: () {
              setState(() {
                _showingHint = !_showingHint;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Hint area
          if (_showingHint)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildHintWidget(),
            ),
          
          // Feedback area
          if (_showFeedback)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _feedback.contains('Great') ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _feedback.contains('Great') ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _feedback.contains('Great') ? Icons.check_circle : Icons.info,
                        color: _feedback.contains('Great') ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Feedback',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _feedback.contains('Great') ? Colors.green : Colors.orange,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _showFeedback = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_feedback),
                ],
              ),
            ),
          
          // Block palette
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: const Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Consumer<BlockProvider>(
              builder: (context, blockProvider, child) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(10),
                  itemCount: blockProvider.availableBlockTypes.length,
                  itemBuilder: (context, index) {
                    final blockType = blockProvider.availableBlockTypes[index];
                    return _buildPaletteItem(blockType);
                  },
                );
              },
            ),
          ),
          
          // Workspace area
          Expanded(
            child: Stack(
              children: [
                // Grid background
                CustomPaint(
                  painter: GridPainter(gridSize: _gridSize),
                  size: Size.infinite,
                ),
                
                // Blocks
                Consumer<BlockProvider>(
                  builder: (context, blockProvider, child) {
                    return Stack(
                      children: blockProvider.blocks.map((block) {
                        return BlockWidget(
                          key: ValueKey(block.id),
                          block: block,
                          isSelected: _selectedBlock?.id == block.id,
                          onBlockTapped: _handleBlockTap,
                          onBlockMoved: (blockModel, offset) {
                            // Snap to grid
                            final snappedOffset = Offset(
                              (offset.dx / _gridSize).round() * _gridSize,
                              (offset.dy / _gridSize).round() * _gridSize,
                            );
                            blockProvider.updateBlockPosition(block.id, snappedOffset);
                          },
                          onConnectionTapped: (blockModel, connection) {
                            _handleConnectionTap(blockModel, connection);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                
                // Drop area for the entire workspace
                DragTarget<Map<String, dynamic>>(
                  builder: (context, candidateItems, rejectedItems) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                    );
                  },
                  onAcceptWithDetails: (DragTargetDetails<Map<String, dynamic>> details) {
                    _handleDrop(details.data, details.offset);
                  },
                ),
              ],
            ),
          ),
          
          // Properties panel for selected block
          if (_selectedBlock != null)
            _buildPropertiesPanel(),
        ],
      ),
    );
  }
  
  /// Build a palette item for dragging new blocks
  Widget _buildPaletteItem(BlockType blockType) {
    final blockColor = _blockColors[blockType] ?? Colors.grey;
    final String blockName = _getDisplayNameForBlockType(blockType);
    
    // Create a draggable item for the palette
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Draggable<Map<String, dynamic>>(
        // Use map instead of BlockModel for draggable data
        data: {
          'isNew': true,
          'type': blockType.toString(),
          'name': blockName,
        },
        feedback: Material(
          elevation: 4.0,
          child: Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.center,
            child: Text(
              blockName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.center,
            child: Text(
              blockName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        child: Container(
          width: 100,
          height: 60,
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Text(
            blockName,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
  
  /// Handle dropping a new block or moving an existing one
  void _handleDrop(Map<String, dynamic> data, Offset offset) {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    
    // Check if this is a new block
    if (data['isNew'] == true) {
      // Parse the block type from string
      final typeStr = data['type'] as String;
      final blockType = _parseBlockType(typeStr);
      
      // Create a new block
      final newBlock = BlockModel(
        id: _uuid.v4(),
        name: data['name'] as String? ?? _getDisplayNameForBlockType(blockType),
        type: blockType,
        position: _snapToGrid(offset),
        size: const Size(150, 100),
        connections: _createDefaultConnectionsForType(blockType),
        properties: _getDefaultPropertiesForType(blockType),
      );
      
      // Add the new block to the workspace
      blockProvider.addBlock(newBlock);
      
      // Select the new block
      setState(() {
        _selectedBlock = newBlock;
      });
    }
  }
  
  /// Handle tapping on a block
  void _handleBlockTap(BlockModel block) {
    setState(() {
      // Toggle selection
      if (_selectedBlock?.id == block.id) {
        _selectedBlock = null;
      } else {
        _selectedBlock = block;
      }
    });
  }
  
  /// Handle tapping on a connection point
  void _handleConnectionTap(BlockModel block, BlockConnection connection) {
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    
    // If we have a selected block and connection, try to connect them
    if (_selectedBlock != null && _selectedBlock!.id != block.id) {
      // Try to find a compatible connection point on the selected block
      for (final selectedConn in _selectedBlock!.connections) {
        if (connection.canConnectTo(selectedConn)) {
          // Connect the blocks
          blockProvider.connectBlocks(
            _selectedBlock!.id, selectedConn.id,
            block.id, connection.id
          );
          break;
        }
      }
    }
  }
  
  /// Build a properties panel for editing the selected block
  Widget _buildPropertiesPanel() {
    if (_selectedBlock == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: const Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Block Properties: ${_selectedBlock!.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  Provider.of<BlockProvider>(context, listen: false)
                    .removeBlock(_selectedBlock!.id);
                  setState(() {
                    _selectedBlock = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Block-specific property controls
          _buildBlockPropertyControls(),
        ],
      ),
    );
  }
  
  /// Build property controls based on the block type
  Widget _buildBlockPropertyControls() {
    if (_selectedBlock == null) return const SizedBox.shrink();
    
    final blockProvider = Provider.of<BlockProvider>(context, listen: false);
    
    switch (_selectedBlock!.type) {
      case BlockType.color:
        // Color picker
        final color = _selectedBlock!.properties['color'] ?? 'red';
        return Wrap(
          spacing: 8.0,
          children: [
            'red', 'green', 'blue', 'yellow', 'black', 'white'
          ].map((c) => InkWell(
            onTap: () {
              final updatedBlock = _selectedBlock!.copyWith(
                properties: {..._selectedBlock!.properties, 'color': c},
              );
              blockProvider.updateBlock(updatedBlock);
              setState(() {
                _selectedBlock = updatedBlock;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: c == color ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          )).toList(),
        );
        
      case BlockType.pattern:
        // Pattern selector
        final pattern = _selectedBlock!.properties['patternType'] ?? 'checker';
        return Wrap(
          spacing: 8.0,
          children: [
            'checker', 'zigzag', 'diamond', 'stripes'
          ].map((p) => InkWell(
            onTap: () {
              final updatedBlock = _selectedBlock!.copyWith(
                properties: {..._selectedBlock!.properties, 'patternType': p},
              );
              blockProvider.updateBlock(updatedBlock);
              setState(() {
                _selectedBlock = updatedBlock;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: p == pattern ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: p == pattern ? Colors.blue : Colors.grey,
                ),
              ),
              child: Text(p),
            ),
          )).toList(),
        );
        
      case BlockType.loop:
        // Loop count slider
        final count = (_selectedBlock!.properties['count'] as num? ?? 1).toInt();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repeat Count: $count'),
            Slider(
              value: count.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                final updatedBlock = _selectedBlock!.copyWith(
                  properties: {..._selectedBlock!.properties, 'count': value.toInt()},
                );
                blockProvider.updateBlock(updatedBlock);
                setState(() {
                  _selectedBlock = updatedBlock;
                });
              },
            ),
          ],
        );
        
      default:
        return const Text('No editable properties for this block type.');
    }
  }
  
  /// Validate the workspace
  void _validateWorkspace() async {
    final blocks = Provider.of<BlockProvider>(context, listen: false).blocks;
    
    if (blocks.isEmpty) {
      setState(() {
        _feedback = 'Add some blocks to the workspace first!';
        _showFeedback = true;
      });
      return;
    }
    
    // Check if the current workspace matches the challenge requirements
    if (widget.challengeId != null) {
      final isCorrect = await _learningService.validateSolution(
        widget.userId, 
        widget.challengeId!, 
        blocks
      );
      
      setState(() {
        if (isCorrect) {
          _feedback = 'Great job! Your solution works correctly.';
        } else {
          _feedback = 'Not quite right. Try to review the challenge instructions.';
        }
        _showFeedback = true;
      });
      
      // Update user progress with challenge attempt
      _learningService.trackProgress(
        widget.userId, 
        widget.challengeId!, 
        isCorrect,
        blocks.length
      );
    } else {
      // Just give generic feedback for free play
      setState(() {
        _feedback = 'Great job creating your pattern!';
        _showFeedback = true;
      });
    }
  }
  
  /// Build the hint widget
  Widget _buildHintWidget() {
    return FutureBuilder<String>(
      future: _mentorService.generateContextualHint(
        userId: widget.userId,
        storyContext: widget.storyContext,
        codingConcept: widget.codingConcept,
        hintLevel: 2,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error loading hint: ${snapshot.error}');
        } else {
          return ContextualHintWidget(text: snapshot.data ?? 'No hint available');
        }
      },
    );
  }
  
  /// Snap an offset to the grid
  Offset _snapToGrid(Offset offset) {
    return Offset(
      (offset.dx / _gridSize).round() * _gridSize,
      (offset.dy / _gridSize).round() * _gridSize,
    );
  }
  
  /// Get display name for a block type
  String _getDisplayNameForBlockType(BlockType type) {
    switch (type) {
      case BlockType.pattern:
        return 'Pattern';
      case BlockType.color:
        return 'Color';
      case BlockType.structure:
        return 'Structure';
      case BlockType.loop:
        return 'Loop';
      case BlockType.column:
        return 'Column';
      default:
        return 'Block';
    }
  }
  
  /// Parse a color from string
  Color _parseColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }
  
  /// Parse block type from string
  BlockType _parseBlockType(String typeStr) {
    try {
      final typeName = typeStr.split('.').last.toLowerCase();
      return BlockType.values.firstWhere(
        (type) => type.toString().split('.').last.toLowerCase() == typeName,
        orElse: () => BlockType.pattern,
      );
    } catch (e) {
      return BlockType.pattern;
    }
  }
  
  /// Create default connections for a block type
  List<BlockConnection> _createDefaultConnectionsForType(BlockType type) {
    switch (type) {
      case BlockType.pattern:
        return [
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
        ];
        
      case BlockType.color:
        return [
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
        ];
        
      case BlockType.loop:
        return [
          BlockConnection(
            id: const Uuid().v4(),
            name: 'Input',
            type: ConnectionType.input,
            position: const Offset(0, 50),
          ),
          BlockConnection(
            id: const Uuid().v4(),
            name: 'Content',
            type: ConnectionType.output,
            position: const Offset(75, 100),
          ),
          BlockConnection(
            id: const Uuid().v4(),
            name: 'Output',
            type: ConnectionType.output,
            position: const Offset(150, 50),
          ),
        ];
        
      default:
        return [
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
        ];
    }
  }
  
  /// Get default properties for a block type
  Map<String, dynamic> _getDefaultPropertiesForType(BlockType type) {
    switch (type) {
      case BlockType.pattern:
        return {
          'patternType': 'checker',
          'description': 'Creates a checker pattern',
        };
        
      case BlockType.color:
        return {
          'color': 'red',
          'description': 'Sets the color',
        };
        
      case BlockType.loop:
        return {
          'count': 3,
          'description': 'Repeats the pattern',
        };
        
      case BlockType.structure:
        return {
          'structureType': 'grid',
          'description': 'Creates a structure',
        };
        
      case BlockType.column:
        return {
          'width': 1,
          'description': 'Creates a column',
        };
        
      default:
        return {};
    }
  }
}

/// Custom painter for the grid background
class GridPainter extends CustomPainter {
  final double gridSize;
  
  GridPainter({required this.gridSize});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;
    
    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
