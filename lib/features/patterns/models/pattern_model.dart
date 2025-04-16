import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';

/// Represents a user-created pattern
class PatternModel {
  /// Unique identifier for this pattern
  final String id;

  /// ID of the user who created this pattern
  final String userId;

  /// Name of the pattern
  final String name;

  /// Description of the pattern
  final String description;

  /// Tags associated with this pattern
  final List<String> tags;

  /// ID of the challenge this pattern was created for (if any)
  final String? challengeId;

  /// Cultural context information
  final Map<String, dynamic> culturalContext;

  /// The blocks that make up this pattern
  final BlockCollection blockCollection;

  /// User rating (0-5)
  final double rating;

  /// Whether this pattern is shared publicly
  final bool isShared;

  /// When this pattern was created
  final DateTime createdAt;

  /// When this pattern was last modified
  final DateTime modifiedAt;

  /// Calculated difficulty level (1-5)
  final int difficultyLevel;

  /// Constructor
  PatternModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.tags = const [],
    this.challengeId,
    this.culturalContext = const {},
    required this.blockCollection,
    this.rating = 0.0,
    this.isShared = false,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? difficultyLevel,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    modifiedAt = modifiedAt ?? DateTime.now(),
    difficultyLevel = difficultyLevel ?? _calculateDifficulty(blockCollection);

  /// Create a copy with optional new values
  PatternModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<String>? tags,
    String? challengeId,
    Map<String, dynamic>? culturalContext,
    BlockCollection? blockCollection,
    double? rating,
    bool? isShared,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? difficultyLevel,
  }) {
    return PatternModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      challengeId: challengeId ?? this.challengeId,
      culturalContext: culturalContext ?? this.culturalContext,
      blockCollection: blockCollection ?? this.blockCollection,
      rating: rating ?? this.rating,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(), // Always update modified time
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }

  /// Create from JSON
  factory PatternModel.fromJson(Map<String, dynamic> json) {
    return PatternModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      challengeId: json['challengeId'],
      culturalContext: json['culturalContext'] ?? {},
      blockCollection: BlockCollection.fromJson(json['blockCollection']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      isShared: json['isShared'] ?? false,
      createdAt: json['createdAt'] != null ?
          DateTime.parse(json['createdAt']) : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null ?
          DateTime.parse(json['modifiedAt']) : DateTime.now(),
      difficultyLevel: json['difficultyLevel'] ?? 1,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'tags': tags,
      'challengeId': challengeId,
      'culturalContext': culturalContext,
      'blockCollection': blockCollection.toJson(),
      'rating': rating,
      'isShared': isShared,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'difficultyLevel': difficultyLevel,
    };
  }

  /// Calculate difficulty level based on block collection
  static int _calculateDifficulty(BlockCollection collection) {
    // Calculate difficulty based on number of blocks
    // Simple scoring system:
    // 1-5 blocks = level 1
    // 6-10 blocks = level 2
    // 11-15 blocks = level 3
    // 16-20 blocks = level 4
    // 21+ blocks = level 5

    int blockCount = collection.blocks.length;

    if (blockCount <= 5) {
      return 1;
    } else if (blockCount <= 10) {
      return 2;
    } else if (blockCount <= 15) {
      return 3;
    } else if (blockCount <= 20) {
      return 4;
    } else {
      return 5;
    }
  }

  /// Get the number of blocks in this pattern
  int get blockCount => blockCollection.blocks.length;

  /// Get the number of connections in this pattern
  int get connectionCount => blockCollection.countConnections();

  /// Check if this pattern has a specific block type
  bool hasBlockType(String blockType) {
    return blockCollection.containsBlockTypeName(blockType);
  }

  /// Get the structure of this pattern as a string
  /// This is a simplified implementation
  String get structure {
    // In a real implementation, this would return a structured representation
    // of the pattern's blocks and connections
    return blockCollection.blocks.map((block) => block.type).join('-');
  }

  /// Get the output of this pattern as a string
  /// This is a simplified implementation
  String get output {
    // In a real implementation, this would execute the pattern and return its output
    return 'Pattern output for $name';
  }
}

