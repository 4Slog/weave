import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/block_model.dart';

class BlockProvider with ChangeNotifier {
  List<BlockModel> _blocks = [];
  List<BlockType> _availableBlockTypes = [];
  bool _isEditing = false;
  
  List<BlockModel> get blocks => _blocks;
  List<BlockType> get availableBlockTypes => _availableBlockTypes;
  bool get isEditing => _isEditing;
  
  void setAvailableBlocks(List<String> blockTypeNames) {
    _availableBlockTypes = blockTypeNames.map((name) {
      try {
        return BlockType.values.firstWhere(
          (type) => type.toString().split('.').last.toLowerCase() == name.toLowerCase(),
        );
      } catch (e) {
        // Default to move if block type not found
        return BlockType.move;
      }
    }).toList();
    
    notifyListeners();
  }
  
  void addBlock(BlockModel block) {
    _blocks.add(block);
    notifyListeners();
  }
  
  void updateBlockPosition(String id, Offset position) {
    final index = _blocks.indexWhere((block) => block.id == id);
    if (index != -1) {
      _blocks[index] = _blocks[index].copyWith(position: position);
      notifyListeners();
    }
  }
  
  void removeBlock(String id) {
    _blocks.removeWhere((block) => block.id == id);
    notifyListeners();
  }
  
  void clearBlocks() {
    _blocks = [];
    notifyListeners();
  }
  
  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }
  
  Map<String, dynamic> exportBlocksToJson() {
    return {
      'blocks': _blocks.map((block) => block.toJson()).toList(),
    };
  }
  
  void importBlocksFromJson(Map<String, dynamic> json) {
    final blockList = (json['blocks'] as List<dynamic>)
        .map((block) => BlockModel.fromJson(block))
        .toList();
    
    _blocks = blockList;
    notifyListeners();
  }
}