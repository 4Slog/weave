import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:uuid/uuid.dart';

/// Enhanced story model with educational metadata and standards alignment.
/// 
/// This model extends the base StoryModel with additional educational
/// properties to support adaptive learning and standards alignment.
class EnhancedStoryModel extends StoryModel {
  /// Educational standards this story aligns with.
  final List<String> educationalStandards;
  
  /// Learning objectives for this story.
  final List<String> learningObjectives;
  
  /// Prerequisite concepts for understanding this story.
  final List<String> prerequisiteConcepts;
  
  /// Skill level required for this story (1-5).
  final int skillLevel;
  
  /// Estimated time to complete this story (in minutes).
  final int estimatedTimeMinutes;
  
  /// Educational context of the story.
  final String educationalContext;
  
  /// Assessment questions for this story.
  final List<StoryAssessmentQuestion> assessmentQuestions;
  
  /// Cultural significance of the story elements.
  final Map<String, String> culturalSignificance;
  
  /// Coding concepts demonstrated in the story.
  final Map<String, String> codingConceptsExplained;
  
  /// Create a new EnhancedStoryModel.
  EnhancedStoryModel({
    String? id,
    required String title,
    required String theme,
    required String region,
    required String characterName,
    required String ageGroup,
    required List<ContentBlockModel> content,
    StoryChallenge? challenge,
    List<StoryBranch> branches = const [],
    Map<String, String> culturalNotes = const {},
    List<String> learningConcepts = const [],
    EmotionalTone emotionalTone = EmotionalTone.neutral,
    int difficultyLevel = 1,
    String description = '',
    List<BlockModel> codeBlocks = const [],
    this.educationalStandards = const [],
    this.learningObjectives = const [],
    this.prerequisiteConcepts = const [],
    this.skillLevel = 1,
    this.estimatedTimeMinutes = 10,
    this.educationalContext = '',
    this.assessmentQuestions = const [],
    this.culturalSignificance = const {},
    this.codingConceptsExplained = const {},
  }) : super(
    id: id ?? const Uuid().v4(),
    title: title,
    theme: theme,
    region: region,
    characterName: characterName,
    ageGroup: ageGroup,
    content: content,
    challenge: challenge,
    branches: branches,
    culturalNotes: culturalNotes,
    learningConcepts: learningConcepts,
    emotionalTone: emotionalTone,
    difficultyLevel: difficultyLevel,
    description: description,
    codeBlocks: codeBlocks,
  );
  
