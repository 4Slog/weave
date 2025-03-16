import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/services/tts_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_tts/flutter_tts.dart';

// This would be generated with mockito's build_runner
@GenerateMocks([FlutterTts])
import 'tts_service_test.mocks.dart';

void main() {
  group('TTSService tests', () {
    late MockFlutterTts mockTts;
    late TTSService ttsService;

    setUp(() {
      mockTts = MockFlutterTts();
      ttsService = TTSService(flutterTts: mockTts);
    });

    test('speak should call FlutterTts speak method', () async {
      // Arrange
      when(mockTts.speak(any)).thenAnswer((_) async => 1);
      
      // Act
      await ttsService.speak('Hello, testing 1, 2, 3.');
      
      // Assert
      verify(mockTts.speak('Hello, testing 1, 2, 3.')).called(1);
    });
    
    test('stop should call FlutterTts stop method', () async {
      // Arrange
      when(mockTts.stop()).thenAnswer((_) async => 1);
      
      // Act
      await ttsService.stop();
      
      // Assert
      verify(mockTts.stop()).called(1);
    });
    
    test('setLanguage should set TTS language', () async {
      // Arrange
      when(mockTts.setLanguage(any)).thenAnswer((_) async => 1);
      
      // Act
      await ttsService.setLanguage('en-US');
      
      // Assert
      verify(mockTts.setLanguage('en-US')).called(1);
    });
    
    test('setSpeechRate should set TTS rate', () async {
      // Arrange
      when(mockTts.setSpeechRate(any)).thenAnswer((_) async => 1);
      
      // Act
      await ttsService.setSpeechRate(0.8);
      
      // Assert
      verify(mockTts.setSpeechRate(0.8)).called(1);
    });
    
    test('isLanguageAvailable should check if language is supported', () async {
      // Arrange
      when(mockTts.getLanguages).thenAnswer((_) async => ['en-US', 'fr-FR', 'es-ES']);
      
      // Act
      final isEnglishAvailable = await ttsService.isLanguageAvailable('en-US');
      final isSwahiliAvailable = await ttsService.isLanguageAvailable('sw-KE');
      
      // Assert
      expect(isEnglishAvailable, true);
      expect(isSwahiliAvailable, false);
    });
    
    test('onProgress callback is registered', () async {
      // Arrange
      when(mockTts.setStartHandler(any)).thenAnswer((_) async => null);
      when(mockTts.setCompletionHandler(any)).thenAnswer((_) async => null);
      when(mockTts.setProgressHandler(any)).thenAnswer((_) async => null);
      when(mockTts.setErrorHandler(any)).thenAnswer((_) async => null);
      
      // Act
      ttsService.initialize();
      
      // Assert
      verify(mockTts.setStartHandler(any)).called(1);
      verify(mockTts.setCompletionHandler(any)).called(1);
      verify(mockTts.setProgressHandler(any)).called(1);
      verify(mockTts.setErrorHandler(any)).called(1);
    });
  });
}