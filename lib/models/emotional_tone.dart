import 'package:flutter/material.dart';

/// Defines emotional tones for TTS and story narration
enum EmotionalTone {
  /// Neutral tone - standard narrative voice
  neutral,
  
  /// Happy tone - for positive outcomes and success
  happy,
  
  /// Excited tone - for achievements and successes
  excited,
  
  /// Calm tone - for explanations and guidance
  calm,
  
  /// Encouraging tone - for hints and motivation
  encouraging,
  
  /// Dramatic tone - for story climax points
  dramatic,
  
  /// Curious tone - for asking questions
  curious,
  
  /// Concerned tone - when user is struggling
  concerned,
  
  /// Sad tone - for disappointing outcomes
  sad,
  
  /// Proud tone - for celebrating user achievements
  proud,
  
  /// Thoughtful tone - for contemplative moments
  thoughtful,
  
  /// Wise tone - for imparting cultural knowledge
  wise,
  
  /// Mysterious tone - for introducing new cultural elements
  mysterious,
  
  /// Playful tone - for engaging younger users
  playful,
  
  /// Serious tone - for important educational content
  serious,
  
  /// Surprised tone - for unexpected outcomes
  surprised,
  
  /// Inspired tone - for creative moments
  inspired,
  
  /// Determined tone - for perseverance and challenge
  determined,
  
  /// Reflective tone - for cultural significance discussions
  reflective,
  
  /// Celebratory tone - for major achievements
  celebratory,
}

/// Represents the intensity level of an emotional tone
enum ToneIntensity {
  /// Subtle emotional cues
  mild,
  
  /// Moderate emotional expression
  moderate,
  
  /// Strong emotional expression
  strong,
  
  /// Very pronounced emotional expression
  intense,
}

/// Extension methods for emotional tones
extension EmotionalToneExtension on EmotionalTone {
  /// Get the pitch modification for this emotional tone
  double get pitch {
    switch (this) {
      case EmotionalTone.neutral:
        return 1.0;
      case EmotionalTone.happy:
        return 1.2;
      case EmotionalTone.excited:
        return 1.3;
      case EmotionalTone.calm:
        return 0.9;
      case EmotionalTone.encouraging:
        return 1.1;
      case EmotionalTone.dramatic:
        return 1.2;
      case EmotionalTone.curious:
        return 1.05;
      case EmotionalTone.concerned:
        return 0.95;
      case EmotionalTone.sad:
        return 0.85;
      case EmotionalTone.proud:
        return 1.15;
      case EmotionalTone.thoughtful:
        return 0.98;
      case EmotionalTone.wise:
        return 0.9;
      case EmotionalTone.mysterious:
        return 0.88;
      case EmotionalTone.playful:
        return 1.25;
      case EmotionalTone.serious:
        return 0.92;
      case EmotionalTone.surprised:
        return 1.35;
      case EmotionalTone.inspired:
        return 1.18;
      case EmotionalTone.determined:
        return 1.05;
      case EmotionalTone.reflective:
        return 0.95;
      case EmotionalTone.celebratory:
        return 1.28;
    }
  }
  
  /// Get the rate modification for this emotional tone
  double get rate {
    switch (this) {
      case EmotionalTone.neutral:
        return 0.5;
      case EmotionalTone.happy:
        return 0.55;
      case EmotionalTone.excited:
        return 0.6;
      case EmotionalTone.calm:
        return 0.4;
      case EmotionalTone.encouraging:
        return 0.5;
      case EmotionalTone.dramatic:
        return 0.45;
      case EmotionalTone.curious:
        return 0.5;
      case EmotionalTone.concerned:
        return 0.45;
      case EmotionalTone.sad:
        return 0.4;
      case EmotionalTone.proud:
        return 0.55;
      case EmotionalTone.thoughtful:
        return 0.42;
      case EmotionalTone.wise:
        return 0.38;
      case EmotionalTone.mysterious:
        return 0.4;
      case EmotionalTone.playful:
        return 0.58;
      case EmotionalTone.serious:
        return 0.45;
      case EmotionalTone.surprised:
        return 0.52;
      case EmotionalTone.inspired:
        return 0.48;
      case EmotionalTone.determined:
        return 0.52;
      case EmotionalTone.reflective:
        return 0.4;
      case EmotionalTone.celebratory:
        return 0.6;
    }
  }
  
