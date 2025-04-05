import 'dart:math';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';

// Using LearningStyle from user_progress.dart

/// Service for analyzing learning patterns and user behavior
class LearningAnalysisService {
  // Singleton implementation
  static final LearningAnalysisService _instance = LearningAnalysisService._internal();

  factory LearningAnalysisService() {
    return _instance;
  }

  LearningAnalysisService._internal();

  // Learning style points for detection
  final Map<LearningStyle, int> _learningStylePoints = {};

  // Thresholds for learning style detection
  static const int _learningStyleThreshold = 10;

  /// Initialize learning style points from user progress
  void initializeLearningStylePoints(UserProgress userProgress) {
    // Initialize with default values
    for (var style in LearningStyle.values) {
      _learningStylePoints[style] = 0;
    }

    // Update with confidence values from user progress
    userProgress.learningStyleConfidence.forEach((style, confidence) {
      // Convert confidence (0.0-1.0) to points (0-20)
      _learningStylePoints[style] = (confidence * 20).round();
    });
  }

  /// Update learning style points based on action
  void updateLearningStylePoints(String actionType, Map<String, dynamic>? metadata) {
    // Initialize learning style points if needed
    if (_learningStylePoints.isEmpty) {
      for (var style in LearningStyle.values) {
        _learningStylePoints[style] = 0;
      }
    }

    switch (actionType) {
      case 'pattern_creation':
        // Visual and practical learners enjoy pattern creation
        _increaseStylePoints(LearningStyle.visual, 2);
        _increaseStylePoints(LearningStyle.practical, 1);
        break;

      case 'cultural_exploration':
        // Reflective and verbal learners enjoy cultural context
        _increaseStylePoints(LearningStyle.reflective, 2);
        _increaseStylePoints(LearningStyle.verbal, 1);
        break;

      case 'debug_success':
      case 'debug_failure':
        // Logical and reflective learners engage with debugging
        _increaseStylePoints(LearningStyle.logical, 2);
        _increaseStylePoints(LearningStyle.reflective, 1);
        break;

      case 'story_progress':
        // Verbal and reflective learners enjoy storytelling
        _increaseStylePoints(LearningStyle.verbal, 2);
        _increaseStylePoints(LearningStyle.reflective, 1);
        break;

      case 'block_connection':
        // Visual and logical learners engage with block connections
        _increaseStylePoints(LearningStyle.visual, 1);
        _increaseStylePoints(LearningStyle.logical, 1);
        break;

      case 'challenge_completion':
        // Check for interaction patterns that indicate learning style
        if (metadata != null) {
          final completionTime = metadata['completionTimeSeconds'] ?? 0;
          final attempts = metadata['attempts'] ?? 1;
          final blockCount = metadata['blockCount'] ?? 0;

          if (completionTime < 60 && attempts <= 1) {
            // Quick, successful completion indicates practical learner
            _increaseStylePoints(LearningStyle.practical, 2);
          } else if (completionTime > 180 && attempts > 2) {
            // Long completion time with multiple attempts suggests reflective
            _increaseStylePoints(LearningStyle.reflective, 2);
          }

          if (blockCount > 10) {
            // Complex solutions suggest logical learner
            _increaseStylePoints(LearningStyle.logical, 1);
          } else if (blockCount <= 5) {
            // Simple, elegant solutions suggest practical learner
            _increaseStylePoints(LearningStyle.practical, 1);
          }
        }
        break;
    }

    // If user shared their creation, that's a social learning indicator
    if (metadata != null && metadata.containsKey('shared') && metadata['shared'] == true) {
      _increaseStylePoints(LearningStyle.social, 2);
    }

    // If user viewed a hint, that could indicate learning style
    if (metadata != null && metadata.containsKey('viewedHint') && metadata['viewedHint'] == true) {
      if (metadata.containsKey('hintType')) {
        final hintType = metadata['hintType'];

        if (hintType == 'visual') {
          _increaseStylePoints(LearningStyle.visual, 1);
        } else if (hintType == 'verbal') {
          _increaseStylePoints(LearningStyle.verbal, 1);
        } else if (hintType == 'logical') {
          _increaseStylePoints(LearningStyle.logical, 1);
        }
      }
    }
  }

  /// Increase points for a specific learning style
  void _increaseStylePoints(LearningStyle style, int points) {
    _learningStylePoints[style] = (_learningStylePoints[style] ?? 0) + points;
  }

  /// Get the user's primary learning style based on accumulated points
  LearningStyle getPrimaryLearningStyle() {
    LearningStyle primaryStyle = LearningStyle.visual; // Default
    int maxPoints = 0;

    for (final entry in _learningStylePoints.entries) {
      if (entry.value > maxPoints) {
        maxPoints = entry.value;
        primaryStyle = entry.key;
      }
    }

    return primaryStyle;
  }

