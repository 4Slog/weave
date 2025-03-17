import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/emotional_tone.dart';
import 'package:flutter/foundation.dart';
import 'emotional_tone.dart';

/// Represents the voice characteristics for TTS
enum VoiceGender {
  male,
  female,
  neutral,
}

/// Represents the storytelling style for TTS
enum StorytellingStyle {
  neutral,      // Standard narrative style
  dramatic,     // More expressive with dramatic pauses
  conversational, // Casual, friendly tone
  traditional,  // Traditional Ghanaian storyteller style
  rhythmic,     // With rhythmic cadence like kente weaving
  educational,  // Clear, instructional style
}

/// Text-to-Speech settings for narrative and educational content
class TTSSettings {
  /// The voice language to use
  final String language;
  
  /// The voice gender preference
  final String voice;
  
  /// The speech rate (0.0 - 1.0)
  final double rate;
  
  /// The speech pitch (0.5 - 2.0)
  final double pitch;
  
  /// The speech volume (0.0 - 1.0)
  final double volume;
  
  /// The emotional tone to apply
  final EmotionalTone tone;

  /// Creates TTSSettings with the given properties
  TTSSettings({
    this.language = 'en-US',
    this.voice = 'en-us-x-sfg#female_1',
    this.rate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.tone = EmotionalTone.neutral,
  });

  /// Creates a copy of this TTSSettings with the given fields replaced
  TTSSettings copyWith({
    String? language,
    String? voice,
    double? rate,
    double? pitch,
    double? volume,
    EmotionalTone? tone,
  }) {
    return TTSSettings(
      language: language ?? this.language,
      voice: voice ?? this.voice,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      tone: tone ?? this.tone,
    );
  }

  /// Creates TTSSettings from a Map
  factory TTSSettings.fromMap(Map<String, dynamic> map) {
    return TTSSettings(
      language: map['language'] ?? 'en-US',
      voice: map['voice'] ?? 'en-us-x-sfg#female_1',
      rate: map['rate']?.toDouble() ?? 0.5,
      pitch: map['pitch']?.toDouble() ?? 1.0,
      volume: map['volume']?.toDouble() ?? 1.0,
      tone: _parseTone(map['tone']),
    );
  }

  /// Converts this TTSSettings to a Map
  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'voice': voice,
      'rate': rate,
      'pitch': pitch,
      'volume': volume,
      'tone': tone.toString().split('.').last,
    };
  }

  /// Applies emotional tone modifications to these settings
  TTSSettings applyEmotionalTone(EmotionalTone newTone) {
    return copyWith(
      pitch: newTone.pitch,
      rate: newTone.rate,
      volume: newTone.volume,
      tone: newTone,
    );
  }

  /// Helper method to parse tone from string
  static EmotionalTone _parseTone(String? toneStr) {
    if (toneStr == null) return EmotionalTone.neutral;
    
    try {
      return EmotionalTone.values.firstWhere(
        (tone) => tone.toString().split('.').last == toneStr,
        orElse: () => EmotionalTone.neutral,
      );
    } catch (_) {
      return EmotionalTone.neutral;
    }
  }
  
  @override
  String toString() => 'TTSSettings(language: $language, voice: $voice, '
      'rate: $rate, pitch: $pitch, volume: $volume, tone: $tone)';
}

/// Extension to add TTS functionality to Strings
extension TTSString on String {
  /// Adds SSML tags for emphasis
  String withEmphasis() {
    return "<emphasis>$this</emphasis>";
  }
  
  /// Adds SSML tags for cultural term pronunciation
  String asCulturalTerm() {
    return "<say-as interpret-as='cultural-term'>$this</say-as>";
  }
  
  /// Adds SSML tags for a pause
  String withPause(int milliseconds) {
    return "$this<break time='${milliseconds}ms'/>";
  }
}