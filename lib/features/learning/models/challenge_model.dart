/// Model for a challenge
class ChallengeModel {
  /// Challenge ID
  final String id;
  
  /// Challenge title
  final String title;
  
  /// Challenge description
  final String description;
  
  /// Challenge difficulty
  final int difficulty;
  
  /// Story ID
  final String storyId;
  
  /// Required blocks
  final List<String> requiredBlocks;
  
  /// Constructor
  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.storyId,
    required this.requiredBlocks,
  });
  
  /// Create a copy with updated values
  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    int? difficulty,
    String? storyId,
    List<String>? requiredBlocks,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      storyId: storyId ?? this.storyId,
      requiredBlocks: requiredBlocks ?? this.requiredBlocks,
    );
  }
  
  /// Create from JSON
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as int,
      storyId: json['storyId'] as String,
      requiredBlocks: (json['requiredBlocks'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'storyId': storyId,
      'requiredBlocks': requiredBlocks,
    };
  }
}
