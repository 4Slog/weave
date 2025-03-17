import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kente_codeweaver/models/tts_settings.dart';
import 'package:kente_codeweaver/widgets/contextual_hint_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:kente_codeweaver/models/emotional_tone.dart';
import 'package:kente_codeweaver/models/content_block_model.dart';

enum TTSState {
  playing,
  stopped,
  paused,
}

/// Enhanced TTS service with emotional expression
class TTSService {
  final FlutterTts _flutterTts;
  TTSState _ttsState = TTSState.stopped;
  EmotionalTone _currentTone = EmotionalTone.neutral;
  
  /// Create a new TTS service with optional FlutterTts instance
  TTSService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts();
  
  /// Initialize TTS
  Future<void> initialize() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower for children
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Set up callbacks
    _flutterTts.setStartHandler(() {
      _ttsState = TTSState.playing;
    });
    
    _flutterTts.setCompletionHandler(() {
      _ttsState = TTSState.stopped;
    });
    
    _flutterTts.setCancelHandler(() {
      _ttsState = TTSState.stopped;
    });
    
    _flutterTts.setPauseHandler(() {
      _ttsState = TTSState.paused;
    });
    
    _flutterTts.setContinueHandler(() {
      _ttsState = TTSState.playing;
    });
  }
  
  /// Speak text with emotional tone
  Future<void> speak(String text, {EmotionalTone? tone}) async {
    if (text.isEmpty) return;
    
    // Apply emotional tone settings
    if (tone != null && tone != _currentTone) {
      await _applyEmotionalTone(tone);
      _currentTone = tone;
    }
    
    // Speak the text
    await _flutterTts.speak(text);
  }
  
  /// Apply emotional tone to TTS parameters
  Future<void> _applyEmotionalTone(EmotionalTone tone) async {
    // Use the tone's properties directly from EmotionalToneExtension
    await _flutterTts.setPitch(tone.pitch);
    await _flutterTts.setSpeechRate(tone.rate);
    await _flutterTts.setVolume(tone.volume);
  }
  
  /// Stop speech
  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TTSState.stopped;
  }
  
  /// Pause speech
  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TTSState.paused;
  }
  
  /// Resume speech
  Future<void> resume() async {
    await _flutterTts.stop(); // Some platforms need this to resume properly
    _ttsState = TTSState.playing;
  }
  
  /// Set language
  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }
  
  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }
  
  /// Speak content blocks
  Future<void> speakContentBlocks(List<ContentBlock> blocks) async {
    for (var block in blocks) {
      // Apply block-specific settings
      if (block.speaker != null) {
        await _applyEmotionalTone(block.speaker!.voiceSettings.tone);
      } else {
        await _applyEmotionalTone(block.ttsSettings.tone);
      }
      
      // Add delay if specified
      if (block.delay > 0) {
        await Future.delayed(Duration(milliseconds: block.delay));
      }
      
      // Speak the text
      await speak(block.text);
      
      // Wait for interaction if required
      if (block.waitForInteraction) {
        // This would be handled by the UI
        continue;
      }
      
      // Otherwise wait for the display duration
      if (block.displayDuration > 0) {
        await Future.delayed(Duration(milliseconds: block.displayDuration));
      }
    }
  }
}