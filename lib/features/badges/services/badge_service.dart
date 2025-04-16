import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/services/adaptive_learning_service.dart';
import 'package:kente_codeweaver/core/services/storage/storage_service.dart';

/// Storage service extensions for badge functionality
extension BadgeStorageExtension on StorageService {
  /// Get the earned badges for a user
  Future<List<String>> getEarnedBadges(String userId) async {
    // This would normally use actual storage, but for now just return mock data
    return ['pattern_creator', 'storyteller']; // Mock value for demonstration
  }

  /// Save earned badges for a user
  Future<void> saveEarnedBadges(String userId, List<String> badgeIds) async {
    // This would normally save to actual storage
    // For now, we just print for demonstration
    debugPrint('Saved badges for $userId: $badgeIds');
  }
}

/// Extension of the AdaptiveLearningService for badge integration
extension BadgeAdaptiveLearningExtension on AdaptiveLearningService {
  /// Get user's skill proficiencies
  Future<Map<String, double>> getUserSkills(String userId) async {
    final progress = await getUserProgress(userId);
    if (progress == null) {
      return {};
    }

    // Convert the skill levels to double values
    Map<String, double> skillValues = {};
    progress.skills.forEach((key, value) {
      switch (value) {
        case SkillLevel.novice:
          skillValues[key.toString().split('.').last] = 0.1;
          break;
        case SkillLevel.beginner:
          skillValues[key.toString().split('.').last] = 0.3;
          break;
        case SkillLevel.intermediate:
          skillValues[key.toString().split('.').last] = 0.7;
          break;
        case SkillLevel.advanced:
          skillValues[key.toString().split('.').last] = 1.0;
          break;
      }
    });

    // Add some mock values for other skills used in badge requirements
    skillValues['loops'] = 0.8;
    skillValues['pattern'] = 0.6;
    skillValues['story'] = 0.7;

    return skillValues;
  }
}

/// Manage achievements
class BadgeService {
  final StorageService _storageService;
  final AdaptiveLearningService _learningService;

  // Stream controller for badge earned events
  final _badgeEarnedController = StreamController<BadgeModel>.broadcast();
  Stream<BadgeModel> get badgeEarned => _badgeEarnedController.stream;

  BadgeService({
    StorageService? storageService,
    AdaptiveLearningService? learningService,
  }) :
    _storageService = storageService ?? StorageService(),
    _learningService = learningService ?? AdaptiveLearningService();

  /// Get all available badges
  Future<List<BadgeModel>> getAvailableBadges() async {
    // In a real implementation, these would be loaded from a JSON file
    return [
      BadgeModel(
        id: 'loops_master',
        name: 'Loop Master',
        description: 'Successfully completed 5 loop challenges',
        imageAssetPath: 'assets/images/badges/loop_master.png',
        requiredSkills: {'loops': 0.7},
        tier: 2,
      ),
      BadgeModel(
        id: 'pattern_creator',
        name: 'Pattern Creator',
        description: 'Created your first Kente pattern',
        imageAssetPath: 'assets/images/badges/pattern_creator.png',
        requiredSkills: {'pattern': 0.5},
        tier: 1,
      ),
      BadgeModel(
        id: 'storyteller',
        name: 'Storyteller',
        description: 'Completed 3 stories',
        imageAssetPath: 'assets/images/badges/storyteller.png',
        requiredSkills: {'story': 0.6},
        tier: 1,
      ),
      // Add more badges as needed
    ];
  }

  /// Check for newly earned badges
  Future<List<BadgeModel>> checkForNewBadges(String userId) async {
    // Get user's current skills
    final userSkills = await _learningService.getUserSkills(userId);

    // Get user's already earned badges
    final earnedBadgeIds = await _storageService.getEarnedBadges(userId);

    // Get all available badges
    final allBadges = await getAvailableBadges();

    // Find badges that the user qualifies for but hasn't earned yet
    final newBadges = allBadges.where((badge) {
      // Skip if already earned
      if (earnedBadgeIds.contains(badge.id)) return false;

      // Check if user meets all skill requirements
      return badge.requiredSkills.entries.every((entry) {
        final skillName = entry.key;
        final requiredProficiency = entry.value;
        final userProficiency = userSkills[skillName] ?? 0.0;
        return userProficiency >= requiredProficiency;
      });
    }).toList();

    // If new badges earned, save them and play sound
    if (newBadges.isNotEmpty) {
      final allEarnedBadgeIds = [
        ...earnedBadgeIds,
        ...newBadges.map((b) => b.id),
      ];

      await _storageService.saveEarnedBadges(userId, allEarnedBadgeIds);

      // Notify subscribers about new badges
      for (final badge in newBadges) {
        _badgeEarnedController.add(badge);
      }
    }

    return newBadges;
  }

  /// Get user's earned badges
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    final earnedBadgeIds = await _storageService.getEarnedBadges(userId);
    final allBadges = await getAvailableBadges();

    return allBadges.where((badge) => earnedBadgeIds.contains(badge.id)).toList();
  }

  /// Award a specific badge (for testing/admin purposes)
  Future<void> awardBadge(String userId, String badgeId) async {
    final earnedBadgeIds = await _storageService.getEarnedBadges(userId);

    // Skip if already earned
    if (earnedBadgeIds.contains(badgeId)) {
      return;
    }

    // Add to earned badges
    final updatedBadgeIds = [...earnedBadgeIds, badgeId];
    await _storageService.saveEarnedBadges(userId, updatedBadgeIds);

    // Get badge details and notify subscribers
    final allBadges = await getAvailableBadges();
    final badge = allBadges.firstWhere(
      (b) => b.id == badgeId,
      orElse: () => throw Exception('Badge $badgeId not found')
    );

    _badgeEarnedController.add(badge);
  }

  /// Get badge details by ID
  Future<BadgeModel?> getBadgeById(String badgeId) async {
    try {
      final badges = await getAvailableBadges();
      return badges.firstWhere((b) => b.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _badgeEarnedController.close();
  }
}
