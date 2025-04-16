import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_type.dart';

/// Model representing a pattern created with blocks
class PatternModel {
  /// Unique identifier for the pattern
  final String id;
  
  /// Name of the pattern
  final String name;
  
  /// Description of the pattern
  final String description;
  
  /// Blocks that make up this pattern
  final List<BlockModel> blocks;
  
  /// Difficulty level of the pattern (1-5)
  final int difficulty;
  
  /// Cultural significance or meaning of the pattern
  final String? culturalMeaning;
  
  /// Tags associated with this pattern
  final List<String> tags;
  
  /// Create a new pattern model
  PatternModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.blocks,
    this.difficulty = 1,
    this.culturalMeaning,
    this.tags = const [],
  });
  
  /// Create a pattern from JSON data
  factory PatternModel.fromJson(Map<String, dynamic> json) {
    return PatternModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      blocks: (json['blocks'] as List?)
          ?.map((block) => BlockModel.fromJson(block))
          .toList() ?? [],
      difficulty: json['difficulty'] ?? 1,
      culturalMeaning: json['culturalMeaning'],
      tags: (json['tags'] as List?)?.map((tag) => tag.toString()).toList() ?? [],
    );
  }
  
  /// Convert pattern to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'difficulty': difficulty,
      'culturalMeaning': culturalMeaning,
      'tags': tags,
    };
  }
  
  /// Get the count of blocks by type
  Map<BlockType, int> getBlockTypeCounts() {
    final counts = <BlockType, int>{};
    
    for (final block in blocks) {
      counts[block.type] = (counts[block.type] ?? 0) + 1;
    }
    
    return counts;
  }
  
  /// Check if the pattern contains all required block types
  bool containsAllBlockTypes(List<BlockType> requiredTypes) {
    final typesInPattern = blocks.map((block) => block.type).toSet();
    return requiredTypes.every((type) => typesInPattern.contains(type));
  }
  
  /// Get a copy of this pattern with optional new values
  PatternModel copyWith({
    String? id,
    String? name,
    String? description,
    List<BlockModel>? blocks,
    int? difficulty,
    String? culturalMeaning,
    List<String>? tags,
  }) {
    return PatternModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      blocks: blocks ?? this.blocks,
      difficulty: difficulty ?? this.difficulty,
      culturalMeaning: culturalMeaning ?? this.culturalMeaning,
      tags: tags ?? this.tags,
    );
  }
}