  /// Get the volume for this emotional tone
  double get volume {
    switch (this) {
      case EmotionalTone.neutral:
        return 1.0;
      case EmotionalTone.happy:
        return 1.0;
      case EmotionalTone.excited:
        return 1.0;
      case EmotionalTone.calm:
        return 0.8;
      case EmotionalTone.encouraging:
        return 0.9;
      case EmotionalTone.dramatic:
        return 1.0;
      case EmotionalTone.curious:
        return 0.9;
      case EmotionalTone.concerned:
        return 0.85;
      case EmotionalTone.sad:
        return 0.8;
      case EmotionalTone.proud:
        return 1.0;
      case EmotionalTone.thoughtful:
        return 0.9;
      case EmotionalTone.wise:
        return 0.95;
      case EmotionalTone.mysterious:
        return 0.85;
      case EmotionalTone.playful:
        return 0.95;
      case EmotionalTone.serious:
        return 0.9;
      case EmotionalTone.surprised:
        return 1.0;
      case EmotionalTone.inspired:
        return 0.95;
      case EmotionalTone.determined:
        return 1.0;
      case EmotionalTone.reflective:
        return 0.85;
      case EmotionalTone.celebratory:
        return 1.0;
    }
  }
  
  /// Get display name for this emotional tone
  String get displayName {
    switch (this) {
      case EmotionalTone.neutral:
        return 'Neutral';
      case EmotionalTone.happy:
        return 'Happy';
      case EmotionalTone.excited:
        return 'Excited';
      case EmotionalTone.calm:
        return 'Calm';
      case EmotionalTone.encouraging:
        return 'Encouraging';
      case EmotionalTone.dramatic:
        return 'Dramatic';
      case EmotionalTone.curious:
        return 'Curious';
      case EmotionalTone.concerned:
        return 'Concerned';
      case EmotionalTone.sad:
        return 'Sad';
      case EmotionalTone.proud:
        return 'Proud';
      case EmotionalTone.thoughtful:
        return 'Thoughtful';
      case EmotionalTone.wise:
        return 'Wise';
      case EmotionalTone.mysterious:
        return 'Mysterious';
      case EmotionalTone.playful:
        return 'Playful';
      case EmotionalTone.serious:
        return 'Serious';
      case EmotionalTone.surprised:
        return 'Surprised';
      case EmotionalTone.inspired:
        return 'Inspired';
      case EmotionalTone.determined:
        return 'Determined';
      case EmotionalTone.reflective:
        return 'Reflective';
      case EmotionalTone.celebratory:
        return 'Celebratory';
    }
  }
  
  /// Get the color associated with this emotional tone
  Color get color {
    switch (this) {
      case EmotionalTone.neutral:
        return Colors.grey;
      case EmotionalTone.happy:
        return Colors.yellow;
      case EmotionalTone.excited:
        return Colors.orange;
      case EmotionalTone.calm:
        return Colors.lightBlue;
      case EmotionalTone.encouraging:
        return Colors.green;
      case EmotionalTone.dramatic:
        return Colors.deepPurple;
      case EmotionalTone.curious:
        return Colors.cyan;
      case EmotionalTone.concerned:
        return Colors.amber;
      case EmotionalTone.sad:
        return Colors.blueGrey;
      case EmotionalTone.proud:
        return Colors.indigo;
      case EmotionalTone.thoughtful:
        return Colors.teal;
      case EmotionalTone.wise:
        return Colors.brown;
      case EmotionalTone.mysterious:
        return Colors.deepPurple.shade900;
      case EmotionalTone.playful:
        return Colors.pink;
      case EmotionalTone.serious:
        return Colors.grey.shade800;
      case EmotionalTone.surprised:
        return Colors.lime;
      case EmotionalTone.inspired:
        return Colors.lightGreen;
      case EmotionalTone.determined:
        return Colors.red;
      case EmotionalTone.reflective:
        return Colors.blue.shade300;
      case EmotionalTone.celebratory:
        return Colors.amber.shade600;
    }
  }
  
  /// Get the icon associated with this emotional tone
  IconData get icon {
    switch (this) {
      case EmotionalTone.neutral:
        return Icons.sentiment_neutral;
      case EmotionalTone.happy:
        return Icons.sentiment_very_satisfied;
      case EmotionalTone.excited:
        return Icons.celebration;
      case EmotionalTone.calm:
        return Icons.spa;
      case EmotionalTone.encouraging:
        return Icons.thumb_up;
      case EmotionalTone.dramatic:
        return Icons.theater_comedy;
      case EmotionalTone.curious:
        return Icons.psychology;
      case EmotionalTone.concerned:
        return Icons.sentiment_dissatisfied;
      case EmotionalTone.sad:
        return Icons.sentiment_very_dissatisfied;
      case EmotionalTone.proud:
        return Icons.emoji_events;
      case EmotionalTone.thoughtful:
        return Icons.lightbulb;
      case EmotionalTone.wise:
        return Icons.auto_stories;
      case EmotionalTone.mysterious:
        return Icons.visibility_off;
      case EmotionalTone.playful:
        return Icons.toys;
      case EmotionalTone.serious:
        return Icons.warning;
      case EmotionalTone.surprised:
        return Icons.emoji_emotions;
      case EmotionalTone.inspired:
        return Icons.wb_incandescent;
      case EmotionalTone.determined:
        return Icons.fitness_center;
      case EmotionalTone.reflective:
        return Icons.hourglass_bottom;
      case EmotionalTone.celebratory:
        return Icons.cake;
    }
  }
  
