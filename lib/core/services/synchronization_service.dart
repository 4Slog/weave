import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/core/services/storage_service.dart';
import 'package:kente_codeweaver/core/utils/connectivity_utils.dart';

/// Service for handling offline data synchronization
class SynchronizationService {
  // Singleton implementation
  static final SynchronizationService _instance = SynchronizationService._internal();

  factory SynchronizationService() {
    return _instance;
  }

  SynchronizationService._internal();

  // Dependencies
  final StorageService _storageService = StorageService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  final PendingOperationsManager _pendingOperationsManager = PendingOperationsManager();

  // Synchronization state
  bool _isInitialized = false;
  bool _isSynchronizing = false;
  DateTime? _lastSyncTime;

  // Stream controller for sync events
  final StreamController<SyncEvent> _syncEventController = StreamController<SyncEvent>.broadcast();

  // Timer for periodic sync
  Timer? _syncTimer;

  /// Stream of synchronization events
  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  /// Last synchronization time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Number of pending operations
  int get pendingOperationCount => _pendingOperationsManager.pendingOperationCount;

  /// Initialize the synchronization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize connectivity utils
      _connectivityUtils.initialize();

      // Listen for connectivity changes
      _connectivityUtils.connectivityStream.listen(_handleConnectivityChange);

      // Start periodic sync
      _syncTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => synchronize(),
      );

      _isInitialized = true;
      debugPrint('SynchronizationService initialized successfully');

      // Perform initial sync if online
      if (_connectivityUtils.isOnline) {
        synchronize();
      }
    } catch (e) {
      debugPrint('Failed to initialize SynchronizationService: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncEventController.close();
  }

  /// Synchronize data with the server
  Future<void> synchronize() async {
    if (_isSynchronizing) return;

    _isSynchronizing = true;
    _syncEventController.add(SyncEvent(SyncEventType.syncStarted));

    try {
      // Check connectivity
      final isOnline = await _connectivityUtils.checkConnectivity();
      if (!isOnline) {
        _syncEventController.add(SyncEvent(
          SyncEventType.syncFailed,
          message: 'Device is offline',
        ));
        _isSynchronizing = false;
        return;
      }

      // Sync user progress
      await _syncUserProgress();

      // Sync analytics events
      await _syncAnalyticsEvents();

      // Update last sync time
      _lastSyncTime = DateTime.now();

      // Save last sync time
      await _storageService.cacheData('last_sync_time', {
        'timestamp': _lastSyncTime!.toIso8601String(),
      });

      _syncEventController.add(SyncEvent(
        SyncEventType.syncCompleted,
        timestamp: _lastSyncTime,
      ));
    } catch (e) {
      debugPrint('Error during synchronization: $e');
      _syncEventController.add(SyncEvent(
        SyncEventType.syncFailed,
        message: 'Error during synchronization: $e',
      ));
    } finally {
      _isSynchronizing = false;
    }
  }

  /// Queue an operation to be executed when online
  void queueOperation<T>({
    required Future<T> Function() operation,
    required String operationType,
    Map<String, dynamic>? metadata,
    void Function(T result)? onSuccess,
    void Function(dynamic error)? onError,
    void Function()? onFailure,
    bool shouldRetry = true,
    int maxRetries = 3,
  }) {
    // Create a pending operation
    final pendingOperation = PendingOperation<T>(
      execute: operation,
      shouldRetry: shouldRetry,
      maxRetries: maxRetries,
      onSuccess: (result) {
        onSuccess?.call(result);
        _syncEventController.add(SyncEvent(
          SyncEventType.operationCompleted,
          operationType: operationType,
          metadata: metadata,
        ));
      },
      onError: (error) {
        onError?.call(error);
        _syncEventController.add(SyncEvent(
          SyncEventType.operationFailed,
          operationType: operationType,
          message: 'Operation failed: $error',
          metadata: metadata,
        ));
      },
      onFailure: () {
        onFailure?.call();
        _syncEventController.add(SyncEvent(
          SyncEventType.operationFailed,
          operationType: operationType,
          message: 'Operation failed after $maxRetries retries',
          metadata: metadata,
        ));
      },
    );

    // Add to pending operations manager
    _pendingOperationsManager.addOperation(pendingOperation);

    _syncEventController.add(SyncEvent(
      SyncEventType.operationQueued,
      operationType: operationType,
      metadata: metadata,
    ));
  }

  /// Save data locally for later synchronization
  Future<void> saveForSync(String key, dynamic data) async {
    try {
      // Add sync flag to data
      final syncData = {
        'data': data,
        'needs_sync': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Save to storage
      await _storageService.cacheData('sync_$key', syncData);

      _syncEventController.add(SyncEvent(
        SyncEventType.dataSavedForSync,
        operationType: 'save',
        metadata: {'key': key},
      ));
    } catch (e) {
      debugPrint('Error saving data for sync: $e');
    }
  }

  /// Get data that needs to be synchronized
  Future<List<Map<String, dynamic>>> getPendingSyncData() async {
    final result = <Map<String, dynamic>>[];

    try {
      final keys = await _storageService.getAllKeys();

      for (final key in keys) {
        if (key.startsWith('cache_sync_')) {
          final data = await _storageService.getCachedData(key.replaceFirst('cache_', ''));

          if (data != null && data is Map<String, dynamic> && data['needs_sync'] == true) {
            result.add({
              'key': key.replaceFirst('cache_sync_', ''),
              'data': data['data'],
              'timestamp': data['timestamp'],
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting pending sync data: $e');
    }

    return result;
  }

  /// Mark data as synchronized
  Future<void> markAsSynced(String key) async {
    try {
      final fullKey = 'sync_$key';
      final data = await _storageService.getCachedData(fullKey);

      if (data != null && data is Map<String, dynamic>) {
        // Update sync flag
        data['needs_sync'] = false;
        data['last_synced'] = DateTime.now().toIso8601String();

        // Save updated data
        await _storageService.cacheData(fullKey, data);
      }
    } catch (e) {
      debugPrint('Error marking data as synced: $e');
    }
  }

  // Private methods

  /// Handle connectivity changes
  void _handleConnectivityChange(bool isOnline) {
    if (isOnline) {
      // Try to synchronize when coming online
      synchronize();
    }
  }

  /// Synchronize user progress
  Future<void> _syncUserProgress() async {
    try {
      // Get pending user progress data
      final pendingData = await getPendingSyncData();

      // Filter for user progress data
      final userProgressData = pendingData.where(
        (item) => item['key'].toString().startsWith('user_progress_'),
      ).toList();

      if (userProgressData.isEmpty) {
        debugPrint('No user progress data to sync');
        return;
      }

      debugPrint('Syncing ${userProgressData.length} user progress items');

      // In a real app, you would send this data to a server
      // For now, just mark as synced
      for (final item in userProgressData) {
        await markAsSynced(item['key']);
      }

      debugPrint('User progress sync completed');
    } catch (e) {
      debugPrint('Error syncing user progress: $e');
    }
  }

  /// Synchronize analytics events
  Future<void> _syncAnalyticsEvents() async {
    try {
      // In a real app, you would send analytics events to a server
      // For now, just log that we would sync analytics
      debugPrint('Analytics events would be synced here');
    } catch (e) {
      debugPrint('Error syncing analytics events: $e');
    }
  }
}

/// Types of synchronization events
enum SyncEventType {
  /// Synchronization started
  syncStarted,

  /// Synchronization completed successfully
  syncCompleted,

  /// Synchronization failed
  syncFailed,

  /// Operation queued for later execution
  operationQueued,

  /// Operation completed successfully
  operationCompleted,

  /// Operation failed
  operationFailed,

  /// Data saved locally for later synchronization
  dataSavedForSync,
}

/// Represents a synchronization event
class SyncEvent {
  /// Type of event
  final SyncEventType type;

  /// Optional message
  final String? message;

  /// Optional timestamp
  final DateTime? timestamp;

  /// Optional operation type
  final String? operationType;

  /// Optional metadata
  final Map<String, dynamic>? metadata;

  /// Create a new sync event
  SyncEvent(
    this.type, {
    this.message,
    this.timestamp,
    this.operationType,
    this.metadata,
  });
}
