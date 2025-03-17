import 'package:flutter/material.dart';

enum PatternDifficulty {
  basic,     // Ages 7-8, simple patterns
  beginner,  // Ages 8-9, basic patterns with some variation
  intermediate, // Ages 9-11, more complex patterns with multiple elements
  advanced,  // Ages 11-13, complex patterns with multiple techniques
  master,    // Ages 13+, sophisticated patterns requiring mastery
}

// Extension methods for difficulty calculations and descriptions
extension PatternDifficultyExtension on PatternDifficulty {
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
      case PatternDifficulty.master:
        return 'Master';
    }
  }
  
  String get description {
    switch (this) {
      case PatternDifficulty.basic:
        return 'Simple patterns with few elements - perfect for beginners.';
      case PatternDifficulty.beginner:
        return 'Basic patterns with some variety - a step up from the basics.';
      case PatternDifficulty.intermediate:
        return 'More complex patterns with multiple elements - for confident weavers.';
      case PatternDifficulty.advanced:
        return 'Complex patterns with multiple techniques - for experienced weavers.';
      case PatternDifficulty.master:
        return 'Sophisticated patterns requiring mastery - for experts only.';
    }
  }
  
  int get recommendedMinAge {
    switch (this) {
      case PatternDifficulty.basic:
        return 7;
      case PatternDifficulty.beginner:
        return 8;
      case PatternDifficulty.intermediate:
        return 9;
      case PatternDifficulty.advanced:
        return 11;
      case PatternDifficulty.master:
        return 13;
    }
  }
  
  Color get color {
    switch (this) {
      case PatternDifficulty.basic:
        return Colors.green;
      case PatternDifficulty.beginner:
        return Colors.blue;
      case PatternDifficulty.intermediate:
        return Colors.amber;
      case PatternDifficulty.advanced:
        return Colors.orange;
      case PatternDifficulty.master:
        return Colors.red;
    }
  }
  
  IconData get icon {
    switch (this) {
      case PatternDifficulty.basic:
        return Icons.star_border;
      case PatternDifficulty.beginner:
        return Icons.star_half;
      case PatternDifficulty.intermediate:
        return Icons.star;
      case PatternDifficulty.advanced:
        return Icons.stars;
      case PatternDifficulty.master:
        return Icons.auto_awesome;
    }
  }
}