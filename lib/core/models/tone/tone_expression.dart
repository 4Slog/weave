import 'tone.dart';
import 'tone_intensity.dart';

/// Class to represent a complete tone expression with tone and intensity.
/// 
/// This class combines a tone with an intensity level to create a complete
/// expression that can be used for narration, feedback, and other educational
/// interactions.
class ToneExpression<T extends Tone> {
  /// The tone being expressed.
  final T tone;
  
  /// The intensity of the expression.
  final ToneIntensity intensity;
  
  /// Educational context for this expression.
  final String? educationalContext;
  
  /// Create a tone expression.
  const ToneExpression({
    required this.tone,
    this.intensity = ToneIntensity.moderate,
    this.educationalContext,
  });
  
  /// Get the adjusted pitch for this expression.
  double get pitch {
    final basePitch = tone.pitch;
    final intensityEffect = (basePitch > 1.0) 
        ? (basePitch - 1.0) * intensity.multiplier + 1.0
        : 1.0 - (1.0 - basePitch) * intensity.multiplier;
    return intensityEffect;
  }
  
  /// Get the adjusted rate for this expression.
  double get rate {
    final baseRate = tone.rate;
    final intensityEffect = (baseRate > 0.5) 
        ? (baseRate - 0.5) * intensity.multiplier + 0.5
        : 0.5 - (0.5 - baseRate) * intensity.multiplier;
    return intensityEffect;
  }
  
  /// Get the adjusted volume for this expression.
  double get volume {
    return tone.volume * (0.8 + (intensity.multiplier * 0.2));
  }
  
  /// Get the educational effectiveness of this expression.
  /// 
  /// This combines the tone's educational effectiveness with the
  /// appropriateness of the intensity for the given context.
  double get educationalEffectiveness {
    double contextMultiplier = 1.0;
    
    if (educationalContext != null && educationalContext!.isNotEmpty) {
      contextMultiplier = intensity.isAppropriateForContext(educationalContext!) ? 1.2 : 0.8;
    }
    
    return tone.educationalEffectiveness * contextMultiplier;
  }
  
  /// Check if this expression is appropriate for a given age.
  bool isAppropriateForAge(int age) {
    return tone.isAppropriateForAge(age) && intensity.isAppropriateForAge(age);
  }
  
  /// Check if this expression is effective for a given learning style.
  bool isEffectiveForLearningStyle(String learningStyle) {
    return tone.isEffectiveForLearningStyle(learningStyle) && 
           intensity.isAppropriateForLearningStyle(learningStyle);
  }
  
  /// Get a string representation of this expression.
  @override
  String toString() {
    return '${intensity.displayName} ${tone.displayName}';
  }
  
  /// Create a copy of this expression with some fields replaced.
  ToneExpression<T> copyWith({
    T? tone,
    ToneIntensity? intensity,
    String? educationalContext,
  }) {
    return ToneExpression<T>(
      tone: tone ?? this.tone,
      intensity: intensity ?? this.intensity,
      educationalContext: educationalContext ?? this.educationalContext,
    );
  }
  
  /// Convert this expression to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'tone': tone.toMap(),
      'intensity': intensity.toString().split('.').last,
      'educationalContext': educationalContext,
    };
  }
}
