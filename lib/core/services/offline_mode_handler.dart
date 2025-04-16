import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/enhanced_storage_service.dart';
import 'package:kente_codeweaver/core/services/synchronization_service.dart';
import 'package:kente_codeweaver/core/services/ai_content_manager.dart';
import 'package:kente_codeweaver/core/utils/connectivity_utils.dart';
import 'package:kente_codeweaver/core/services/service_provider.dart';

/// Service for handling offline mode and data synchronization
class OfflineModeHandler {
  // Singleton implementation
  static final OfflineModeHandler _instance = OfflineModeHandler._internal();

  factory OfflineModeHandler() {
    return _instance;
  }

  OfflineModeHandler._internal();

  // Dependencies
  late final EnhancedStorageService _storageService;
  late final SynchronizationService _syncService;
  late final AIContentManager _aiContentManager;
  late final ConnectivityUtils _connectivityUtils;

  // Offline mode state
  bool _isInitialized = false;
  bool _isOffline = false;
  bool _isInOfflineMode = false;

  // Stream controller for offline mode changes
  final StreamController<bool> _offlineModeController = StreamController<bool>.broadcast();

  // Offline mode listeners
  final List<Function(bool)> _offlineModeListeners = [];

  /// Stream of offline mode changes
  Stream<bool> get offlineModeStream => _offlineModeController.stream;

  /// Current offline mode state
  bool get isOffline => _isOffline;

  /// Whether the app is in offline mode
  bool get isInOfflineMode => _isInOfflineMode;

  /// Initialize the offline mode handler
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get dependencies
      _storageService = ServiceProvider.get<EnhancedStorageService>();
      _syncService = ServiceProvider.get<SynchronizationService>();
      _aiContentManager = ServiceProvider.get<AIContentManager>();
      _connectivityUtils = ServiceProvider.get<ConnectivityUtils>();

      // Listen for connectivity changes
      _connectivityUtils.connectivityStream.listen(_handleConnectivityChange);

      // Check initial connectivity
      _isOffline = !await _connectivityUtils.checkConnectivity();
      _isInOfflineMode = _isOffline;

      _isInitialized = true;
      debugPrint('OfflineModeHandler initialized successfully');
      debugPrint('Initial offline state: ${_isOffline ? 'offline' : 'online'}');
    } catch (e) {
      debugPrint('Failed to initialize OfflineModeHandler: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _offlineModeController.close();
    _offlineModeListeners.clear();
  }

  /// Add a listener for offline mode changes
  void addOfflineModeListener(Function(bool) listener) {
    _offlineModeListeners.add(listener);
  }

  /// Remove a listener for offline mode changes
  void removeOfflineModeListener(Function(bool) listener) {
    _offlineModeListeners.remove(listener);
  }

  /// Enter offline mode manually
  void enterOfflineMode() {
    if (_isInOfflineMode) return;

    _isInOfflineMode = true;
    _notifyOfflineModeChange();

    debugPrint('Manually entered offline mode');
  }

  /// Exit offline mode manually
  Future<void> exitOfflineMode() async {
    if (!_isInOfflineMode) return;

    // Check if we're actually online
    final isOnline = await _connectivityUtils.checkConnectivity();
    if (!isOnline) {
      debugPrint('Cannot exit offline mode: device is offline');
      return;
    }

    _isInOfflineMode = false;
    _notifyOfflineModeChange();

    // Trigger synchronization
    await _syncService.synchronize();

    debugPrint('Exited offline mode');
  }

  /// Check if a feature is available in offline mode
  bool isFeatureAvailableOffline(String featureId) {
    // Define features that are available offline
    final offlineFeatures = {
      'block_workspace': true,
      'story_viewer': true,
      'challenge_basic': true,
      'pattern_viewer': true,
      'user_progress': true,
      'badges': true,
      'settings': true,

      // Features that require online connectivity
      'ai_story_generation': false,
      'ai_hint_generation': false,
      'ai_feedback': false,
      'leaderboard': false,
      'content_download': false,
    };

    return offlineFeatures[featureId] ?? false;
  }

  /// Prepare for offline mode by caching essential data
  Future<void> prepareForOfflineMode() async {
    await _ensureInitialized();

    debugPrint('Preparing for offline mode...');

    try {
      // Cache user progress
      await _cacheUserProgress();

      // Cache essential stories
      await _cacheEssentialStories();

      // Cache challenges
      await _cacheChallenges();

      // Cache cultural data
      await _cacheCulturalData();

      debugPrint('Offline mode preparation complete');
    } catch (e) {
      debugPrint('Error preparing for offline mode: $e');
    }
  }

  /// Get offline mode status for a specific feature
  Map<String, dynamic> getOfflineModeStatus(String featureId) {
    final isAvailable = isFeatureAvailableOffline(featureId);

    return {
      'feature_id': featureId,
      'is_available_offline': isAvailable,
      'is_in_offline_mode': _isInOfflineMode,
      'is_device_offline': _isOffline,
      'message': isAvailable
          ? 'This feature is available in offline mode'
          : 'This feature requires an internet connection',
    };
  }

  /// Get overall offline mode status
  Map<String, dynamic> getOverallOfflineStatus() {
    return {
      'is_in_offline_mode': _isInOfflineMode,
      'is_device_offline': _isOffline,
      'pending_sync_operations': _syncService.pendingOperationCount,
      'last_sync_time': _syncService.lastSyncTime?.toIso8601String(),
    };
  }

  // Helper methods

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(bool isOnline) {
    final wasOffline = _isOffline;
    _isOffline = !isOnline;

    // If we were offline and now we're online
    if (wasOffline && !_isOffline) {
      // Don't automatically exit offline mode, let the user decide
      debugPrint('Device is now online, but staying in offline mode until user exits');
    }

    // If we were online and now we're offline
    if (!wasOffline && _isOffline) {
      // Automatically enter offline mode
      _isInOfflineMode = true;
      _notifyOfflineModeChange();
      debugPrint('Device is now offline, automatically entered offline mode');
    }
  }

  /// Notify listeners of offline mode change
  void _notifyOfflineModeChange() {
    // Notify stream listeners
    _offlineModeController.add(_isInOfflineMode);

    // Notify direct listeners
    for (final listener in _offlineModeListeners) {
      listener(_isInOfflineMode);
    }
  }

  /// Cache user progress for offline mode
  Future<void> _cacheUserProgress() async {
    try {
      // In a real app, you would cache the current user's progress
      // For now, just log that we would cache user progress
      debugPrint('Would cache user progress for offline mode');
    } catch (e) {
      debugPrint('Error caching user progress: $e');
    }
  }

  /// Cache essential stories for offline mode
  Future<void> _cacheEssentialStories() async {
    try {
      // In a real app, you would cache essential stories
      // For now, just log that we would cache stories
      debugPrint('Would cache essential stories for offline mode');
    } catch (e) {
      debugPrint('Error caching essential stories: $e');
    }
  }

  /// Cache challenges for offline mode
  Future<void> _cacheChallenges() async {
    try {
      // In a real app, you would cache challenges
      // For now, just log that we would cache challenges
      debugPrint('Would cache challenges for offline mode');
    } catch (e) {
      debugPrint('Error caching challenges: $e');
    }
  }

  /// Cache cultural data for offline mode
  Future<void> _cacheCulturalData() async {
    try {
      // In a real app, you would cache cultural data
      // For now, just log that we would cache cultural data
      debugPrint('Would cache cultural data for offline mode');
    } catch (e) {
      debugPrint('Error caching cultural data: $e');
    }
  }
}
