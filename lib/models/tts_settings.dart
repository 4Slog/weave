import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/emotional_tone.dart';
import 'package:flutter/foundation.dart';

/// Represents the voice characteristics for TTS
enum VoiceGender {
  /// Male voice characteristics
  male,
  
  /// Female voice characteristics
  female,
  
  /// Gender-neutral voice characteristics
  neutral,
}

/// Represents the storytelling style for TTS
enum StorytellingStyle {
  /// Standard narrative style
  neutral,
  
  /// More expressive with dramatic pauses
  dramatic,
  
  /// Casual, friendly tone
  conversational,
  
  /// Traditional Ghanaian storyteller style
  traditional,
  
  /// With rhythmic cadence like kente weaving
  rhythmic,
  
  /// Clear, instructional style
  educational,
  
  /// Engaging style for younger children
  childFriendly,
  
  /// Culturally authentic style with traditional elements
  cultural,
  
  /// Interactive style that encourages participation
  interactive,
  
  /// Mysterious style for suspenseful moments
  mysterious,
}

/// Represents the accessibility options for TTS
enum AccessibilityOption {
  /// Standard speech
  standard,
  
  /// Slower speech for better comprehension
  slowSpeech,
  
  /// Clearer pronunciation for language learners
  clearPronunciation,
  
  /// Enhanced volume for hearing difficulties
  louder,
  
  /// Simplified vocabulary for younger users
  simplifiedVocabulary,
  
  /// Detailed descriptions for visual elements
  enhancedDescriptions,
}

/// Text-to-Speech settings for narrative and educational content
class TTSSettings {
  /// The voice language to use
  final String language;
  
  /// The voice identifier
  final String voice;
  
  /// The speech rate (0.0 - 1.0)
  final double rate;
  
  /// The speech pitch (0.5 - 2.0)
  final double pitch;
  
  /// The speech volume (0.0 - 1.0)
  final double volume;
  
  /// The emotional tone to apply
  final EmotionalTone tone;
  
  /// The intensity of the emotional tone
  final ToneIntensity toneIntensity;
  
  /// The storytelling style to use
  final StorytellingStyle storytellingStyle;
  
  /// The voice gender preference
  final VoiceGender voiceGender;
  
  /// Whether to use cultural pronunciation
  final bool useCulturalPronunciation;
  
  /// The accessibility options to apply
  final List<AccessibilityOption> accessibilityOptions;
  
  /// The target age group for voice adaptation
  final int targetAgeGroup;
  
  /// Whether to use automatic emotional adaptation
  final bool autoEmotionalAdaptation;

  /// Creates TTSSettings with the given properties
  TTSSettings({
    this.language = 'en-US',
    this.voice = 'en-us-x-sfg#female_1',
    this.rate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.tone = EmotionalTone.neutral,
    this.toneIntensity = ToneIntensity.moderate,
    this.storytellingStyle = StorytellingStyle.neutral,
    this.voiceGender = VoiceGender.female,
    this.useCulturalPronunciation = false,
    this.accessibilityOptions = const [],
    this.targetAgeGroup = 10,
    this.autoEmotionalAdaptation = true,
  });

  /// Creates a copy of this TTSSettings with the given fields replaced
  TTSSettings copyWith({
    String? language,
    String? voice,
    double? rate,
    double? pitch,
    double? volume,
    EmotionalTone? tone,
    ToneIntensity? toneIntensity,
    StorytellingStyle? storytellingStyle,
    VoiceGender? voiceGender,
    bool? useCulturalPronunciation,
    List<AccessibilityOption>? accessibilityOptions,
    int? targetAgeGroup,
    bool? autoEmotionalAdaptation,
  }) {
    return TTSSettings(
      language: language ?? this.language,
      voice: voice ?? this.voice,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      tone: tone ?? this.tone,
      toneIntensity: toneIntensity ?? this.toneIntensity,
      storytellingStyle: storytellingStyle ?? this.storytellingStyle,
      voiceGender: voiceGender ?? this.voiceGender,
      useCulturalPronunciation: useCulturalPronunciation ?? this.useCulturalPronunciation,
      accessibilityOptions: accessibilityOptions ?? this.accessibilityOptions,
      targetAgeGroup: targetAgeGroup ?? this.targetAgeGroup,
      autoEmotionalAdaptation: autoEmotionalAdaptation ?? this.autoEmotionalAdaptation,
    );
  }