  /// Create an EnhancedStoryModel from a JSON map.
  factory EnhancedStoryModel.fromJson(Map<String, dynamic> json) {
    // Create a base StoryModel first
    final baseStory = StoryModel.fromJson(json);
    
    // Extract enhanced properties
    final educationalStandards = json['educationalStandards'] != null
        ? List<String>.from(json['educationalStandards'])
        : <String>[];
    
    final learningObjectives = json['learningObjectives'] != null
        ? List<String>.from(json['learningObjectives'])
        : <String>[];
    
    final prerequisiteConcepts = json['prerequisiteConcepts'] != null
        ? List<String>.from(json['prerequisiteConcepts'])
        : <String>[];
    
    final assessmentQuestions = json['assessmentQuestions'] != null
        ? (json['assessmentQuestions'] as List)
            .map((q) => StoryAssessmentQuestion.fromJson(q))
            .toList()
        : <StoryAssessmentQuestion>[];
    
    final culturalSignificance = json['culturalSignificance'] != null
        ? Map<String, String>.from(json['culturalSignificance'])
        : <String, String>{};
    
    final codingConceptsExplained = json['codingConceptsExplained'] != null
        ? Map<String, String>.from(json['codingConceptsExplained'])
        : <String, String>{};
    
    // Create the enhanced story model
    return EnhancedStoryModel(
      id: baseStory.id,
      title: baseStory.title,
      theme: baseStory.theme,
      region: baseStory.region,
      characterName: baseStory.characterName,
      ageGroup: baseStory.ageGroup,
      content: baseStory.content,
      challenge: baseStory.challenge,
      branches: baseStory.branches,
      culturalNotes: baseStory.culturalNotes,
      learningConcepts: baseStory.learningConcepts,
      emotionalTone: baseStory.emotionalTone,
      difficultyLevel: baseStory.difficultyLevel,
      description: baseStory.description,
      codeBlocks: baseStory.codeBlocks,
      educationalStandards: educationalStandards,
      learningObjectives: learningObjectives,
      prerequisiteConcepts: prerequisiteConcepts,
      skillLevel: json['skillLevel'] ?? 1,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] ?? 10,
      educationalContext: json['educationalContext'] ?? '',
      assessmentQuestions: assessmentQuestions,
      culturalSignificance: culturalSignificance,
      codingConceptsExplained: codingConceptsExplained,
    );
  }
  
  /// Convert this EnhancedStoryModel to a JSON map.
  @override
  Map<String, dynamic> toJson() {
    // Get the base JSON from the parent class
    final baseJson = super.toJson();
    
    // Add enhanced properties
    return {
      ...baseJson,
      'educationalStandards': educationalStandards,
      'learningObjectives': learningObjectives,
      'prerequisiteConcepts': prerequisiteConcepts,
      'skillLevel': skillLevel,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'educationalContext': educationalContext,
      'assessmentQuestions': assessmentQuestions.map((q) => q.toJson()).toList(),
      'culturalSignificance': culturalSignificance,
      'codingConceptsExplained': codingConceptsExplained,
    };
  }
  
  /// Create a copy of this EnhancedStoryModel with some fields replaced.
  EnhancedStoryModel copyWithEnhanced({
    String? id,
    String? title,
    String? theme,
    String? region,
    String? characterName,
    String? ageGroup,
    List<ContentBlockModel>? content,
    StoryChallenge? challenge,
    List<StoryBranch>? branches,
    Map<String, String>? culturalNotes,
    List<String>? learningConcepts,
    EmotionalTone? emotionalTone,
    int? difficultyLevel,
    String? description,
    List<BlockModel>? codeBlocks,
    List<String>? educationalStandards,
    List<String>? learningObjectives,
    List<String>? prerequisiteConcepts,
    int? skillLevel,
    int? estimatedTimeMinutes,
    String? educationalContext,
    List<StoryAssessmentQuestion>? assessmentQuestions,
    Map<String, String>? culturalSignificance,
    Map<String, String>? codingConceptsExplained,
  }) {
    return EnhancedStoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      theme: theme ?? this.theme,
      region: region ?? this.region,
      characterName: characterName ?? this.characterName,
      ageGroup: ageGroup ?? this.ageGroup,
      content: content ?? this.content,
      challenge: challenge ?? this.challenge,
      branches: branches ?? this.branches,
      culturalNotes: culturalNotes ?? this.culturalNotes,
      learningConcepts: learningConcepts ?? this.learningConcepts,
      emotionalTone: emotionalTone ?? this.emotionalTone,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      description: description ?? this.description,
      codeBlocks: codeBlocks ?? this.codeBlocks,
      educationalStandards: educationalStandards ?? this.educationalStandards,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      prerequisiteConcepts: prerequisiteConcepts ?? this.prerequisiteConcepts,
      skillLevel: skillLevel ?? this.skillLevel,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      educationalContext: educationalContext ?? this.educationalContext,
      assessmentQuestions: assessmentQuestions ?? this.assessmentQuestions,
      culturalSignificance: culturalSignificance ?? this.culturalSignificance,
      codingConceptsExplained: codingConceptsExplained ?? this.codingConceptsExplained,
    );
  }
  
  /// Convert a regular StoryModel to an EnhancedStoryModel.
  factory EnhancedStoryModel.fromStoryModel(StoryModel story) {
    return EnhancedStoryModel(
      id: story.id,
      title: story.title,
      theme: story.theme,
      region: story.region,
      characterName: story.characterName,
      ageGroup: story.ageGroup,
      content: story.content,
      challenge: story.challenge,
      branches: story.branches,
      culturalNotes: story.culturalNotes,
      learningConcepts: story.learningConcepts,
      emotionalTone: story.emotionalTone,
      difficultyLevel: story.difficultyLevel,
      description: story.description,
      codeBlocks: story.codeBlocks,
    );
  }
  
  /// Check if this story is appropriate for a given skill level.
  bool isAppropriateForSkillLevel(int userSkillLevel) {
    // Allow stories within +/- 1 skill level
    return (userSkillLevel - 1 <= skillLevel) && (skillLevel <= userSkillLevel + 1);
  }
  
  /// Check if the user has the prerequisite concepts for this story.
  bool hasPrerequisites(List<String> masteredConcepts) {
    // If no prerequisites, return true
    if (prerequisiteConcepts.isEmpty) return true;
    
    // Check if all prerequisites are mastered
    for (final concept in prerequisiteConcepts) {
      if (!masteredConcepts.contains(concept)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Get the educational standards IDs for this story.
  List<String> getStandardIds() {
    return educationalStandards;
  }
  
  /// Get the skill level name for this story.
  String get skillLevelName {
    switch (skillLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Elementary';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Custom';
    }
  }
  
  /// Get the educational summary for this story.
  Map<String, dynamic> getEducationalSummary() {
    return {
      'learningObjectives': learningObjectives,
      'learningConcepts': learningConcepts,
      'educationalStandards': educationalStandards,
      'prerequisiteConcepts': prerequisiteConcepts,
      'skillLevel': skillLevel,
      'skillLevelName': skillLevelName,
      'educationalContext': educationalContext,
      'codingConceptsExplained': codingConceptsExplained,
    };
  }
  
  /// Get the cultural summary for this story.
  Map<String, dynamic> getCulturalSummary() {
    return {
      'region': region,
      'culturalNotes': culturalNotes,
      'culturalSignificance': culturalSignificance,
    };
  }
}

/// Model for story assessment questions.
class StoryAssessmentQuestion {
  /// Unique identifier for the question.
  final String id;
  
  /// The question text.
  final String question;
  
  /// Possible answers to the question.
  final List<String> options;
  
  /// Index of the correct answer in the options list.
  final int correctAnswerIndex;
  
  /// Explanation of the correct answer.
  final String explanation;
  
  /// Learning concept this question assesses.
  final String conceptAssessed;
  
  /// Create a new StoryAssessmentQuestion.
  StoryAssessmentQuestion({
    String? id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.conceptAssessed,
  }) : id = id ?? const Uuid().v4();
  
  /// Create a StoryAssessmentQuestion from a JSON map.
  factory StoryAssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return StoryAssessmentQuestion(
      id: json['id'] ?? const Uuid().v4(),
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String,
      conceptAssessed: json['conceptAssessed'] as String,
    );
  }
  
  /// Convert this StoryAssessmentQuestion to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'conceptAssessed': conceptAssessed,
    };
  }
}
