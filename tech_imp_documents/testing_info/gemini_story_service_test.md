import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/services/gemini_story_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Generate the mock class
@GenerateMocks([http.Client])
import 'gemini_story_service_test.mocks.dart';

void main() {
  group('GeminiStoryService tests', () {
    late MockClient mockClient;
    late GeminiStoryService storyService;

    setUp(() {
      mockClient = MockClient();
      storyService = GeminiStoryService(client: mockClient);
    });

    test('AI-generated story should return valid JSON structure', () async {
      // Arrange
      final responseJson = {
        'id': 'story123',
        'title': 'Ananse and the Coding Web',
        'content': 'Once upon a time...',
        'theme': 'loops',
        'age': 10,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseJson), 200));
      
      // Act
      final story = await storyService.generateStory(age: 10, theme: 'loops');
      final storyMap = jsonDecode(story);
      
      // Assert
      expect(storyMap['title'], 'Ananse and the Coding Web');
      expect(storyMap['content'], 'Once upon a time...');
      expect(storyMap['theme'], 'loops');
      expect(storyMap['age'], 10);
    });
    
    test('generateStory should handle API errors gracefully', () async {
      // Arrange
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"error": "API quota exceeded"}', 429));
      
      // Act & Assert
      expect(
        () => storyService.generateStory(age: 8, theme: 'variables'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('generateStory should validate age parameter', () async {
      // Act & Assert
      expect(
        () => storyService.generateStory(age: 0, theme: 'loops'),
        throwsA(isA<ArgumentError>()),
      );
      
      expect(
        () => storyService.generateStory(age: 17, theme: 'loops'),
        returnsNormally,
      );
    });
    
    test('generateStory should validate theme parameter', () async {
      // Arrange
      final validResponse = jsonEncode({
        'id': 'story123',
        'title': 'Variables in Action',
        'content': 'Story content here...',
        'theme': 'variables',
        'age': 10,
      });
      
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(validResponse, 200));
      
      // Act & Assert
      expect(
        () => storyService.generateStory(age: 10, theme: 'invalid_theme'),
        throwsA(isA<ArgumentError>()),
      );
      
      final story = await storyService.generateStory(age: 10, theme: 'variables');
      final storyMap = jsonDecode(story);
      expect(storyMap['theme'], 'variables');
    });
  });
}