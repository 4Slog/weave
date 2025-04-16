import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../base_repository.dart';
import '../storage_strategy.dart';
import '../../../../features/learning/models/user_progress.dart' as app_models;

/// Repository for managing user data.
///
/// This repository handles the storage and retrieval of user-related data,
/// such as user progress, preferences, and settings.
class UserDataRepository implements BaseRepository {
  final StorageStrategy _storage;
  static const String _progressKeyPrefix = 'user_progress_';
  static const String _preferencesKeyPrefix = 'user_preferences_';
  static const String _settingsKeyPrefix = 'user_settings_';

  /// Creates a new UserDataRepository.
  ///
  /// [storage] is the storage strategy to use for data persistence.
  UserDataRepository(this._storage);

  @override
  StorageStrategy get storage => _storage;

  @override
  Future<void> initialize() async {
    await _storage.initialize();
  }

  /// Save user progress data.
  ///
  /// [progress] is the user progress object to save.
  /// This method accepts both the repository UserProgress model and the app UserProgress model.
  Future<void> saveUserProgress(dynamic progress) async {
    // Convert app UserProgress to repository UserProgress if needed
    UserProgress repoProgress;

    if (progress is app_models.UserProgress) {
      // Convert from app model to repository model
      repoProgress = _convertToRepositoryUserProgress(progress);
    } else if (progress is UserProgress) {
      // Already in repository format
      repoProgress = progress;
    } else {
      throw ArgumentError('Invalid progress type: ${progress.runtimeType}');
    }

    final key = _progressKeyPrefix + repoProgress.userId;
    await _storage.saveData(key, repoProgress.toJson());
  }

  /// Convert from app UserProgress model to repository UserProgress model
  UserProgress _convertToRepositoryUserProgress(app_models.UserProgress appProgress) {
    // Extract concept mastery from skill proficiency
    Map<String, double> conceptMastery = {};
    if (appProgress.skillProficiency.isNotEmpty) {
      conceptMastery = Map<String, double>.from(appProgress.skillProficiency);
    }

    // Calculate total points (simplified example)
    int totalPoints = appProgress.experiencePoints;

    return UserProgress(
      userId: appProgress.userId,
      completedChallenges: appProgress.completedChallenges,
      completedStories: appProgress.completedStories,
      challengeAttempts: appProgress.challengeAttempts,
      conceptMastery: conceptMastery,
      totalPoints: totalPoints,
      lastUpdated: appProgress.lastActiveDate,
    );
  }

  /// Get user progress data.
  ///
  /// [userId] is the ID of the user whose progress to retrieve.
  /// Returns the user progress if found, or null if not found.
  Future<UserProgress?> getUserProgress(String userId) async {
    final key = _progressKeyPrefix + userId;
    final data = await _storage.getData(key);

    if (data == null) return null;

    try {
      return UserProgress.fromJson(data);
    } catch (e) {
      debugPrint('Error parsing user progress: $e');
      return null;
    }
  }

  /// Save user preferences.
  ///
  /// [userId] is the ID of the user whose preferences to save.
  /// [preferences] is the preferences data to save.
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    final key = _preferencesKeyPrefix + userId;
    await _storage.saveData(key, preferences);
  }

  /// Get user preferences.
  ///
  /// [userId] is the ID of the user whose preferences to retrieve.
  /// Returns the user preferences if found, or an empty map if not found.
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    final key = _preferencesKeyPrefix + userId;
    final data = await _storage.getData(key);

    if (data == null) return {};

    try {
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Error parsing user preferences: $e');
      return {};
    }
  }

  /// Save user settings.
  ///
  /// [userId] is the ID of the user whose settings to save.
  /// [settings] is the settings data to save.
  Future<void> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    final key = _settingsKeyPrefix + userId;
    await _storage.saveData(key, settings);
  }

  /// Get user settings.
  ///
  /// [userId] is the ID of the user whose settings to retrieve.
  /// Returns the user settings if found, or an empty map if not found.
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    final key = _settingsKeyPrefix + userId;
    final data = await _storage.getData(key);

    if (data == null) return {};

    try {
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Error parsing user settings: $e');
      return {};
    }
  }

  /// Delete all data for a user.
  ///
  /// [userId] is the ID of the user whose data to delete.
  Future<void> deleteUserData(String userId) async {
    final progressKey = _progressKeyPrefix + userId;
    final preferencesKey = _preferencesKeyPrefix + userId;
    final settingsKey = _settingsKeyPrefix + userId;

    await _storage.removeData(progressKey);
    await _storage.removeData(preferencesKey);
    await _storage.removeData(settingsKey);
  }
}

/// Model class for user progress data.
class UserProgress {
  final String userId;
  final List<String> completedChallenges;
  final List<String> completedStories;
  final Map<String, int> challengeAttempts;
  final Map<String, double> conceptMastery;
  final int totalPoints;
  final DateTime lastUpdated;

  UserProgress({
    required this.userId,
    this.completedChallenges = const [],
    this.completedStories = const [],
    this.challengeAttempts = const {},
    this.conceptMastery = const {},
    this.totalPoints = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Create a copy of this UserProgress with some fields replaced.
  UserProgress copyWith({
    String? userId,
    List<String>? completedChallenges,
    List<String>? completedStories,
    Map<String, int>? challengeAttempts,
    Map<String, double>? conceptMastery,
    int? totalPoints,
    DateTime? lastUpdated,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      completedStories: completedStories ?? this.completedStories,
      challengeAttempts: challengeAttempts ?? this.challengeAttempts,
      conceptMastery: conceptMastery ?? this.conceptMastery,
      totalPoints: totalPoints ?? this.totalPoints,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Convert this UserProgress to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'completedChallenges': completedChallenges,
      'completedStories': completedStories,
      'challengeAttempts': challengeAttempts,
      'conceptMastery': conceptMastery,
      'totalPoints': totalPoints,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a UserProgress from a JSON map.
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'],
      completedChallenges: List<String>.from(json['completedChallenges'] ?? []),
      completedStories: List<String>.from(json['completedStories'] ?? []),
      challengeAttempts: (json['challengeAttempts'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toInt())
      ) ?? {},
      conceptMastery: (json['conceptMastery'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble())
      ) ?? {},
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}
