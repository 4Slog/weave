import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/tts_settings.dart';

/// Represents a block of content to be spoken by the TTS service
class ContentBlock {
  /// The text to be spoken
  final String text;

  /// The emotional tone to apply (optional)
  final EmotionalTone? emotionalTone;

  /// The intensity of the emotional tone (optional)
  final ToneIntensity? toneIntensity;

  /// The storytelling style to apply (optional)
  final StorytellingStyle? storytellingStyle;

  /// The voice gender to use (optional)
  final VoiceGender? voiceGender;

  /// Whether to use cultural pronunciation (optional)
  final bool? useCulturalPronunciation;

  /// The delay before speaking this block in milliseconds (optional)
  final int? delayBeforeMs;

  /// The delay after speaking this block in milliseconds (optional)
  final int? delayAfterMs;

  /// The ID of this content block (optional)
  final String? id;

  /// Additional metadata for this content block (optional)
  final Map<String, dynamic>? metadata;

  /// Creates a new content block with the given properties
  ContentBlock({
    required this.text,
    this.emotionalTone,
    this.toneIntensity,
    this.storytellingStyle,
    this.voiceGender,
    this.useCulturalPronunciation,
    this.delayBeforeMs,
    this.delayAfterMs,
    this.id,
    this.metadata,
  });

  /// Creates a copy of this content block with the given fields replaced
  ContentBlock copyWith({
    String? text,
    EmotionalTone? emotionalTone,
    ToneIntensity? toneIntensity,
    StorytellingStyle? storytellingStyle,
    VoiceGender? voiceGender,
    bool? useCulturalPronunciation,
    int? delayBeforeMs,
    int? delayAfterMs,
    String? id,
    Map<String, dynamic>? metadata,
  }) {
    return ContentBlock(
      text: text ?? this.text,
      emotionalTone: emotionalTone ?? this.emotionalTone,
      toneIntensity: toneIntensity ?? this.toneIntensity,
      storytellingStyle: storytellingStyle ?? this.storytellingStyle,
      voiceGender: voiceGender ?? this.voiceGender,
      useCulturalPronunciation: useCulturalPronunciation ?? this.useCulturalPronunciation,
      delayBeforeMs: delayBeforeMs ?? this.delayBeforeMs,
      delayAfterMs: delayAfterMs ?? this.delayAfterMs,
      id: id ?? this.id,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a content block from a map
  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    return ContentBlock(
      text: map['text'] as String,
      emotionalTone: map['emotionalTone'] != null
          ? EmotionalToneExtension.fromString(map['emotionalTone'])
          : null,
      toneIntensity: map['toneIntensity'] != null
          ? ToneIntensityExtension.fromString(map['toneIntensity'])
          : null,
      storytellingStyle: map['storytellingStyle'] != null
          ? StorytellingStyleExtension.fromString(map['storytellingStyle'])
          : null,
      voiceGender: map['voiceGender'] != null
          ? _parseVoiceGender(map['voiceGender'])
          : null,
      useCulturalPronunciation: map['useCulturalPronunciation'] as bool?,
      delayBeforeMs: map['delayBeforeMs'] as int?,
      delayAfterMs: map['delayAfterMs'] as int?,
      id: map['id'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  /// Converts this content block to a map
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'emotionalTone': emotionalTone?.toString().split('.').last,
      'toneIntensity': toneIntensity?.toString().split('.').last,
      'storytellingStyle': storytellingStyle?.toString().split('.').last,
      'voiceGender': voiceGender?.toString().split('.').last,
      'useCulturalPronunciation': useCulturalPronunciation,
      'delayBeforeMs': delayBeforeMs,
      'delayAfterMs': delayAfterMs,
      'id': id,
      'metadata': metadata,
    };
  }

  /// Helper method to parse voice gender from string
  static VoiceGender? _parseVoiceGender(String genderStr) {
    try {
      return VoiceGender.values.firstWhere(
        (gender) => gender.toString().split('.').last == genderStr,
        orElse: () => VoiceGender.female,
      );
    } catch (_) {
      return VoiceGender.female;
    }
  }

  @override
  String toString() => 'ContentBlock(text: $text, emotionalTone: $emotionalTone)';
}

/// Extension methods for EmotionalTone
extension EmotionalToneExtension on EmotionalTone {
  /// Create an EmotionalTone from a string
  static EmotionalTone fromString(String toneStr) {
    try {
      return EmotionalTone.values.firstWhere(
        (tone) => tone.toString().split('.').last == toneStr,
        orElse: () => EmotionalTone.neutral,
      );
    } catch (_) {
      return EmotionalTone.neutral;
    }
  }
}

/// Extension methods for ToneIntensity
extension ToneIntensityExtension on ToneIntensity {
  /// Create a ToneIntensity from a string
  static ToneIntensity fromString(String intensityStr) {
    try {
      return ToneIntensity.values.firstWhere(
        (intensity) => intensity.toString().split('.').last == intensityStr,
        orElse: () => ToneIntensity.moderate,
      );
    } catch (_) {
      return ToneIntensity.moderate;
    }
  }
}

/// Extension methods for StorytellingStyle
extension StorytellingStyleExtension on StorytellingStyle {
  /// Create a StorytellingStyle from a string
  static StorytellingStyle fromString(String styleStr) {
    try {
      return StorytellingStyle.values.firstWhere(
        (style) => style.toString().split('.').last == styleStr,
        orElse: () => StorytellingStyle.neutral,
      );
    } catch (_) {
      return StorytellingStyle.neutral;
    }
  }
}
