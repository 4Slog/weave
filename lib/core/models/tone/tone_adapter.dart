import 'tone.dart';

/// Interface for adapting between different tone implementations.
/// 
/// This interface defines methods for converting between different
/// tone implementations and selecting appropriate tones based on context.
abstract class ToneAdapter<T extends Tone> {
  /// Convert a tone to a string representation.
  String toneToString(T tone);
  
  /// Create a tone from a string representation.
  T toneFromString(String toneString);
  
  /// Get a tone by its identifier.
  T getToneById(String id);
  
  /// Get all available tones.
  List<T> getAllTones();
  
  /// Get tones appropriate for a given age.
  List<T> getTonesForAge(int age);
  
  /// Get tones effective for a given learning style.
  List<T> getTonesForLearningStyle(String learningStyle);
  
  /// Get a tone appropriate for a given narrative context.
  T getToneForContext(String context);
  
  /// Get a tone appropriate for a given educational context.
  T getToneForEducationalContext(String educationalContext);
  
  /// Get a tone appropriate for a given educational objective.
  /// 
  /// [objective] is the learning objective (e.g., "introduce new concept",
  /// "reinforce understanding", "assess knowledge").
  /// [conceptDifficulty] is the difficulty level of the concept (0.0 to 1.0).
  /// [learnerProfile] is optional information about the learner.
  T getToneForEducationalObjective(
    String objective, 
    double conceptDifficulty, 
    {Map<String, dynamic>? learnerProfile}
  );
}