  /// Get all learning styles that meet the threshold
  List<LearningStyle> getSignificantLearningStyles() {
    List<LearningStyle> significantStyles = [];

    for (final entry in _learningStylePoints.entries) {
      if (entry.value >= _learningStyleThreshold) {
        significantStyles.add(entry.key);
      }
    }

    return significantStyles;
  }

  /// Get learning style confidence values (0.0 to 1.0)
  Map<LearningStyle, double> getLearningStyleConfidence() {
    Map<LearningStyle, double> confidences = {};

    // Get total points
    int totalPoints = 0;
    for (final points in _learningStylePoints.values) {
      totalPoints += points;
    }

    // Calculate confidence for each style (minimum 0.1 baseline)
    if (totalPoints > 0) {
      for (final entry in _learningStylePoints.entries) {
        confidences[entry.key] = 0.1 + (0.9 * entry.value / totalPoints);
      }
    } else {
      // If no data yet, assign equal confidence
      for (final style in _learningStylePoints.keys) {
        confidences[style] = 0.1;
      }
    }

    return confidences;
  }

  /// Get hint priority based on hint type and user skills
  int getHintPriority(String hintType, UserProgress userProgress) {
    int priority = 5; // Default priority

    switch (hintType) {
      case 'loop':
        // Higher priority if struggling with loops
        double loopsProficiency = userProgress.skillProficiency['loops'] ?? 0.0;
        if (loopsProficiency < 0.4) {
          priority += 3;
        }
        break;

      case 'conditional':
        // Higher priority if struggling with conditionals
        double conditionalsProficiency = userProgress.skillProficiency['conditionals'] ?? 0.0;
        if (conditionalsProficiency < 0.4) {
          priority += 3;
        }
        break;

      case 'pattern':
        // Higher priority if good with patterns
        double patternsProficiency = userProgress.skillProficiency['patterns'] ?? 0.0;
        if (patternsProficiency > 0.6) {
          priority += 2;
        }
        break;

      case 'cultural':
        // Higher priority for cultural hints if the user shows interest
        double culturalProficiency = userProgress.skillProficiency['cultural'] ?? 0.0;
        if (culturalProficiency > 0.6) {
          priority += 2;
        }

        // Boost if user has shown interest in cultural aspects
        if (userProgress.preferences.containsKey('interestedInCulture') &&
            userProgress.preferences['interestedInCulture'] == true) {
          priority += 2;
        }

        // Also consider learning style - verbal and reflective learners prefer cultural context
        if (getPrimaryLearningStyle() == LearningStyle.verbal ||
            getPrimaryLearningStyle() == LearningStyle.reflective) {
          priority += 1;
        }
        break;

      case 'debug':
        // Higher priority if user is actively debugging
        if (userProgress.preferences.containsKey('consecutiveFailures') &&
            userProgress.preferences['consecutiveFailures'] >= 3) {
          priority += 4;
        }
        break;
    }

    // Adjust priority based on learning style preferences
    priority = _adjustPriorityForLearningStyle(hintType, priority);

    // Ensure priority is within bounds
    return min(10, max(0, priority));
  }

  /// Adjust hint priority based on learning style
  int _adjustPriorityForLearningStyle(String hintType, int basePriority) {
    final learningStyle = getPrimaryLearningStyle();

    // Visual learners prefer image-based hints
    if (learningStyle == LearningStyle.visual && hintType.contains('image')) {
      return basePriority + 2;
    }

    // Verbal learners prefer text-based hints
    if (learningStyle == LearningStyle.verbal && hintType.contains('text')) {
      return basePriority + 2;
    }

    // Logical learners prefer structured hints
    if (learningStyle == LearningStyle.logical && hintType.contains('logic')) {
      return basePriority + 2;
    }

    // Practical learners prefer example-based hints
    if (learningStyle == LearningStyle.practical && hintType.contains('example')) {
      return basePriority + 2;
    }

    return basePriority;
  }

  /// Calculate experience points for an action
  int calculateExperienceForAction(String actionType, Map<String, dynamic>? metadata) {
    // Base XP values for different action types
    switch (actionType) {
      case 'challenge_completion':
        int difficulty = metadata?['difficulty'] ?? 1;
        return 10 * difficulty;

      case 'pattern_creation':
        int blockCount = metadata?['blockCount'] ?? 1;
        return 5 + (blockCount * 2);

      case 'story_progress':
        return 15;

      case 'cultural_exploration':
        return 8;

      case 'block_connection':
        return 1; // Small reward for basic interaction

      default:
        return 5; // Default XP amount
    }
  }

  /// Detect learning style from user interactions
  LearningStyle detectLearningStyle(UserProgress userProgress) {
    // Initialize from user progress if needed
    if (_learningStylePoints.isEmpty) {
      initializeLearningStylePoints(userProgress);
    }

    return getPrimaryLearningStyle();
  }

  /// Get learning style points for debugging
  Map<LearningStyle, int> getLearningStylePoints() {
    return Map.from(_learningStylePoints);
  }
}