  /// Creates TTSSettings from a Map
  factory TTSSettings.fromMap(Map<String, dynamic> map) {
    // Parse accessibility options
    final List<AccessibilityOption> accessOptions = [];
    if (map['accessibilityOptions'] != null) {
      for (final option in map['accessibilityOptions']) {
        try {
          accessOptions.add(
            AccessibilityOption.values.firstWhere(
              (o) => o.toString().split('.').last == option,
              orElse: () => AccessibilityOption.standard,
            ),
          );
        } catch (_) {
          // Skip invalid options
        }
      }
    }
    
    return TTSSettings(
      language: map['language'] ?? 'en-US',
      voice: map['voice'] ?? 'en-us-x-sfg#female_1',
      rate: map['rate']?.toDouble() ?? 0.5,
      pitch: map['pitch']?.toDouble() ?? 1.0,
      volume: map['volume']?.toDouble() ?? 1.0,
      tone: _parseTone(map['tone']),
      toneIntensity: _parseIntensity(map['toneIntensity']),
      storytellingStyle: _parseStyle(map['storytellingStyle']),
      voiceGender: _parseGender(map['voiceGender']),
      useCulturalPronunciation: map['useCulturalPronunciation'] ?? false,
      accessibilityOptions: accessOptions,
      targetAgeGroup: map['targetAgeGroup'] ?? 10,
      autoEmotionalAdaptation: map['autoEmotionalAdaptation'] ?? true,
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
      'toneIntensity': toneIntensity.toString().split('.').last,
      'storytellingStyle': storytellingStyle.toString().split('.').last,
      'voiceGender': voiceGender.toString().split('.').last,
      'useCulturalPronunciation': useCulturalPronunciation,
      'accessibilityOptions': accessibilityOptions
          .map((option) => option.toString().split('.').last)
          .toList(),
      'targetAgeGroup': targetAgeGroup,
      'autoEmotionalAdaptation': autoEmotionalAdaptation,
    };
  }

  /// Applies emotional tone modifications to these settings
  TTSSettings applyEmotionalTone(EmotionalTone newTone, {ToneIntensity? intensity}) {
    final effectiveIntensity = intensity ?? toneIntensity;
    final expression = EmotionalExpression(tone: newTone, intensity: effectiveIntensity);
    
    return copyWith(
      pitch: expression.pitch,
      rate: expression.rate,
      volume: expression.volume,
      tone: newTone,
      toneIntensity: effectiveIntensity,
    );
  }
  
  /// Applies emotional expression to these settings
  TTSSettings applyEmotionalExpression(EmotionalExpression expression) {
    return copyWith(
      pitch: expression.pitch,
      rate: expression.rate,
      volume: expression.volume,
      tone: expression.tone,
      toneIntensity: expression.intensity,
    );
  }
  
  /// Applies storytelling style modifications
  TTSSettings applyStorytellingStyle(StorytellingStyle style) {
    // Apply style-specific modifications
    switch (style) {
      case StorytellingStyle.dramatic:
        return copyWith(
          rate: 0.45,
          pitch: 1.1,
          storytellingStyle: style,
        );
      case StorytellingStyle.conversational:
        return copyWith(
          rate: 0.55,
          pitch: 1.0,
          storytellingStyle: style,
        );
      case StorytellingStyle.traditional:
        return copyWith(
          rate: 0.4,
          pitch: 0.95,
          useCulturalPronunciation: true,
          storytellingStyle: style,
        );
      case StorytellingStyle.rhythmic:
        return copyWith(
          rate: 0.5,
          pitch: 1.05,
          storytellingStyle: style,
        );
      case StorytellingStyle.educational:
        return copyWith(
          rate: 0.45,
          pitch: 1.0,
          storytellingStyle: style,
        );
      case StorytellingStyle.childFriendly:
        return copyWith(
          rate: 0.5,
          pitch: 1.15,
          storytellingStyle: style,
        );
      case StorytellingStyle.cultural:
        return copyWith(
          rate: 0.42,
          pitch: 0.98,
          useCulturalPronunciation: true,
          storytellingStyle: style,
        );
      case StorytellingStyle.interactive:
        return copyWith(
          rate: 0.52,
          pitch: 1.08,
          storytellingStyle: style,
        );
      case StorytellingStyle.mysterious:
        return copyWith(
          rate: 0.4,
          pitch: 0.9,
          storytellingStyle: style,
        );
      case StorytellingStyle.neutral:
      default:
        return copyWith(
          rate: 0.5,
          pitch: 1.0,
          storytellingStyle: style,
        );
    }
  }
  