  /// Get a description of this emotional tone
  String get description {
    switch (this) {
      case EmotionalTone.neutral:
        return 'A balanced tone without strong emotion, used for general narration.';
      case EmotionalTone.happy:
        return 'A joyful tone expressing pleasure and contentment.';
      case EmotionalTone.excited:
        return 'An energetic tone full of enthusiasm and anticipation.';
      case EmotionalTone.calm:
        return 'A peaceful tone that conveys tranquility and serenity.';
      case EmotionalTone.encouraging:
        return 'A supportive tone that motivates and inspires confidence.';
      case EmotionalTone.dramatic:
        return 'An intense tone that emphasizes important moments.';
      case EmotionalTone.curious:
        return 'An inquisitive tone that expresses wonder and interest.';
      case EmotionalTone.concerned:
        return 'A worried tone that shows care and attention to problems.';
      case EmotionalTone.sad:
        return 'A sorrowful tone expressing disappointment or grief.';
      case EmotionalTone.proud:
        return 'A satisfied tone that celebrates achievements and success.';
      case EmotionalTone.thoughtful:
        return 'A contemplative tone that suggests deep thinking.';
      case EmotionalTone.wise:
        return 'A knowledgeable tone that conveys experience and insight.';
      case EmotionalTone.mysterious:
        return 'An enigmatic tone that creates intrigue and suspense.';
      case EmotionalTone.playful:
        return 'A lighthearted tone full of fun and amusement.';
      case EmotionalTone.serious:
        return 'A grave tone that emphasizes importance and gravity.';
      case EmotionalTone.surprised:
        return 'An astonished tone expressing unexpected discoveries.';
      case EmotionalTone.inspired:
        return 'A creative tone full of new ideas and possibilities.';
      case EmotionalTone.determined:
        return 'A resolute tone showing commitment and perseverance.';
      case EmotionalTone.reflective:
        return 'A meditative tone that considers past experiences.';
      case EmotionalTone.celebratory:
        return 'A festive tone that marks special achievements and milestones.';
    }
  }
  
  /// Get the cultural significance of this emotional tone in Ghanaian context
  String get culturalContext {
    switch (this) {
      case EmotionalTone.neutral:
        return 'Represents balance and harmony in traditional storytelling.';
      case EmotionalTone.happy:
        return 'Connected to community celebrations and harvest festivals.';
      case EmotionalTone.excited:
        return 'Associated with drumming ceremonies and dance celebrations.';
      case EmotionalTone.calm:
        return 'Reflects the peaceful resolution in traditional conflict mediation.';
      case EmotionalTone.encouraging:
        return 'Embodies the supportive nature of extended family structures.';
      case EmotionalTone.dramatic:
        return 'Used in traditional performances to emphasize moral lessons.';
      case EmotionalTone.curious:
        return 'Represents the quest for knowledge in coming-of-age ceremonies.';
      case EmotionalTone.concerned:
        return 'Reflects community care and responsibility for all members.';
      case EmotionalTone.sad:
        return 'Expressed in funeral dirges and remembrance ceremonies.';
      case EmotionalTone.proud:
        return 'Connected to ancestral heritage and cultural identity.';
      case EmotionalTone.thoughtful:
        return 'Embodied in the wisdom of elders and council deliberations.';
      case EmotionalTone.wise:
        return 'Represents the respected voice of elders sharing cultural knowledge.';
      case EmotionalTone.mysterious:
        return 'Connected to traditional spiritual practices and folklore.';
      case EmotionalTone.playful:
        return 'Seen in children\'s games and community entertainment.';
      case EmotionalTone.serious:
        return 'Used when discussing important community matters and traditions.';
      case EmotionalTone.surprised:
        return 'Expressed during unexpected revelations in storytelling.';
      case EmotionalTone.inspired:
        return 'Associated with artistic creation and cultural innovation.';
      case EmotionalTone.determined:
        return 'Reflects the perseverance shown in traditional rites of passage.';
      case EmotionalTone.reflective:
        return 'Embodied in the oral history tradition and ancestral remembrance.';
      case EmotionalTone.celebratory:
        return 'Central to naming ceremonies, weddings, and cultural festivals.';
    }
  }
  
