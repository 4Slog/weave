import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/models/story.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// This would be generated with mockito's build_runner
@GenerateMocks([StorageService])
import 'storage_service_test.mocks.dart';

void main() {
  group('StorageService tests', () {
    late StorageService storageService;

    setUp(() async {
      // Set up shared preferences mock values
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs: prefs);
    });

    test('saveStory should store story in local storage', () async {
      // Arrange
      final story = Story(
        id: 'test-story-123',
        title: 'Test Story',
        content: 'This is a test story content',
        theme: 'loops',
        age: 9,
        createdAt: DateTime.now(),
      );
      
      // Act
      await storageService.saveStory(story);
      
      // Assert
      final allStories = await storageService.getAllStories();
      expect(allStories.length, 1);
      expect(allStories.first.id, 'test-story-123');
      expect(allStories.first.title, 'Test Story');
    });
    
    test('getAllStories returns empty list when no stories exist', () async {
      // Act
      final stories = await storageService.getAllStories();
      
      // Assert
      expect(stories, isEmpty);
    });
    
    test('getStoryById returns correct story', () async {
      // Arrange
      final story1 = Story(
        id: 'story-1',
        title: 'First Story',
        content: 'Content 1',
        theme: 'loops',
        age: 8,
        createdAt: DateTime.now(),
      );
      
      final story2 = Story(
        id: 'story-2',
        title: 'Second Story',
        content: 'Content 2',
        theme: 'conditionals',
        age: 10,
        createdAt: DateTime.now(),
      );
      
      await storageService.saveStory(story1);
      await storageService.saveStory(story2);
      
      // Act
      final retrievedStory = await storageService.getStoryById('story-2');
      
      // Assert
      expect(retrievedStory, isNotNull);
      expect(retrievedStory!.id, 'story-2');
      expect(retrievedStory.title, 'Second Story');
    });
    
    test('deleteStory removes story from storage', () async {
      // Arrange
      final story = Story(
        id: 'delete-test',
        title: 'Delete Me',
        content: 'To be deleted',
        theme: 'variables',
        age: 11,
        createdAt: DateTime.now(),
      );
      
      await storageService.saveStory(story);
      
      // Verify story exists
      var allStories = await storageService.getAllStories();
      expect(allStories.length, 1);
      
      // Act
      await storageService.deleteStory('delete-test');
      
      // Assert
      allStories = await storageService.getAllStories();
      expect(allStories, isEmpty);
    });
    
    test('saveUserSettings stores settings correctly', () async {
      // Arrange
      final settings = {
        'textSize': 16,
        'darkMode': true,
        'ttsEnabled': true,
        'ttsSpeed': 1.0,
      };
      
      // Act
      await storageService.saveUserSettings(settings);
      
      // Assert
      final retrievedSettings = await storageService.getUserSettings();
      expect(retrievedSettings['textSize'], 16);
      expect(retrievedSettings['darkMode'], true);
      expect(retrievedSettings['ttsEnabled'], true);
      expect(retrievedSettings['ttsSpeed'], 1.0);
    });
  });
}