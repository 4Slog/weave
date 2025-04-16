import 'package:flutter/material.dart';
import 'emotional_tone_type.dart';
import 'emotional_tone.dart';

/// Legacy enum for backward compatibility with the original EmotionalTone.
/// 
/// This enum provides the same values as the original EmotionalTone enum
/// to ensure backward compatibility with existing code.
@Deprecated('Use EmotionalToneType instead')
enum LegacyEmotionalTone {
  neutral,
  happy,
  excited,
  calm,
  encouraging,
  dramatic,
  curious,
  concerned,
  sad,
  proud,
  thoughtful,
  wise,
  mysterious,
  playful,
  serious,
  surprised,
  inspired,
  determined,
  reflective,
  celebratory,
}

/// Extension methods for the legacy emotional tone enum.
@Deprecated('Use EmotionalTone class instead')
extension LegacyEmotionalToneExtension on LegacyEmotionalTone {
  /// Convert legacy enum to string.
  String get name {
    return toString().split('.').last;
  }
  
  /// Get display name for this tone.
  String get displayName {
    return _getEmotionalTone().displayName;
  }
  
  /// Get description for this tone.
  String get description {
    return _getEmotionalTone().description;
  }
  
  /// Get color for this tone.
  Color get color {
    return _getEmotionalTone().color;
  }
  
  /// Get icon for this tone.
  IconData get icon {
    return _getEmotionalTone().icon;
  }
  
  /// Get pitch modification for this tone.
  double get pitch {
    return _getEmotionalTone().pitch;
  }
  
  /// Get rate modification for this tone.
  double get rate {
    return _getEmotionalTone().rate;
  }
  
  /// Get volume for this tone.
  double get volume {
    return _getEmotionalTone().volume;
  }
  
  /// Convert legacy enum to new EmotionalToneType.
  EmotionalToneType toEmotionalToneType() {
    switch (this) {
      case LegacyEmotionalTone.neutral:
        return EmotionalToneType.neutral;
      case LegacyEmotionalTone.happy:
        return EmotionalToneType.happy;
      case LegacyEmotionalTone.excited:
        return EmotionalToneType.excited;
      case LegacyEmotionalTone.calm:
        return EmotionalToneType.calm;
      case LegacyEmotionalTone.encouraging:
        return EmotionalToneType.encouraging;
      case LegacyEmotionalTone.dramatic:
        return EmotionalToneType.dramatic;
      case LegacyEmotionalTone.curious:
        return EmotionalToneType.curious;
      case LegacyEmotionalTone.concerned:
        return EmotionalToneType.concerned;
      case LegacyEmotionalTone.sad:
        return EmotionalToneType.sad;
      case LegacyEmotionalTone.proud:
        return EmotionalToneType.proud;
      case LegacyEmotionalTone.thoughtful:
        return EmotionalToneType.thoughtful;
      case LegacyEmotionalTone.wise:
        return EmotionalToneType.wise;
      case LegacyEmotionalTone.mysterious:
        return EmotionalToneType.mysterious;
      case LegacyEmotionalTone.playful:
        return EmotionalToneType.playful;
      case LegacyEmotionalTone.serious:
        return EmotionalToneType.serious;
      case LegacyEmotionalTone.surprised:
        return EmotionalToneType.surprised;
      case LegacyEmotionalTone.inspired:
        return EmotionalToneType.inspired;
      case LegacyEmotionalTone.determined:
        return EmotionalToneType.determined;
      case LegacyEmotionalTone.reflective:
        return EmotionalToneType.reflective;
      case LegacyEmotionalTone.celebratory:
        return EmotionalToneType.celebratory;
    }
  }
  
  /// Get the corresponding EmotionalTone object.
  EmotionalTone _getEmotionalTone() {
    return EmotionalTone.getByType(toEmotionalToneType());
  }
}

/// Extension methods for the new EmotionalToneType enum.
extension EmotionalToneTypeExtension on EmotionalToneType {
  /// Convert new enum to legacy enum.
  LegacyEmotionalTone toLegacyEmotionalTone() {
    switch (this) {
      case EmotionalToneType.neutral:
        return LegacyEmotionalTone.neutral;
      case EmotionalToneType.happy:
        return LegacyEmotionalTone.happy;
      case EmotionalToneType.excited:
        return LegacyEmotionalTone.excited;
      case EmotionalToneType.calm:
        return LegacyEmotionalTone.calm;
      case EmotionalToneType.encouraging:
        return LegacyEmotionalTone.encouraging;
      case EmotionalToneType.dramatic:
        return LegacyEmotionalTone.dramatic;
      case EmotionalToneType.curious:
        return LegacyEmotionalTone.curious;
      case EmotionalToneType.concerned:
        return LegacyEmotionalTone.concerned;
      case EmotionalToneType.sad:
        return LegacyEmotionalTone.sad;
      case EmotionalToneType.proud:
        return LegacyEmotionalTone.proud;
      case EmotionalToneType.thoughtful:
        return LegacyEmotionalTone.thoughtful;
      case EmotionalToneType.wise:
        return LegacyEmotionalTone.wise;
      case EmotionalToneType.mysterious:
        return LegacyEmotionalTone.mysterious;
      case EmotionalToneType.playful:
        return LegacyEmotionalTone.playful;
      case EmotionalToneType.serious:
        return LegacyEmotionalTone.serious;
      case EmotionalToneType.surprised:
        return LegacyEmotionalTone.surprised;
      case EmotionalToneType.inspired:
        return LegacyEmotionalTone.inspired;
      case EmotionalToneType.determined:
        return LegacyEmotionalTone.determined;
      case EmotionalToneType.reflective:
        return LegacyEmotionalTone.reflective;
      case EmotionalToneType.celebratory:
        return LegacyEmotionalTone.celebratory;
    }
  }
}
