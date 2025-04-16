import 'package:flutter/material.dart';
import 'tone.dart';
import 'emotional_tone_type.dart';

/// Implementation of the Tone interface for emotional tones.
///
/// This class represents an emotional tone with educational context
/// and other properties required by the Tone interface.
class EmotionalTone implements Tone {
  /// The type of emotional tone.
  final EmotionalToneType type;

  @override
  final String id;

  @override
  final String displayName;

  @override
  final String description;

  @override
  final Color color;

  @override
  final IconData icon;

  @override
  final String culturalContext;

  @override
  final String educationalContext;

  @override
  final int minAgeAppropriate;

  @override
  final int maxAgeAppropriate;

  @override
  final List<String> effectiveLearningStyles;

  @override
  final double educationalEffectiveness;

  @override
  final double pitch;

  @override
  final double rate;

  @override
  final double volume;

  /// Create an emotional tone.
  const EmotionalTone({
    required this.type,
    required this.id,
    required this.displayName,
    required this.description,
    required this.color,
    required this.icon,
    required this.culturalContext,
    required this.educationalContext,
    required this.minAgeAppropriate,
    this.maxAgeAppropriate = -1,
    required this.effectiveLearningStyles,
    required this.educationalEffectiveness,
    required this.pitch,
    required this.rate,
    required this.volume,
  });

  /// Create a copy of this tone with some fields replaced.
  EmotionalTone copyWith({
    EmotionalToneType? type,
    String? id,
    String? displayName,
    String? description,
    Color? color,
    IconData? icon,
    String? culturalContext,
    String? educationalContext,
    int? minAgeAppropriate,
    int? maxAgeAppropriate,
    List<String>? effectiveLearningStyles,
    double? educationalEffectiveness,
    double? pitch,
    double? rate,
    double? volume,
  }) {
    return EmotionalTone(
      type: type ?? this.type,
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      culturalContext: culturalContext ?? this.culturalContext,
      educationalContext: educationalContext ?? this.educationalContext,
      minAgeAppropriate: minAgeAppropriate ?? this.minAgeAppropriate,
      maxAgeAppropriate: maxAgeAppropriate ?? this.maxAgeAppropriate,
      effectiveLearningStyles: effectiveLearningStyles ?? this.effectiveLearningStyles,
      educationalEffectiveness: educationalEffectiveness ?? this.educationalEffectiveness,
      pitch: pitch ?? this.pitch,
      rate: rate ?? this.rate,
      volume: volume ?? this.volume,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'id': id,
      'displayName': displayName,
      'description': description,
      'color': color.toARGB32(), // Using non-deprecated method
      'icon': icon.codePoint,
      'culturalContext': culturalContext,
      'educationalContext': educationalContext,
      'minAgeAppropriate': minAgeAppropriate,
      'maxAgeAppropriate': maxAgeAppropriate,
      'effectiveLearningStyles': effectiveLearningStyles,
      'educationalEffectiveness': educationalEffectiveness,
      'pitch': pitch,
      'rate': rate,
      'volume': volume,
    };
  }

  /// Create an emotional tone from a map.
  factory EmotionalTone.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String;
    final type = EmotionalToneType.values.firstWhere(
      (t) => t.toString().split('.').last == typeStr,
      orElse: () => EmotionalToneType.neutral,
    );

