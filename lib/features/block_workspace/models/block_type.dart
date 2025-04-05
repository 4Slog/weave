// filepath: lib/models/block_type.dart
import 'package:flutter/foundation.dart';

/// Defines the different types of blocks available in the application
/// as specified in the technical implementation guide.
enum BlockType {
  /// Pattern blocks represent specific Kente weaving patterns
  pattern,
  
  /// Color blocks define the color properties of the pattern
  color,
  
  /// Structure blocks determine how patterns are arranged
  structure,
  
  /// Loop blocks represent repeated patterns in Kente weaving
  loop,
  
  /// Column blocks represent vertical sections in the pattern
  column,
}

/// Extension methods for BlockType to provide additional functionality
extension BlockTypeExtension on BlockType {
  /// Get a user-friendly display name for this block type
  String get displayName {
    switch (this) {
      case BlockType.pattern:
        return 'Pattern Block';
      case BlockType.color:
        return 'Color Block';
      case BlockType.structure:
        return 'Structure Block';
      case BlockType.loop:
        return 'Loop Block';
      case BlockType.column:
        return 'Column Block';
      default:
        return 'Unknown Block';
    }
  }
  
  /// Get a short description of what this block type does
  String get description {
    switch (this) {
      case BlockType.pattern:
        return 'Creates a specific Kente weaving pattern';
      case BlockType.color:
        return 'Defines colors used in the pattern';
      case BlockType.structure:
        return 'Determines how patterns are arranged';
      case BlockType.loop:
        return 'Repeats patterns multiple times';
      case BlockType.column:
        return 'Creates vertical sections in the pattern';
      default:
        return 'Unknown block type';
    }
  }
  
  /// Check if this block type can connect to another block type
  bool canConnectTo(BlockType other) {
    // Define connection rules based on block types
    switch (this) {
      case BlockType.pattern:
        return other == BlockType.color || other == BlockType.structure;
      case BlockType.color:
        return other == BlockType.pattern || other == BlockType.loop;
      case BlockType.structure:
        return other == BlockType.pattern || other == BlockType.column;
      case BlockType.loop:
        return other == BlockType.pattern || other == BlockType.color;
      case BlockType.column:
        return other == BlockType.structure;
      default:
        return false;
    }
  }
}
