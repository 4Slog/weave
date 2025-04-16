import '../models/tone/tone_expression.dart';
import '../models/tone/tone_intensity.dart';
import '../models/tone/emotional_tone.dart';
import '../models/tone/emotional_tone_type.dart';
import '../models/education/learning_style_profile.dart';
import 'storage/storage_service_refactored.dart';

/// Service for selecting appropriate tones for educational contexts.
///
/// This service provides methods for selecting tones based on educational
/// objectives, learning styles, and other educational factors.
class EducationalToneService {
  final StorageService _storageService;

  /// Create an educational tone service.
  EducationalToneService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  /// Get a tone expression appropriate for a given educational context.
  ///
  /// [context] is the educational context (e.g., "introducing new concept",
  /// "providing feedback", "celebrating achievement").
  /// [userId] is the ID of the user, used to retrieve their learning profile.
  /// [age] is the age of the user, used if no learning profile is available.
  /// [conceptDifficulty] is the difficulty level of the concept (0.0 to 1.0).
  Future<ToneExpression<EmotionalTone>> getToneForEducationalContext(
    String context, {
    String? userId,
    int? age,
    double conceptDifficulty = 0.5,
  }) async {
    // Get user's learning profile if available
    LearningStyleProfile? learningProfile;
    if (userId != null) {
      learningProfile = await _storageService.getLearningStyleProfile(userId);
    }

    // Determine user's age
    final userAge = age ??
                   (learningProfile != null ? _estimateAgeFromProfile(learningProfile) : 10);

    // Determine user's learning style
    final learningStyle = learningProfile?.dominantStyle.toString().split('.').last ?? 'visual';

    // Select appropriate tone based on context
    final tone = EmotionalTone.getToneForEducationalContext(context);

    // Select appropriate intensity based on context, age, and learning style
    final intensity = _getIntensityForContext(
      context,
      age: userAge,
      learningStyle: learningStyle,
    );

    // Create and return the tone expression
    return ToneExpression<EmotionalTone>(
      tone: tone,
      intensity: intensity,
      educationalContext: context,
    );
  }

  /// Get a tone expression appropriate for a given educational objective.
  ///
  /// [objective] is the learning objective (e.g., "introduce new concept",
  /// "reinforce understanding", "assess knowledge").
  /// [userId] is the ID of the user, used to retrieve their learning profile.
  /// [age] is the age of the user, used if no learning profile is available.
  /// [conceptDifficulty] is the difficulty level of the concept (0.0 to 1.0).
  Future<ToneExpression<EmotionalTone>> getToneForEducationalObjective(
    String objective, {
    String? userId,
    int? age,
    double conceptDifficulty = 0.5,
  }) async {
    // Get user's learning profile if available
    LearningStyleProfile? learningProfile;
    if (userId != null) {
      learningProfile = await _storageService.getLearningStyleProfile(userId);
    }

    // Determine user's age
    final userAge = age ??
                   (learningProfile != null ? _estimateAgeFromProfile(learningProfile) : 10);

    // Determine user's learning style
    final learningStyle = learningProfile?.dominantStyle.toString().split('.').last ?? 'visual';

    // Create learner profile map
    final learnerProfile = {
      'age': userAge,
      'learningStyle': learningStyle,
      'profile': learningProfile?.toJson(),
    };

    // Select appropriate tone based on objective and difficulty
    final tone = EmotionalTone.getToneForEducationalObjective(
      objective,
      conceptDifficulty,
      learnerProfile: learnerProfile,
    );

    // Select appropriate intensity based on objective, age, and learning style
    final intensity = _getIntensityForContext(
      objective,
      age: userAge,
      learningStyle: learningStyle,
    );

    // Create and return the tone expression
    return ToneExpression<EmotionalTone>(
      tone: tone,
      intensity: intensity,
      educationalContext: objective,
    );
  }

  /// Get a tone expression appropriate for a given learning style.
  ///
  /// [learningStyle] is the learning style (e.g., "visual", "auditory").
  /// [context] is the educational context.
  /// [age] is the age of the user.
  ToneExpression<EmotionalTone> getToneForLearningStyle(
    String learningStyle, {
    String context = '',
    int age = 10,
  }) {
    // Get tones effective for this learning style
    final tones = EmotionalTone.getTonesForLearningStyle(learningStyle);

    // Filter by age appropriateness
    final ageTones = tones.where((tone) => tone.isAppropriateForAge(age)).toList();

    // If no tones match, use neutral
    if (ageTones.isEmpty) {
      return ToneExpression<EmotionalTone>(
        tone: EmotionalTone.getByType(EmotionalToneType.neutral),
        intensity: ToneIntensity.moderate,
        educationalContext: context,
      );
    }

    // Sort by educational effectiveness
    ageTones.sort((a, b) => b.educationalEffectiveness.compareTo(a.educationalEffectiveness));

    // Select appropriate intensity
    final intensity = _getIntensityForContext(
      context,
      age: age,
      learningStyle: learningStyle,
    );

    // Create and return the tone expression
    return ToneExpression<EmotionalTone>(
      tone: ageTones.first,
      intensity: intensity,
      educationalContext: context,
    );
  }

