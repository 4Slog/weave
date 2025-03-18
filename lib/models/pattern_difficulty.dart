import 'package:flutter/material.dart';

/// Defines difficulty levels for patterns, mapping to age-appropriate challenges
enum PatternDifficulty {
  /// Ages 7-8, simple patterns with few elements
  basic,
  
  /// Ages 8-9, basic patterns with some variation
  beginner,
  
  /// Ages 9-11, more complex patterns with multiple elements
  intermediate,
  
  /// Ages 11-13, complex patterns with multiple techniques
  advanced,
  
  /// Ages 13+, sophisticated patterns requiring mastery
  master,
}

/// Extension methods for difficulty calculations and descriptions
extension PatternDifficultyExtension on PatternDifficulty {
  /// Get a human-readable display name for this difficulty level
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
  
  /// Get a descriptive text for this difficulty level
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
  
  /// Get the recommended minimum age for this difficulty level
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
  
  /// Get the color associated with this difficulty level
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
  
  /// Get the icon associated with this difficulty level
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
  
  /// Get the numerical value of this difficulty level (1-5)
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
      case PatternDifficulty.master:
        return 5;
    }
  }
  
  /// Get the maximum recommended block count for this difficulty level
  int get recommendedMaxBlocks {
    switch (this) {
      case PatternDifficulty.basic:
        return 5;
      case PatternDifficulty.beginner:
        return 8;
      case PatternDifficulty.intermediate:
        return 12;
      case PatternDifficulty.advanced:
        return 18;
      case PatternDifficulty.master:
        return 25;
    }
  }
  
  /// Get the recommended time to complete (in minutes) for this difficulty level
  int get recommendedTimeMinutes {
    switch (this) {
      case PatternDifficulty.basic:
        return 5;
      case PatternDifficulty.beginner:
        return 10;
      case PatternDifficulty.intermediate:
        return 15;
      case PatternDifficulty.advanced:
        return 25;
      case PatternDifficulty.master:
        return 40;
    }
  }
  
  /// Get the educational concepts appropriate for this difficulty level
  List<String> get appropriateConcepts {
    final concepts = <String>[];
    
    // All levels include sequences
    concepts.add('sequences');
    
    // Beginner and above include variables
    if (this != PatternDifficulty.basic) {
      concepts.add('variables');
    }
    
    // Intermediate and above include loops
    if (this == PatternDifficulty.intermediate || 
        this == PatternDifficulty.advanced || 
        this == PatternDifficulty.master) {
      concepts.add('loops');
    }
    
    // Advanced and above include conditionals and functions
    if (this == PatternDifficulty.advanced || 
        this == PatternDifficulty.master) {
      concepts.add('conditionals');
      concepts.add('functions');
    }
    
    // Master includes recursion and complex algorithms
    if (this == PatternDifficulty.master) {
      concepts.add('recursion');
      concepts.add('algorithms');
    }
    
    return concepts;
  }
  
  /// Get the badge asset path for this difficulty level
  String get badgeAssetPath {
    switch (this) {
      case PatternDifficulty.basic:
        return 'assets/images/badges/basic_difficulty.png';
      case PatternDifficulty.beginner:
        return 'assets/images/badges/basic_difficulty.png'; // Reusing basic badge for now
      case PatternDifficulty.intermediate:
        return 'assets/images/badges/intermediate_difficulty.png';
      case PatternDifficulty.advanced:
        return 'assets/images/badges/advanced_difficulty.png';
      case PatternDifficulty.master:
        return 'assets/images/badges/advanced_difficulty.png'; // Reusing advanced badge for now
    }
  }
  
  /// Get the next difficulty level (or null if already at maximum)
  PatternDifficulty? get nextLevel {
    switch (this) {
      case PatternDifficulty.basic:
        return PatternDifficulty.beginner;
      case PatternDifficulty.beginner:
        return PatternDifficulty.intermediate;
      case PatternDifficulty.intermediate:
        return PatternDifficulty.advanced;
      case PatternDifficulty.advanced:
        return PatternDifficulty.master;
      case PatternDifficulty.master:
        return null; // Already at maximum
    }
  }
  
  /// Get the previous difficulty level (or null if already at minimum)
  PatternDifficulty? get previousLevel {
    switch (this) {
      case PatternDifficulty.basic:
        return null; // Already at minimum
      case PatternDifficulty.beginner:
        return PatternDifficulty.basic;
      case PatternDifficulty.intermediate:
        return PatternDifficulty.beginner;
      case PatternDifficulty.advanced:
        return PatternDifficulty.intermediate;
      case PatternDifficulty.master:
        return PatternDifficulty.advanced;
    }
  }
  
  /// Check if this difficulty level is appropriate for the given age
  bool isAppropriateForAge(int age) {
    return age >= recommendedMinAge;
  }
  
  /// Get the experience points awarded for completing a pattern of this difficulty
  int get experiencePoints {
    switch (this) {
      case PatternDifficulty.basic:
        return 10;
      case PatternDifficulty.beginner:
        return 20;
      case PatternDifficulty.intermediate:
        return 35;
      case PatternDifficulty.advanced:
        return 50;
      case PatternDifficulty.master:
        return 75;
    }
  }
  
  /// Get a detailed educational description for this difficulty level
  String get educationalDescription {
    switch (this) {
      case PatternDifficulty.basic:
        return 'Basic patterns teach fundamental sequencing and pattern recognition. '
               'These simple patterns help develop spatial reasoning and basic logical thinking.';
      case PatternDifficulty.beginner:
        return 'Beginner patterns introduce the concept of variables through different colors '
               'and simple pattern variations. These patterns help develop pattern recognition '
               'and basic problem-solving skills.';
      case PatternDifficulty.intermediate:
        return 'Intermediate patterns introduce loops and repetition, teaching the concept '
               'of iteration. These patterns help develop more advanced logical thinking and '
               'the ability to identify repeating structures.';
      case PatternDifficulty.advanced:
        return 'Advanced patterns introduce conditionals and functions, teaching decision-making '
               'and code reuse. These patterns help develop complex problem-solving skills and '
               'the ability to break down problems into smaller parts.';
      case PatternDifficulty.master:
        return 'Master patterns introduce recursion and complex algorithms, teaching advanced '
               'computational thinking. These patterns help develop sophisticated problem-solving '
               'skills and the ability to create elegant, efficient solutions.';
    }
  }
}

/// Parse a difficulty level from a string or int
PatternDifficulty parseDifficulty(dynamic value) {
  if (value == null) return PatternDifficulty.basic;
  
  if (value is int) {
    // Convert numeric difficulty to enum
    switch (value) {
      case 1: return PatternDifficulty.basic;
      case 2: return PatternDifficulty.beginner;
      case 3: return PatternDifficulty.intermediate;
      case 4: return PatternDifficulty.advanced;
      case 5: return PatternDifficulty.master;
      default: return PatternDifficulty.basic;
    }
  }
  
  if (value is String) {
    try {
      return PatternDifficulty.values.firstWhere(
        (d) => d.toString().split('.').last.toLowerCase() == value.toLowerCase(),
        orElse: () => PatternDifficulty.basic,
      );
    } catch (_) {
      return PatternDifficulty.basic;
    }
  }
  
  return PatternDifficulty.basic;
}
