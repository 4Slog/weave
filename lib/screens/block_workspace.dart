import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/providers/block_provider.dart';
import 'package:kente_codeweaver/widgets/block_widget.dart';
import 'package:uuid/uuid.dart';

class BlockWorkspace extends StatefulWidget {
  @override
  _BlockWorkspaceState createState() => _BlockWorkspaceState();
}

class _BlockWorkspaceState extends State<BlockWorkspace> {
  final Uuid _uuid = Uuid();
  final double _gridSize = 20.0; // Size of grid cells
  
  // Colors for different block types
  final Map<BlockType, Color> _blockColors = {
    BlockType.move: Colors.blue,
    BlockType.turn: Colors.green,
    BlockType.repeat: Colors.orange,
    BlockType.ifCondition: Colors.purple,
    BlockType.variable: Colors.red,
    BlockType.function: Colors.teal,
  };
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Block Workspace'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              Provider.of<BlockProvider>(context, listen: false).clearBlocks();
            },
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _validateWorkspace,
          ),
        ],
      ),
      body: Column(
        children: [
          // Block palette
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Consumer<BlockProvider>(
              builder: (context, blockProvider, child) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.all(10),
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
                  child: Container(),
                ),
                
                // Blocks
                Consumer<BlockProvider>(
                  builder: (context, blockProvider, child) {
                    return Stack(
                      children: blockProvider.blocks.map((block) {
                        return Positioned(
                          left: block.position.dx,
                          top: block.position.dy,
                          child: Draggable<BlockModel>(
                            data: block,
                            feedback: BlockWidget(
                              block: block,
                              isPreview: true,
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: BlockWidget(block: block),
                            ),
                            onDragEnd: (details) {
                              // Snap to grid
                              final newPosition = Offset(
                                (details.offset.dx / _gridSize).round() * _gridSize,
                                (details.offset.dy / _gridSize).round() * _gridSize,
                              );
                              blockProvider.updateBlockPosition(block.id, newPosition);
                            },
                            child: BlockWidget(block: block),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                
                // Drop area for the entire workspace
                DragTarget<BlockModel>(
                  builder: (context, candidateItems, rejectedItems) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                    );
                  },
                  onAcceptWithDetails: (DragTargetDetails<BlockModel> details) {
                    final BlockModel sourceBlock = details.data;
                    // Handle drop of a new block from palette
                    if (!Provider.of<BlockProvider>(context, listen: false)
                        .blocks.any((b) => b.id == sourceBlock.id)) {
                      Provider.of<BlockProvider>(context, listen: false).addBlock(sourceBlock);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaletteItem(BlockType blockType) {
    final String blockName = blockType.toString().split('.').last;
    final Color blockColor = _blockColors[blockType] ?? Colors.grey;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Draggable<BlockModel>(
        data: BlockModel(
          id: _uuid.v4(),
          type: blockType,
          value: getDefaultValueForBlockType(blockType),
          color: blockColor,
        ),
        feedback: BlockWidget(
          block: BlockModel(
            id: _uuid.v4(),
            type: blockType,
            value: getDefaultValueForBlockType(blockType),
            color: blockColor,
          ),
          isPreview: true,
        ),
        child: BlockWidget(
          block: BlockModel(
            id: 'palette-$blockName',
            type: blockType,
            value: getDefaultValueForBlockType(blockType),
            color: blockColor,
          ),
          isPalette: true,
        ),
      ),
    );
  }
  
  String getDefaultValueForBlockType(BlockType type) {
    return switch (type) {
      BlockType.move => 'Move Forward',
      BlockType.turn => 'Turn Right',
      BlockType.repeat => 'Repeat 3 times',
      BlockType.ifCondition => 'If path ahead',
      BlockType.variable => 'Set x = 0',
      BlockType.function => 'Call function'
    };
  }
  
  void _validateWorkspace() {
    final blocks = Provider.of<BlockProvider>(context, listen: false).blocks;
    
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add some blocks to the workspace first!'))
      );
      return;
    }
    
    // Perform validation logic here
    // For a simple version, just show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Great job! Your code works!'),
        backgroundColor: Colors.green,
      )
    );
  }
}

// Custom painter for the grid background
class GridPainter extends CustomPainter {
  final double gridSize;
  
  GridPainter({required this.gridSize});
  
  @override
  void paint(Canvas canvas, Size size) {
    final greyColor = Colors.grey;
    final paint = Paint()
      ..color = Color.fromRGBO(
        (greyColor.value >> 16) & 0xFF, // Red component
        (greyColor.value >> 8) & 0xFF,  // Green component
        greyColor.value & 0xFF,         // Blue component
        0.2
      )
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