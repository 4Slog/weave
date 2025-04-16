import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/storytelling/interfaces/story_challenge_interface.dart';
import 'package:kente_codeweaver/features/storytelling/services/story_challenge_service_impl.dart';
import 'package:kente_codeweaver/features/challenges/interfaces/challenge_interface.dart';
import 'package:kente_codeweaver/features/challenges/services/challenge_service_impl.dart';

/// Service locator for dependency injection
class ServiceLocator {
  /// Map of services
  static final Map<Type, dynamic> _services = {};

  /// Register a service
  static void register<T>(T service) {
    _services[T] = service;
  }

  /// Get a service
  static T getService<T>() {
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    throw Exception('Service not registered: $T');
  }

  /// Initialize the service locator
  static void initialize(BuildContext context) {
    // Register story challenge service
    register<StoryChallengeInterface>(
      StoryChallengeServiceImpl.fromContext(context),
    );

    // Register challenge service
    register<ChallengeInterface>(
      ChallengeServiceImpl.fromContext(context),
    );
  }

  /// Reset the service locator
  static void reset() {
    _services.clear();
  }
}
