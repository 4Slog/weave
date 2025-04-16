import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';

/// Represents a learning path item in the user's personalized learning journey
class LearningPathItem {
  /// The concept being taught
  final String concept;

  /// Human-readable title for the concept
  final String title;

  /// Description of the concept
  final String description;

  /// Current skill level for this concept
  final SkillLevel skillLevel;

  /// Estimated time to complete in minutes
  final int estimatedTimeMinutes;

  /// Prerequisites for this concept
  final List<String> prerequisites;

  /// Learning resources for this concept
  final List<Map<String, dynamic>> resources;

  /// Challenges related to this concept
  final List<Map<String, dynamic>> challenges;

  /// Cultural elements related to this concept
  final List<Map<String, dynamic>> culturalElements;

  /// Cultural connection explanation
  final String culturalConnection;

  /// Create a learning path item
  LearningPathItem({
    required this.concept,
    required this.title,
    required this.description,
    required this.skillLevel,
    required this.estimatedTimeMinutes,
    this.prerequisites = const [],
    this.resources = const [],
    this.challenges = const [],
    this.culturalElements = const [],
    this.culturalConnection = '',
  });

  /// Create a learning path item from a map
  factory LearningPathItem.fromMap(Map<String, dynamic> map) {
    return LearningPathItem(
      concept: map['concept'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      skillLevel: SkillLevel.values.firstWhere(
        (level) => level.toString().split('.').last == map['skillLevel'],
        orElse: () => SkillLevel.novice,
      ),
      estimatedTimeMinutes: map['estimatedTimeMinutes'] as int,
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      resources: List<Map<String, dynamic>>.from(map['resources'] ?? []),
      challenges: List<Map<String, dynamic>>.from(map['challenges'] ?? []),
      culturalElements: List<Map<String, dynamic>>.from(map['culturalElements'] ?? []),
      culturalConnection: map['culturalConnection'] as String? ?? '',
    );
  }

  /// Convert this learning path item to a map
  Map<String, dynamic> toMap() {
    return {
      'concept': concept,
      'title': title,
      'description': description,
      'skillLevel': skillLevel.toString().split('.').last,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'prerequisites': prerequisites,
      'resources': resources,
      'challenges': challenges,
      'culturalElements': culturalElements,
      'culturalConnection': culturalConnection,
    };
  }
}

/// Represents a complete learning path for a user
class LearningPath {
  /// The type of learning path
  final LearningPathType pathType;

  /// The items in this learning path
  final List<LearningPathItem> items;

  /// The user ID this path is for
  final String userId;

  /// When this path was generated
  final DateTime generatedAt;

  /// Create a learning path
  LearningPath({
    required this.pathType,
    required this.items,
    required this.userId,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// Create a learning path from a map
  factory LearningPath.fromMap(Map<String, dynamic> map) {
    return LearningPath(
      pathType: LearningPathType.values.firstWhere(
        (type) => type.toString().split('.').last == map['pathType'],
        orElse: () => LearningPathType.logicBased,
      ),
      items: (map['items'] as List)
          .map((item) => LearningPathItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      userId: map['userId'] as String,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }

  /// Convert this learning path to a map
  Map<String, dynamic> toMap() {
    return {
      'pathType': pathType.toString().split('.').last,
      'items': items.map((item) => item.toMap()).toList(),
      'userId': userId,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
