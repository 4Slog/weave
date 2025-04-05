import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/block_workspace/models/pattern_difficulty.dart';

/// Represents a coding challenge in the application
class Challenge {
  /// Unique identifier for this challenge
  final String id;
  
  /// Title of the challenge
  final String title;
  
  /// Description of the challenge
  final String description;
  
  /// Difficulty level of the challenge
  final PatternDifficulty difficulty;
  
  /// Required block types for completing the challenge
  final List<String> requiredBlockTypes;
  
  /// Concepts taught by this challenge
  final List<String> concepts;
  
  /// Hint text for the challenge
  final String hint;
  
  /// Cultural context information
  final Map<String, dynamic> culturalContext;
  
  /// Whether this challenge is part of a story
  final bool isStoryChallenge;
  
  /// ID of the story this challenge belongs to (if any)
  final String? storyId;
  
  /// Concept ID associated with this challenge
  final String conceptId;
  
  /// Constructor
  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.requiredBlockTypes,
    required this.concepts,
    this.hint = '',
    this.culturalContext = const {},
    this.isStoryChallenge = false,
    this.storyId,
    required this.conceptId,
  });
  
  /// Create a copy with optional new values
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    PatternDifficulty? difficulty,
    List<String>? requiredBlockTypes,
    List<String>? concepts,
    String? hint,
    Map<String, dynamic>? culturalContext,
    bool? isStoryChallenge,
    String? storyId,
    String? conceptId,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      requiredBlockTypes: requiredBlockTypes ?? this.requiredBlockTypes,
      concepts: concepts ?? this.concepts,
      hint: hint ?? this.hint,
      culturalContext: culturalContext ?? this.culturalContext,
      isStoryChallenge: isStoryChallenge ?? this.isStoryChallenge,
      storyId: storyId ?? this.storyId,
      conceptId: conceptId ?? this.conceptId,
    );
  }
  
  /// Create from JSON
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: PatternDifficulty.values[json['difficulty'] ?? 0],
      requiredBlockTypes: List<String>.from(json['requiredBlockTypes'] ?? []),
      concepts: List<String>.from(json['concepts'] ?? []),
      hint: json['hint'] ?? '',
      culturalContext: json['culturalContext'] ?? {},
      isStoryChallenge: json['isStoryChallenge'] ?? false,
      storyId: json['storyId'],
      conceptId: json['conceptId'] ?? '',
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.index,
      'requiredBlockTypes': requiredBlockTypes,
      'concepts': concepts,
      'hint': hint,
      'culturalContext': culturalContext,
      'isStoryChallenge': isStoryChallenge,
      'storyId': storyId,
      'conceptId': conceptId,
    };
  }
}

/// Represents a challenge that is part of a story
class StoryChallenge extends Challenge {
  /// Position in the story sequence
  final int sequencePosition;
  
  /// Whether this challenge unlocks a new story branch
  final bool unlocksNewBranch;
  
  /// ID of the branch this challenge unlocks (if any)
  final String? branchId;
  
  /// Constructor
  StoryChallenge({
    required String id,
    required String title,
    required String description,
    required PatternDifficulty difficulty,
    required List<String> requiredBlockTypes,
    required List<String> concepts,
    String hint = '',
    Map<String, dynamic> culturalContext = const {},
    required String storyId,
    required String conceptId,
    required this.sequencePosition,
    this.unlocksNewBranch = false,
    this.branchId,
  }) : super(
    id: id,
    title: title,
    description: description,
    difficulty: difficulty,
    requiredBlockTypes: requiredBlockTypes,
    concepts: concepts,
    hint: hint,
    culturalContext: culturalContext,
    isStoryChallenge: true,
    storyId: storyId,
    conceptId: conceptId,
  );
  
  /// Create a copy with optional new values
  @override
  StoryChallenge copyWith({
    String? id,
    String? title,
    String? description,
    PatternDifficulty? difficulty,
    List<String>? requiredBlockTypes,
    List<String>? concepts,
    String? hint,
    Map<String, dynamic>? culturalContext,
    bool? isStoryChallenge,
    String? storyId,
    String? conceptId,
    int? sequencePosition,
    bool? unlocksNewBranch,
    String? branchId,
  }) {
    return StoryChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      requiredBlockTypes: requiredBlockTypes ?? this.requiredBlockTypes,
      concepts: concepts ?? this.concepts,
      hint: hint ?? this.hint,
      culturalContext: culturalContext ?? this.culturalContext,
      storyId: storyId ?? this.storyId!,
      conceptId: conceptId ?? this.conceptId,
      sequencePosition: sequencePosition ?? this.sequencePosition,
      unlocksNewBranch: unlocksNewBranch ?? this.unlocksNewBranch,
      branchId: branchId ?? this.branchId,
    );
  }
  
  /// Create from JSON
  factory StoryChallenge.fromJson(Map<String, dynamic> json) {
    return StoryChallenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: PatternDifficulty.values[json['difficulty'] ?? 0],
      requiredBlockTypes: List<String>.from(json['requiredBlockTypes'] ?? []),
      concepts: List<String>.from(json['concepts'] ?? []),
      hint: json['hint'] ?? '',
      culturalContext: json['culturalContext'] ?? {},
      storyId: json['storyId'] ?? '',
      conceptId: json['conceptId'] ?? '',
      sequencePosition: json['sequencePosition'] ?? 0,
      unlocksNewBranch: json['unlocksNewBranch'] ?? false,
      branchId: json['branchId'],
    );
  }
  
  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'sequencePosition': sequencePosition,
      'unlocksNewBranch': unlocksNewBranch,
      'branchId': branchId,
    });
    return json;
  }
}

