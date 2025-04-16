import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility class for network connectivity management
class ConnectivityUtils {
  // Singleton implementation
  static final ConnectivityUtils _instance = ConnectivityUtils._internal();

  factory ConnectivityUtils() {
    return _instance;
  }

  ConnectivityUtils._internal();

  // Connectivity state
  bool _isOnline = true;
  DateTime? _lastConnectivityCheck;

  // Stream controller for connectivity changes
  final StreamController<bool> _connectivityStreamController = StreamController<bool>.broadcast();

  // Timer for periodic connectivity checks
  Timer? _connectivityCheckTimer;

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  void initialize() {
    // Start periodic connectivity checks
    _connectivityCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkConnectivity(),
    );

    // Perform initial check
    checkConnectivity();
  }

  /// Dispose resources
  void dispose() {
    _connectivityCheckTimer?.cancel();
    _connectivityStreamController.close();
  }

  /// Check connectivity by making a network request
  Future<bool> checkConnectivity() async {
    // Don't check too frequently
    final now = DateTime.now();
    if (_lastConnectivityCheck != null &&
        now.difference(_lastConnectivityCheck!).inSeconds < 5) {
      return _isOnline;
    }

    _lastConnectivityCheck = now;

    try {
      if (kIsWeb) {
        // For web, assume online
        _updateConnectivityStatus(true);
        return true;
      }

      // Try to connect to a reliable host
      final result = await _checkConnection();
      _updateConnectivityStatus(result);
      return result;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _updateConnectivityStatus(false);
      return false;
    }
  }

  /// Check connection by making a request to a reliable host
  Future<bool> _checkConnection() async {
    try {
      // Try to connect to Google's DNS
      final result = await InternetAddress.lookup('8.8.8.8');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return false;
    }
  }

  /// Update connectivity status and notify listeners if changed
  void _updateConnectivityStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityStreamController.add(isOnline);

      debugPrint('Connectivity changed: ${isOnline ? 'online' : 'offline'}');
    }
  }
}

/// A class for managing operations that need to be performed when online
class PendingOperationsManager {
  // Singleton implementation
  static final PendingOperationsManager _instance = PendingOperationsManager._internal();

  factory PendingOperationsManager() {
    return _instance;
  }

  PendingOperationsManager._internal() {
    // Listen for connectivity changes
    ConnectivityUtils().connectivityStream.listen(_handleConnectivityChange);
  }

  // Queue of pending operations
  final List<PendingOperation> _pendingOperations = [];

  // Flag to track if operations are being processed
  bool _isProcessing = false;

  /// Add a pending operation to the queue
  void addOperation(PendingOperation operation) {
    _pendingOperations.add(operation);

    // Try to process operations if online
    if (ConnectivityUtils().isOnline && !_isProcessing) {
      _processOperations();
    }
  }

  /// Get the number of pending operations
  int get pendingOperationCount => _pendingOperations.length;

  /// Handle connectivity changes
  void _handleConnectivityChange(bool isOnline) {
    if (isOnline && _pendingOperations.isNotEmpty && !_isProcessing) {
      _processOperations();
    }
  }

  /// Process pending operations
  Future<void> _processOperations() async {
    if (_pendingOperations.isEmpty || _isProcessing) return;

    _isProcessing = true;

    try {
      // Process operations in order
      while (_pendingOperations.isNotEmpty && ConnectivityUtils().isOnline) {
        final operation = _pendingOperations.first;

        try {
          // Try to execute the operation
          final result = await operation.execute();

          // If successful, remove from queue
          _pendingOperations.removeAt(0);

          // Call success callback
          operation.onSuccess?.call(result);
        } catch (e) {
          debugPrint('Error executing pending operation: $e');

          // Call error callback
          operation.onError?.call(e);

          // If operation should be retried, move to end of queue
          // Otherwise, remove it
          if (operation.shouldRetry) {
            final op = _pendingOperations.removeAt(0);
            op.incrementRetryCount();

            // If max retries not reached, add back to queue
            if (op.retryCount < op.maxRetries) {
              _pendingOperations.add(op);
            } else {
              // Max retries reached, call failure callback
              op.onFailure?.call();
            }
          } else {
            // Don't retry, remove from queue
            _pendingOperations.removeAt(0);
            operation.onFailure?.call();
          }

          // Pause processing if we hit an error
          break;
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}

/// Represents an operation that needs to be performed when online
class PendingOperation<T> {
  /// The function to execute
  final Future<T> Function() execute;

  /// Whether to retry on failure
  final bool shouldRetry;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Callback when operation succeeds
  final void Function(T result)? onSuccess;

  /// Callback when operation fails with an error
  final void Function(dynamic error)? onError;

  /// Callback when operation fails after all retries
  final void Function()? onFailure;

  /// Current retry count
  int retryCount = 0;

  /// Create a new pending operation
  PendingOperation({
    required this.execute,
    this.shouldRetry = true,
    this.maxRetries = 3,
    this.onSuccess,
    this.onError,
    this.onFailure,
  });

  /// Increment the retry count
  void incrementRetryCount() {
    retryCount++;
  }
}
