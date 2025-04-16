/// Represents different learning styles for adaptive content delivery
enum LearningStyle {
  /// Visual learners prefer images, diagrams, and spatial understanding
  visual,

  /// Auditory learners prefer spoken explanations and discussions
  auditory,

  /// Reading/writing learners prefer text-based information
  reading,

  /// Kinesthetic learners prefer hands-on activities and examples
  kinesthetic,

  /// Logical learners prefer reasoning and systems thinking
  logical,

  /// Social learners prefer group learning and discussion
  social,

  /// Solitary learners prefer self-study and independent thinking
  solitary,

  /// Practical learners prefer real-world applications
  practical,

  /// Verbal learners prefer words, both written and spoken
  verbal,

  /// Reflective learners prefer thinking things through
  reflective,
}

/// Extension methods for LearningStyle
extension LearningStyleExtension on LearningStyle {
  /// Get a human-readable name for this learning style
  String get displayName {
    switch (this) {
      case LearningStyle.visual:
        return 'Visual';
      case LearningStyle.auditory:
        return 'Auditory';
      case LearningStyle.reading:
        return 'Reading/Writing';
      case LearningStyle.kinesthetic:
        return 'Kinesthetic';
      case LearningStyle.logical:
        return 'Logical';
      case LearningStyle.social:
        return 'Social';
      case LearningStyle.solitary:
        return 'Solitary';
      case LearningStyle.practical:
        return 'Practical';
      case LearningStyle.verbal:
        return 'Verbal';
      case LearningStyle.reflective:
        return 'Reflective';
      default:
        return 'Unknown';
    }
  }

  /// Get a description of this learning style
  String get description {
    switch (this) {
      case LearningStyle.visual:
        return 'Learns best through images, diagrams, and spatial understanding';
      case LearningStyle.auditory:
        return 'Learns best through spoken explanations and discussions';
      case LearningStyle.reading:
        return 'Learns best through text-based information and writing';
      case LearningStyle.kinesthetic:
        return 'Learns best through hands-on activities and examples';
      case LearningStyle.logical:
        return 'Learns best through reasoning and systems thinking';
      case LearningStyle.social:
        return 'Learns best through group learning and discussion';
      case LearningStyle.solitary:
        return 'Learns best through self-study and independent thinking';
      case LearningStyle.practical:
        return 'Learns best through real-world applications and examples';
      case LearningStyle.verbal:
        return 'Learns best through words, both written and spoken';
      case LearningStyle.reflective:
        return 'Learns best through thinking things through and reflection';
      default:
        return 'Unknown learning style';
    }
  }

  /// Get recommended content types for this learning style
  List<String> get recommendedContentTypes {
    switch (this) {
      case LearningStyle.visual:
        return ['diagrams', 'charts', 'videos', 'animations', 'color-coding'];
      case LearningStyle.auditory:
        return ['spoken explanations', 'discussions', 'audio recordings', 'verbal analogies'];
      case LearningStyle.reading:
        return ['written explanations', 'articles', 'lists', 'definitions', 'notes'];
      case LearningStyle.kinesthetic:
        return ['hands-on activities', 'examples', 'simulations', 'role-playing'];
      case LearningStyle.logical:
        return ['systems diagrams', 'flowcharts', 'statistics', 'logical reasoning'];
      case LearningStyle.social:
        return ['group discussions', 'peer teaching', 'collaborative projects'];
      case LearningStyle.solitary:
        return ['self-paced tutorials', 'independent projects', 'reflection exercises'];
      case LearningStyle.practical:
        return ['real-world examples', 'case studies', 'practical applications', 'problem-solving'];
      case LearningStyle.verbal:
        return ['written text', 'spoken explanations', 'discussions', 'word-based activities'];
      case LearningStyle.reflective:
        return ['thought experiments', 'reflection exercises', 'analysis tasks', 'journals'];
      default:
        return ['mixed content'];
    }
  }

  /// Get recommended teaching approaches for this learning style
  List<String> get recommendedApproaches {
    switch (this) {
      case LearningStyle.visual:
        return ['Use diagrams and visual metaphors', 'Show examples', 'Use color-coding'];
      case LearningStyle.auditory:
        return ['Explain verbally', 'Use discussions', 'Incorporate sound cues'];
      case LearningStyle.reading:
        return ['Provide written explanations', 'Use text-based examples', 'Encourage note-taking'];
      case LearningStyle.kinesthetic:
        return ['Use hands-on activities', 'Incorporate physical movement', 'Build working models'];
      case LearningStyle.logical:
        return ['Explain the reasoning', 'Show systems and patterns', 'Use step-by-step approaches'];
      case LearningStyle.social:
        return ['Encourage group work', 'Facilitate discussions', 'Use peer teaching'];
      case LearningStyle.solitary:
        return ['Provide self-paced materials', 'Allow independent exploration', 'Offer reflection time'];
      case LearningStyle.practical:
        return ['Provide real-world examples', 'Show practical applications', 'Use case studies'];
      case LearningStyle.verbal:
        return ['Use word-based activities', 'Encourage discussions', 'Provide written materials'];
      case LearningStyle.reflective:
        return ['Allow time for reflection', 'Ask thought-provoking questions', 'Encourage analysis'];
      default:
        return ['Use mixed approaches'];
    }
  }