  /// Applies accessibility options
  TTSSettings applyAccessibilityOptions(List<AccessibilityOption> options) {
    double newRate = rate;
    double newVolume = volume;
    double newPitch = pitch;
    bool newCulturalPronunciation = useCulturalPronunciation;
    
    for (final option in options) {
      switch (option) {
        case AccessibilityOption.slowSpeech:
          newRate = 0.4;
          break;
        case AccessibilityOption.clearPronunciation:
          newRate = 0.45;
          newPitch = 1.0;
          break;
        case AccessibilityOption.louder:
          newVolume = 1.0;
          break;
        case AccessibilityOption.simplifiedVocabulary:
          // This is handled at the content level
          break;
        case AccessibilityOption.enhancedDescriptions:
          // This is handled at the content level
          break;
        case AccessibilityOption.standard:
        default:
          // No changes
          break;
      }
    }
    
    return copyWith(
      rate: newRate,
      volume: newVolume,
      pitch: newPitch,
      useCulturalPronunciation: newCulturalPronunciation,
      accessibilityOptions: options,
    );
  }
  
  /// Adapts settings for a specific age group
  TTSSettings adaptForAgeGroup(int age) {
    double newRate;
    double newPitch;
    StorytellingStyle newStyle;
    
    if (age <= 8) {
      // Younger children - slower, more expressive
      newRate = 0.45;
      newPitch = 1.1;
      newStyle = StorytellingStyle.childFriendly;
    } else if (age <= 11) {
      // Middle age group - balanced
      newRate = 0.5;
      newPitch = 1.05;
      newStyle = StorytellingStyle.conversational;
    } else {
      // Older children - more natural
      newRate = 0.52;
      newPitch = 1.0;
      newStyle = StorytellingStyle.educational;
    }
    
    return copyWith(
      rate: newRate,
      pitch: newPitch,
      storytellingStyle: newStyle,
      targetAgeGroup: age,
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
  
  /// Helper method to parse intensity from string
  static ToneIntensity _parseIntensity(String? intensityStr) {
    if (intensityStr == null) return ToneIntensity.moderate;
    
    try {
      return ToneIntensity.values.firstWhere(
        (intensity) => intensity.toString().split('.').last == intensityStr,
        orElse: () => ToneIntensity.moderate,
      );
    } catch (_) {
      return ToneIntensity.moderate;
    }
  }
  
  /// Helper method to parse storytelling style from string
  static StorytellingStyle _parseStyle(String? styleStr) {
    if (styleStr == null) return StorytellingStyle.neutral;
    
    try {
      return StorytellingStyle.values.firstWhere(
        (style) => style.toString().split('.').last == styleStr,
        orElse: () => StorytellingStyle.neutral,
      );
    } catch (_) {
      return StorytellingStyle.neutral;
    }
  }
  
  /// Helper method to parse voice gender from string
  static VoiceGender _parseGender(String? genderStr) {
    if (genderStr == null) return VoiceGender.female;
    
    try {
      return VoiceGender.values.firstWhere(
        (gender) => gender.toString().split('.').last == genderStr,
        orElse: () => VoiceGender.female,
      );
    } catch (_) {
      return VoiceGender.female;
    }
  }
  
  /// Get the current emotional expression
  EmotionalExpression get emotionalExpression {
    return EmotionalExpression(
      tone: tone,
      intensity: toneIntensity,
    );
  }
  
  /// Get a voice appropriate for the current settings
  String getAppropriateVoice() {
    // Base voice selection on gender and language
    String baseVoice;
    
    switch (voiceGender) {
      case VoiceGender.male:
        baseVoice = 'en-us-x-sfg#male_1';
        break;
      case VoiceGender.female:
        baseVoice = 'en-us-x-sfg#female_1';
        break;
      case VoiceGender.neutral:
        baseVoice = 'en-us-x-sfg#neutral_1';
        break;
    }
    
    // Adjust for age group if needed
    if (targetAgeGroup <= 8) {
      // More child-friendly voice for younger children
      if (voiceGender == VoiceGender.female) {
        baseVoice = 'en-us-x-sfg#female_2'; // Softer female voice
      }
    }
    
    // Adjust for cultural pronunciation if needed
    if (useCulturalPronunciation) {
      // Use a voice with better pronunciation of African terms
      // This is a placeholder - actual implementation would depend on TTS engine capabilities
      baseVoice += '-cultural';
    }
    
    return baseVoice;
  }
  
  @override
  String toString() => 'TTSSettings(language: $language, voice: $voice, '
      'rate: $rate, pitch: $pitch, volume: $volume, tone: $tone, '
      'toneIntensity: $toneIntensity, storytellingStyle: $storytellingStyle)';
}

/// Extension to add TTS functionality to Strings
extension TTSString on String {
  /// Adds SSML tags for emphasis
  String withEmphasis({String level = 'moderate'}) {
    return "<emphasis level='$level'>$this</emphasis>";
  }
  
  /// Adds SSML tags for cultural term pronunciation
  String asCulturalTerm() {
    return "<say-as interpret-as='cultural-term'>$this</say-as>";
  }
  
  /// Adds SSML tags for a pause
  String withPause(int milliseconds) {
    return "$this<break time='${milliseconds}ms'/>";
  }
  
  /// Adds SSML tags for prosody (pitch, rate, volume)
  String withProsody({String? pitch, String? rate, String? volume}) {
    final attributes = <String>[];
    if (pitch != null) attributes.add("pitch='$pitch'");
    if (rate != null) attributes.add("rate='$rate'");
    if (volume != null) attributes.add("volume='$volume'");
    
    return "<prosody ${attributes.join(' ')}>$this</prosody>";
  }
  
  /// Adds SSML tags for phonetic pronunciation
  String withPhoneticPronunciation(String phonetic, {String alphabet = 'ipa'}) {
    return "<phoneme alphabet='$alphabet' ph='$phonetic'>$this</phoneme>";
  }
  
  /// Adds SSML tags for a specific voice
  String withVoice(String voice) {
    return "<voice name='$voice'>$this</voice>";
  }
  
  /// Adds SSML tags for a specific language
  String inLanguage(String language) {
    return "<lang xml:lang='$language'>$this</lang>";
  }
  
  /// Adds SSML tags for a specific emotional tone
  String withEmotionalTone(EmotionalTone tone, {ToneIntensity intensity = ToneIntensity.moderate}) {
    final expression = EmotionalExpression(tone: tone, intensity: intensity);
    
    return withProsody(
      pitch: expression.pitch > 1.0 ? '+${((expression.pitch - 1.0) * 100).toInt()}%' : 
             expression.pitch < 1.0 ? '-${((1.0 - expression.pitch) * 100).toInt()}%' : '0%',
      rate: expression.rate > 0.5 ? '+${((expression.rate - 0.5) * 200).toInt()}%' : 
            expression.rate < 0.5 ? '-${((0.5 - expression.rate) * 200).toInt()}%' : '0%',
      volume: expression.volume > 1.0 ? '+${((expression.volume - 1.0) * 100).toInt()}%' : 
              expression.volume < 1.0 ? '-${((1.0 - expression.volume) * 100).toInt()}%' : '0%',
    );
  }
  
  /// Adds SSML tags for a cultural storytelling style
  String withCulturalStyle() {
    return withProsody(rate: '-10%', pitch: '-5%')
        .withPause(300)
        .withEmphasis(level: 'strong');
  }
  
  /// Adds SSML tags for a child-friendly style
  String asChildFriendly() {
    return withProsody(rate: '-5%', pitch: '+10%', volume: '+10%');
  }
  
  /// Adds SSML tags for an educational style
  String asEducational() {
    return withProsody(rate: '-10%', pitch: '0%')
        .withEmphasis(level: 'moderate');
  }
  
  /// Adds SSML tags for a dramatic style
  String asDramatic() {
    return withProsody(rate: '-15%', pitch: '+15%')
        .withEmphasis(level: 'strong')
        .withPause(500);
  }
}

/// Extension to add storytelling style functionality to StorytellingStyle
extension StorytellingStyleExtension on StorytellingStyle {
  /// Get a description of this storytelling style
  String get description {
    switch (this) {
      case StorytellingStyle.neutral:
        return 'A balanced, standard narrative style suitable for general content.';
      case StorytellingStyle.dramatic:
        return 'An expressive style with dramatic pauses and emphasis for engaging storytelling.';
      case StorytellingStyle.conversational:
        return 'A casual, friendly tone that feels like a conversation with the listener.';
      case StorytellingStyle.traditional:
        return 'A traditional Ghanaian storyteller style with cultural inflections and pacing.';
      case StorytellingStyle.rhythmic:
        return 'A style with rhythmic cadence reminiscent of kente weaving patterns.';
      case StorytellingStyle.educational:
        return 'A clear, instructional style focused on learning and comprehension.';
      case StorytellingStyle.childFriendly:
        return 'An engaging style with simpler language for younger children.';
      case StorytellingStyle.cultural:
        return 'A culturally authentic style with traditional elements and pronunciations.';
      case StorytellingStyle.interactive:
        return 'An engaging style that encourages participation and response.';
      case StorytellingStyle.mysterious:
        return 'A suspenseful style for creating intrigue and maintaining attention.';
    }
  }
  
  /// Get the cultural significance of this storytelling style
  String get culturalContext {
    switch (this) {
      case StorytellingStyle.neutral:
        return 'A modern narrative approach that balances traditional and contemporary elements.';
      case StorytellingStyle.dramatic:
        return 'Reflects the animated storytelling traditions of West African griots.';
      case StorytellingStyle.conversational:
        return 'Mirrors the informal knowledge sharing that occurs during community gatherings.';
      case StorytellingStyle.traditional:
        return 'Preserves the authentic voice and cadence of Ghanaian Anansesem (spider stories).';
      case StorytellingStyle.rhythmic:
        return 'Echoes the rhythmic patterns of kente weaving and traditional drumming.';
      case StorytellingStyle.educational:
        return 'Represents the teaching approach of elders passing knowledge to younger generations.';
      case StorytellingStyle.childFriendly:
        return 'Adapts traditional stories for children in the way grandparents would simplify tales.';
      case StorytellingStyle.cultural:
        return 'Incorporates authentic pronunciation and cultural references from Ghanaian traditions.';
      case StorytellingStyle.interactive:
        return 'Reflects the call-and-response pattern common in West African storytelling.';
      case StorytellingStyle.mysterious:
        return 'Draws from the tradition of evening fireside tales that build suspense and wonder.';
    }
  }
  
  /// Get appropriate storytelling style for a given age group
  static StorytellingStyle getStyleForAgeGroup(int age) {
    if (age <= 8) {
      return StorytellingStyle.childFriendly;
    } else if (age <= 11) {
      return StorytellingStyle.conversational;
    } else {
      return StorytellingStyle.educational;
    }
  }
  
  /// Get appropriate storytelling style for a narrative context
  static StorytellingStyle getStyleForContext(String context) {
    final lowerContext = context.toLowerCase();
    
    if (lowerContext.contains('cultural') || lowerContext.contains('tradition')) {
      return StorytellingStyle.cultural;
    } else if (lowerContext.contains('teach') || lowerContext.contains('learn')) {
      return StorytellingStyle.educational;
    } else if (lowerContext.contains('child') || lowerContext.contains('young')) {
      return StorytellingStyle.childFriendly;
    } else if (lowerContext.contains('drama') || lowerContext.contains('exciting')) {
      return StorytellingStyle.dramatic;
    } else if (lowerContext.contains('interact') || lowerContext.contains('participate')) {
      return StorytellingStyle.interactive;
    } else if (lowerContext.contains('mystery') || lowerContext.contains('suspense')) {
      return StorytellingStyle.mysterious;
    } else if (lowerContext.contains('rhythm') || lowerContext.contains('pattern')) {
      return StorytellingStyle.rhythmic;
    } else if (lowerContext.contains('talk') || lowerContext.contains('chat')) {
      return StorytellingStyle.conversational;
    } else if (lowerContext.contains('ananse') || lowerContext.contains('folktale')) {
      return StorytellingStyle.traditional;
    } else {
      return StorytellingStyle.neutral;
    }
  }
}
