import 'package:flutter/material.dart';

enum BlockType {
  move,
  turn,
  repeat,
  ifCondition,
  variable,
  function,
}

class BlockModel {
  final String id;
  final BlockType type;
  final String value;
  final Color color;
  Offset position;
  List<BlockModel> childBlocks;

  BlockModel({
    required this.id,
    required this.type,
    required this.value,
    required this.color,
    this.position = Offset.zero,
    this.childBlocks = const [],
  });

  BlockModel copyWith({
    String? id,
    BlockType? type,
    String? value,
    Color? color,
    Offset? position,
    List<BlockModel>? childBlocks,
  }) {
    return BlockModel(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      color: color ?? this.color,
      position: position ?? this.position,
      childBlocks: childBlocks ?? this.childBlocks,
    );
  }

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      id: json['id'],
      type: BlockType.values.firstWhere(
          (e) => e.toString() == 'BlockType.${json['type']}'),
      value: json['value'],
      color: json['color'] is Map
        ? Color.fromARGB(
            json['color']['a'] ?? 255,
            json['color']['r'],
            json['color']['g'],
            json['color']['b'],
          )
        : Color.fromARGB(
            255,
            (json['color'] >> 16) & 0xFF,
            (json['color'] >> 8) & 0xFF,
            json['color'] & 0xFF,
          ),
      position: Offset(json['position'][0], json['position'][1]),
      childBlocks: (json['childBlocks'] as List<dynamic>)
          .map((block) => BlockModel.fromJson(block))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'color': {
        'r': color.red,
        'g': color.green,
        'b': color.blue,
        'a': color.alpha,
      },
      'value': value,
      'position': [position.dx, position.dy],
      'childBlocks': childBlocks.map((block) => block.toJson()).toList(),
    };
  }
}