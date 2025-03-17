import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_model.dart';
import 'package:kente_codeweaver/models/block_type.dart';

/// Widget representing a block in the visual programming environment
class BlockWidget extends StatefulWidget {
  /// The block model this widget represents
  final BlockModel block;
  
  /// Callback when the block is moved
  final Function(BlockModel block, Offset position)? onBlockMoved;
  
  /// Callback when a connection point is tapped
  final Function(BlockModel block, BlockConnection connection)? onConnectionTapped;
  
  /// Callback when the block is tapped
  final Function(BlockModel block)? onBlockTapped;
  
  /// Whether the block is selected
  final bool isSelected;
  
  /// Create a block widget
  const BlockWidget({
    Key? key,
    required this.block,
    this.onBlockMoved,
    this.onConnectionTapped,
    this.onBlockTapped,
    this.isSelected = false,
  }) : super(key: key);
  
  @override
  _BlockWidgetState createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.block.position.dx,
      top: widget.block.position.dy,
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onTap: () {
          if (widget.onBlockTapped != null) {
            widget.onBlockTapped!(widget.block);
          }
        },
        child: Container(
          width: widget.block.size.width,
          height: widget.block.size.height,
          decoration: BoxDecoration(
            color: _getBlockColor(),
            borderRadius: BorderRadius.circular(8.0),
            border: widget.isSelected
                ? Border.all(color: Colors.yellow, width: 3.0)
                : Border.all(color: Colors.black54, width: 1.0),
            boxShadow: _isDragging
                ? [BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Block header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _getBlockColor().withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                child: Text(
                  widget.block.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Block content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildBlockContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the content of the block based on its type
  Widget _buildBlockContent() {
    // Display different content based on block type
    switch (widget.block.type) {
      case BlockType.pattern:
        return _buildPatternBlockContent();
      case BlockType.color:
        return _buildColorBlockContent();
      case BlockType.structure:
        return _buildStructureBlockContent();
      case BlockType.loop:
        return _buildLoopBlockContent();
      case BlockType.column:
        return _buildColumnBlockContent();
      default:
        return const Center(child: Text('Unknown block type'));
    }
  }
  
  /// Build pattern block content
  Widget _buildPatternBlockContent() {
    final patternType = widget.block.properties['patternType'] ?? 'default';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.dashboard,
          size: 32,
          color: _getBlockColor().withOpacity(0.8),
        ),
        const SizedBox(height: 4),
        Text(
          'Pattern: $patternType',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Build color block content
  Widget _buildColorBlockContent() {
    final colorStr = widget.block.properties['color'] ?? 'black';
    Color blockColor;
    
    try {
      if (colorStr.startsWith('#')) {
        blockColor = Color(int.parse('0xFF${colorStr.substring(1)}'));
      } else {
        // Map common color names to colors
        switch (colorStr.toLowerCase()) {
          case 'red':
            blockColor = Colors.red;
            break;
          case 'green':
            blockColor = Colors.green;
            break;
          case 'blue':
            blockColor = Colors.blue;
            break;
          case 'yellow':
            blockColor = Colors.yellow;
            break;
          default:
            blockColor = Colors.black;
        }
      }
    } catch (_) {
      blockColor = Colors.black;
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: blockColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Color: $colorStr',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Build structure block content
  Widget _buildStructureBlockContent() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.view_module,
          size: 32,
          color: Colors.indigo,
        ),
        SizedBox(height: 4),
        Text(
          'Structure Block',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Build loop block content
  Widget _buildLoopBlockContent() {
    final count = widget.block.properties['count'] ?? 1;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.loop,
          size: 32,
          color: Colors.orange.shade800,
        ),
        const SizedBox(height: 4),
        Text(
          'Repeat $count times',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Build column block content
  Widget _buildColumnBlockContent() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.view_column,
          size: 32,
          color: Colors.teal,
        ),
        SizedBox(height: 4),
        Text(
          'Column Block',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Get the color for the block based on its type
  Color _getBlockColor() {
    switch (widget.block.type) {
      case BlockType.pattern:
        return Colors.blue;
      case BlockType.color:
        return Colors.purple;
      case BlockType.structure:
        return Colors.indigo;
      case BlockType.loop:
        return Colors.orange;
      case BlockType.column:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  /// Handle pan gesture start
  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = details.localPosition;
    });
  }
  
  /// Handle pan gesture update
  void _handlePanUpdate(DragUpdateDetails details) {
    final Offset newPosition = Offset(
      widget.block.position.dx + details.delta.dx,
      widget.block.position.dy + details.delta.dy,
    );
    
    if (widget.onBlockMoved != null) {
      widget.onBlockMoved!(widget.block, newPosition);
    }
  }
  
  /// Handle pan gesture end
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }
  
  /// Build the connection points
  List<Widget> _buildConnectionPoints() {
    final List<Widget> connectionWidgets = [];
    
    for (final connection in widget.block.connections) {
      connectionWidgets.add(
        Positioned(
          left: connection.position.dx - 6,
          top: connection.position.dy - 6,
          child: GestureDetector(
            onTap: () {
              if (widget.onConnectionTapped != null) {
                widget.onConnectionTapped!(widget.block, connection);
              }
            },
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getConnectionColor(connection.type),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ),
      );
    }
    
    return connectionWidgets;
  }
  
  /// Get color for connection based on type
  Color _getConnectionColor(ConnectionType type) {
    switch (type) {
      case ConnectionType.input:
        return Colors.green;
      case ConnectionType.output:
        return Colors.red;
      case ConnectionType.bidirectional:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}