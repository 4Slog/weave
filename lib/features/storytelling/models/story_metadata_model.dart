import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Model for story educational metadata.
/// 
/// This model represents the educational metadata for a story,
/// including standards alignment, learning objectives, and
/// educational context.
class StoryMetadataModel {
  /// Unique identifier for the metadata.
  final String id;
  
  /// Story ID associated with this metadata.
  final String storyId;
  
  /// Educational standards this story aligns with.
  final List<StandardAlignment> standardsAlignment;
  
  /// Learning objectives for this story.
  final List<LearningObjective> learningObjectives;
  
  /// Coding concepts covered in this story.
  final List<CodingConceptCoverage> codingConcepts;
  
  /// Cultural elements in this story.
  final List<CulturalElement> culturalElements;
  
  /// Age range this story is appropriate for.
  final AgeRange ageRange;
  
  /// Difficulty level of this story (1-5).
  final int difficultyLevel;
  
  /// Estimated time to complete this story (in minutes).
  final int estimatedTimeMinutes;
  
  /// Keywords for this story.
  final List<String> keywords;
  
  /// Create a new StoryMetadataModel.
  StoryMetadataModel({
    String? id,
    required this.storyId,
    this.standardsAlignment = const [],
    this.learningObjectives = const [],
    this.codingConcepts = const [],
    this.culturalElements = const [],
    required this.ageRange,
    this.difficultyLevel = 1,
    this.estimatedTimeMinutes = 10,
    this.keywords = const [],
  }) : id = id ?? const Uuid().v4();
  
  /// Create a StoryMetadataModel from a JSON map.
  factory StoryMetadataModel.fromJson(Map<String, dynamic> json) {
    return StoryMetadataModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      storyId: json['storyId'] as String,
      standardsAlignment: json['standardsAlignment'] != null
          ? (json['standardsAlignment'] as List)
              .map((e) => StandardAlignment.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      learningObjectives: json['learningObjectives'] != null
          ? (json['learningObjectives'] as List)
              .map((e) => LearningObjective.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      codingConcepts: json['codingConcepts'] != null
          ? (json['codingConcepts'] as List)
              .map((e) => CodingConceptCoverage.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      culturalElements: json['culturalElements'] != null
          ? (json['culturalElements'] as List)
              .map((e) => CulturalElement.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      ageRange: json['ageRange'] != null
          ? AgeRange.fromJson(json['ageRange'] as Map<String, dynamic>)
          : AgeRange(minAge: 7, maxAge: 15),
      difficultyLevel: json['difficultyLevel'] as int? ?? 1,
      estimatedTimeMinutes: json['estimatedTimeMinutes'] as int? ?? 10,
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'] as List)
          : [],
    );
  }
  
  /// Convert this StoryMetadataModel to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'standardsAlignment': standardsAlignment.map((e) => e.toJson()).toList(),
      'learningObjectives': learningObjectives.map((e) => e.toJson()).toList(),
      'codingConcepts': codingConcepts.map((e) => e.toJson()).toList(),
      'culturalElements': culturalElements.map((e) => e.toJson()).toList(),
      'ageRange': ageRange.toJson(),
      'difficultyLevel': difficultyLevel,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'keywords': keywords,
    };
  }
  
  /// Create a copy of this StoryMetadataModel with some fields replaced.
  StoryMetadataModel copyWith({
    String? id,
    String? storyId,
    List<StandardAlignment>? standardsAlignment,
    List<LearningObjective>? learningObjectives,
    List<CodingConceptCoverage>? codingConcepts,
    List<CulturalElement>? culturalElements,
    AgeRange? ageRange,
    int? difficultyLevel,
    int? estimatedTimeMinutes,
    List<String>? keywords,
  }) {
    return StoryMetadataModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      standardsAlignment: standardsAlignment ?? this.standardsAlignment,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      codingConcepts: codingConcepts ?? this.codingConcepts,
      culturalElements: culturalElements ?? this.culturalElements,
      ageRange: ageRange ?? this.ageRange,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      keywords: keywords ?? this.keywords,
    );
  }
  
  /// Get the difficulty level name for this story.
  String get difficultyLevelName {
    switch (difficultyLevel) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Elementary';
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
  
  /// Get the educational standards IDs for this story.
  List<String> getStandardIds() {
    return standardsAlignment.map((alignment) => alignment.standardId).toList();
  }
  
  /// Get the coding concepts covered in this story.
  List<String> getCodingConceptIds() {
    return codingConcepts.map((concept) => concept.conceptId).toList();
  }
  
  /// Check if this story is appropriate for a given age.
  bool isAppropriateForAge(int age) {
    return age >= ageRange.minAge && age <= ageRange.maxAge;
  }
  
  /// Check if this story covers a specific coding concept.
  bool coversCodingConcept(String conceptId) {
    return codingConcepts.any((concept) => concept.conceptId == conceptId);
  }
  
  /// Check if this story aligns with a specific educational standard.
  bool alignsWithStandard(String standardId) {
    return standardsAlignment.any((alignment) => alignment.standardId == standardId);
  }
  
  /// Get the educational summary for this story.
  Map<String, dynamic> getEducationalSummary() {
    return {
      'difficultyLevel': difficultyLevel,
      'difficultyLevelName': difficultyLevelName,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'ageRange': '${ageRange.minAge}-${ageRange.maxAge}',
      'standardsCount': standardsAlignment.length,
      'learningObjectivesCount': learningObjectives.length,
      'codingConceptsCount': codingConcepts.length,
      'culturalElementsCount': culturalElements.length,
    };
  }
}

/// Model for standard alignment.
class StandardAlignment {
  /// Unique identifier for the alignment.
  final String id;
  
  /// Standard ID (e.g., 'CSTA-1A-AP-10').
  final String standardId;
  
