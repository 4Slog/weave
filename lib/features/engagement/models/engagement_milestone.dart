
/// Model representing an engagement milestone.
///
/// Engagement milestones are achievements related to user engagement,
/// such as time spent, interactions, or educational progress.
class EngagementMilestone {
  /// Unique identifier for the milestone.
  final String id;

  /// Type of milestone (e.g., 'engagement_hours', 'challenges_completed').
  final String type;

  /// Value associated with the milestone.
  final int value;

  /// Display name of the milestone.
  final String name;

  /// Description of the milestone.
  final String description;

  /// Reward for achieving the milestone.
  final String reward;

  /// Educational context of the milestone.
  final String? educationalContext;

  /// Timestamp when the milestone was reached.
  final DateTime? reachedAt;

  /// Create a new EngagementMilestone.
  EngagementMilestone({
    required this.id,
    required this.type,
    required this.value,
    required this.name,
    required this.description,
    required this.reward,
    this.educationalContext,
    this.reachedAt,
  });

  /// Create an EngagementMilestone from a JSON map.
  factory EngagementMilestone.fromJson(Map<String, dynamic> json) {
    return EngagementMilestone(
      id: json['id'] as String,
      type: json['type'] as String,
      value: json['value'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      reward: json['reward'] as String,
      educationalContext: json['educational_context'] as String?,
      reachedAt: json['reached_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['reached_at'] as int)
          : null,
    );
  }

  /// Convert this EngagementMilestone to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'name': name,
      'description': description,
      'reward': reward,
      if (educationalContext != null) 'educational_context': educationalContext,
      if (reachedAt != null) 'reached_at': reachedAt!.millisecondsSinceEpoch,
    };
  }

  /// Create a copy of this EngagementMilestone with some fields replaced.
  EngagementMilestone copyWith({
    String? id,
    String? type,
    int? value,
    String? name,
    String? description,
    String? reward,
    String? educationalContext,
    DateTime? reachedAt,
  }) {
    return EngagementMilestone(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      name: name ?? this.name,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      educationalContext: educationalContext ?? this.educationalContext,
      reachedAt: reachedAt ?? this.reachedAt,
    );
  }

  /// Mark this milestone as reached.
  EngagementMilestone markAsReached() {
    return copyWith(reachedAt: DateTime.now());
  }

  /// Check if this milestone has been reached.
  bool get isReached => reachedAt != null;

  /// Check if this milestone is educational.
  bool get isEducational => educationalContext != null ||
                           type.contains('concept') ||
                           type.contains('standard') ||
                           type.contains('learning');

  /// Get the milestone category.
  String get category {
    if (type.contains('engagement') || type.contains('session')) {
      return 'engagement';
    } else if (type.contains('challenge')) {
      return 'challenge';
    } else if (type.contains('story')) {
      return 'story';
    } else if (type.contains('concept') || type.contains('standard') || type.contains('learning')) {
      return 'educational';
    } else {
      return 'other';
    }
  }

  @override
  String toString() {
    return 'EngagementMilestone(id: $id, type: $type, value: $value, name: $name)';
  }

  /// Create a time-based milestone.
  static EngagementMilestone createTimeMilestone(int hours) {
    return EngagementMilestone(
      id: 'engagement_hours_$hours',
      type: 'engagement_hours',
      value: hours,
      name: '$hours Hour${hours == 1 ? '' : 's'} of Engagement',
      description: 'You have spent $hours hour${hours == 1 ? '' : 's'} engaging with the app!',
      reward: 'New customization options unlocked',
      educationalContext: 'Regular engagement helps reinforce learning concepts and build coding skills.',
    );
  }

  /// Create an interaction milestone.
  static EngagementMilestone createInteractionMilestone(int interactions) {
    return EngagementMilestone(
      id: 'interactions_$interactions',
      type: 'interactions',
      value: interactions,
      name: '$interactions Interactions',
      description: 'You have made $interactions interactions with the app!',
      reward: 'New block types unlocked',
      educationalContext: 'Active participation through interactions enhances the learning experience.',
    );
  }