  /// Get appropriate tone for a given age group
  static List<EmotionalTone> getTonesForAgeGroup(int age) {
    if (age <= 8) {
      // Younger children - simpler, more expressive tones
      return [
        EmotionalTone.happy,
        EmotionalTone.excited,
        EmotionalTone.calm,
        EmotionalTone.encouraging,
        EmotionalTone.curious,
        EmotionalTone.playful,
        EmotionalTone.surprised,
      ];
    } else if (age <= 11) {
      // Middle age group - adding more nuanced tones
      return [
        EmotionalTone.happy,
        EmotionalTone.excited,
        EmotionalTone.calm,
        EmotionalTone.encouraging,
        EmotionalTone.curious,
        EmotionalTone.proud,
        EmotionalTone.thoughtful,
        EmotionalTone.playful,
        EmotionalTone.surprised,
        EmotionalTone.inspired,
        EmotionalTone.determined,
      ];
    } else {
      // Older children - full range of emotional tones
      return EmotionalTone.values;
    }
  }
  
  /// Get appropriate tone for a narrative context
  static EmotionalTone getToneForContext(String context) {
    final lowerContext = context.toLowerCase();
    
    if (lowerContext.contains('success') || lowerContext.contains('achievement')) {
      return EmotionalTone.proud;
    } else if (lowerContext.contains('challenge') || lowerContext.contains('difficult')) {
      return EmotionalTone.determined;
    } else if (lowerContext.contains('cultural') || lowerContext.contains('tradition')) {
      return EmotionalTone.wise;
    } else if (lowerContext.contains('question') || lowerContext.contains('wonder')) {
      return EmotionalTone.curious;
    } else if (lowerContext.contains('sad') || lowerContext.contains('disappoint')) {
      return EmotionalTone.sad;
    } else if (lowerContext.contains('happy') || lowerContext.contains('joy')) {
      return EmotionalTone.happy;
    } else if (lowerContext.contains('explain') || lowerContext.contains('learn')) {
      return EmotionalTone.thoughtful;
    } else if (lowerContext.contains('celebrate') || lowerContext.contains('festival')) {
      return EmotionalTone.celebratory;
    } else if (lowerContext.contains('mystery') || lowerContext.contains('secret')) {
      return EmotionalTone.mysterious;
    } else if (lowerContext.contains('reflect') || lowerContext.contains('remember')) {
      return EmotionalTone.reflective;
    } else {
      return EmotionalTone.neutral;
    }
  }
}

/// Extension methods for tone intensity
extension ToneIntensityExtension on ToneIntensity {
  /// Get a multiplier for tone parameters based on intensity
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
  
  /// Get display name for this intensity level
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
}

/// Class to represent a complete emotional expression with tone and intensity
class EmotionalExpression {
  /// The emotional tone
  final EmotionalTone tone;
  
  /// The intensity of the emotion
  final ToneIntensity intensity;
  
  /// Create an emotional expression
  const EmotionalExpression({
    required this.tone,
    this.intensity = ToneIntensity.moderate,
  });
  
  /// Get the adjusted pitch for this expression
  double get pitch {
    final basePitch = tone.pitch;
    final intensityEffect = (basePitch > 1.0) 
        ? (basePitch - 1.0) * intensity.multiplier + 1.0
        : 1.0 - (1.0 - basePitch) * intensity.multiplier;
    return intensityEffect;
  }
  
  /// Get the adjusted rate for this expression
  double get rate {
    final baseRate = tone.rate;
    final intensityEffect = (baseRate > 0.5) 
        ? (baseRate - 0.5) * intensity.multiplier + 0.5
        : 0.5 - (0.5 - baseRate) * intensity.multiplier;
    return intensityEffect;
  }
  
  /// Get the adjusted volume for this expression
  double get volume {
    return tone.volume * (0.8 + (intensity.multiplier * 0.2));
  }
  
  /// Create an emotional expression from a string description
  factory EmotionalExpression.fromString(String description) {
    final parts = description.toLowerCase().split(' ');
    
    // Default values
    EmotionalTone tone = EmotionalTone.neutral;
    ToneIntensity intensity = ToneIntensity.moderate;
    
    // Try to parse tone
    for (final value in EmotionalTone.values) {
      if (parts.contains(value.toString().split('.').last)) {
        tone = value;
        break;
      }
    }
    
    // Try to parse intensity
    for (final value in ToneIntensity.values) {
      if (parts.contains(value.toString().split('.').last)) {
        intensity = value;
        break;
      }
    }
    
    return EmotionalExpression(tone: tone, intensity: intensity);
  }
  
  /// Get a string representation of this expression
  @override
  String toString() {
    return '${intensity.displayName} ${tone.displayName}';
  }
}
