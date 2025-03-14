import 'package:flutter_tts/flutter_tts.dart';


enum TTSState { playing, stopped, paused, continued }

class TTSService {
  late FlutterTts _flutterTts;
  TTSState _ttsState = TTSState.stopped;
  
  Future<void> initialize() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower for children
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      _ttsState = TTSState.playing;
    });
    
    _flutterTts.setCompletionHandler(() {
      _ttsState = TTSState.stopped;
    });
    
    _flutterTts.setErrorHandler((error) {
      _ttsState = TTSState.stopped;
      print('TTS Error: $error');
    });
    
    // New API in Flutter TTS 4.x - initialize engines
    await _flutterTts.awaitSpeakCompletion(true);
    
    // Check if platform is supported and initialize
    List<String>? engines = await _flutterTts.getEngines;
    if (engines != null && engines.isNotEmpty) {
      print('TTS Engines available: $engines');
    }
  }
  
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }
  
  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TTSState.stopped;
  }
  
  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TTSState.paused;
  }
  
  TTSState get state => _ttsState;
  
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}