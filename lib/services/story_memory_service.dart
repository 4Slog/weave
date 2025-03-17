import 'dart:convert';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:kente_codeweaver/models/story_model.dart';
import 'package:kente_codeweaver/models/user_progress.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for managing story-related data persistence
class StoryMemoryService {
  final StorageService _storageService = StorageService();
  
  /// Save a user's progress with a story
  /// 
  /// Takes [userProgress] and updates it with the [story] data
  Future<void> saveStoryProgress(UserProgress userProgress, StoryModel story) async {
    try {
      // Convert to JSON and save
      final String jsonData = jsonEncode(userProgress.toJson());
      await _storageService.saveProgress(userProgress.userId, jsonData);
    } catch (e) {
      debugPrint('Error saving story progress: $e');
    }
  }
  
  /// Get a user's progress
  /// 
  /// Retrieves the [UserProgress] for the given [userId]
  Future<UserProgress?> getUserProgress(String userId) async {
    try {
      final String? savedData = await _storageService.getProgress(userId);
      if (savedData == null || savedData.isEmpty) {
        return null;
      }
      
      // Parse the saved data into a UserProgress object
      final Map<String, dynamic> jsonData = jsonDecode(savedData);
      return UserProgress.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      return null;
    }
  }
  
  /// Save story decisions
  /// 
  /// Saves the user's decisions for a specific story
  Future<void> saveStoryDecisions(String userId, String storyId, Map<String, String> decisions) async {
    try {
      // Get existing user progress
      UserProgress? userProgress = await getUserProgress(userId);
      
      // If no existing progress, create new
      if (userProgress == null) {
        userProgress = UserProgress(
          userId: userId,
          name: 'Learner',
        );
      }
      
      // Add story decision and save
      final updatedProgress = userProgress.addStoryDecision(storyId, decisions);
      await saveStoryProgress(updatedProgress, null);
    } catch (e) {
      debugPrint('Error saving story decisions: $e');
    }
  }
  
  /// Get story decisions
  /// 
  /// Retrieves the decisions made by a user for a specific story
  Future<Map<String, String>> getStoryDecisions(String userId, String storyId) async {
    try {
      // Get user progress
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        return {};
      }
      
      // Return decisions for this story or empty map
      return userProgress.storyDecisions[storyId] ?? {};
    } catch (e) {
      debugPrint('Error getting story decisions: $e');
      return {};
    }
  }
  
  /// Mark a story as completed
  /// 
  /// Updates the user progress to mark a story as completed with metrics
  Future<void> saveCompletedStory(String userId, String storyId, Map<String, dynamic> metrics) async {
    try {
      // Get existing user progress
      UserProgress? userProgress = await getUserProgress(userId);
      
      // If no existing progress, create new
      if (userProgress == null) {
        userProgress = UserProgress(
          userId: userId,
          name: 'Learner',
        );
      }
      
      // Add completed story and save
      final updatedProgress = userProgress.addCompletedStory(storyId, metrics);
      await saveStoryProgress(updatedProgress, null);
    } catch (e) {
      debugPrint('Error saving completed story: $e');
    }
  }
  
  /// Check if a story is completed
  /// 
  /// Returns true if the story has been completed by the user
  Future<bool> isStoryCompleted(String userId, String storyId) async {
    try {
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        return false;
      }
      
      return userProgress.isStoryCompleted(storyId);
    } catch (e) {
      debugPrint('Error checking if story is completed: $e');
      return false;
    }
  }
  
  /// Get completed stories
  /// 
  /// Returns a list of story IDs that have been completed by the user
  Future<List<String>> getCompletedStories(String userId) async {
    try {
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        return [];
      }
      
      return userProgress.completedStories;
    } catch (e) {
      debugPrint('Error getting completed stories: $e');
      return [];
    }
  }
  
  /// Get story metrics
  /// 
  /// Retrieves the metrics for a specific completed story
  Future<Map<String, dynamic>> getStoryMetrics(String userId, String storyId) async {
    try {
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        return {};
      }
      
      return userProgress.storyMetrics[storyId] ?? {};
    } catch (e) {
      debugPrint('Error getting story metrics: $e');
      return {};
    }
  }
  
  /// Get narrative context
  /// 
  /// Retrieves the narrative context for personalized storytelling
  Future<Map<String, dynamic>> getNarrativeContext(String userId) async {
    try {
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        return {};
      }
      
      return userProgress.narrativeContext;
    } catch (e) {
      debugPrint('Error getting narrative context: $e');
      return {};
    }
  }
  
  /// Update narrative context
  /// 
  /// Updates the narrative context for a user with new values
  Future<void> updateNarrativeContext(String userId, Map<String, dynamic> newContext) async {
    try {
      // Get existing user progress
      UserProgress? userProgress = await getUserProgress(userId);
      
      // If no existing progress, create new
      if (userProgress == null) {
        userProgress = UserProgress(
          userId: userId,
          name: 'Learner',
        );
      }
      
      // Update context and save
      final updatedProgress = userProgress.updateNarrativeContext(newContext);
      await saveStoryProgress(updatedProgress, null);
    } catch (e) {
      debugPrint('Error updating narrative context: $e');
    }
  }
}