  /// Get the primary VARK category for this learning style
  String get varkCategory {
    switch (this) {
      case LearningStyle.visual:
        return 'V';
      case LearningStyle.auditory:
        return 'A';
      case LearningStyle.reading:
        return 'R';
      case LearningStyle.kinesthetic:
        return 'K';
      case LearningStyle.verbal:
        return 'A/R';
      case LearningStyle.practical:
        return 'K';
      case LearningStyle.reflective:
        return 'R';
      default:
        return 'Mixed';
    }
  }

  /// Get the compatibility score with another learning style (0.0-1.0)
  double compatibilityWith(LearningStyle other) {
    // Define compatibility matrix
    const Map<LearningStyle, Map<LearningStyle, double>> compatibilityMatrix = {
      LearningStyle.visual: {
        LearningStyle.visual: 1.0,
        LearningStyle.auditory: 0.5,
        LearningStyle.reading: 0.7,
        LearningStyle.kinesthetic: 0.6,
        LearningStyle.logical: 0.8,
        LearningStyle.social: 0.5,
        LearningStyle.solitary: 0.7,
      },
      LearningStyle.auditory: {
        LearningStyle.visual: 0.5,
        LearningStyle.auditory: 1.0,
        LearningStyle.reading: 0.6,
        LearningStyle.kinesthetic: 0.5,
        LearningStyle.logical: 0.6,
        LearningStyle.social: 0.9,
        LearningStyle.solitary: 0.4,
      },
      LearningStyle.reading: {
        LearningStyle.visual: 0.7,
        LearningStyle.auditory: 0.6,
        LearningStyle.reading: 1.0,
        LearningStyle.kinesthetic: 0.4,
        LearningStyle.logical: 0.8,
        LearningStyle.social: 0.5,
        LearningStyle.solitary: 0.8,
      },
      LearningStyle.kinesthetic: {
        LearningStyle.visual: 0.6,
        LearningStyle.auditory: 0.5,
        LearningStyle.reading: 0.4,
        LearningStyle.kinesthetic: 1.0,
        LearningStyle.logical: 0.6,
        LearningStyle.social: 0.7,
        LearningStyle.solitary: 0.5,
      },
      LearningStyle.logical: {
        LearningStyle.visual: 0.8,
        LearningStyle.auditory: 0.6,
        LearningStyle.reading: 0.8,
        LearningStyle.kinesthetic: 0.6,
        LearningStyle.logical: 1.0,
        LearningStyle.social: 0.5,
        LearningStyle.solitary: 0.7,
      },
      LearningStyle.social: {
        LearningStyle.visual: 0.5,
        LearningStyle.auditory: 0.9,
        LearningStyle.reading: 0.5,
        LearningStyle.kinesthetic: 0.7,
        LearningStyle.logical: 0.5,
        LearningStyle.social: 1.0,
        LearningStyle.solitary: 0.2,
      },
      LearningStyle.solitary: {
        LearningStyle.visual: 0.7,
        LearningStyle.auditory: 0.4,
        LearningStyle.reading: 0.8,
        LearningStyle.kinesthetic: 0.5,
        LearningStyle.logical: 0.7,
        LearningStyle.social: 0.2,
        LearningStyle.solitary: 1.0,
      },
    };

    return compatibilityMatrix[this]?[other] ?? 0.5;
  }

  /// Get learning style from string
  static LearningStyle fromString(String value) {
    switch (value.toLowerCase()) {
      case 'visual':
        return LearningStyle.visual;
      case 'auditory':
        return LearningStyle.auditory;
      case 'reading':
      case 'reading/writing':
      case 'read/write':
        return LearningStyle.reading;
      case 'kinesthetic':
        return LearningStyle.kinesthetic;
      case 'logical':
        return LearningStyle.logical;
      case 'social':
        return LearningStyle.social;
      case 'solitary':
        return LearningStyle.solitary;
      case 'practical':
        return LearningStyle.practical;
      case 'verbal':
        return LearningStyle.verbal;
      case 'reflective':
        return LearningStyle.reflective;
      default:
        return LearningStyle.visual; // Default to visual
    }
  }
}
