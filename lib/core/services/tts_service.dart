import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/tts_settings.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block.dart';

/// State of the TTS service
enum TTSState {
  /// TTS is stopped
  stopped,

  /// TTS is playing
  playing,

  /// TTS is paused
  paused,

  /// TTS is in the process of stopping
  stopping,

  /// TTS is in the process of starting
  starting,

  /// TTS has encountered an error
  error,
}

/// Service for text-to-speech functionality with emotional tone support
class TTSService {
  // Singleton implementation
  static final TTSService _instance = TTSService._internal();

  factory TTSService() {
    return _instance;
  }

  TTSService._internal();

  /// Flutter TTS instance
  late FlutterTts _flutterTts;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Current state of the TTS service
  TTSState _state = TTSState.stopped;

  /// Current TTS settings
  TTSSettings _settings = TTSSettings();

  /// Queue of content blocks to speak
  final List<ContentBlock> _speakQueue = [];

  /// Flag indicating if the queue is currently being processed
  bool _isProcessingQueue = false;

  /// Completer for the current speaking operation
  Completer<void>? _speakCompleter;

  /// Get the current TTS state
  TTSState get state => _state;

  /// Get whether speech is currently in progress
  bool get isSpeaking => _state == TTSState.playing;

  /// Get whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get the current TTS settings
  TTSSettings get settings => _settings;

  /// Initialize the TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterTts = FlutterTts();

      // Set default configuration from settings
      await _flutterTts.setLanguage(_settings.language);
      await _flutterTts.setSpeechRate(_settings.rate);
      await _flutterTts.setVolume(_settings.volume);
      await _flutterTts.setPitch(_settings.pitch);

