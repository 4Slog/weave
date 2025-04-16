
/// Model representing an engagement event in the application.
///
/// Engagement events track user interactions and activities within the app,
/// providing data for analytics and adaptive learning.
class EngagementEvent {
  /// Unique identifier for the event.
  final String id;

  /// Type of engagement event (e.g., 'interaction', 'challenge_complete').
  final String eventType;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  /// User ID associated with the event.
  final String userId;

  /// Additional details about the event.
  final Map<String, dynamic> details;

  /// Educational context of the event (if applicable).
  final String? educationalContext;

  /// Create a new EngagementEvent.
  EngagementEvent({
    required this.id,
    required this.eventType,
    required this.timestamp,
    required this.userId,
    this.details = const {},
    this.educationalContext,
  });

  /// Create an EngagementEvent from a JSON map.
  factory EngagementEvent.fromJson(Map<String, dynamic> json) {
    return EngagementEvent(
      id: json['id'] as String,
      eventType: json['event_type'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      userId: json['user_id'] as String,
      details: json['details'] as Map<String, dynamic>? ?? {},
      educationalContext: json['educational_context'] as String?,
    );
  }

  /// Convert this EngagementEvent to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'user_id': userId,
      'details': details,
      if (educationalContext != null) 'educational_context': educationalContext,
    };
  }

  /// Create a copy of this EngagementEvent with some fields replaced.
  EngagementEvent copyWith({
    String? id,
    String? eventType,
    DateTime? timestamp,
    String? userId,
    Map<String, dynamic>? details,
    String? educationalContext,
  }) {
    return EngagementEvent(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      details: details ?? this.details,
      educationalContext: educationalContext ?? this.educationalContext,
    );
  }

  /// Get a specific detail value from the event.
  dynamic getDetail(String key) {
    return details[key];
  }

  /// Check if this event is related to a specific activity type.
  bool isActivityType(String activityType) {
    return eventType == activityType ||
           (details.containsKey('type') && details['type'] == activityType);
  }

  /// Check if this event is related to a specific challenge.
  bool isForChallenge(String challengeId) {
    return details.containsKey('challenge_id') &&
           details['challenge_id'] == challengeId;
  }

  /// Check if this event is related to a specific story.
  bool isForStory(String storyId) {
    return details.containsKey('story_id') &&
           details['story_id'] == storyId;
  }

  /// Check if this event is a milestone event.
  bool isMilestone() {
    return eventType == 'milestone_reached';
  }

  /// Check if this event is a session event.
  bool isSessionEvent() {
    return eventType == 'session_start' || eventType == 'session_end';
  }

  /// Check if this event is an educational event.
  bool isEducationalEvent() {
    return educationalContext != null ||
           eventType == 'challenge_complete' ||
           eventType == 'story_progress';
  }

  /// Whether this event is educational in nature.
  ///
  /// This is a getter that provides the same functionality as isEducationalEvent()
  /// but as a property for easier access.
  bool get isEducational => isEducationalEvent();

  /// Get the duration of the event if available.
  Duration? getDuration() {
    if (details.containsKey('duration_seconds')) {
      return Duration(seconds: details['duration_seconds'] as int);
    } else if (details.containsKey('time_spent_seconds')) {
      return Duration(seconds: details['time_spent_seconds'] as int);
    } else if (details.containsKey('attempt_duration_seconds')) {
      return Duration(seconds: details['attempt_duration_seconds'] as int);
    }
    return null;
  }

  /// Get the educational concepts associated with this event.
  List<String> getEducationalConcepts() {
    if (details.containsKey('concepts')) {
      return List<String>.from(details['concepts']);
    } else if (details.containsKey('required_concepts')) {
      return List<String>.from(details['required_concepts']);
    }
    return [];
  }

  /// Get the educational standards associated with this event.
  List<String> getEducationalStandards() {
    if (details.containsKey('standards')) {
      return List<String>.from(details['standards']);
    }
    return [];
  }

  /// Get the difficulty level of the event if available.
  int? getDifficultyLevel() {
    if (details.containsKey('difficulty')) {
      return details['difficulty'] as int;
    }
    return null;
  }

  /// Get the success status of the event if available.
  bool? getSuccessStatus() {
    if (details.containsKey('success')) {
      return details['success'] as bool;
    }
    return null;
  }

  @override
  String toString() {
    return 'EngagementEvent(id: $id, eventType: $eventType, timestamp: $timestamp, userId: $userId)';
  }
}
