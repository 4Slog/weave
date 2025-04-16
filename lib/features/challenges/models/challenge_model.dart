import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';

/// Enhanced model for challenges with educational standards integration.
///
/// This model represents a challenge with detailed educational metadata,
/// including alignment with educational standards, skill requirements,
/// and learning objectives.
class ChallengeModel {
  /// Unique identifier for the challenge.
  final String id;

  /// Type of challenge (e.g., 'pattern', 'sequence', 'function').
  final String type;

  /// Title of the challenge.
  final String title;

  /// Detailed description of the challenge.
  final String description;

  /// Difficulty level of the challenge (1-5).
  final int difficulty;

  /// Coding concepts required for this challenge.
  final List<String> requiredConcepts;

  /// Success criteria for the challenge.
  final SuccessCriteria successCriteria;

  /// Block types available for this challenge.
  final List<String> availableBlockTypes;

  /// Hints for completing the challenge.
  final List<String> hints;

  /// Tags for categorizing the challenge.
  final List<String> tags;

  /// Learning path type this challenge is best suited for.
  final LearningPathType? learningPathType;

  /// Educational standards this challenge aligns with.
  final EducationalStandards educationalStandards;

  /// Learning objectives for this challenge.
  final Map<String, String> learningObjectives;

  /// Skill level requirements for this challenge.
  final Map<String, double> skillRequirements;

  /// Assessment rubric for evaluating solutions.
  final AssessmentRubric assessmentRubric;

  /// Scaffolding level for this challenge (0-3).
  ///
  /// 0 = No scaffolding (open-ended)
  /// 1 = Light scaffolding (hints only)
  /// 2 = Medium scaffolding (starter blocks)
  /// 3 = Heavy scaffolding (partial solution)
  final int scaffoldingLevel;

  /// Starter blocks or template for the challenge.
  final Map<String, dynamic>? starterTemplate;

  /// Time estimate for completing the challenge (in minutes).
  final int estimatedTimeMinutes;

  /// Cultural context or relevance of the challenge.
  final String culturalContext;

