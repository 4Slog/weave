import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_model.dart';

class BlockWidget extends StatelessWidget {
  final BlockModel block;
  final bool isPalette;
  final bool isPreview;
  
  const BlockWidget({
    Key? key,
    required this.block,
    this.isPalette = false,
    this.isPreview = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 50,
      decoration: BoxDecoration(
        color: isPreview 
          ? Color.fromRGBO(
              (block.color.value >> 16) & 0xFF, // Red component
              (block.color.value >> 8) & 0xFF,  // Green component
              block.color.value & 0xFF,         // Blue component
              0.7
            )
          : block.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isPreview ? null : [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPalette ? null : () => _showBlockOptions(context),
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForBlockType(block.type),
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _getDisplayText(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForBlockType(BlockType type) {
    return switch (type) {
      BlockType.move => Icons.arrow_forward,
      BlockType.turn => Icons.refresh,
      BlockType.repeat => Icons.repeat,
      BlockType.ifCondition => Icons.device_hub,
      BlockType.variable => Icons.data_usage,
      BlockType.function => Icons.functions
    };
  }
  
  String _getDisplayText() {
    if (block.value.length > 15) {
      return '${block.value.substring(0, 12)}...';
    }
    return block.value;
  }
  
  void _showBlockOptions(BuildContext context) {
    if (isPalette || isPreview) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                block.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Block'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Block'),
                onTap: () {
                  Navigator.pop(context);
                  // Delete block implementation
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showEditDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: block.value);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Block'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Block Value',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Update block value implementation
              },
              child: Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}