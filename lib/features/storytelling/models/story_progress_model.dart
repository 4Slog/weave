import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Model for tracking user progress through stories.
/// 
/// This model tracks a user's progress through stories, including
/// completion status, decisions made, and learning outcomes.
class StoryProgressModel {
  /// Unique identifier for the progress record.
  final String id;
  
  /// User ID associated with this progress.
  final String userId;
  
  /// Story ID associated with this progress.
  final String storyId;
  
  /// Whether the story has been completed.
  final bool completed;
  
  /// Timestamp when the story was started.
  final DateTime startedAt;
  
  /// Timestamp when the story was completed (if completed).
  final DateTime? completedAt;
  
  /// Current position in the story (content block index).
  final int currentPosition;
  
  /// Decisions made during the story.
  final Map<String, String> decisions;
  
  /// Branches followed during the story.
  final List<String> branchesFollowed;
  
  /// Assessment results for this story.
  final StoryAssessmentResults? assessmentResults;
  
  /// Learning outcomes from this story.
  final List<StoryLearningOutcome> learningOutcomes;
  
  /// Time spent on this story (in seconds).
  final int timeSpentSeconds;
  
  /// Number of interactions with this story.
  final int interactionCount;
  
  /// Create a new StoryProgressModel.
  StoryProgressModel({
    String? id,
    required this.userId,
    required this.storyId,
    this.completed = false,
    DateTime? startedAt,
    this.completedAt,
    this.currentPosition = 0,
    this.decisions = const {},
    this.branchesFollowed = const [],
    this.assessmentResults,
    this.learningOutcomes = const [],
    this.timeSpentSeconds = 0,
    this.interactionCount = 0,
  }) : 
    id = id ?? const Uuid().v4(),
    startedAt = startedAt ?? DateTime.now();
  
  /// Create a StoryProgressModel from a JSON map.
  factory StoryProgressModel.fromJson(Map<String, dynamic> json) {
    return StoryProgressModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      userId: json['userId'] as String,
      storyId: json['storyId'] as String,
      completed: json['completed'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
      currentPosition: json['currentPosition'] as int? ?? 0,
      decisions: json['decisions'] != null
          ? Map<String, String>.from(json['decisions'] as Map)
          : {},
      branchesFollowed: json['branchesFollowed'] != null
          ? List<String>.from(json['branchesFollowed'] as List)
          : [],
      assessmentResults: json['assessmentResults'] != null
          ? StoryAssessmentResults.fromJson(json['assessmentResults'] as Map<String, dynamic>)
          : null,
      learningOutcomes: json['learningOutcomes'] != null
          ? (json['learningOutcomes'] as List)
              .map((e) => StoryLearningOutcome.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      interactionCount: json['interactionCount'] as int? ?? 0,
    );
  }
  
  /// Convert this StoryProgressModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'storyId': storyId,
      'completed': completed,
      'startedAt': startedAt.millisecondsSinceEpoch,
      if (completedAt != null) 'completedAt': completedAt!.millisecondsSinceEpoch,
      'currentPosition': currentPosition,
      'decisions': decisions,
      'branchesFollowed': branchesFollowed,
      if (assessmentResults != null) 'assessmentResults': assessmentResults!.toJson(),
      'learningOutcomes': learningOutcomes.map((e) => e.toJson()).toList(),
      'timeSpentSeconds': timeSpentSeconds,
      'interactionCount': interactionCount,
    };
  }
  
  /// Create a copy of this StoryProgressModel with some fields replaced.
  StoryProgressModel copyWith({
    String? id,
    String? userId,
    String? storyId,
    bool? completed,
    DateTime? startedAt,
    DateTime? completedAt,
    int? currentPosition,
    Map<String, String>? decisions,
    List<String>? branchesFollowed,
    StoryAssessmentResults? assessmentResults,
    List<StoryLearningOutcome>? learningOutcomes,
    int? timeSpentSeconds,
    int? interactionCount,
  }) {
    return StoryProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storyId: storyId ?? this.storyId,
      completed: completed ?? this.completed,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      currentPosition: currentPosition ?? this.currentPosition,
      decisions: decisions ?? this.decisions,
      branchesFollowed: branchesFollowed ?? this.branchesFollowed,
      assessmentResults: assessmentResults ?? this.assessmentResults,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      interactionCount: interactionCount ?? this.interactionCount,
    );
  }
  
  /// Mark this story as completed.
  StoryProgressModel markAsCompleted() {
    return copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );
  }
  
  /// Update the current position in the story.
  StoryProgressModel updatePosition(int position) {
    return copyWith(
      currentPosition: position,
    );
  }
  
  /// Add a decision made during the story.
  StoryProgressModel addDecision(String decisionPoint, String decision) {
    final updatedDecisions = Map<String, String>.from(decisions);
    updatedDecisions[decisionPoint] = decision;
    
    return copyWith(
      decisions: updatedDecisions,
    );
  }
  
  /// Add a branch followed during the story.
  StoryProgressModel addBranchFollowed(String branchId) {
    final updatedBranches = List<String>.from(branchesFollowed);
    updatedBranches.add(branchId);
    
    return copyWith(
      branchesFollowed: updatedBranches,
    );
  }
  
  /// Add assessment results for this story.
  StoryProgressModel addAssessmentResults(StoryAssessmentResults results) {
    return copyWith(
      assessmentResults: results,
    );
  }
  
  /// Add a learning outcome from this story.
  StoryProgressModel addLearningOutcome(StoryLearningOutcome outcome) {
    final updatedOutcomes = List<StoryLearningOutcome>.from(learningOutcomes);
    updatedOutcomes.add(outcome);
    
    return copyWith(
      learningOutcomes: updatedOutcomes,
    );
  }
  
  /// Add time spent on this story.
  StoryProgressModel addTimeSpent(int seconds) {
    return copyWith(
      timeSpentSeconds: timeSpentSeconds + seconds,
    );
  }
  
  /// Add an interaction with this story.
  StoryProgressModel addInteraction() {
    return copyWith(
      interactionCount: interactionCount + 1,
    );
  }
  
  /// Get the duration of the story session.
  Duration get duration {
    if (completed && completedAt != null) {
      return completedAt!.difference(startedAt);
    } else {
      return DateTime.now().difference(startedAt);
    }
  }
  
  /// Get the completion percentage of the story.
  double get completionPercentage {
    if (completed) return 1.0;
    
    // This is a simplified implementation
    // A more sophisticated approach would use the total number of content blocks
    return currentPosition / 10;
  }
  
  /// Get the learning outcomes summary.
  Map<String, dynamic> getLearningOutcomesSummary() {
    final conceptsLearned = <String>[];
    final standardsMet = <String>[];
    
    for (final outcome in learningOutcomes) {
      if (outcome.conceptLearned != null) {
        conceptsLearned.add(outcome.conceptLearned!);
      }
      
      if (outcome.standardMet != null) {
        standardsMet.add(outcome.standardMet!);
      }
    }
    
    return {
      'conceptsLearned': conceptsLearned,
      'standardsMet': standardsMet,
      'totalOutcomes': learningOutcomes.length,
    };
  }
}

