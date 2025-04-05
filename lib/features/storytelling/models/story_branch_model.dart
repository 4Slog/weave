import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:uuid/uuid.dart';

/// Represents a branch in a story with content and metadata
class StoryBranchModel {
  /// Unique identifier for this branch
  final String id;

  /// Description of the branch
  final String description;

  /// ID of the target story this branch leads to
  final String targetStoryId;

  /// Requirements to unlock this branch
  final Map<String, dynamic> requirements;

  /// Difficulty level (1-5)
  final int difficultyLevel;

  /// Main concept this branch focuses on
  final String? focusConcept;

  /// The content of this branch
  final String content;

  /// Learning concepts covered in this branch
  final List<String> learningConcepts;

  /// Emotional tone of this branch
  final EmotionalTone emotionalTone;

  /// Cultural context information
  final Map<String, dynamic> culturalContext;

  /// Whether this branch has choices
  final bool hasChoices;

  /// Prompt for choices if hasChoices is true
  final String? choicePrompt;

  /// Parent story ID if this is a branch of another story
  final String? parentStoryId;

  /// Text displayed for this choice in the parent story
  final String? choiceText;

  /// Constructor
  StoryBranchModel({
    String? id,
    required this.description,
    required this.targetStoryId,
    this.requirements = const {},
    this.difficultyLevel = 1,
    this.focusConcept,
    this.content = '',
    this.learningConcepts = const [],
    this.emotionalTone = EmotionalTone.neutral,
    this.culturalContext = const {},
    this.hasChoices = false,
    this.choicePrompt,
    this.parentStoryId,
    this.choiceText,
  }) : id = id ?? const Uuid().v4();

  // Requirements are structured as follows:
  // - "skill:loops": 0.5 (min. proficiency required in loops)
  // - "concept:patterns": true (concept must be in progress/mastered)
  // - "badge:pattern_master": true (badge must be earned)
  // - "story:intro_story": true (story must be completed)

  /// Create a copy with optional new values
  StoryBranchModel copyWith({
    String? id,
    String? description,
    String? targetStoryId,
    Map<String, dynamic>? requirements,
    int? difficultyLevel,
    String? focusConcept,
    String? content,
    List<String>? learningConcepts,
    EmotionalTone? emotionalTone,
    Map<String, dynamic>? culturalContext,
    bool? hasChoices,
    String? choicePrompt,
    String? parentStoryId,
    String? choiceText,
  }) {
    return StoryBranchModel(
      id: id ?? this.id,
      description: description ?? this.description,
      targetStoryId: targetStoryId ?? this.targetStoryId,
      requirements: requirements ?? this.requirements,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      focusConcept: focusConcept ?? this.focusConcept,
      content: content ?? this.content,
      learningConcepts: learningConcepts ?? this.learningConcepts,
      emotionalTone: emotionalTone ?? this.emotionalTone,
      culturalContext: culturalContext ?? this.culturalContext,
      hasChoices: hasChoices ?? this.hasChoices,
      choicePrompt: choicePrompt ?? this.choicePrompt,
      parentStoryId: parentStoryId ?? this.parentStoryId,
      choiceText: choiceText ?? this.choiceText,
    );
  }

  /// Create from JSON
  factory StoryBranchModel.fromJson(Map<String, dynamic> json) {
    // Parse emotional tone
    EmotionalTone tone = EmotionalTone.neutral;
    if (json['emotionalTone'] != null) {
      try {
        tone = EmotionalTone.values.firstWhere(
          (t) => t.toString().split('.').last == json['emotionalTone'],
          orElse: () => EmotionalTone.neutral,
        );
      } catch (_) {
        // Default to neutral if parsing fails
      }
    }

    // Parse learning concepts
    List<String> concepts = [];
    if (json['learningConcepts'] != null) {
      concepts = List<String>.from(json['learningConcepts']);
    }

    return StoryBranchModel(
      id: json['id'],
      description: json['description'] ?? '',
      targetStoryId: json['targetStoryId'] ?? '',
      requirements: json['requirements'] ?? {},
      difficultyLevel: json['difficultyLevel'] ?? 1,
      focusConcept: json['focusConcept'],
      content: json['content'] ?? '',
      learningConcepts: concepts,
      emotionalTone: tone,
      culturalContext: json['culturalContext'] ?? {},
      hasChoices: json['hasChoices'] ?? false,
      choicePrompt: json['choicePrompt'],
      parentStoryId: json['parentStoryId'],
      choiceText: json['choiceText'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'targetStoryId': targetStoryId,
      'requirements': requirements,
      'difficultyLevel': difficultyLevel,
      'focusConcept': focusConcept,
      'content': content,
      'learningConcepts': learningConcepts,
      'emotionalTone': emotionalTone.toString().split('.').last,
      'culturalContext': culturalContext,
      'hasChoices': hasChoices,
      'choicePrompt': choicePrompt,
      'parentStoryId': parentStoryId,
      'choiceText': choiceText,
    };
  }
}
