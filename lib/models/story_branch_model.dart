// Support branching narratives
class StoryBranchModel {
  final String id;
  final String description;
  final String targetStoryId;
  final Map<String, dynamic> requirements; // Requirements to unlock
  final int difficultyLevel;
  
  StoryBranchModel({
    required this.id,
    required this.description,
    required this.targetStoryId,
    this.requirements = const {},
    this.difficultyLevel = 1,
  });
  
  // Requirements are structured as follows:
  // - "skill:loops": 0.5 (min. proficiency required in loops)
  // - "concept:patterns": true (concept must be in progress/mastered)
  // - "badge:pattern_master": true (badge must be earned)
  // - "story:intro_story": true (story must be completed)
  
  factory StoryBranchModel.fromJson(Map<String, dynamic> json) {
    return StoryBranchModel(
      id: json['id'],
      description: json['description'],
      targetStoryId: json['targetStoryId'],
      requirements: json['requirements'] ?? {},
      difficultyLevel: json['difficultyLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'targetStoryId': targetStoryId,
      'requirements': requirements,
      'difficultyLevel': difficultyLevel,
    };
  }
}