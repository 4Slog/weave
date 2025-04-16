import '../emotional_tone.dart' as legacy;
import 'emotional_tone_type.dart';
import 'emotional_tone.dart';
import 'tone_intensity.dart';
import 'tone_expression.dart';

/// Wrapper class for the original EmotionalTone enum.
///
/// This class provides methods to convert between the original EmotionalTone enum
/// and the new EmotionalTone class.
class EmotionalToneWrapper {
  /// Convert legacy enum to new EmotionalToneType.
  static EmotionalToneType legacyToType(legacy.EmotionalTone legacyTone) {
    switch (legacyTone) {
      case legacy.EmotionalTone.neutral:
        return EmotionalToneType.neutral;
      case legacy.EmotionalTone.happy:
        return EmotionalToneType.happy;
      case legacy.EmotionalTone.excited:
        return EmotionalToneType.excited;
      case legacy.EmotionalTone.calm:
        return EmotionalToneType.calm;
      case legacy.EmotionalTone.encouraging:
        return EmotionalToneType.encouraging;
      case legacy.EmotionalTone.dramatic:
        return EmotionalToneType.dramatic;
      case legacy.EmotionalTone.curious:
        return EmotionalToneType.curious;
      case legacy.EmotionalTone.concerned:
        return EmotionalToneType.concerned;
      case legacy.EmotionalTone.sad:
        return EmotionalToneType.sad;
      case legacy.EmotionalTone.proud:
        return EmotionalToneType.proud;
      case legacy.EmotionalTone.thoughtful:
        return EmotionalToneType.thoughtful;
      case legacy.EmotionalTone.wise:
        return EmotionalToneType.wise;
      case legacy.EmotionalTone.mysterious:
        return EmotionalToneType.mysterious;
      case legacy.EmotionalTone.playful:
        return EmotionalToneType.playful;
      case legacy.EmotionalTone.serious:
        return EmotionalToneType.serious;
      case legacy.EmotionalTone.surprised:
        return EmotionalToneType.surprised;
      case legacy.EmotionalTone.inspired:
        return EmotionalToneType.inspired;
      case legacy.EmotionalTone.determined:
        return EmotionalToneType.determined;
      case legacy.EmotionalTone.reflective:
        return EmotionalToneType.reflective;
      case legacy.EmotionalTone.celebratory:
        return EmotionalToneType.celebratory;
    }
  }

  /// Convert legacy enum to new EmotionalTone class.
  static EmotionalTone legacyToTone(legacy.EmotionalTone legacyTone) {
    return EmotionalTone.getByType(legacyToType(legacyTone));
  }

  /// Convert new EmotionalToneType to legacy enum.
  static legacy.EmotionalTone typeToLegacy(EmotionalToneType type) {
    switch (type) {
      case EmotionalToneType.neutral:
        return legacy.EmotionalTone.neutral;
      case EmotionalToneType.happy:
        return legacy.EmotionalTone.happy;
      case EmotionalToneType.excited:
        return legacy.EmotionalTone.excited;
      case EmotionalToneType.calm:
        return legacy.EmotionalTone.calm;
      case EmotionalToneType.encouraging:
        return legacy.EmotionalTone.encouraging;
      case EmotionalToneType.dramatic:
        return legacy.EmotionalTone.dramatic;
      case EmotionalToneType.curious:
        return legacy.EmotionalTone.curious;
      case EmotionalToneType.concerned:
        return legacy.EmotionalTone.concerned;
      case EmotionalToneType.sad:
        return legacy.EmotionalTone.sad;
      case EmotionalToneType.proud:
        return legacy.EmotionalTone.proud;
      case EmotionalToneType.thoughtful:
        return legacy.EmotionalTone.thoughtful;
      case EmotionalToneType.wise:
        return legacy.EmotionalTone.wise;
      case EmotionalToneType.mysterious:
        return legacy.EmotionalTone.mysterious;
      case EmotionalToneType.playful:
        return legacy.EmotionalTone.playful;
      case EmotionalToneType.serious:
        return legacy.EmotionalTone.serious;
      case EmotionalToneType.surprised:
        return legacy.EmotionalTone.surprised;
      case EmotionalToneType.inspired:
        return legacy.EmotionalTone.inspired;
      case EmotionalToneType.determined:
        return legacy.EmotionalTone.determined;
      case EmotionalToneType.reflective:
        return legacy.EmotionalTone.reflective;
      case EmotionalToneType.celebratory:
        return legacy.EmotionalTone.celebratory;
    }
  }

  /// Convert new EmotionalTone class to legacy enum.
  static legacy.EmotionalTone toneToLegacy(EmotionalTone tone) {
    return typeToLegacy(tone.type);
  }

  /// Create a ToneExpression from a legacy EmotionalTone.
  static ToneExpression<EmotionalTone> createExpressionFromLegacy(
    legacy.EmotionalTone legacyTone, {
    ToneIntensity intensity = ToneIntensity.moderate,
    String? educationalContext,
  }) {
    return ToneExpression<EmotionalTone>(
      tone: legacyToTone(legacyTone),
      intensity: intensity,
      educationalContext: educationalContext,
    );
  }
}
