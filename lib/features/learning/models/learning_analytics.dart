import 'package:kente_codeweaver/features/learning/models/learning_style.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';

/// Represents real-time analytics about a user's learning progress
class LearningAnalytics {
  /// Overall skill progress (0.0 to 1.0)
  final double skillProgress;
  
  /// Concept mastery progress (0.0 to 1.0)
  final double conceptMastery;
  
  /// Learning rate (concepts per week)
  final double learningRate;
  
  /// Engagement score (0.0 to 1.0)
  final double engagementScore;
  
  /// Challenge completion rate (0.0 to 1.0)
  final double challengeCompletion;
  
  /// Total time spent in minutes
  final int timeSpent;
  
  /// User's strengths
  final List<String> strengths;
  
  /// Areas that need improvement
  final List<String> areasForImprovement;
  
  /// Primary learning style
  final LearningStyle primaryLearningStyle;
  
  /// Secondary learning styles
  final List<LearningStyle> secondaryLearningStyles;
  
  /// Recommended learning path type
  final LearningPathType recommendedPathType;
  
  /// Recommended activities
  final List<String> recommendedActivities;
  
  /// Session-specific analytics
  final Map<String, dynamic> sessionAnalytics;
  
  /// Create a learning analytics object
  LearningAnalytics({
    this.skillProgress = 0.0,
    this.conceptMastery = 0.0,
    this.learningRate = 0.0,
    this.engagementScore = 0.0,
    this.challengeCompletion = 0.0,
    this.timeSpent = 0,
    this.strengths = const [],
    this.areasForImprovement = const [],
    this.primaryLearningStyle = LearningStyle.visual,
    this.secondaryLearningStyles = const [],
    this.recommendedPathType = LearningPathType.logicBased,
    this.recommendedActivities = const [],
    this.sessionAnalytics = const {},
  });
  
  /// Create a learning analytics object from a map
  factory LearningAnalytics.fromMap(Map<String, dynamic> map) {
    return LearningAnalytics(
      skillProgress: map['skillProgress'] as double? ?? 0.0,
      conceptMastery: map['conceptMastery'] as double? ?? 0.0,
      learningRate: map['learningRate'] as double? ?? 0.0,
      engagementScore: map['engagementScore'] as double? ?? 0.0,
      challengeCompletion: map['challengeCompletion'] as double? ?? 0.0,
      timeSpent: map['timeSpent'] as int? ?? 0,
      strengths: List<String>.from(map['strengths'] ?? []),
      areasForImprovement: List<String>.from(map['areasForImprovement'] ?? []),
      primaryLearningStyle: LearningStyle.values.firstWhere(
        (style) => style.toString().split('.').last == map['primaryLearningStyle'],
        orElse: () => LearningStyle.visual,
      ),
      secondaryLearningStyles: (map['secondaryLearningStyles'] as List?)
          ?.map((style) => LearningStyle.values.firstWhere(
                (s) => s.toString().split('.').last == style,
                orElse: () => LearningStyle.visual,
              ))
          .toList() ??
          [],
      recommendedPathType: LearningPathType.values.firstWhere(
        (type) => type.toString().split('.').last == map['recommendedPathType'],
        orElse: () => LearningPathType.logicBased,
      ),
      recommendedActivities: List<String>.from(map['recommendedActivities'] ?? []),
      sessionAnalytics: Map<String, dynamic>.from(map['sessionAnalytics'] ?? {}),
    );
  }
  
  /// Convert this learning analytics to a map
  Map<String, dynamic> toMap() {
    return {
      'skillProgress': skillProgress,
      'conceptMastery': conceptMastery,
      'learningRate': learningRate,
      'engagementScore': engagementScore,
      'challengeCompletion': challengeCompletion,
      'timeSpent': timeSpent,
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
      'primaryLearningStyle': primaryLearningStyle.toString().split('.').last,
      'secondaryLearningStyles': secondaryLearningStyles
          .map((style) => style.toString().split('.').last)
          .toList(),
      'recommendedPathType': recommendedPathType.toString().split('.').last,
      'recommendedActivities': recommendedActivities,
      'sessionAnalytics': sessionAnalytics,
    };
  }
  
  /// Create a copy with updated fields
  LearningAnalytics copyWith({
    double? skillProgress,
    double? conceptMastery,
    double? learningRate,
    double? engagementScore,
    double? challengeCompletion,
    int? timeSpent,
    List<String>? strengths,
    List<String>? areasForImprovement,
    LearningStyle? primaryLearningStyle,
    List<LearningStyle>? secondaryLearningStyles,
    LearningPathType? recommendedPathType,
    List<String>? recommendedActivities,
    Map<String, dynamic>? sessionAnalytics,
  }) {
    return LearningAnalytics(
      skillProgress: skillProgress ?? this.skillProgress,
      conceptMastery: conceptMastery ?? this.conceptMastery,
      learningRate: learningRate ?? this.learningRate,
      engagementScore: engagementScore ?? this.engagementScore,
      challengeCompletion: challengeCompletion ?? this.challengeCompletion,
      timeSpent: timeSpent ?? this.timeSpent,
      strengths: strengths ?? this.strengths,
      areasForImprovement: areasForImprovement ?? this.areasForImprovement,
      primaryLearningStyle: primaryLearningStyle ?? this.primaryLearningStyle,
      secondaryLearningStyles: secondaryLearningStyles ?? this.secondaryLearningStyles,
      recommendedPathType: recommendedPathType ?? this.recommendedPathType,
      recommendedActivities: recommendedActivities ?? this.recommendedActivities,
      sessionAnalytics: sessionAnalytics ?? this.sessionAnalytics,
    );
  }
  
  /// Update session analytics with new data
  LearningAnalytics updateSessionAnalytics(Map<String, dynamic> newData) {
    final updatedSessionAnalytics = Map<String, dynamic>.from(sessionAnalytics);
    updatedSessionAnalytics.addAll(newData);
    
    return copyWith(sessionAnalytics: updatedSessionAnalytics);
  }
  
  /// Record time spent in the current session
  LearningAnalytics recordTimeSpent(int additionalMinutes) {
    return copyWith(timeSpent: timeSpent + additionalMinutes);
  }
}