  /// Create a new ChallengeModel.
  ChallengeModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.requiredConcepts,
    required this.successCriteria,
    required this.availableBlockTypes,
    this.hints = const [],
    this.tags = const [],
    this.learningPathType,
    EducationalStandards? educationalStandards,
    this.learningObjectives = const {},
    this.skillRequirements = const {},
    AssessmentRubric? assessmentRubric,
    this.scaffoldingLevel = 1,
    this.starterTemplate,
    this.estimatedTimeMinutes = 10,
    this.culturalContext = '',
  }) :
    educationalStandards = educationalStandards ?? EducationalStandards(),
    assessmentRubric = assessmentRubric ?? AssessmentRubric();

  /// Create a ChallengeModel from a JSON map.
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      requiredConcepts: (json['requiredConcepts'] as List<dynamic>?)?.cast<String>() ?? [],
      successCriteria: SuccessCriteria.fromJson(
        json['successCriteria'] as Map<String, dynamic>? ?? {}
      ),
      availableBlockTypes: (json['availableBlockTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      hints: (json['hints'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      learningPathType: json['learningPathType'] != null
          ? LearningPathType.values.firstWhere(
              (e) => e.toString().split('.').last == json['learningPathType'],
              orElse: () => LearningPathType.balanced,
            )
          : null,
      educationalStandards: json['educationalStandards'] != null
          ? EducationalStandards.fromJson(json['educationalStandards'] as Map<String, dynamic>)
          : null,
      learningObjectives: (json['learningObjectives'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ) ?? {},
      skillRequirements: (json['skillRequirements'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ) ?? {},
      assessmentRubric: json['assessmentRubric'] != null
          ? AssessmentRubric.fromJson(json['assessmentRubric'] as Map<String, dynamic>)
          : null,
      scaffoldingLevel: json['scaffoldingLevel'] as int? ?? 1,
      starterTemplate: json['starterTemplate'] as Map<String, dynamic>?,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int? ?? 10,
      culturalContext: json['culturalContext'] as String? ?? '',
    );
  }

  /// Convert this ChallengeModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'requiredConcepts': requiredConcepts,
      'successCriteria': successCriteria.toJson(),
      'availableBlockTypes': availableBlockTypes,
      'hints': hints,
      'tags': tags,
      'learningPathType': learningPathType?.toString().split('.').last,
      'educationalStandards': educationalStandards.toJson(),
      'learningObjectives': learningObjectives,
      'skillRequirements': skillRequirements,
      'assessmentRubric': assessmentRubric.toJson(),
      'scaffoldingLevel': scaffoldingLevel,
      'starterTemplate': starterTemplate,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'culturalContext': culturalContext,
    };
  }

  /// Create a copy of this ChallengeModel with some fields replaced.
  ChallengeModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    int? difficulty,
    List<String>? requiredConcepts,
    SuccessCriteria? successCriteria,
    List<String>? availableBlockTypes,
    List<String>? hints,
    List<String>? tags,
    LearningPathType? learningPathType,
    EducationalStandards? educationalStandards,
    Map<String, String>? learningObjectives,
    Map<String, double>? skillRequirements,
    AssessmentRubric? assessmentRubric,
    int? scaffoldingLevel,
    Map<String, dynamic>? starterTemplate,
    int? estimatedTimeMinutes,
    String? culturalContext,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      requiredConcepts: requiredConcepts ?? this.requiredConcepts,
      successCriteria: successCriteria ?? this.successCriteria,
      availableBlockTypes: availableBlockTypes ?? this.availableBlockTypes,
      hints: hints ?? this.hints,
      tags: tags ?? this.tags,
      learningPathType: learningPathType ?? this.learningPathType,
      educationalStandards: educationalStandards ?? this.educationalStandards,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      skillRequirements: skillRequirements ?? this.skillRequirements,
      assessmentRubric: assessmentRubric ?? this.assessmentRubric,
      scaffoldingLevel: scaffoldingLevel ?? this.scaffoldingLevel,
      starterTemplate: starterTemplate ?? this.starterTemplate,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      culturalContext: culturalContext ?? this.culturalContext,
    );
  }

  /// Check if this challenge is appropriate for a user's skill level.
  bool isAppropriateForSkillLevel(Map<String, double> userSkills) {
    // If no skill requirements, assume it's appropriate
    if (skillRequirements.isEmpty) return true;

    // Check each required skill
    for (final entry in skillRequirements.entries) {
      final skillId = entry.key;
      final requiredLevel = entry.value;
      final userLevel = userSkills[skillId] ?? 0.0;

      // If user's skill level is significantly below the requirement, it's not appropriate
      if (userLevel < requiredLevel - 0.2) {
        return false;
      }
    }

    return true;
  }

  /// Get the educational standards IDs for this challenge.
  List<String> getStandardIds() {
    return [
      ...educationalStandards.csStandardIds,
      ...educationalStandards.isteStandardIds,
      ...educationalStandards.k12FrameworkIds,
    ];
  }

  /// Get the difficulty name for this challenge.
  String get difficultyName {
    switch (difficulty) {
      case 1:
        return 'Simple';
      case 2:
        return 'Basic';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Custom';
    }
  }

  /// Get the scaffolding level name for this challenge.
  String get scaffoldingLevelName {
    switch (scaffoldingLevel) {
      case 0:
        return 'Open-ended';
      case 1:
        return 'Light guidance';
      case 2:
        return 'Structured';
      case 3:
        return 'Highly guided';
      default:
        return 'Custom';
    }
  }
}

/// Model for success criteria of a challenge.
class SuccessCriteria {
  /// Block types required for the challenge.
  final List<String> requiresBlockType;

  /// Minimum number of connections required.
  final int minConnections;

  /// Maximum number of blocks allowed (optional).
  final int? maxBlocks;

  /// Required pattern structure (optional).
  final String? requiredStructure;

  /// Required output or result (optional).
  final String? requiredOutput;

  /// Additional custom criteria (optional).
  final Map<String, dynamic> customCriteria;

  /// Create a new SuccessCriteria.
  SuccessCriteria({
    this.requiresBlockType = const [],
    this.minConnections = 0,
    this.maxBlocks,
    this.requiredStructure,
    this.requiredOutput,
    this.customCriteria = const {},
  });

