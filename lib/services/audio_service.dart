import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'dart:async';

/// Audio types available in the application
enum AudioType {
  mainTheme,
  learningTheme,
  challengeTheme,
  success,
  failure,
  achievement,
  buttonTap,
  navigationTap,
  culturalIntro,
  celebration,
  hint,
  confirmationTap,
  cancelTap,
}

/// Service for handling audio playback in the application
class AudioService {
  // Audio player instances
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  
  // Volume settings
  double _musicVolume = 0.5;
  double _effectsVolume = 0.7;
  
  // Playback state
  bool _isMusicEnabled = true;
  bool _areEffectsEnabled = true;
  
  /// Initialize the audio service
  Future<void> initialize() async {
    await _musicPlayer.setVolume(_musicVolume);
    await _effectPlayer.setVolume(_effectsVolume);
  }
  
  /// Play background music by asset name
  Future<void> playMusic(String assetName) async {
    if (!_isMusicEnabled) return;
    
    await _musicPlayer.stop();
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setSource(AssetSource(assetName));
    await _musicPlayer.resume();
  }
  
  /// Play a sound effect once
  Future<void> playEffect(AudioType type) async {
    if (!_areEffectsEnabled) return;
    
    final assetPath = _getEffectPath(type);
    await _effectPlayer.stop();
    await _effectPlayer.setReleaseMode(ReleaseMode.release);
    await _effectPlayer.setSource(AssetSource(assetPath));
    await _effectPlayer.resume();
  }
  
  /// Get the sound effect asset path based on type
  String _getEffectPath(AudioType type) {
    switch (type) {
      case AudioType.achievement:
        return 'audio/achievement.mp3';
      case AudioType.success:
        return 'audio/success.mp3';
      case AudioType.failure:
        return 'audio/failure.mp3';
      case AudioType.button:
        return 'audio/button_tap.mp3';
      default:
        return 'audio/button_tap.mp3';
    }
  }
  
  /// Stop all audio playback
  Future<void> stopAll() async {
    await _musicPlayer.stop();
    await _effectPlayer.stop();
  }
  
  /// Toggle background music on/off
  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    
    if (_isMusicEnabled) {
      await _musicPlayer.setVolume(_musicVolume);
    } else {
      await _musicPlayer.setVolume(0);
    }
  }
  
  /// Toggle sound effects on/off
  Future<void> toggleEffects() async {
    _areEffectsEnabled = !_areEffectsEnabled;
  }
  
  /// Set music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_isMusicEnabled) {
      await _musicPlayer.setVolume(_musicVolume);
    }
  }
  
  /// Set effects volume (0.0 to 1.0)
  Future<void> setEffectsVolume(double volume) async {
    _effectsVolume = volume.clamp(0.0, 1.0);
    await _effectPlayer.setVolume(_effectsVolume);
  }
  
  /// Get current music enabled state
  bool get isMusicEnabled => _isMusicEnabled;
  
  /// Get current effects enabled state
  bool get areEffectsEnabled => _areEffectsEnabled;
  
  /// Dispose resources
  void dispose() {
    _musicPlayer.dispose();
    _effectPlayer.dispose();
  }
}