import 'package:flutter/material.dart';

/// Enum representing the difficulty level of a pattern
enum PatternDifficulty {
  /// Basic difficulty level (suitable for beginners)
  basic,
  
  /// Beginner difficulty level
  beginner,
  
  /// Intermediate difficulty level
  intermediate,
  
  /// Advanced difficulty level
  advanced,
  
  /// Expert difficulty level (suitable for experienced users)
  expert,
  
  /// Master difficulty level (suitable for masters)
  master,
}

/// Extension methods for PatternDifficulty
extension PatternDifficultyExtension on PatternDifficulty {
  /// Get the display name for this difficulty level
  String get displayName {
    switch (this) {
      case PatternDifficulty.basic:
        return 'Basic';
      case PatternDifficulty.beginner:
        return 'Beginner';
      case PatternDifficulty.intermediate:
        return 'Intermediate';
      case PatternDifficulty.advanced:
        return 'Advanced';
      case PatternDifficulty.expert:
        return 'Expert';
      case PatternDifficulty.master:
        return 'Master';
    }
  }
  
  /// Get the color associated with this difficulty level
  Color get color {
    switch (this) {
      case PatternDifficulty.basic:
        return Colors.green.shade300;
      case PatternDifficulty.beginner:
        return Colors.green;
      case PatternDifficulty.intermediate:
        return Colors.blue;
      case PatternDifficulty.advanced:
        return Colors.orange;
      case PatternDifficulty.expert:
        return Colors.red;
      case PatternDifficulty.master:
        return Colors.purple;
    }
  }
  
  /// Get the numeric value of this difficulty level (1-6)
  int get value {
    switch (this) {
      case PatternDifficulty.basic:
        return 1;
      case PatternDifficulty.beginner:
        return 2;
      case PatternDifficulty.intermediate:
        return 3;
      case PatternDifficulty.advanced:
        return 4;
      case PatternDifficulty.expert:
        return 5;
      case PatternDifficulty.master:
        return 6;
    }
  }
  
  /// Get the recommended minimum age for this difficulty level
  int get recommendedMinAge {
    switch (this) {
      case PatternDifficulty.basic:
        return 5;
      case PatternDifficulty.beginner:
        return 6;
      case PatternDifficulty.intermediate:
        return 7;
      case PatternDifficulty.advanced:
        return 9;
      case PatternDifficulty.expert:
        return 11;
      case PatternDifficulty.master:
        return 13;
    }
  }
  
  /// Get the recommended maximum age for this difficulty level
  int get recommendedMaxAge {
    switch (this) {
      case PatternDifficulty.basic:
        return 7;
      case PatternDifficulty.beginner:
        return 8;
      case PatternDifficulty.intermediate:
        return 10;
      case PatternDifficulty.advanced:
        return 12;
      case PatternDifficulty.expert:
        return 14;
      case PatternDifficulty.master:
        return 18;
    }
  }
  
  /// Get the icon associated with this difficulty level
  IconData get icon {
    switch (this) {
      case PatternDifficulty.basic:
        return Icons.star_border_outlined;
      case PatternDifficulty.beginner:
        return Icons.star_border;
      case PatternDifficulty.intermediate:
        return Icons.star_half;
      case PatternDifficulty.advanced:
        return Icons.star;
      case PatternDifficulty.expert:
        return Icons.auto_awesome;
      case PatternDifficulty.master:
        return Icons.workspace_premium;
    }
  }
  
  /// Get the description of this difficulty level
  String get description {
    switch (this) {
      case PatternDifficulty.basic:
        return 'Very simple patterns with minimal elements, suitable for absolute beginners';
      case PatternDifficulty.beginner:
        return 'Simple patterns with few elements, suitable for beginners';
      case PatternDifficulty.intermediate:
        return 'Moderately complex patterns with more elements';
      case PatternDifficulty.advanced:
        return 'Complex patterns with multiple elements and connections';
      case PatternDifficulty.expert:
        return 'Very complex patterns requiring deep understanding';
      case PatternDifficulty.master:
        return 'Extremely complex patterns for masters of the craft';
    }
  }
  
  /// Parse a difficulty level from a string
  static PatternDifficulty fromString(String difficultyStr) {
    try {
      return PatternDifficulty.values.firstWhere(
        (diff) => diff.toString().split('.').last.toLowerCase() == difficultyStr.toLowerCase(),
        orElse: () => PatternDifficulty.basic,
      );
    } catch (e) {
      return PatternDifficulty.basic; // Default
    }
  }
}
