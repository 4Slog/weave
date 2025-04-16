import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

/// A service for processing intensive operations in the background
class BackgroundProcessor {
  /// Singleton instance
  static final BackgroundProcessor _instance = BackgroundProcessor._internal();

  /// Factory constructor
  factory BackgroundProcessor() => _instance;

  /// Private constructor
  BackgroundProcessor._internal();

  /// Task queue for background processing
  final Map<String, _BackgroundTask> _taskQueue = {};

  /// Process a task in the background
  ///
  /// Parameters:
  /// - `taskId`: Unique identifier for the task
  /// - `function`: The function to execute in the background
  /// - `input`: Input data for the function
  /// - `onComplete`: Callback when the task is complete
  /// - `onError`: Callback when an error occurs
  Future<void> processTask<T, R>({
    required String taskId,
    required FutureOr<R> Function(T input) function,
    required T input,
    required void Function(R result) onComplete,
    void Function(dynamic error)? onError,
  }) async {
    // Check if task is already in queue
    if (_taskQueue.containsKey(taskId)) {
      // Cancel existing task
      await _taskQueue[taskId]!.cancel();
    }

    // Create a new task
    final task = _BackgroundTask<T, R>(
      function: function,
      input: input,
      onComplete: onComplete,
      onError: onError,
    );

    // Add to queue
    _taskQueue[taskId] = task;

    // Start the task
    await task.start();

    // Remove from queue when complete
    task.future.whenComplete(() {
      _taskQueue.remove(taskId);
    });
  }

  /// Process a task using compute (for simpler tasks)
  ///
  /// Parameters:
  /// - `function`: The function to execute in the background
  /// - `input`: Input data for the function
  Future<R> computeTask<T, R>(FutureOr<R> Function(T input) function, T input) async {
    return await compute(function, input);
  }

  /// Cancel a task
  ///
  /// Parameters:
  /// - `taskId`: ID of the task to cancel
  Future<void> cancelTask(String taskId) async {
    if (_taskQueue.containsKey(taskId)) {
      await _taskQueue[taskId]!.cancel();
      _taskQueue.remove(taskId);
    }
  }

  /// Cancel all tasks
  Future<void> cancelAllTasks() async {
    for (final task in _taskQueue.values) {
      await task.cancel();
    }
    _taskQueue.clear();
  }

  /// Check if a task is running
  ///
  /// Parameters:
  /// - `taskId`: ID of the task to check
  bool isTaskRunning(String taskId) {
    return _taskQueue.containsKey(taskId);
  }
}

/// Represents a background task
class _BackgroundTask<T, R> {
  /// The function to execute
  final FutureOr<R> Function(T input) function;

  /// Input data for the function
  final T input;

  /// Callback when the task is complete
  final void Function(R result) onComplete;

  /// Callback when an error occurs
  final void Function(dynamic error)? onError;

  /// Isolate for the task
  Isolate? _isolate;

  /// Receive port for communication
  ReceivePort? _receivePort;

  /// Completer for the task
  final Completer<R> _completer = Completer<R>();

  /// Future for the task
  Future<R> get future => _completer.future;

  /// Constructor
  _BackgroundTask({
    required this.function,
    required this.input,
    required this.onComplete,
    this.onError,
  });

  /// Start the task
  Future<void> start() async {
    try {
      if (kIsWeb) {
        // Web doesn't support isolates, use compute instead
        final result = await compute(_isolateFunction, _IsolateData(function, input));
        _handleResult(result);
      } else {
        // Use isolate for native platforms
        _receivePort = ReceivePort();

        _isolate = await Isolate.spawn(
          _isolateEntryPoint,
          _IsolateData(function, input, _receivePort!.sendPort),
        );

        _receivePort!.listen((message) {
          if (message is R) {
            _handleResult(message);
          } else if (message is _IsolateError) {
            _handleError(message.error);
          }
        });
      }
    } catch (e) {
      _handleError(e);
    }
  }

  /// Handle the result of the task
  void _handleResult(R result) {
    if (!_completer.isCompleted) {
      onComplete(result);
      _completer.complete(result);
    }
    _cleanup();
  }

  /// Handle an error in the task
  void _handleError(dynamic error) {
    if (!_completer.isCompleted) {
      onError?.call(error);
      _completer.completeError(error);
    }
    _cleanup();
  }

  /// Clean up resources
  void _cleanup() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  /// Cancel the task
  Future<void> cancel() async {
    _cleanup();
    if (!_completer.isCompleted) {
      _completer.completeError('Task cancelled');
    }
  }
}

/// Data for isolate communication
class _IsolateData<T, R> {
  /// The function to execute
  final FutureOr<R> Function(T input) function;

  /// Input data for the function
  final T input;

  /// Send port for communication
  final SendPort? sendPort;

  /// Constructor
  _IsolateData(this.function, this.input, [this.sendPort]);
}

/// Error from isolate
class _IsolateError {
  /// The error
  final dynamic error;

  /// Constructor
  _IsolateError(this.error);
}

/// Entry point for isolate
void _isolateEntryPoint<T, R>(_IsolateData<T, R> data) async {
  try {
    final result = await data.function(data.input);
    data.sendPort?.send(result);
  } catch (e) {
    data.sendPort?.send(_IsolateError(e));
  }
}

/// Function for compute
FutureOr<R> _isolateFunction<T, R>(_IsolateData<T, R> data) {
  return data.function(data.input);
}
