
/// Defines the different types of learning paths available to users
enum LearningPathType {
  /// Logic-based learning path focuses on structured problem-solving and algorithmic thinking
  logicBased,

  /// Creativity-based learning path emphasizes creative expression and open-ended solutions
  creativityBased,

  /// Challenge-based learning path focuses on overcoming increasingly difficult challenges
  challengeBased,

  /// Balanced learning path combines elements of logic, creativity, and challenge
  balanced,
}

/// Extension methods for learning path types
extension LearningPathTypeExtension on LearningPathType {
  /// Get a human-readable name for this learning path type
  String get displayName {
    switch (this) {
      case LearningPathType.logicBased:
        return 'Logic Explorer';
      case LearningPathType.creativityBased:
        return 'Creative Weaver';
      case LearningPathType.challengeBased:
        return 'Challenge Seeker';
      case LearningPathType.balanced:
        return 'Balanced Learner';
    }
  }

  /// Get a description of this learning path type
  String get description {
    switch (this) {
      case LearningPathType.logicBased:
        return 'Focus on structured problem-solving, algorithms, and logical reasoning. '
               'This path emphasizes understanding the "why" behind coding concepts.';
      case LearningPathType.creativityBased:
        return 'Express yourself through creative pattern design and open-ended challenges. '
               'This path emphasizes artistic expression and innovative solutions.';
      case LearningPathType.challengeBased:
        return 'Test your skills with increasingly difficult challenges and puzzles. '
               'This path emphasizes mastery through practice and overcoming obstacles.';
      case LearningPathType.balanced:
        return 'Experience a balanced approach combining logical thinking, creativity, and challenges. '
               'This path provides a well-rounded introduction to coding concepts.';
    }
  }

  /// Get the primary skills emphasized by this learning path
  List<String> get emphasizedSkills {
    switch (this) {
      case LearningPathType.logicBased:
        return ['algorithmic_thinking', 'logical_reasoning', 'pattern_recognition', 'problem_decomposition'];
      case LearningPathType.creativityBased:
        return ['creative_thinking', 'design_skills', 'aesthetic_judgment', 'self_expression'];
      case LearningPathType.challengeBased:
        return ['problem_solving', 'persistence', 'adaptability', 'optimization'];
      case LearningPathType.balanced:
        return ['algorithmic_thinking', 'creative_thinking', 'problem_solving', 'adaptability'];
    }
  }

  /// Get the recommended teaching approaches for this learning path
  List<String> get recommendedApproaches {
    switch (this) {
      case LearningPathType.logicBased:
        return [
          'Explain concepts thoroughly before application',
          'Provide clear step-by-step instructions',
          'Use diagrams and flowcharts to illustrate concepts',
          'Emphasize pattern recognition in code structures'
        ];
      case LearningPathType.creativityBased:
        return [
          'Provide open-ended challenges with multiple solutions',
          'Encourage experimentation and exploration',
          'Celebrate unique and innovative approaches',
          'Connect coding concepts to artistic expression'
        ];
      case LearningPathType.challengeBased:
        return [
          'Present increasingly difficult challenges',
          'Provide immediate feedback on solutions',
          'Encourage optimization and refinement',
          'Celebrate persistence and overcoming obstacles'
        ];
      case LearningPathType.balanced:
        return [
          'Combine structured learning with creative exploration',
          'Alternate between guided instruction and open-ended challenges',
          'Provide multiple paths to success',
          'Balance technical concepts with creative applications'
        ];
    }
  }
}
