import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/badge_model.dart';
import 'package:kente_codeweaver/services/badge_service.dart';
import 'dart:async';

/// Provider for badge state management
class BadgeProvider with ChangeNotifier {
  final BadgeService _badgeService = BadgeService();
  
  // State variables
  List<BadgeModel> _availableBadges = [];
  List<BadgeModel> _earnedBadges = [];
  List<BadgeModel> _newBadges = [];
  String? _currentUserId;
  bool _isLoading = false;
  bool _isInitialized = false;
  StreamSubscription? _badgeEarnedSubscription;
  
  // Getters
  List<BadgeModel> get availableBadges => _availableBadges;
  List<BadgeModel> get earnedBadges => _earnedBadges;
  List<BadgeModel> get newBadges => _newBadges;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the provider with a user ID
  Future<void> initialize(String userId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _currentUserId = userId;
    notifyListeners();
    
    try {
      // Get all available badges
      _availableBadges = await _badgeService.getAvailableBadges();
      
      // Get user's earned badges
      _earnedBadges = await _badgeService.getUserBadges(userId);
      
      // Listen for new badges
      _badgeEarnedSubscription = _badgeService.badgeEarned.listen(_onBadgeEarned);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing BadgeProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Check for new badges
  Future<void> checkForNewBadges() async {
    if (_isLoading || _currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check for new badges
      final newlyEarnedBadges = await _badgeService.checkForNewBadges(_currentUserId!);
      
      if (newlyEarnedBadges.isNotEmpty) {
        // Update earned badges
        _earnedBadges = await _badgeService.getUserBadges(_currentUserId!);
        
        // Add to new badges
        _newBadges.addAll(newlyEarnedBadges);
      }
    } catch (e) {
      debugPrint('Error checking for new badges: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Acknowledge new badges (mark as seen)
  void acknowledgeNewBadges() {
    _newBadges.clear();
    notifyListeners();
  }
  
  /// Handler for badge earned events
  void _onBadgeEarned(BadgeModel badge) {
    // Add to earned badges if not already there
    if (!_earnedBadges.any((b) => b.id == badge.id)) {
      _earnedBadges.add(badge);
    }
    
    // Add to new badges
    if (!_newBadges.any((b) => b.id == badge.id)) {
      _newBadges.add(badge);
    }
    
    notifyListeners();
  }
  
  /// Award a specific badge (for testing/admin purposes)
  Future<void> awardBadge(String badgeId) async {
    if (_currentUserId == null) return;
    
    await _badgeService.awardBadge(_currentUserId!, badgeId);
    
    // Refresh earned badges
    _earnedBadges = await _badgeService.getUserBadges(_currentUserId!);
    notifyListeners();
  }
  
  /// Get badge details by ID
  Future<BadgeModel?> getBadgeById(String badgeId) async {
    return await _badgeService.getBadgeById(badgeId);
  }
  
  @override
  void dispose() {
    _badgeEarnedSubscription?.cancel();
    super.dispose();
  }
}
