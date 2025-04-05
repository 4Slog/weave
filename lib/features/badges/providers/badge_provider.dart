import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';
import 'package:kente_codeweaver/features/badges/services/badge_service.dart';

/// Provider for badge-related functionality
class BadgeProvider with ChangeNotifier {
  final BadgeService _badgeService = BadgeService();

  /// List of all available badges
  List<BadgeModel> _badges = [];

  /// List of earned badges for the current user
  List<BadgeModel> _earnedBadges = [];

  /// User ID for the current user
  String? _userId;

  /// Flag to track initialization status
  bool _isInitialized = false;

  /// Get all available badges
  List<BadgeModel> get badges => _badges;

  /// Get earned badges for the current user
  List<BadgeModel> get earnedBadges => _earnedBadges;

  /// Check if the provider has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the provider with user data
  Future<void> initialize(String userId) async {
    _userId = userId;

    try {
      // Load all available badges
      _badges = await _badgeService.getAvailableBadges();

      // Load earned badges for this user
      _earnedBadges = await _badgeService.getUserBadges(userId);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing BadgeProvider: $e');
      _isInitialized = false;
    }
  }

  /// Check if a badge has been earned
  bool hasBadge(String badgeId) {
    return _earnedBadges.any((badge) => badge.id == badgeId);
  }

  /// Award a badge to the user
  Future<bool> awardBadge(String badgeId) async {
    if (_userId == null) return false;

    try {
      // Check if badge already earned
      if (hasBadge(badgeId)) return true;

      // Find the badge in available badges
      final badge = _badges.firstWhere(
        (b) => b.id == badgeId,
        orElse: () => throw Exception('Badge not found: $badgeId'),
      );

      // Award the badge
      await _badgeService.awardBadge(_userId!, badgeId);

      // Add to earned badges
      _earnedBadges.add(badge);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error awarding badge: $e');
      return false;
    }
  }

  /// Get a badge by ID
  BadgeModel? getBadge(String badgeId) {
    try {
      return _badges.firstWhere((b) => b.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  /// Get all badges for a specific category (using tier as category)
  List<BadgeModel> getBadgesByCategory(String category) {
    // Convert category to tier if possible
    int? tier = int.tryParse(category);
    if (tier != null) {
      return _badges.where((badge) => badge.tier == tier).toList();
    }
    // If category is not a number, return all badges
    return _badges;
  }

  /// Get earned badges for a specific category (using tier as category)
  List<BadgeModel> getEarnedBadgesByCategory(String category) {
    // Convert category to tier if possible
    int? tier = int.tryParse(category);
    if (tier != null) {
      return _earnedBadges.where((badge) => badge.tier == tier).toList();
    }
    // If category is not a number, return all earned badges
    return _earnedBadges;
  }

  /// Get the progress towards a specific badge (0.0 to 1.0)
  Future<double> getBadgeProgress(String badgeId) async {
    if (_userId == null) return 0.0;

    try {
      // This is a simplified implementation since BadgeService doesn't have this method
      // In a real app, you would calculate this based on the badge requirements
      final badge = getBadge(badgeId);
      if (badge == null) return 0.0;

      // If the badge is already earned, return 1.0
      if (hasBadge(badgeId)) return 1.0;

      // Otherwise return a random value between 0.0 and 0.9
      return 0.5; // Simplified implementation
    } catch (e) {
      debugPrint('Error getting badge progress: $e');
      return 0.0;
    }
  }

  /// Refresh the list of earned badges
  Future<void> refreshEarnedBadges() async {
    if (_userId == null) return;

    try {
      _earnedBadges = await _badgeService.getUserBadges(_userId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing earned badges: $e');
    }
  }
}
