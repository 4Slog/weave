/// Model representing a coding skill.
/// 
/// This model contains information about a specific coding skill,
/// including its identifier, name, description, and prerequisites.
class CodingSkill {
  /// Unique identifier for the skill.
  final String id;
  
  /// Display name of the skill.
  final String name;
  
  /// Detailed description of the skill.
  final String description;
  
  /// Category the skill belongs to (e.g., "Algorithms", "Data", "Control Flow").
  final String category;
  
  /// Difficulty level of the skill (1-5).
  final int difficultyLevel;
  
  /// IDs of skills that are prerequisites for this skill.
  final List<String> prerequisites;
  
  /// IDs of CS standards related to this skill.
  final List<String> relatedCSStandards;
  
  /// IDs of ISTE standards related to this skill.
  final List<String> relatedISTEStandards;
  
  /// IDs of K-12 CS Framework elements related to this skill.
  final List<String> relatedK12Elements;
  
  /// Examples of this skill in practice.
  final List<String> examples;
  
  /// Creates a new CodingSkill.
  CodingSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.difficultyLevel = 1,
    this.prerequisites = const [],
    this.relatedCSStandards = const [],
    this.relatedISTEStandards = const [],
    this.relatedK12Elements = const [],
    this.examples = const [],
  });
  
  /// Create a copy of this CodingSkill with some fields replaced.
  CodingSkill copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? difficultyLevel,
    List<String>? prerequisites,
    List<String>? relatedCSStandards,
    List<String>? relatedISTEStandards,
    List<String>? relatedK12Elements,
    List<String>? examples,
  }) {
    return CodingSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      prerequisites: prerequisites ?? this.prerequisites,
      relatedCSStandards: relatedCSStandards ?? this.relatedCSStandards,
      relatedISTEStandards: relatedISTEStandards ?? this.relatedISTEStandards,
      relatedK12Elements: relatedK12Elements ?? this.relatedK12Elements,
      examples: examples ?? this.examples,
    );
  }
  
  /// Convert this CodingSkill to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'prerequisites': prerequisites,
      'relatedCSStandards': relatedCSStandards,
      'relatedISTEStandards': relatedISTEStandards,
      'relatedK12Elements': relatedK12Elements,
      'examples': examples,
    };
  }
  
  /// Create a CodingSkill from a JSON map.
  factory CodingSkill.fromJson(Map<String, dynamic> json) {
    return CodingSkill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      difficultyLevel: json['difficultyLevel'] ?? 1,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      relatedCSStandards: List<String>.from(json['relatedCSStandards'] ?? []),
      relatedISTEStandards: List<String>.from(json['relatedISTEStandards'] ?? []),
      relatedK12Elements: List<String>.from(json['relatedK12Elements'] ?? []),
      examples: List<String>.from(json['examples'] ?? []),
    );
  }
  
  @override
  String toString() {
    return 'CodingSkill: $name (ID: $id)';
  }
}
