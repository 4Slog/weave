import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Default settings
  bool _ttsEnabled = true;
  double _ttsSpeed = 1.0;
  bool _darkModeEnabled = false;
  bool _soundEffectsEnabled = true;
  
  // Getters
  bool get ttsEnabled => _ttsEnabled;
  double get ttsSpeed => _ttsSpeed;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    _ttsSpeed = prefs.getDouble('tts_speed') ?? 1.0;
    _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    _soundEffectsEnabled = prefs.getBool('sound_effects_enabled') ?? true;
    
    notifyListeners();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('tts_enabled', _ttsEnabled);
    await prefs.setDouble('tts_speed', _ttsSpeed);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setBool('sound_effects_enabled', _soundEffectsEnabled);
  }
  
  void setTtsEnabled(bool value) {
    _ttsEnabled = value;
    _saveSettings();
    notifyListeners();
  }
  
  void setTtsSpeed(double value) {
    _ttsSpeed = value;
    _saveSettings();
    notifyListeners();
  }
  
  void setDarkModeEnabled(bool value) {
    _darkModeEnabled = value;
    _saveSettings();
    notifyListeners();
  }
  
  void setSoundEffectsEnabled(bool value) {
    _soundEffectsEnabled = value;
    _saveSettings();
    notifyListeners();
  }
}