/// Model for story assessment results.
class StoryAssessmentResults {
  /// Total number of questions.
  final int totalQuestions;
  
  /// Number of correct answers.
  final int correctAnswers;
  
  /// Score as a percentage.
  final double score;
  
  /// Timestamp when the assessment was completed.
  final DateTime completedAt;
  
  /// Time taken to complete the assessment (in seconds).
  final int timeTakenSeconds;
  
  /// Detailed results for each question.
  final List<QuestionResult> questionResults;
  
  /// Create a new StoryAssessmentResults.
  StoryAssessmentResults({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    DateTime? completedAt,
    required this.timeTakenSeconds,
    required this.questionResults,
  }) : completedAt = completedAt ?? DateTime.now();
  
  /// Create a StoryAssessmentResults from a JSON map.
  factory StoryAssessmentResults.fromJson(Map<String, dynamic> json) {
    return StoryAssessmentResults(
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      score: (json['score'] as num).toDouble(),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : DateTime.now(),
      timeTakenSeconds: json['timeTakenSeconds'] as int,
      questionResults: json['questionResults'] != null
          ? (json['questionResults'] as List)
              .map((e) => QuestionResult.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
  
  /// Convert this StoryAssessmentResults to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'score': score,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'timeTakenSeconds': timeTakenSeconds,
      'questionResults': questionResults.map((e) => e.toJson()).toList(),
    };
  }
  
  /// Get the pass/fail status of the assessment.
  bool get passed => score >= 70.0;
  
  /// Get the grade for the assessment.
  String get grade {
    if (score >= 90.0) return 'A';
    if (score >= 80.0) return 'B';
    if (score >= 70.0) return 'C';
    if (score >= 60.0) return 'D';
    return 'F';
  }
}

/// Model for individual question results.
class QuestionResult {
  /// Question ID.
  final String questionId;
  
  /// Whether the answer was correct.
  final bool correct;
  
  /// The answer given by the user.
  final String answerGiven;
  
  /// The correct answer.
  final String correctAnswer;
  
  /// Time taken to answer the question (in seconds).
  final int timeTakenSeconds;
  
  /// Create a new QuestionResult.
  QuestionResult({
    required this.questionId,
    required this.correct,
    required this.answerGiven,
    required this.correctAnswer,
    required this.timeTakenSeconds,
  });
  
  /// Create a QuestionResult from a JSON map.
  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId'] as String,
      correct: json['correct'] as bool,
      answerGiven: json['answerGiven'] as String,
      correctAnswer: json['correctAnswer'] as String,
      timeTakenSeconds: json['timeTakenSeconds'] as int,
    );
  }
  
  /// Convert this QuestionResult to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'correct': correct,
      'answerGiven': answerGiven,
      'correctAnswer': correctAnswer,
      'timeTakenSeconds': timeTakenSeconds,
    };
  }
}

/// Model for story learning outcomes.
class StoryLearningOutcome {
  /// Unique identifier for the learning outcome.
  final String id;
  
  /// Description of the learning outcome.
  final String description;
  
  /// Concept learned (if applicable).
  final String? conceptLearned;
  
  /// Standard met (if applicable).
  final String? standardMet;
  
  /// Mastery level achieved (0.0 to 1.0).
  final double masteryLevel;
  
  /// Evidence for this learning outcome.
  final String evidence;
  
  /// Create a new StoryLearningOutcome.
  StoryLearningOutcome({
    String? id,
    required this.description,
    this.conceptLearned,
    this.standardMet,
    required this.masteryLevel,
    required this.evidence,
  }) : id = id ?? const Uuid().v4();
  
  /// Create a StoryLearningOutcome from a JSON map.
  factory StoryLearningOutcome.fromJson(Map<String, dynamic> json) {
    return StoryLearningOutcome(
      id: json['id'] as String? ?? const Uuid().v4(),
      description: json['description'] as String,
      conceptLearned: json['conceptLearned'] as String?,
      standardMet: json['standardMet'] as String?,
      masteryLevel: (json['masteryLevel'] as num).toDouble(),
      evidence: json['evidence'] as String,
    );
  }
  
  /// Convert this StoryLearningOutcome to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      if (conceptLearned != null) 'conceptLearned': conceptLearned,
      if (standardMet != null) 'standardMet': standardMet,
      'masteryLevel': masteryLevel,
      'evidence': evidence,
    };
  }
}
