
/// Skill proficiency levels for tracking progress
enum ProficiencyLevel {
  /// No exposure to the concept yet
  notIntroduced,
  
  /// Concept has been introduced but not practiced
  introduced,
  
  /// Beginning to practice the concept with guidance
  practicing,
  
  /// Can apply the concept with occasional help
  developing,
  
  /// Can reliably apply the concept independently
  proficient,
  
  /// Can teach or extend the concept to new contexts
  mastered,
}

/// Extension to convert between ProficiencyLevel and double values
extension ProficiencyLevelExtension on ProficiencyLevel {
  /// Convert proficiency level to a double value (0.0 to 1.0)
  double toDouble() {
    switch (this) {
      case ProficiencyLevel.notIntroduced:
        return 0.0;
      case ProficiencyLevel.introduced:
        return 0.2;
      case ProficiencyLevel.practicing:
        return 0.4;
      case ProficiencyLevel.developing:
        return 0.6;
      case ProficiencyLevel.proficient:
        return 0.8;
      case ProficiencyLevel.mastered:
        return 1.0;
    }
  }
  
  /// Create a proficiency level from a double value
  static ProficiencyLevel fromDouble(double value) {
    if (value < 0.1) return ProficiencyLevel.notIntroduced;
    if (value < 0.3) return ProficiencyLevel.introduced;
    if (value < 0.5) return ProficiencyLevel.practicing;
    if (value < 0.7) return ProficiencyLevel.developing;
    if (value < 0.9) return ProficiencyLevel.proficient;
    return ProficiencyLevel.mastered;
  }
  
  /// Get a human-readable name for the proficiency level
  String get displayName {
    switch (this) {
      case ProficiencyLevel.notIntroduced:
        return 'Not Introduced';
      case ProficiencyLevel.introduced:
        return 'Introduced';
      case ProficiencyLevel.practicing:
        return 'Practicing';
      case ProficiencyLevel.developing:
        return 'Developing';
      case ProficiencyLevel.proficient:
        return 'Proficient';
      case ProficiencyLevel.mastered:
        return 'Mastered';
    }
  }
  
  /// Get a description of the proficiency level
  String get description {
    switch (this) {
      case ProficiencyLevel.notIntroduced:
        return 'No exposure to the concept yet';
      case ProficiencyLevel.introduced:
        return 'Concept has been introduced but not practiced';
      case ProficiencyLevel.practicing:
        return 'Beginning to practice the concept with guidance';
      case ProficiencyLevel.developing:
        return 'Can apply the concept with occasional help';
      case ProficiencyLevel.proficient:
        return 'Can reliably apply the concept independently';
      case ProficiencyLevel.mastered:
        return 'Can teach or extend the concept to new contexts';
    }
  }
  
  /// Get the string representation of the proficiency level
  String toStringValue() {
    return toString().split('.').last;
  }
  
  /// Create a proficiency level from a string
  static ProficiencyLevel fromString(String value) {
    return ProficiencyLevel.values.firstWhere(
      (level) => level.toString().split('.').last == value,
      orElse: () => ProficiencyLevel.notIntroduced,
    );
  }
}
