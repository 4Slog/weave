import 'package:kente_codeweaver/models/tts_settings.dart';
import 'package:kente_codeweaver/models/emotional_tone.dart';

/// Character speaker for narratives
class Speaker {
  /// Speaker's name
  final String name;
  
  /// Speaker's voice settings
  final TTSSettings voiceSettings;
  
  /// Speaker's avatar image path
  final String? avatarPath;
  
  /// Creates a speaker with the given properties
  Speaker({
    required this.name,
    required this.voiceSettings,
    this.avatarPath,
  });
}

/// Content block model for narrative content
class ContentBlock {
  /// Unique ID for this block
  final String id;
  
  /// Text content to be displayed/spoken
  final String text;
  
  /// Speaker for this content (if applicable)
  final Speaker? speaker;
  
  /// TTS settings for this block
  final TTSSettings ttsSettings;
  
  /// Delay before displaying/speaking (milliseconds)
  final int delay;
  
  /// How long to display this block (milliseconds)
  final int displayDuration;
  
  /// Whether to wait for user interaction before proceeding
  final bool waitForInteraction;
  
  /// Associated image path (if any)
  final String? imagePath;
  
  /// Associated animation name (if any)
  final String? animationName;
  
  /// Creates a content block with the given properties
  ContentBlock({
    required this.id,
    required this.text,
    this.speaker,
    TTSSettings? ttsSettings,
    this.delay = 0,
    this.displayDuration = 3000,
    this.waitForInteraction = false,
    this.imagePath,
    this.animationName,
  }) : ttsSettings = ttsSettings ?? TTSSettings();
  
  /// Creates a copy of this content block with the given fields replaced
  ContentBlock copyWith({
    String? id,
    String? text,
    Speaker? speaker,
    TTSSettings? ttsSettings,
    int? delay,
    int? displayDuration,
    bool? waitForInteraction,
    String? imagePath,
    String? animationName,
  }) {
    return ContentBlock(
      id: id ?? this.id,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      ttsSettings: ttsSettings ?? this.ttsSettings,
      delay: delay ?? this.delay,
      displayDuration: displayDuration ?? this.displayDuration,
      waitForInteraction: waitForInteraction ?? this.waitForInteraction,
      imagePath: imagePath ?? this.imagePath,
      animationName: animationName ?? this.animationName,
    );
  }
}