  /// Get a tone expression appropriate for a given age group.
  ///
  /// [age] is the age of the user.
  /// [context] is the educational context.
  /// [learningStyle] is the learning style.
  ToneExpression<EmotionalTone> getToneForAge(
    int age, {
    String context = '',
    String learningStyle = 'visual',
  }) {
    // Get tones appropriate for this age
    final tones = EmotionalTone.getTonesForAge(age);

    // If no tones match, use neutral
    if (tones.isEmpty) {
      return ToneExpression<EmotionalTone>(
        tone: EmotionalTone.getByType(EmotionalToneType.neutral),
        intensity: ToneIntensity.moderate,
        educationalContext: context,
      );
    }

    // Filter by learning style if specified
    List<EmotionalTone> filteredTones = tones;
    if (learningStyle.isNotEmpty) {
      final styleTones = tones.where((tone) =>
          tone.isEffectiveForLearningStyle(learningStyle)).toList();
      if (styleTones.isNotEmpty) {
        filteredTones = styleTones;
      }
    }

    // Sort by educational effectiveness
    filteredTones.sort((a, b) => b.educationalEffectiveness.compareTo(a.educationalEffectiveness));

    // Select appropriate intensity
    final intensity = _getIntensityForContext(
      context,
      age: age,
      learningStyle: learningStyle,
    );

    // Create and return the tone expression
    return ToneExpression<EmotionalTone>(
      tone: filteredTones.first,
      intensity: intensity,
      educationalContext: context,
    );
  }

  /// Get a tone expression for providing feedback.
  ///
  /// [success] indicates whether the feedback is for success or failure.
  /// [userId] is the ID of the user, used to retrieve their learning profile.
  /// [age] is the age of the user, used if no learning profile is available.
  /// [conceptDifficulty] is the difficulty level of the concept (0.0 to 1.0).
  Future<ToneExpression<EmotionalTone>> getToneForFeedback(
    bool success, {
    String? userId,
    int? age,
    double conceptDifficulty = 0.5,
  }) async {
    // For this method, we don't need to get the user's learning profile
    // We determine the tone and intensity directly based on success and difficulty

    // Select appropriate tone based on success or failure
    final tone = success
        ? EmotionalTone.getByType(EmotionalToneType.proud)
        : EmotionalTone.getByType(EmotionalToneType.encouraging);

    // Select appropriate intensity based on difficulty and success
    ToneIntensity intensity;
    if (success) {
      // Higher intensity for success with difficult concepts
      intensity = conceptDifficulty > 0.7
          ? ToneIntensity.strong
          : ToneIntensity.moderate;
    } else {
      // Milder intensity for failure with difficult concepts
      intensity = conceptDifficulty > 0.7
          ? ToneIntensity.mild
          : ToneIntensity.moderate;
    }

    // Create and return the tone expression
    return ToneExpression<EmotionalTone>(
      tone: tone,
      intensity: intensity,
      educationalContext: success ? 'success feedback' : 'constructive feedback',
    );
  }

  /// Get a tone expression for a story narration.
  ///
  /// [storyPhase] indicates the phase of the story (e.g., "introduction",
  /// "rising action", "climax", "resolution").
  /// [culturalContext] provides cultural context for the story.
  /// [userId] is the ID of the user, used to retrieve their learning profile.
  /// [age] is the age of the user, used if no learning profile is available.
  Future<ToneExpression<EmotionalTone>> getToneForStoryNarration(
    String storyPhase, {
    String culturalContext = '',
    String? userId,
    int? age,
  }) async {
    // Get user's learning profile if available
    LearningStyleProfile? learningProfile;
    if (userId != null) {
      learningProfile = await _storageService.getLearningStyleProfile(userId);
    }

    // Determine user's age
    final userAge = age ??
                   (learningProfile != null ? _estimateAgeFromProfile(learningProfile) : 10);

    // Select appropriate tone based on story phase
    EmotionalTone tone;
    final lowerPhase = storyPhase.toLowerCase();

    if (lowerPhase.contains('introduction') || lowerPhase.contains('beginning')) {
      tone = EmotionalTone.getByType(EmotionalToneType.curious);
    } else if (lowerPhase.contains('rising') || lowerPhase.contains('building')) {
      tone = EmotionalTone.getByType(EmotionalToneType.mysterious);
    } else if (lowerPhase.contains('climax') || lowerPhase.contains('peak')) {
      tone = EmotionalTone.getByType(EmotionalToneType.dramatic);
    } else if (lowerPhase.contains('resolution') || lowerPhase.contains('ending')) {
      tone = EmotionalTone.getByType(EmotionalToneType.reflective);
    } else if (lowerPhase.contains('cultural') || culturalContext.isNotEmpty) {
      tone = EmotionalTone.getByType(EmotionalToneType.wise);
    } else {
      tone = EmotionalTone.getByType(EmotionalToneType.neutral);
    }

    // Select appropriate intensity based on story phase and age
    ToneIntensity intensity;

    if (lowerPhase.contains('climax') || lowerPhase.contains('peak')) {
      intensity = userAge < 10 ? ToneIntensity.moderate : ToneIntensity.strong;
    } else if (lowerPhase.contains('resolution') || lowerPhase.contains('ending')) {
      intensity = ToneIntensity.mild;
    } else {
      intensity = ToneIntensity.moderate;
    }

    // Create and return the tone expression
    return ToneExpression<EmotionalTone>(
      tone: tone,
      intensity: intensity,
      educationalContext: 'story narration - $storyPhase',
    );
  }

  /// Estimate age from learning profile.
  ///
  /// This is a simple heuristic based on the learning profile.
  int _estimateAgeFromProfile(LearningStyleProfile profile) {
    // Default age if we can't estimate
    return 10;
  }

  /// Helper method to get the appropriate intensity for a context
  /// This is a workaround for the static extension method
  ToneIntensity _getIntensityForContext(
    String context, {
    int age = 10,
    String learningStyle = 'visual',
  }) {
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
