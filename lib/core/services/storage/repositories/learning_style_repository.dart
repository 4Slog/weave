import 'package:flutter/foundation.dart';
import '../../../models/education/learning_style_profile.dart';
import '../base_repository.dart';
import '../storage_strategy.dart';

/// Repository for managing learning style profiles.
/// 
/// This repository handles the storage and retrieval of user learning style profiles,
/// which contain information about users' preferred learning styles.
class LearningStyleRepository implements BaseRepository {
  final StorageStrategy _storage;
  static const String _profileKeyPrefix = 'learning_style_profile_';
  static const String _allProfilesKey = 'all_learning_style_profiles';
  
  /// Creates a new LearningStyleRepository.
  /// 
  /// [storage] is the storage strategy to use for data persistence.
  LearningStyleRepository(this._storage);
  
  @override
  StorageStrategy get storage => _storage;
  
  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }
  
  /// Save a learning style profile.
  /// 
  /// [profile] is the learning style profile to save.
  Future<void> saveProfile(LearningStyleProfile profile) async {
    final key = _profileKeyPrefix + profile.userId;
    await _storage.saveData(key, profile.toJson());
    
    // Update the list of all profiles
    await _updateProfilesList(profile.userId);
  }
  
  /// Get a learning style profile by user ID.
  /// 
  /// [userId] is the ID of the user whose profile to retrieve.
  /// Returns the profile if found, or null if not found.
  Future<LearningStyleProfile?> getProfile(String userId) async {
    final key = _profileKeyPrefix + userId;
    final data = await _storage.getData(key);
    
    if (data == null) return null;
    
    try {
      return LearningStyleProfile.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing learning style profile: $e');
      return null;
    }
  }
  
  /// Get all learning style profiles.
  /// 
  /// Returns a list of all learning style profiles.
  Future<List<LearningStyleProfile>> getAllProfiles() async {
    final userIds = await _getUserIds();
    final profiles = <LearningStyleProfile>[];
    
    for (final userId in userIds) {
      final profile = await getProfile(userId);
      if (profile != null) {
        profiles.add(profile);
      }
    }
    
    return profiles;
  }
  
  /// Get profiles by dominant learning style.
  /// 
  /// [style] is the dominant learning style to filter by.
  /// Returns a list of profiles with the specified dominant learning style.
  Future<List<LearningStyleProfile>> getProfilesByDominantStyle(LearningStyle style) async {
    final allProfiles = await getAllProfiles();
    return allProfiles.where((profile) => profile.dominantStyle == style).toList();
  }
  
  /// Get profiles by preference.
  /// 
  /// [preference] is the preference to filter by.
  /// Returns a list of profiles that have the specified preference enabled.
  Future<List<LearningStyleProfile>> getProfilesByPreference(String preference) async {
    final allProfiles = await getAllProfiles();
    return allProfiles.where((profile) => profile.hasPreference(preference)).toList();
  }
  
  /// Delete a learning style profile.
  /// 
  /// [userId] is the ID of the user whose profile to delete.
  Future<void> deleteProfile(String userId) async {
    final key = _profileKeyPrefix + userId;
    await _storage.removeData(key);
    
    // Update the list of all profiles
    await _removeFromProfilesList(userId);
  }
  
  /// Update a user's learning style scores.
  /// 
  /// [userId] is the ID of the user whose scores to update.
  /// [scores] is a map of learning styles to scores (0.0 to 1.0).
  /// Returns the updated profile.
  Future<LearningStyleProfile> updateLearningStyleScores(
    String userId, 
    Map<LearningStyle, double> scores
  ) async {
    // Get the existing profile or create a new one
    final existingProfile = await getProfile(userId);
    
    // Determine the dominant style
    LearningStyle dominantStyle = LearningStyle.multimodal;
    double maxScore = 0.0;
    
    scores.forEach((style, score) {
      if (score > maxScore) {
        maxScore = score;
        dominantStyle = style;
      }
    });
    
    // Create or update the profile
    final updatedProfile = existingProfile != null
        ? existingProfile.copyWith(
            scores: scores,
            dominantStyle: dominantStyle,
          )
        : LearningStyleProfile(
            userId: userId,
            dominantStyle: dominantStyle,
            scores: scores,
          );
    
    // Save the updated profile
    await saveProfile(updatedProfile);
    
    return updatedProfile;
  }
  
  /// Update a user's learning preferences.
  /// 
  /// [userId] is the ID of the user whose preferences to update.
  /// [preferences] is a map of preference names to boolean values.
  /// Returns the updated profile.
  Future<LearningStyleProfile> updateLearningPreferences(
    String userId, 
    Map<String, bool> preferences
  ) async {
    // Get the existing profile or create a new one
    final existingProfile = await getProfile(userId);
    
    if (existingProfile == null) {
      throw StateError('Cannot update preferences for non-existent profile');
    }
    
    // Create a new preferences map with the updated values
    final updatedPreferences = Map<String, bool>.from(existingProfile.preferences);
    updatedPreferences.addAll(preferences);
    
    // Create the updated profile
    final updatedProfile = existingProfile.copyWith(
      preferences: updatedPreferences,
    );
    
    // Save the updated profile
    await saveProfile(updatedProfile);
    
    return updatedProfile;
  }
  
  /// Detect a user's learning style based on interaction data.
  /// 
  /// [userId] is the ID of the user whose learning style to detect.
  /// [interactionData] is a map of interaction types to counts or durations.
  /// Returns the detected learning style profile.
  Future<LearningStyleProfile> detectLearningStyle(
    String userId, 
    Map<String, dynamic> interactionData
  ) async {
    // This is a simplified implementation of learning style detection
    // A more sophisticated approach would use machine learning or more complex heuristics
    
    // Initialize scores for each learning style
    final scores = <LearningStyle, double>{
      LearningStyle.visual: 0.0,
      LearningStyle.auditory: 0.0,
      LearningStyle.reading: 0.0,
      LearningStyle.kinesthetic: 0.0,
    };
    
    // Visual indicators
    final visualIndicators = [
      'diagram_views',
      'image_interactions',
      'visual_pattern_usage',
      'color_scheme_changes',
      'visual_elements_used',
    ];
    
    // Auditory indicators
    final auditoryIndicators = [
      'audio_playback_count',
      'narration_usage',
      'voice_command_usage',
      'audio_feedback_preference',
      'spoken_instructions_usage',
    ];
    
    // Reading indicators
    final readingIndicators = [
      'text_interaction_time',
      'documentation_views',
      'written_explanation_preference',
      'text_based_help_usage',
      'note_taking',
    ];
    
    // Kinesthetic indicators
    final kinestheticIndicators = [
      'drag_drop_count',
      'interactive_element_usage',
      'physical_interaction_time',
      'hands_on_activity_preference',
      'block_manipulation_count',
    ];
    
    // Calculate scores based on interaction data
    double totalScore = 0.0;
    
    // Process visual indicators
    for (final indicator in visualIndicators) {
      if (interactionData.containsKey(indicator)) {
        final value = _getNumericValue(interactionData[indicator]);
        scores[LearningStyle.visual] = (scores[LearningStyle.visual] ?? 0.0) + value;
        totalScore += value;
      }
    }
    
    // Process auditory indicators
    for (final indicator in auditoryIndicators) {
      if (interactionData.containsKey(indicator)) {
        final value = _getNumericValue(interactionData[indicator]);
        scores[LearningStyle.auditory] = (scores[LearningStyle.auditory] ?? 0.0) + value;
        totalScore += value;
      }
    }
    
    // Process reading indicators
    for (final indicator in readingIndicators) {
      if (interactionData.containsKey(indicator)) {
        final value = _getNumericValue(interactionData[indicator]);
        scores[LearningStyle.reading] = (scores[LearningStyle.reading] ?? 0.0) + value;
        totalScore += value;
      }
    }
    
    // Process kinesthetic indicators
    for (final indicator in kinestheticIndicators) {
      if (interactionData.containsKey(indicator)) {
        final value = _getNumericValue(interactionData[indicator]);
        scores[LearningStyle.kinesthetic] = (scores[LearningStyle.kinesthetic] ?? 0.0) + value;
        totalScore += value;
      }
    }
    
    // Normalize scores
    if (totalScore > 0) {
      scores.forEach((style, score) {
        scores[style] = score / totalScore;
      });
    } else {
      // If no data, default to equal distribution
      scores.forEach((style, _) {
        scores[style] = 0.25;
      });
    }
    
    // Determine dominant style
    LearningStyle dominantStyle = LearningStyle.multimodal;
    double maxScore = 0.0;
    
    scores.forEach((style, score) {
      if (score > maxScore) {
        maxScore = score;
        dominantStyle = style;
      }
    });
    
    // If no clear dominant style, use multimodal
    if (maxScore < 0.4) {
      dominantStyle = LearningStyle.multimodal;
    }
    
    // Get the existing profile or create a new one
    final existingProfile = await getProfile(userId);
    
    // Create or update the profile
    final updatedProfile = existingProfile != null
        ? existingProfile.copyWith(
            scores: scores,
            dominantStyle: dominantStyle,
          )
        : LearningStyleProfile(
            userId: userId,
            dominantStyle: dominantStyle,
            scores: scores,
          );
    
    // Save the updated profile
    await saveProfile(updatedProfile);
    
    return updatedProfile;
  }
  
  /// Helper method to get a numeric value from an interaction data value.
  double _getNumericValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is bool) {
      return value ? 1.0 : 0.0;
    } else if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    } else {
      return 0.0;
    }
  }
  
  /// Helper method to update the list of all profiles.
  Future<void> _updateProfilesList(String userId) async {
    final userIds = await _getUserIds();
    
    if (!userIds.contains(userId)) {
      userIds.add(userId);
      await _storage.saveData(_allProfilesKey, userIds);
    }
  }
  
  /// Helper method to remove a profile from the list of all profiles.
  Future<void> _removeFromProfilesList(String userId) async {
    final userIds = await _getUserIds();
    
    if (userIds.contains(userId)) {
      userIds.remove(userId);
      await _storage.saveData(_allProfilesKey, userIds);
    }
  }
  
  /// Helper method to get the list of all user IDs.
  Future<List<String>> _getUserIds() async {
    final data = await _storage.getData(_allProfilesKey);
    
    if (data == null) return [];
    
    try {
      return List<String>.from(data);
    } catch (e) {
      debugPrint('Error parsing learning style profiles list: $e');
      return [];
    }
  }
}
