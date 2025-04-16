import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// Represents a block in the block workspace
class BlockModel {
  /// Unique identifier for this block
  final String id;

  /// Type of block (e.g., 'move', 'turn', 'repeat')
  final String type;

  /// Position of the block in the workspace
  final Offset position;

  /// Parameters for this block
  final Map<String, dynamic> parameters;

  /// Connected blocks (children)
  final List<BlockModel> children;

  /// Parent block (if any)
  final BlockModel? parent;

  /// Creates a new block with the given properties
  BlockModel({
    String? id,
    required this.type,
    this.position = Offset.zero,
    this.parameters = const {},
    this.children = const [],
    this.parent,
  }) : id = id ?? const Uuid().v4();

  /// Create a copy of this block with the given fields replaced
  BlockModel copyWith({
    String? id,
    String? type,
    Offset? position,
    Map<String, dynamic>? parameters,
    List<BlockModel>? children,
    BlockModel? parent,
  }) {
    return BlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      parameters: parameters ?? this.parameters,
      children: children ?? this.children,
      parent: parent ?? this.parent,
    );
  }

  /// Create a BlockModel from JSON data
  factory BlockModel.fromJson(Map<String, dynamic> json) {
    // Parse children
    List<BlockModel> childBlocks = [];
    if (json['children'] != null) {
      childBlocks = (json['children'] as List)
          .map((childJson) => BlockModel.fromJson(childJson))
          .toList();
    }

    return BlockModel(
      id: json['id'] ?? const Uuid().v4(),
      type: json['type'] ?? 'unknown',
      position: json['position'] != null
          ? Offset(
              (json['position']['x'] ?? 0).toDouble(),
              (json['position']['y'] ?? 0).toDouble(),
            )
          : Offset.zero,
      parameters: json['parameters'] ?? {},
      children: childBlocks,
    );
  }

  /// Convert this block to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'parameters': parameters,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  /// Get a parameter value with a default
  T getParameter<T>(String key, T defaultValue) {
    return parameters.containsKey(key) ? parameters[key] as T : defaultValue;
  }

  /// Check if this block has a specific parameter
  bool hasParameter(String key) {
    return parameters.containsKey(key);
  }

  /// Get the number of children
  int get childCount => children.length;

  /// Check if this block has children
  bool get hasChildren => children.isNotEmpty;

  /// Get a string representation of this block
  @override
  String toString() {
    return 'BlockModel(id: $id, type: $type, childCount: $childCount)';
  }
}