    return EmotionalTone(
      type: type,
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      description: map['description'] as String,
      color: Color(map['color'] as int),
      icon: IconData(map['icon'] as int, fontFamily: 'MaterialIcons'),
      culturalContext: map['culturalContext'] as String,
      educationalContext: map['educationalContext'] as String,
      minAgeAppropriate: map['minAgeAppropriate'] as int,
      maxAgeAppropriate: map['maxAgeAppropriate'] as int,
      effectiveLearningStyles: List<String>.from(map['effectiveLearningStyles']),
      educationalEffectiveness: map['educationalEffectiveness'] as double,
      pitch: map['pitch'] as double,
      rate: map['rate'] as double,
      volume: map['volume'] as double,
    );
  }

  /// Get the default emotional tones.
  static List<EmotionalTone> getDefaultTones() {
    return [
      EmotionalTone(
        type: EmotionalToneType.neutral,
        id: 'neutral',
        displayName: 'Neutral',
        description: 'Standard narrative voice without strong emotion',
        color: Colors.grey,
        icon: Icons.sentiment_neutral,
        culturalContext: 'Used for objective storytelling across cultures',
        educationalContext: 'Effective for presenting factual information and basic instructions',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['visual', 'reading', 'analytical'],
        educationalEffectiveness: 0.7,
        pitch: 1.0,
        rate: 1.0,
        volume: 1.0,
      ),
      EmotionalTone(
        type: EmotionalToneType.happy,
        id: 'happy',
        displayName: 'Happy',
        description: 'Cheerful and positive tone',
        color: Colors.yellow,
        icon: Icons.sentiment_very_satisfied,
        culturalContext: 'Universal expression of joy and satisfaction',
        educationalContext: 'Reinforces positive learning experiences and celebrates achievements',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['visual', 'auditory', 'kinesthetic'],
        educationalEffectiveness: 0.8,
        pitch: 1.2,
        rate: 1.1,
        volume: 1.1,
      ),
      EmotionalTone(
        type: EmotionalToneType.excited,
        id: 'excited',
        displayName: 'Excited',
        description: 'Enthusiastic and energetic tone',
        color: Colors.orange,
        icon: Icons.celebration,
        culturalContext: 'Used to mark significant achievements and celebrations',
        educationalContext: 'Builds enthusiasm for new concepts and reinforces major achievements',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['auditory', 'kinesthetic', 'active'],
        educationalEffectiveness: 0.9,
        pitch: 1.3,
        rate: 1.2,
        volume: 1.2,
      ),
      EmotionalTone(
        type: EmotionalToneType.calm,
        id: 'calm',
        displayName: 'Calm',
        description: 'Soothing and reassuring tone',
        color: Colors.blue,
        icon: Icons.spa,
        culturalContext: 'Associated with wisdom and thoughtful reflection in many cultures',
        educationalContext: 'Helps create a focused learning environment and reduces anxiety',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['reflective', 'analytical', 'reading'],
        educationalEffectiveness: 0.8,
        pitch: 0.9,
        rate: 0.9,
        volume: 0.9,
      ),
      EmotionalTone(
        type: EmotionalToneType.encouraging,
        id: 'encouraging',
        displayName: 'Encouraging',
        description: 'Supportive and motivational tone',
        color: Colors.green,
        icon: Icons.thumb_up,
        culturalContext: 'Universal expression of support and mentorship',
        educationalContext: 'Builds confidence and motivates learners to persist through challenges',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['all'],
        educationalEffectiveness: 0.9,
        pitch: 1.1,
        rate: 1.0,
        volume: 1.1,
      ),
      EmotionalTone(
        type: EmotionalToneType.dramatic,
        id: 'dramatic',
        displayName: 'Dramatic',
        description: 'Intense and theatrical tone',
        color: Colors.purple,
        icon: Icons.theater_comedy,
        culturalContext: 'Used in storytelling traditions to mark climactic moments',
        educationalContext: 'Creates memorable learning moments and emphasizes key points',
        minAgeAppropriate: 9,
        effectiveLearningStyles: ['auditory', 'visual', 'active'],
        educationalEffectiveness: 0.7,
        pitch: 1.2,
        rate: 0.9,
        volume: 1.2,
      ),
      EmotionalTone(
        type: EmotionalToneType.curious,
        id: 'curious',
        displayName: 'Curious',
        description: 'Inquisitive and wondering tone',
        color: Colors.cyan,
        icon: Icons.help,
        culturalContext: 'Associated with learning and discovery across cultures',
        educationalContext: 'Stimulates critical thinking and encourages exploration',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['reflective', 'theoretical', 'analytical'],
        educationalEffectiveness: 0.8,
        pitch: 1.1,
        rate: 0.9,
        volume: 1.0,
      ),
      EmotionalTone(
        type: EmotionalToneType.concerned,
        id: 'concerned',
        displayName: 'Concerned',
        description: 'Worried and caring tone',
        color: Colors.amber,
        icon: Icons.sentiment_dissatisfied,
        culturalContext: 'Expression of empathy and care in challenging situations',
        educationalContext: 'Provides supportive feedback when learners are struggling',
        minAgeAppropriate: 8,
        effectiveLearningStyles: ['reflective', 'analytical'],
        educationalEffectiveness: 0.6,
        pitch: 0.9,
        rate: 0.8,
        volume: 0.9,
      ),
      EmotionalTone(
        type: EmotionalToneType.sad,
        id: 'sad',
        displayName: 'Sad',
        description: 'Melancholy and sorrowful tone',
        color: Colors.indigo,
        icon: Icons.sentiment_very_dissatisfied,
        culturalContext: 'Universal expression of disappointment or loss',
        educationalContext: 'Used sparingly to acknowledge setbacks and teach emotional resilience',
        minAgeAppropriate: 9,
        maxAgeAppropriate: 15,
        effectiveLearningStyles: ['reflective', 'analytical'],
        educationalEffectiveness: 0.5,
        pitch: 0.8,
        rate: 0.8,
        volume: 0.8,
      ),
      EmotionalTone(
        type: EmotionalToneType.proud,
        id: 'proud',
        displayName: 'Proud',
        description: 'Satisfied and accomplished tone',
        color: Colors.deepPurple,
        icon: Icons.military_tech,
        culturalContext: 'Associated with achievement and recognition across cultures',
        educationalContext: 'Reinforces learning achievements and builds self-efficacy',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['all'],
        educationalEffectiveness: 0.9,
        pitch: 1.1,
        rate: 1.0,
        volume: 1.1,
      ),
      EmotionalTone(
        type: EmotionalToneType.thoughtful,
        id: 'thoughtful',
        displayName: 'Thoughtful',
        description: 'Contemplative and reflective tone',
        color: Colors.teal,
        icon: Icons.psychology,
        culturalContext: 'Associated with wisdom and deep thinking in many traditions',
        educationalContext: 'Encourages metacognition and deeper processing of concepts',
        minAgeAppropriate: 9,
        effectiveLearningStyles: ['reflective', 'theoretical', 'analytical'],
        educationalEffectiveness: 0.8,
        pitch: 0.9,
        rate: 0.9,
        volume: 0.9,
      ),
      EmotionalTone(
        type: EmotionalToneType.wise,
        id: 'wise',
        displayName: 'Wise',
        description: 'Knowledgeable and sage-like tone',
        color: Colors.brown,
        icon: Icons.auto_stories,
        culturalContext: 'Represents elders and knowledge keepers in many traditions',
        educationalContext: 'Effective for imparting cultural knowledge and important concepts',
        minAgeAppropriate: 8,
        effectiveLearningStyles: ['reflective', 'theoretical', 'reading'],
        educationalEffectiveness: 0.9,
        pitch: 0.8,
        rate: 0.9,
        volume: 1.0,
      ),
      EmotionalTone(
        type: EmotionalToneType.mysterious,
        id: 'mysterious',
        displayName: 'Mysterious',
        description: 'Enigmatic and intriguing tone',
        color: Colors.deepPurple,
        icon: Icons.visibility_off,
        culturalContext: 'Used in storytelling to introduce new elements or create suspense',
        educationalContext: 'Creates curiosity and engagement when introducing new concepts',
        minAgeAppropriate: 8,
        effectiveLearningStyles: ['visual', 'auditory', 'active'],
        educationalEffectiveness: 0.7,
        pitch: 0.9,
        rate: 0.8,
        volume: 0.9,
      ),
      EmotionalTone(
        type: EmotionalToneType.playful,
        id: 'playful',
        displayName: 'Playful',
        description: 'Fun and lighthearted tone',
        color: Colors.pink,
        icon: Icons.toys,
        culturalContext: 'Universal expression of joy and play',
        educationalContext: 'Engages younger learners and makes learning fun',
        minAgeAppropriate: 7,
        maxAgeAppropriate: 12,
        effectiveLearningStyles: ['kinesthetic', 'active', 'pragmatic'],
        educationalEffectiveness: 0.8,
        pitch: 1.2,
        rate: 1.1,
        volume: 1.0,
      ),
      EmotionalTone(
        type: EmotionalToneType.serious,
        id: 'serious',
        displayName: 'Serious',
        description: 'Earnest and important tone',
        color: Colors.blueGrey,
        icon: Icons.priority_high,
        culturalContext: 'Used across cultures to mark important information',
        educationalContext: 'Signals important educational content that requires attention',
        minAgeAppropriate: 9,
        effectiveLearningStyles: ['analytical', 'theoretical', 'reading'],
        educationalEffectiveness: 0.7,
        pitch: 0.9,
        rate: 0.9,
        volume: 1.1,
      ),
      EmotionalTone(
        type: EmotionalToneType.surprised,
        id: 'surprised',
        displayName: 'Surprised',
        description: 'Astonished and unexpected tone',
        color: Colors.lime,
        icon: Icons.sentiment_very_satisfied, // Using a valid icon instead of sentiment_surprised
        culturalContext: 'Universal expression of unexpected discovery',
        educationalContext: 'Creates memorable moments when revealing unexpected information',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['visual', 'auditory', 'active'],
        educationalEffectiveness: 0.7,
        pitch: 1.3,
        rate: 1.0,
        volume: 1.1,
      ),
      EmotionalTone(
        type: EmotionalToneType.inspired,
        id: 'inspired',
        displayName: 'Inspired',
        description: 'Creative and motivated tone',
        color: Colors.lightBlue,
        icon: Icons.lightbulb,
        culturalContext: 'Associated with creativity and innovation across cultures',
        educationalContext: 'Encourages creative thinking and problem-solving',
        minAgeAppropriate: 8,
        effectiveLearningStyles: ['visual', 'kinesthetic', 'active'],
        educationalEffectiveness: 0.8,
        pitch: 1.1,
        rate: 1.0,
        volume: 1.0,
      ),
      EmotionalTone(
        type: EmotionalToneType.determined,
        id: 'determined',
        displayName: 'Determined',
        description: 'Resolute and persistent tone',
        color: Colors.red,
        icon: Icons.fitness_center,
        culturalContext: 'Valued across cultures for overcoming challenges',
        educationalContext: 'Encourages perseverance through difficult learning challenges',
        minAgeAppropriate: 8,
        effectiveLearningStyles: ['pragmatic', 'active', 'kinesthetic'],
        educationalEffectiveness: 0.8,
        pitch: 1.0,
        rate: 1.0,
        volume: 1.1,
      ),
      EmotionalTone(
        type: EmotionalToneType.reflective,
        id: 'reflective',
        displayName: 'Reflective',
        description: 'Thoughtful and introspective tone',
        color: Colors.blueGrey,
        icon: Icons.self_improvement,
        culturalContext: 'Associated with cultural significance and meaning-making',
        educationalContext: 'Encourages deeper processing and connection to personal experience',
        minAgeAppropriate: 9,
        effectiveLearningStyles: ['reflective', 'theoretical', 'reading'],
        educationalEffectiveness: 0.8,
        pitch: 0.9,
        rate: 0.8,
        volume: 0.9,
      ),
      EmotionalTone(
        type: EmotionalToneType.celebratory,
        id: 'celebratory',
        displayName: 'Celebratory',
        description: 'Festive and congratulatory tone',
        color: Colors.amber,
        icon: Icons.emoji_events,
        culturalContext: 'Used in celebrations and ceremonies across cultures',
        educationalContext: 'Marks major learning achievements and milestones',
        minAgeAppropriate: 7,
        effectiveLearningStyles: ['all'],
        educationalEffectiveness: 0.9,
        pitch: 1.3,
        rate: 1.2,
        volume: 1.2,
      ),
    ];
  }

  /// Get an emotional tone by type.
  static EmotionalTone getByType(EmotionalToneType type) {
    final tones = getDefaultTones();
    return tones.firstWhere(
      (tone) => tone.type == type,
      orElse: () => tones.first, // Default to neutral
    );
  }

  /// Get an emotional tone by ID.
  static EmotionalTone getById(String id) {
    final tones = getDefaultTones();
    return tones.firstWhere(
      (tone) => tone.id == id,
      orElse: () => tones.first, // Default to neutral
    );
  }

  /// Get tones appropriate for a given age.
  static List<EmotionalTone> getTonesForAge(int age) {
    final tones = getDefaultTones();
    return tones.where((tone) => tone.isAppropriateForAge(age)).toList();
  }

  /// Get tones effective for a given learning style.
  static List<EmotionalTone> getTonesForLearningStyle(String learningStyle) {
    final tones = getDefaultTones();
    return tones.where((tone) => tone.isEffectiveForLearningStyle(learningStyle)).toList();
  }

  /// Get a tone appropriate for a given educational context.
  static EmotionalTone getToneForEducationalContext(String educationalContext) {
    // No need to get all tones here, we'll use getByType directly
    final lowerContext = educationalContext.toLowerCase();

    // Check for specific educational contexts
    if (lowerContext.contains('achievement') ||
        lowerContext.contains('success') ||
        lowerContext.contains('milestone')) {
      return getByType(EmotionalToneType.celebratory);
    } else if (lowerContext.contains('challenge') ||
               lowerContext.contains('difficult') ||
               lowerContext.contains('persevere')) {
      return getByType(EmotionalToneType.determined);
    } else if (lowerContext.contains('creative') ||
               lowerContext.contains('innovation') ||
               lowerContext.contains('design')) {
      return getByType(EmotionalToneType.inspired);
    } else if (lowerContext.contains('reflect') ||
               lowerContext.contains('consider') ||
               lowerContext.contains('think about')) {
      return getByType(EmotionalToneType.reflective);
    } else if (lowerContext.contains('important') ||
               lowerContext.contains('critical') ||
               lowerContext.contains('essential')) {
      return getByType(EmotionalToneType.serious);
    } else if (lowerContext.contains('cultural') ||
               lowerContext.contains('tradition') ||
               lowerContext.contains('heritage')) {
      return getByType(EmotionalToneType.wise);
    } else if (lowerContext.contains('explore') ||
               lowerContext.contains('discover') ||
               lowerContext.contains('investigate')) {
      return getByType(EmotionalToneType.curious);
    } else if (lowerContext.contains('practice') ||
               lowerContext.contains('try again') ||
               lowerContext.contains('keep going')) {
      return getByType(EmotionalToneType.encouraging);
    } else if (lowerContext.contains('explain') ||
               lowerContext.contains('understand') ||
               lowerContext.contains('concept')) {
      return getByType(EmotionalToneType.calm);
    } else if (lowerContext.contains('fun') ||
               lowerContext.contains('game') ||
               lowerContext.contains('play')) {
      return getByType(EmotionalToneType.playful);
    }

    // Default to neutral for general educational contexts
    return getByType(EmotionalToneType.neutral);
  }

  /// Get a tone appropriate for a given educational objective.
  static EmotionalTone getToneForEducationalObjective(
    String objective,
    double conceptDifficulty,
    {Map<String, dynamic>? learnerProfile}
  ) {
    final lowerObjective = objective.toLowerCase();
    final age = learnerProfile?['age'] as int? ?? 10;
    final learningStyle = learnerProfile?['learningStyle'] as String? ?? 'visual';

    // Check for specific educational objectives
    if (lowerObjective.contains('introduce') ||
        lowerObjective.contains('present') ||
        lowerObjective.contains('new concept')) {
      // For introducing new concepts, use different tones based on difficulty
      if (conceptDifficulty > 0.7) {
        return getByType(EmotionalToneType.calm); // Calm for difficult concepts
      } else {
        return getByType(EmotionalToneType.curious); // Curious for easier concepts
      }
    } else if (lowerObjective.contains('practice') ||
               lowerObjective.contains('reinforce') ||
               lowerObjective.contains('strengthen')) {
      return getByType(EmotionalToneType.encouraging);
    } else if (lowerObjective.contains('assess') ||
               lowerObjective.contains('evaluate') ||
               lowerObjective.contains('test')) {
      return getByType(EmotionalToneType.neutral);
    } else if (lowerObjective.contains('celebrate') ||
               lowerObjective.contains('recognize') ||
               lowerObjective.contains('achievement')) {
      return getByType(EmotionalToneType.celebratory);
    } else if (lowerObjective.contains('reflect') ||
               lowerObjective.contains('connect') ||
               lowerObjective.contains('relate')) {
      return getByType(EmotionalToneType.reflective);
    } else if (lowerObjective.contains('challenge') ||
               lowerObjective.contains('extend') ||
               lowerObjective.contains('advanced')) {
      return getByType(EmotionalToneType.determined);
    } else if (lowerObjective.contains('create') ||
               lowerObjective.contains('design') ||
               lowerObjective.contains('invent')) {
      return getByType(EmotionalToneType.inspired);
    } else if (lowerObjective.contains('cultural') ||
               lowerObjective.contains('tradition') ||
               lowerObjective.contains('heritage')) {
      return getByType(EmotionalToneType.wise);
    }

    // If no specific match, use a tone appropriate for the learner's age and style
    final appropriateTones = getTonesForAge(age)
        .where((tone) => tone.isEffectiveForLearningStyle(learningStyle))
        .toList();

    if (appropriateTones.isNotEmpty) {
      // Sort by educational effectiveness
      appropriateTones.sort((a, b) =>
          b.educationalEffectiveness.compareTo(a.educationalEffectiveness));
      return appropriateTones.first;
    }

    // Default to neutral if no appropriate tone found
    return getByType(EmotionalToneType.neutral);
  }

  /// Check if this tone is appropriate for a given age.
  @override
  bool isAppropriateForAge(int age) {
    return age >= minAgeAppropriate &&
           (maxAgeAppropriate == -1 || age <= maxAgeAppropriate);
  }

  /// Check if this tone is effective for a given learning style.
  @override
  bool isEffectiveForLearningStyle(String learningStyle) {
    return effectiveLearningStyles.contains(learningStyle.toLowerCase()) ||
           effectiveLearningStyles.contains('all');
  }
}
