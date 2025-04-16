/// Represents the intensity level of a tone.
/// 
/// This enum defines different intensity levels that can be applied to tones
/// to modify their expression.
enum ToneIntensity {
  /// Subtle emotional cues.
  /// 
  /// Appropriate for subtle guidance and background information.
  mild,
  
  /// Moderate emotional expression.
  /// 
  /// The default intensity level for most educational contexts.
  moderate,
  
  /// Strong emotional expression.
  /// 
  /// Useful for emphasizing important points and creating memorable moments.
  strong,
  
  /// Very pronounced emotional expression.
  /// 
  /// Reserved for critical information and major achievements.
  intense,
}

/// Extension methods for tone intensity.
extension ToneIntensityExtension on ToneIntensity {
  /// Get a multiplier for tone parameters based on intensity.
  double get multiplier {
    switch (this) {
      case ToneIntensity.mild:
        return 0.5;
      case ToneIntensity.moderate:
        return 1.0;
      case ToneIntensity.strong:
        return 1.5;
      case ToneIntensity.intense:
        return 2.0;
    }
  }
  
  /// Get display name for this intensity level.
  String get displayName {
    switch (this) {
      case ToneIntensity.mild:
        return 'Mild';
      case ToneIntensity.moderate:
        return 'Moderate';
      case ToneIntensity.strong:
        return 'Strong';
      case ToneIntensity.intense:
        return 'Intense';
    }
  }
  
  /// Get educational appropriateness of this intensity level.
  /// 
  /// Returns a map with age ranges and learning contexts where
  /// this intensity level is most appropriate.
  Map<String, dynamic> get educationalAppropriateness {
    switch (this) {
      case ToneIntensity.mild:
        return {
          'ageRanges': ['7-9', '10-12', '13-15'],
          'contexts': [
            'background information',
            'subtle guidance',
            'reflection activities',
            'calm exploration',
          ],
          'learningStyles': ['reflective', 'analytical'],
        };
      case ToneIntensity.moderate:
        return {
          'ageRanges': ['7-9', '10-12', '13-15'],
          'contexts': [
            'standard instruction',
            'guided practice',
            'concept introduction',
            'general feedback',
          ],
          'learningStyles': ['all'],
        };
      case ToneIntensity.strong:
        return {
          'ageRanges': ['10-12', '13-15'],
          'contexts': [
            'important concepts',
            'key learning moments',
            'achievement recognition',
            'corrective feedback',
          ],
          'learningStyles': ['active', 'pragmatic', 'enthusiastic'],
        };
      case ToneIntensity.intense:
        return {
          'ageRanges': ['13-15'],
          'contexts': [
            'critical information',
            'major achievements',
            'safety instructions',
            'culminating activities',
          ],
          'learningStyles': ['active', 'enthusiastic'],
        };
    }
  }
  
  /// Check if this intensity is appropriate for a given age.
  bool isAppropriateForAge(int age) {
    final ageRanges = educationalAppropriateness['ageRanges'] as List<String>;
    
    for (final range in ageRanges) {
      final parts = range.split('-');
      final minAge = int.parse(parts[0]);
      final maxAge = int.parse(parts[1]);
      
      if (age >= minAge && age <= maxAge) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if this intensity is appropriate for a given learning context.
  bool isAppropriateForContext(String context) {
    final contexts = educationalAppropriateness['contexts'] as List<String>;
    final lowerContext = context.toLowerCase();
    
    for (final c in contexts) {
      if (lowerContext.contains(c.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if this intensity is appropriate for a given learning style.
  bool isAppropriateForLearningStyle(String learningStyle) {
    final styles = educationalAppropriateness['learningStyles'] as List<String>;
    final lowerStyle = learningStyle.toLowerCase();
    
    return styles.contains('all') || styles.contains(lowerStyle);
  }
  
  /// Get the most appropriate intensity for a given educational context.
  static ToneIntensity forEducationalContext(
    String context, 
    {int age = 10, String learningStyle = 'visual'}
  ) {
    // Check each intensity level for appropriateness
    for (final intensity in ToneIntensity.values.reversed) {
      if (intensity.isAppropriateForAge(age) &&
          intensity.isAppropriateForContext(context) &&
          intensity.isAppropriateForLearningStyle(learningStyle)) {
        return intensity;
      }
    }
    
    // Default to moderate if no match found
    return ToneIntensity.moderate;
  }
}