  /// Create a challenge completion milestone.
  static EngagementMilestone createChallengeMilestone(int challenges) {
    return EngagementMilestone(
      id: 'challenges_completed_$challenges',
      type: 'challenges_completed',
      value: challenges,
      name: '$challenges Challenge${challenges == 1 ? '' : 's'} Completed',
      description: 'You have completed $challenges coding challenge${challenges == 1 ? '' : 's'}!',
      reward: 'Advanced pattern creation tools unlocked',
      educationalContext: 'Completing challenges demonstrates mastery of coding concepts and problem-solving skills.',
    );
  }

  /// Create a story progression milestone.
  static EngagementMilestone createStoryMilestone(int stories) {
    return EngagementMilestone(
      id: 'stories_progressed_$stories',
      type: 'stories_progressed',
      value: stories,
      name: '$stories Stor${stories == 1 ? 'y' : 'ies'} Progressed',
      description: 'You have progressed through $stories stor${stories == 1 ? 'y' : 'ies'}!',
      reward: 'New story themes unlocked',
      educationalContext: 'Stories provide context for coding concepts and cultural connections.',
    );
  }

  /// Create a concept mastery milestone.
  static EngagementMilestone createConceptMilestone(int concepts) {
    return EngagementMilestone(
      id: 'concepts_mastered_$concepts',
      type: 'concepts_mastered',
      value: concepts,
      name: '$concepts Concept${concepts == 1 ? '' : 's'} Mastered',
      description: 'You have mastered $concepts coding concept${concepts == 1 ? '' : 's'}!',
      reward: 'New advanced challenges unlocked',
      educationalContext: 'Mastering coding concepts builds a foundation for computational thinking.',
    );
  }

  /// Create a standard demonstration milestone.
  static EngagementMilestone createStandardMilestone(int standards) {
    return EngagementMilestone(
      id: 'standards_demonstrated_$standards',
      type: 'standards_demonstrated',
      value: standards,
      name: '$standards Standard${standards == 1 ? '' : 's'} Demonstrated',
      description: 'You have demonstrated proficiency in $standards educational standard${standards == 1 ? '' : 's'}!',
      reward: 'New educational content unlocked',
      educationalContext: 'Educational standards provide a framework for measuring learning progress.',
    );
  }

  /// Create a learning objective milestone.
  static EngagementMilestone createLearningObjectiveMilestone(int objectives) {
    return EngagementMilestone(
      id: 'learning_objectives_completed_$objectives',
      type: 'learning_objectives_completed',
      value: objectives,
      name: '$objectives Learning Objective${objectives == 1 ? '' : 's'} Completed',
      description: 'You have completed $objectives learning objective${objectives == 1 ? '' : 's'}!',
      reward: 'New learning paths unlocked',
      educationalContext: 'Learning objectives provide clear goals for educational progress.',
    );
  }

  /// Get default engagement milestones.
  static List<EngagementMilestone> getDefaultMilestones() {
    return [
      // Time-based milestones
      createTimeMilestone(1),
      createTimeMilestone(5),
      createTimeMilestone(10),
      createTimeMilestone(20),
      createTimeMilestone(50),
      createTimeMilestone(100),

      // Interaction milestones
      createInteractionMilestone(100),
      createInteractionMilestone(500),
      createInteractionMilestone(1000),
      createInteractionMilestone(5000),
      createInteractionMilestone(10000),

      // Challenge milestones
      createChallengeMilestone(1),
      createChallengeMilestone(5),
      createChallengeMilestone(10),
      createChallengeMilestone(25),
      createChallengeMilestone(50),
      createChallengeMilestone(100),

      // Story milestones
      createStoryMilestone(1),
      createStoryMilestone(5),
      createStoryMilestone(10),
      createStoryMilestone(20),
      createStoryMilestone(50),

      // Educational milestones
      createConceptMilestone(1),
      createConceptMilestone(5),
      createConceptMilestone(10),
      createConceptMilestone(20),
      createStandardMilestone(1),
      createStandardMilestone(5),
      createStandardMilestone(10),
      createLearningObjectiveMilestone(1),
      createLearningObjectiveMilestone(5),
      createLearningObjectiveMilestone(10),
      createLearningObjectiveMilestone(20),
    ];
  }
}
