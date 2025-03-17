import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/models/badge_model.dart';

/// Represents a user's progress in the Kente Codeweaver application
class UserProgress {
  /// Unique identifier for the user
  final String userId;
  
  /// Name of the user (if provided)
  final String name;
  
  /// List of completed story IDs
  final List<String> completedStories;
  
  /// Badges earned by the user
  final List<Badge> earnedBadges;
  
  /// Map of story IDs to completion metrics
  final Map<String, Map<String, dynamic>> storyMetrics;
  
  /// Map of story IDs to user decisions
  final Map<String, Map<String, String>> storyDecisions;
  
  /// Adaptive learning metrics
  final Map<String, dynamic> learningMetrics;
  
  /// Narrative context for personalized stories
  final Map<String, dynamic> narrativeContext;
  
  /// Create a user progress object
  UserProgress({
    required this.userId,
    required this.name,
    this.completedStories = const [],
    this.earnedBadges = const [],
    this.storyMetrics = const {},
    this.storyDecisions = const {},
    this.learningMetrics = const {},
    this.narrativeContext = const {},
  });
  
  /// Create a copy with updated fields
  UserProgress copyWith({
    String? userId,
    String? name,
    List<String>? completedStories,
    List<Badge>? earnedBadges,
    Map<String, Map<String, dynamic>>? storyMetrics,
    Map<String, Map<String, String>>? storyDecisions,
    Map<String, dynamic>? learningMetrics,
    Map<String, dynamic>? narrativeContext,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      completedStories: completedStories ?? this.completedStories,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      storyMetrics: storyMetrics ?? this.storyMetrics,
      storyDecisions: storyDecisions ?? this.storyDecisions,
      learningMetrics: learningMetrics ?? this.learningMetrics,
      narrativeContext: narrativeContext ?? this.narrativeContext,
    );
  }
  
  /// Create from JSON
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    // Parse badges
    final List<Badge> badges = [];
    if (json['earnedBadges'] != null) {
      for (final badgeJson in (json['earnedBadges'] as List<dynamic>)) {
        badges.add(Badge.fromJson(badgeJson));
      }
    }
    
    // Parse story metrics
    final Map<String, Map<String, dynamic>> metrics = {};
    if (json['storyMetrics'] != null) {
      final metricsMap = json['storyMetrics'] as Map<String, dynamic>;
      metricsMap.forEach((storyId, storyMetric) {
        metrics[storyId] = Map<String, dynamic>.from(storyMetric);
      });
    }
    
    // Parse story decisions
    final Map<String, Map<String, String>> decisions = {};
    if (json['storyDecisions'] != null) {
      final decisionsMap = json['storyDecisions'] as Map<String, dynamic>;
      decisionsMap.forEach((storyId, storyDecision) {
        decisions[storyId] = Map<String, String>.from(storyDecision);
      });
    }
    
    return UserProgress(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Learner',
      completedStories: json['completedStories'] != null 
          ? List<String>.from(json['completedStories']) 
          : [],
      earnedBadges: badges,
      storyMetrics: metrics,
      storyDecisions: decisions,
      learningMetrics: json['learningMetrics'] != null 
          ? Map<String, dynamic>.from(json['learningMetrics']) 
          : {},
      narrativeContext: json['narrativeContext'] != null 
          ? Map<String, dynamic>.from(json['narrativeContext']) 
          : {},
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'completedStories': completedStories,
      'earnedBadges': earnedBadges.map((badge) => badge.toJson()).toList(),
      'storyMetrics': storyMetrics,
      'storyDecisions': storyDecisions,
      'learningMetrics': learningMetrics,
      'narrativeContext': narrativeContext,
    };
  }
  
  /// Helper method to add a completed story
  UserProgress addCompletedStory(String storyId, Map<String, dynamic> metrics) {
    final newCompletedStories = List<String>.from(completedStories);
    if (!newCompletedStories.contains(storyId)) {
      newCompletedStories.add(storyId);
    }
    
    final newStoryMetrics = Map<String, Map<String, dynamic>>.from(storyMetrics);
    newStoryMetrics[storyId] = metrics;
    
    return copyWith(
      completedStories: newCompletedStories,
      storyMetrics: newStoryMetrics,
    );
  }
  
  /// Helper method to add a story decision
  UserProgress addStoryDecision(String storyId, Map<String, String> decisions) {
    final newStoryDecisions = Map<String, Map<String, String>>.from(storyDecisions);
    newStoryDecisions[storyId] = decisions;
    
    return copyWith(
      storyDecisions: newStoryDecisions,
    );
  }
  
  /// Helper method to add a badge
  UserProgress addBadge(Badge badge) {
    final newBadges = List<Badge>.from(earnedBadges);
    
    // Check if badge already exists
    if (!newBadges.any((existing) => existing.id == badge.id)) {
      newBadges.add(badge);
    }
    
    return copyWith(earnedBadges: newBadges);
  }
  
  /// Update narrative context
  UserProgress updateNarrativeContext(Map<String, dynamic> newContext) {
    final updatedContext = Map<String, dynamic>.from(narrativeContext)
      ..addAll(newContext);
    
    return copyWith(narrativeContext: updatedContext);
  }
  
  /// Update learning metrics
  UserProgress updateLearningMetrics(Map<String, dynamic> newMetrics) {
    final updatedMetrics = Map<String, dynamic>.from(learningMetrics)
      ..addAll(newMetrics);
    
    return copyWith(learningMetrics: updatedMetrics);
  }
  
  /// Check if a story is completed
  bool isStoryCompleted(String storyId) {
    return completedStories.contains(storyId);
  }
  
  /// Get the number of completed stories
  int get completedStoriesCount => completedStories.length;
  
  /// Get the number of earned badges
  int get earnedBadgesCount => earnedBadges.length;
}