  /// Create a SuccessCriteria from a JSON map.
  factory SuccessCriteria.fromJson(Map<String, dynamic> json) {
    return SuccessCriteria(
      requiresBlockType: (json['requiresBlockType'] as List<dynamic>?)?.cast<String>() ?? [],
      minConnections: json['minConnections'] as int? ?? 0,
      maxBlocks: json['maxBlocks'] as int?,
      requiredStructure: json['requiredStructure'] as String?,
      requiredOutput: json['requiredOutput'] as String?,
      customCriteria: json['customCriteria'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert this SuccessCriteria to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'requiresBlockType': requiresBlockType,
      'minConnections': minConnections,
      if (maxBlocks != null) 'maxBlocks': maxBlocks,
      if (requiredStructure != null) 'requiredStructure': requiredStructure,
      if (requiredOutput != null) 'requiredOutput': requiredOutput,
      'customCriteria': customCriteria,
    };
  }
}

/// Model for educational standards alignment.
class EducationalStandards {
  /// Computer Science Teachers Association (CSTA) standard IDs.
  final List<String> csStandardIds;

  /// International Society for Technology in Education (ISTE) standard IDs.
  final List<String> isteStandardIds;

  /// K-12 Computer Science Framework element IDs.
  final List<String> k12FrameworkIds;

  /// Create a new EducationalStandards.
  EducationalStandards({
    this.csStandardIds = const [],
    this.isteStandardIds = const [],
    this.k12FrameworkIds = const [],
  });

  /// Create an EducationalStandards from a JSON map.
  factory EducationalStandards.fromJson(Map<String, dynamic> json) {
    return EducationalStandards(
      csStandardIds: (json['csStandardIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isteStandardIds: (json['isteStandardIds'] as List<dynamic>?)?.cast<String>() ?? [],
      k12FrameworkIds: (json['k12FrameworkIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Convert this EducationalStandards to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'csStandardIds': csStandardIds,
      'isteStandardIds': isteStandardIds,
      'k12FrameworkIds': k12FrameworkIds,
    };
  }

  /// Check if this standards alignment is empty.
  bool get isEmpty =>
      csStandardIds.isEmpty &&
      isteStandardIds.isEmpty &&
      k12FrameworkIds.isEmpty;

  /// Get all standard IDs.
  List<String> getAllStandardIds() {
    return [
      ...csStandardIds,
      ...isteStandardIds,
      ...k12FrameworkIds,
    ];
  }
}

/// Model for assessment rubric.
class AssessmentRubric {
  /// Criteria for basic achievement level.
  final Map<String, String> basicCriteria;

  /// Criteria for proficient achievement level.
  final Map<String, String> proficientCriteria;

  /// Criteria for advanced achievement level.
  final Map<String, String> advancedCriteria;

  /// Points assigned to each achievement level.
  final Map<String, int> pointValues;

  /// Create a new AssessmentRubric.
  AssessmentRubric({
    this.basicCriteria = const {},
    this.proficientCriteria = const {},
    this.advancedCriteria = const {},
    Map<String, int>? pointValues,
  }) : pointValues = pointValues ?? {
         'basic': 1,
         'proficient': 2,
         'advanced': 3,
       };

  /// Create an AssessmentRubric from a JSON map.
  factory AssessmentRubric.fromJson(Map<String, dynamic> json) {
    return AssessmentRubric(
      basicCriteria: (json['basicCriteria'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ) ?? {},
      proficientCriteria: (json['proficientCriteria'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ) ?? {},
      advancedCriteria: (json['advancedCriteria'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ) ?? {},
      pointValues: (json['pointValues'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }

  /// Convert this AssessmentRubric to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'basicCriteria': basicCriteria,
      'proficientCriteria': proficientCriteria,
      'advancedCriteria': advancedCriteria,
      'pointValues': pointValues,
    };
  }

  /// Get all criteria for a specific achievement level.
  Map<String, String> getCriteriaForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'basic':
        return basicCriteria;
      case 'proficient':
        return proficientCriteria;
      case 'advanced':
        return advancedCriteria;
      default:
        return {};
    }
  }

  /// Get points for a specific achievement level.
  int getPointsForLevel(String level) {
    return pointValues[level.toLowerCase()] ?? 0;
  }
}
