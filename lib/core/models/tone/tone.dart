import 'package:flutter/material.dart';

/// Interface for all tone types.
/// 
/// This interface defines the common properties and methods that all tone
/// implementations must provide, including educational context.
abstract class Tone {
  /// Unique identifier for the tone.
  String get id;
  
  /// Display name of the tone.
  String get displayName;
  
  /// Description of the tone.
  String get description;
  
  /// Color associated with the tone.
  Color get color;
  
  /// Icon associated with the tone.
  IconData get icon;
  
  /// Cultural context or significance of the tone.
  String get culturalContext;
  
  /// Educational context of the tone.
  /// 
  /// This describes how the tone can be used in educational settings
  /// and its relevance to learning.
  String get educationalContext;
  
  /// Age appropriateness of the tone.
  /// 
  /// Minimum recommended age for using this tone.
  int get minAgeAppropriate;
  
  /// Maximum recommended age for using this tone.
  /// 
  /// Use -1 for no upper limit.
  int get maxAgeAppropriate;
  
  /// Learning styles that this tone is most effective for.
  /// 
  /// This is a list of learning style identifiers (e.g., "visual", "auditory").
  List<String> get effectiveLearningStyles;
  
  /// Educational effectiveness of the tone.
  /// 
  /// A value from 0.0 to 1.0 indicating how effective this tone is
  /// for educational purposes.
  double get educationalEffectiveness;
  
  /// Speech parameters for text-to-speech.
  /// 
  /// Get the pitch modification for this tone.
  double get pitch;
  
  /// Get the rate modification for this tone.
  double get rate;
  
  /// Get the volume for this tone.
  double get volume;
  
  /// Check if this tone is appropriate for a given age.
  bool isAppropriateForAge(int age) {
    return age >= minAgeAppropriate && 
           (maxAgeAppropriate == -1 || age <= maxAgeAppropriate);
  }
  
  /// Check if this tone is effective for a given learning style.
  bool isEffectiveForLearningStyle(String learningStyle) {
    return effectiveLearningStyles.contains(learningStyle.toLowerCase());
  }
  
  /// Get a map of all properties for serialization.
  Map<String, dynamic> toMap();
}
