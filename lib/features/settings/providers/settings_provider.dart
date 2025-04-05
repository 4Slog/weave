import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for application settings
class SettingsProvider extends ChangeNotifier {
  /// Shared preferences instance
  late SharedPreferences _prefs;
  
  /// Text-to-speech enabled
  bool _ttsEnabled = true;
  
  /// Sound effects enabled
  bool _soundEffectsEnabled = true;
  
  /// Music enabled
  bool _musicEnabled = true;
  
  /// Dark mode enabled
  bool _darkModeEnabled = false;
  
  /// Text size
  double _textSize = 16.0;
  
  /// Is initialized
  bool _isInitialized = false;
  
  /// Get text-to-speech enabled
  bool get ttsEnabled => _ttsEnabled;
  
  /// Get sound effects enabled
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  
  /// Get music enabled
  bool get musicEnabled => _musicEnabled;
  
  /// Get dark mode enabled
  bool get darkModeEnabled => _darkModeEnabled;
  
  /// Get text size
  double get textSize => _textSize;
  
  /// Get is initialized
  bool get isInitialized => _isInitialized;
  
  /// Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load settings from shared preferences
      _ttsEnabled = _prefs.getBool('tts_enabled') ?? true;
      _soundEffectsEnabled = _prefs.getBool('sound_effects_enabled') ?? true;
      _musicEnabled = _prefs.getBool('music_enabled') ?? true;
      _darkModeEnabled = _prefs.getBool('dark_mode_enabled') ?? false;
      _textSize = _prefs.getDouble('text_size') ?? 16.0;
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Failed to initialize settings: $e');
      // Use default values
      _ttsEnabled = true;
      _soundEffectsEnabled = true;
      _musicEnabled = true;
      _darkModeEnabled = false;
      _textSize = 16.0;
      
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Set text-to-speech enabled
  Future<void> setTtsEnabled(bool value) async {
    if (_ttsEnabled == value) return;
    
    _ttsEnabled = value;
    await _prefs.setBool('tts_enabled', value);
    notifyListeners();
  }
  
  /// Set sound effects enabled
  Future<void> setSoundEffectsEnabled(bool value) async {
    if (_soundEffectsEnabled == value) return;
    
    _soundEffectsEnabled = value;
    await _prefs.setBool('sound_effects_enabled', value);
    notifyListeners();
  }
  
  /// Set music enabled
  Future<void> setMusicEnabled(bool value) async {
    if (_musicEnabled == value) return;
    
    _musicEnabled = value;
    await _prefs.setBool('music_enabled', value);
    notifyListeners();
  }
  
  /// Set dark mode enabled
  Future<void> setDarkModeEnabled(bool value) async {
    if (_darkModeEnabled == value) return;
    
    _darkModeEnabled = value;
    await _prefs.setBool('dark_mode_enabled', value);
    notifyListeners();
  }
  
  /// Set text size
  Future<void> setTextSize(double value) async {
    if (_textSize == value) return;
    
    _textSize = value;
    await _prefs.setDouble('text_size', value);
    notifyListeners();
  }
  
  /// Reset settings to default values
  Future<void> resetSettings() async {
    _ttsEnabled = true;
    _soundEffectsEnabled = true;
    _musicEnabled = true;
    _darkModeEnabled = false;
    _textSize = 16.0;
    
    await _prefs.setBool('tts_enabled', true);
    await _prefs.setBool('sound_effects_enabled', true);
    await _prefs.setBool('music_enabled', true);
    await _prefs.setBool('dark_mode_enabled', false);
    await _prefs.setDouble('text_size', 16.0);
    
    notifyListeners();
  }
}
