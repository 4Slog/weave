import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/pattern_model.dart';
import 'package:kente_codeweaver/models/block_collection.dart';
import 'package:kente_codeweaver/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Provider for pattern operations and state management
class PatternProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = Uuid();
  
  // Current state
  bool _isLoading = false;
  String? _currentUserId;
  List<PatternModel> _userPatterns = [];
  PatternModel? _currentPattern;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  List<PatternModel> get userPatterns => _userPatterns;
  PatternModel? get currentPattern => _currentPattern;
  
  /// Initialize provider with user ID
  Future<void> initialize(String userId) async {
    _isLoading = true;
    _currentUserId = userId;
    notifyListeners();
    
    try {
      await _storageService.initialize();
      await loadUserPatterns();
    } catch (e) {
      debugPrint('Error initializing PatternProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load all patterns for current user
  Future<void> loadUserPatterns() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _userPatterns = await _storageService.getUserPatterns(_currentUserId!);
      
      // Sort by most recently modified
      _userPatterns.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    } catch (e) {
      debugPrint('Error loading user patterns: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Set the current pattern being worked on
  void setCurrentPattern(PatternModel pattern) {
    _currentPattern = pattern;
    notifyListeners();
  }
  
  /// Create a new pattern
  Future<PatternModel> createPattern({
    required String name,
    required BlockCollection blockCollection,
    String? description,
    List<String>? tags,
    String? challengeId,
    Map<String, dynamic>? culturalContext,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create new pattern
      final pattern = PatternModel(
        id: _uuid.v4(),
        userId: _currentUserId!,
        name: name,
        description: description,
        tags: tags,
        challengeId: challengeId,
        culturalContext: culturalContext,
        blockCollection: blockCollection,
      );
      
      // Save to storage
      await _storageService.savePattern(pattern);
      
      // Add to local list and sort
      _userPatterns.add(pattern);
      _userPatterns.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      
      // Set as current pattern
      _currentPattern = pattern;
      
      return pattern;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update an existing pattern
  Future<void> updatePattern({
    required String patternId,
    String? name,
    String? description,
    List<String>? tags,
    BlockCollection? blockCollection,
    Map<String, dynamic>? culturalContext,
    double? rating,
    bool? isShared,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Find pattern in local list
      final index = _userPatterns.indexWhere((p) => p.id == patternId);
      if (index < 0) {
        throw Exception('Pattern not found');
      }
      
      // Create updated pattern
      final updatedPattern = _userPatterns[index].copyWith(
        name: name,
        description: description,
        tags: tags,
        blockCollection: blockCollection,
        culturalContext: culturalContext,
        rating: rating,
        isShared: isShared,
      );
      
      // Save to storage
      await _storageService.savePattern(updatedPattern);
      
      // Update local list
      _userPatterns[index] = updatedPattern;
      
      // Update current pattern if it's the one being edited
      if (_currentPattern?.id == patternId) {
        _currentPattern = updatedPattern;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Delete a pattern
  Future<void> deletePattern(String patternId) async {
    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Delete from storage
      await _storageService.deletePattern(_currentUserId!, patternId);
      
      // Remove from local list
      _userPatterns.removeWhere((p) => p.id == patternId);
      
      // Clear current pattern if it was deleted
      if (_currentPattern?.id == patternId) {
        _currentPattern = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get a pattern by ID
  Future<PatternModel?> getPatternById(String patternId) async {
    // First check local list
    final pattern = _userPatterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => throw Exception('Pattern not found'),
    );
    
    if (pattern != null) {
      return pattern;
    }
    
    // If not found locally, try to load from storage
    if (_currentUserId != null) {
      return _storageService.getPattern(_currentUserId!, patternId);
    }
    
    return null;
  }
  
  /// Get patterns filtered by tags
  List<PatternModel> getPatternsByTags(List<String> tags) {
    return _userPatterns.where((p) {
      return p.tags.any((tag) => tags.contains(tag));
    }).toList();
  }
  
  /// Get patterns by difficulty level
  List<PatternModel> getPatternsByDifficulty(int level) {
    return _userPatterns.where((p) => p.difficultyLevel == level).toList();
  }
  
  /// Get shared patterns
  List<PatternModel> getSharedPatterns() {
    return _userPatterns.where((p) => p.isShared).toList();
  }
  
  /// Update pattern rating
  Future<void> updatePatternRating(String patternId, double rating) async {
    final index = _userPatterns.indexWhere((p) => p.id == patternId);
    if (index < 0) return;
    
    await updatePattern(
      patternId: patternId,
      rating: rating,
    );
  }
  
  /// Get pattern count
  int get patternCount =>