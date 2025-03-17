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
    }
  }
}