  /// Standard type (e.g., 'CSTA', 'ISTE', 'K12CS').
  final String standardType;
  
  /// Description of the standard.
  final String description;
  
  /// How this story aligns with the standard.
  final String alignmentDescription;
  
  /// Create a new StandardAlignment.
  StandardAlignment({
    String? id,
    required this.standardId,
    required this.standardType,
    required this.description,
    required this.alignmentDescription,
  }) : id = id ?? const Uuid().v4();
  
  /// Create a StandardAlignment from a JSON map.
  factory StandardAlignment.fromJson(Map<String, dynamic> json) {
    return StandardAlignment(
      id: json['id'] as String? ?? const Uuid().v4(),
      standardId: json['standardId'] as String,
      standardType: json['standardType'] as String,
      description: json['description'] as String,
      alignmentDescription: json['alignmentDescription'] as String,
    );
  }
  
  /// Convert this StandardAlignment to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'standardId': standardId,
      'standardType': standardType,
      'description': description,
      'alignmentDescription': alignmentDescription,
    };
  }
}

/// Model for learning objective.
class LearningObjective {
  /// Unique identifier for the objective.
  final String id;
  
  /// Description of the objective.
  final String description;
  
  /// How this objective is addressed in the story.
  final String implementation;
  
  /// Assessment method for this objective.
  final String assessmentMethod;
  
  /// Create a new LearningObjective.
  LearningObjective({
    String? id,
    required this.description,
    required this.implementation,
    required this.assessmentMethod,
  }) : id = id ?? const Uuid().v4();
  
  /// Create a LearningObjective from a JSON map.
  factory LearningObjective.fromJson(Map<String, dynamic> json) {
    return LearningObjective(
      id: json['id'] as String? ?? const Uuid().v4(),
      description: json['description'] as String,
      implementation: json['implementation'] as String,
      assessmentMethod: json['assessmentMethod'] as String,
    );
  }
  
  /// Convert this LearningObjective to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'implementation': implementation,
      'assessmentMethod': assessmentMethod,
    };
  }
}

/// Model for coding concept coverage.
class CodingConceptCoverage {
  /// Unique identifier for the coverage.
  final String id;
  
  /// Concept ID (e.g., 'loops', 'conditionals').
  final String conceptId;
  
  /// Name of the concept.
  final String conceptName;
  
  /// Description of the concept.
  final String description;
  
  /// How this concept is covered in the story.
  final String coverageDescription;
  
  /// Depth of coverage (1-5).
  final int depthOfCoverage;
  
  /// Create a new CodingConceptCoverage.
  CodingConceptCoverage({
    String? id,
    required this.conceptId,
    required this.conceptName,
    required this.description,
    required this.coverageDescription,
    this.depthOfCoverage = 1,
  }) : id = id ?? const Uuid().v4();
  
  /// Create a CodingConceptCoverage from a JSON map.
  factory CodingConceptCoverage.fromJson(Map<String, dynamic> json) {
    return CodingConceptCoverage(
      id: json['id'] as String? ?? const Uuid().v4(),
      conceptId: json['conceptId'] as String,
      conceptName: json['conceptName'] as String,
      description: json['description'] as String,
      coverageDescription: json['coverageDescription'] as String,
      depthOfCoverage: json['depthOfCoverage'] as int? ?? 1,
    );
  }
  
  /// Convert this CodingConceptCoverage to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conceptId': conceptId,
      'conceptName': conceptName,
      'description': description,
      'coverageDescription': coverageDescription,
      'depthOfCoverage': depthOfCoverage,
    };
  }
  
  /// Get the depth of coverage name.
  String get depthOfCoverageName {
    switch (depthOfCoverage) {
      case 1:
        return 'Introduction';
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
}

/// Model for cultural element.
class CulturalElement {
  /// Unique identifier for the element.
  final String id;
  
  /// Name of the cultural element.
  final String name;
  
  /// Description of the cultural element.
  final String description;
  
  /// Cultural significance of the element.
  final String significance;
  
  /// How this element is incorporated in the story.
  final String incorporation;
  
  /// Region or culture this element belongs to.
  final String region;
  
  /// Create a new CulturalElement.
  CulturalElement({
    String? id,
    required this.name,
    required this.description,
    required this.significance,
    required this.incorporation,
    required this.region,
  }) : id = id ?? const Uuid().v4();
  
  /// Create a CulturalElement from a JSON map.
  factory CulturalElement.fromJson(Map<String, dynamic> json) {
    return CulturalElement(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String,
      description: json['description'] as String,
      significance: json['significance'] as String,
      incorporation: json['incorporation'] as String,
      region: json['region'] as String,
    );
  }
  
  /// Convert this CulturalElement to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'significance': significance,
      'incorporation': incorporation,
      'region': region,
    };
  }
}

/// Model for age range.
class AgeRange {
  /// Minimum age in the range.
  final int minAge;
  
  /// Maximum age in the range.
  final int maxAge;
  
  /// Create a new AgeRange.
  AgeRange({
    required this.minAge,
    required this.maxAge,
  });
  
  /// Create an AgeRange from a JSON map.
  factory AgeRange.fromJson(Map<String, dynamic> json) {
    return AgeRange(
      minAge: json['minAge'] as int,
      maxAge: json['maxAge'] as int,
    );
  }
  
  /// Convert this AgeRange to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
    };
  }
  
  /// Get the age range as a string.
  String get displayString => '$minAge-$maxAge';
  
  /// Check if this age range includes a specific age.
  bool includesAge(int age) {
    return age >= minAge && age <= maxAge;
  }
  
  /// Check if this age range overlaps with another age range.
  bool overlaps(AgeRange other) {
    return (minAge <= other.maxAge) && (maxAge >= other.minAge);
  }
}