      // Set voice if available
      final voices = await _flutterTts.getVoices;
      if (voices != null && voices is List && voices.isNotEmpty) {
        // Try to find a voice that matches our settings
        final voiceToUse = _settings.getAppropriateVoice();
        await _flutterTts.setVoice({'name': voiceToUse});
      }

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        _setState(TTSState.stopped);
        _processSpeakQueue();
        _completeSpeaking();
      });

      // Set start handler
      _flutterTts.setStartHandler(() {
        _setState(TTSState.playing);
      });

      // Set error handler
      _flutterTts.setErrorHandler((error) {
        debugPrint('TTS Error: $error');
        _setState(TTSState.error);
        _completeSpeaking(error: error.toString());
      });

      // Set cancel handler
      _flutterTts.setCancelHandler(() {
        _setState(TTSState.stopped);
        _completeSpeaking(cancelled: true);
      });

      // Set pause handler
      _flutterTts.setPauseHandler(() {
        _setState(TTSState.paused);
      });

      // Set continue handler
      _flutterTts.setContinueHandler(() {
        _setState(TTSState.playing);
      });

      _isInitialized = true;
      debugPrint('TTSService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize TTSService: $e');
      _isInitialized = false;
      _setState(TTSState.error);
    }
  }

  /// Speak the provided text with optional emotional tone
  ///
  /// @param text The text to speak
  /// @param tone Optional emotional tone to apply
  /// @param intensity Optional intensity of the emotional tone
  /// @return A future that completes when the speech finishes
  Future<void> speak(String text, {
    EmotionalTone tone = EmotionalTone.neutral,
    ToneIntensity intensity = ToneIntensity.moderate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_state == TTSState.playing || _state == TTSState.starting) {
      await stop();
    }

    _speakCompleter = Completer<void>();
    _setState(TTSState.starting);

    try {
      // Apply emotional tone to settings
      final toneSettings = _settings.applyEmotionalTone(tone, intensity: intensity);

      // Apply settings to TTS engine
      await _flutterTts.setSpeechRate(toneSettings.rate);
      await _flutterTts.setPitch(toneSettings.pitch);
      await _flutterTts.setVolume(toneSettings.volume);

      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Failed to speak text: $e');
      _setState(TTSState.error);
      _completeSpeaking(error: e.toString());
    }

    return _speakCompleter!.future;
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      _setState(TTSState.stopping);
      await _flutterTts.stop();
      _setState(TTSState.stopped);
      _speakQueue.clear();
      _isProcessingQueue = false;
      _completeSpeaking(cancelled: true);
    } catch (e) {
      debugPrint('Failed to stop speech: $e');
      _setState(TTSState.error);
    }
  }

  /// Pause any ongoing speech
  Future<void> pause() async {
    if (!_isInitialized || _state != TTSState.playing) return;

    try {
      await _flutterTts.pause();
      // State will be updated by the pause handler
    } catch (e) {
      debugPrint('Failed to pause speech: $e');
      _setState(TTSState.error);
    }
  }

  /// Set the speech rate
  ///
  /// @param rate The speech rate (0.0 to 1.0)
  Future<void> setRate(double rate) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final clampedRate = rate.clamp(0.0, 1.0);
      _settings = _settings.copyWith(rate: clampedRate);
      await _flutterTts.setSpeechRate(clampedRate);
    } catch (e) {
      debugPrint('Failed to set speech rate: $e');
    }
  }

  /// Set the speech pitch
  ///
  /// @param pitch The speech pitch (0.0 to 2.0)
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final clampedPitch = pitch.clamp(0.5, 2.0);
      _settings = _settings.copyWith(pitch: clampedPitch);
      await _flutterTts.setPitch(clampedPitch);
    } catch (e) {
      debugPrint('Failed to set speech pitch: $e');
    }
  }

  /// Set the speech volume
  ///
  /// @param volume The speech volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      _settings = _settings.copyWith(volume: clampedVolume);
      await _flutterTts.setVolume(clampedVolume);
    } catch (e) {
      debugPrint('Failed to set speech volume: $e');
    }
  }

  /// Set the speech language
  ///
  /// @param language The language code (e.g., 'en-US')
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _settings = _settings.copyWith(language: language);
      await _flutterTts.setLanguage(language);
    } catch (e) {
      debugPrint('Failed to set speech language: $e');
    }
  }

  /// Apply TTS settings
  ///
  /// @param settings The settings to apply
  Future<void> applySettings(TTSSettings settings) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _settings = settings;
      await _flutterTts.setLanguage(settings.language);
      await _flutterTts.setSpeechRate(settings.rate);
      await _flutterTts.setPitch(settings.pitch);
      await _flutterTts.setVolume(settings.volume);

      // Set voice if available
      final voices = await _flutterTts.getVoices;
      if (voices != null && voices is List && voices.isNotEmpty) {
        final voiceToUse = settings.getAppropriateVoice();
        await _flutterTts.setVoice({'name': voiceToUse});
      }
    } catch (e) {
      debugPrint('Failed to apply TTS settings: $e');
    }
  }

  /// Speak a sequence of content blocks
  ///
  /// @param blocks The content blocks to speak
  /// @return A future that completes when all blocks have been spoken
  Future<void> speakContentBlocks(List<ContentBlock> blocks) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Add blocks to the queue
    _speakQueue.addAll(blocks);

    // Start processing the queue if not already processing
    if (!_isProcessingQueue) {
      _processSpeakQueue();
    }

    // Return a future that completes when all blocks have been spoken
    _speakCompleter = Completer<void>();
    return _speakCompleter!.future;
  }

  /// Process the speak queue
  void _processSpeakQueue() async {
    if (_speakQueue.isEmpty || _isProcessingQueue) {
      if (_speakQueue.isEmpty && _speakCompleter != null && !_speakCompleter!.isCompleted) {
        _speakCompleter!.complete();
      }
      return;
    }

    _isProcessingQueue = true;

    try {
      final block = _speakQueue.removeAt(0);

      // Apply appropriate settings for the block
      TTSSettings blockSettings = _settings;

      // Apply emotional tone if specified
      if (block.emotionalTone != null) {
        blockSettings = blockSettings.applyEmotionalTone(
          block.emotionalTone!,
          intensity: block.toneIntensity ?? ToneIntensity.moderate,
        );
      }

      // Apply storytelling style if specified
      if (block.storytellingStyle != null) {
        blockSettings = blockSettings.applyStorytellingStyle(block.storytellingStyle!);
      }

      // Apply settings
      await applySettings(blockSettings);

      // Speak the text
      await _flutterTts.speak(block.text);

      // Wait for completion before processing next block
      // The completion handler will call _processSpeakQueue again
    } catch (e) {
      debugPrint('Failed to process speak queue: $e');
      _isProcessingQueue = false;
      _setState(TTSState.error);
      _completeSpeaking(error: e.toString());
    }
  }

  /// Update the TTS state and notify listeners
  void _setState(TTSState newState) {
    _state = newState;
    // Notify listeners if needed
  }

  /// Complete the current speaking operation
  void _completeSpeaking({String? error, bool cancelled = false}) {
    if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
      if (error != null) {
        _speakCompleter!.completeError(error);
      } else if (cancelled) {
        _speakCompleter!.completeError('Speech cancelled');
      } else {
        _speakCompleter!.complete();
      }
    }

    _isProcessingQueue = false;
  }

  /// Dispose the TTS service
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await stop();
      _speakQueue.clear();
      _isProcessingQueue = false;
      if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
        _speakCompleter!.completeError('TTS service disposed');
      }
    } catch (e) {
      debugPrint('Failed to dispose TTSService: $e');
    }
  }
}
