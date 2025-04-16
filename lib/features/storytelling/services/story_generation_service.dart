import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/enhanced_story_model.dart';
import '../repositories/story_repository.dart';
import 'dart:math' as math;

/// Enhanced service for generating stories with educational focus.
///
/// This service provides methods for generating stories based on
/// educational criteria, learning objectives, and user preferences.
class StoryGenerationService {
  final StoryRepository _repository;
  final StorageService _storageService;

  /// Create a new StoryGenerationService.
  StoryGenerationService({
    StoryRepository? repository,
    StorageService? storageService,
  }) :
    _repository = repository ?? StoryRepository(StorageService().storage),
    _storageService = storageService ?? StorageService();

  /// Initialize the service.
  Future<void> initialize() async {
    await _repository.initialize();
  }

  /// Generate a story based on user preferences.
  ///
  /// [userId] is the ID of the user.
  /// [theme] is the preferred theme (optional).
  /// [region] is the preferred region (optional).
  /// [ageGroup] is the preferred age group (optional).
  /// [learningConcepts] is the list of learning concepts to include (optional).
  /// [difficultyLevel] is the preferred difficulty level (optional).
  ///
  /// Returns a generated story.
  Future<EnhancedStoryModel> generateStory({
    required String userId,
    String? theme,
    String? region,
    String? ageGroup,
    List<String>? learningConcepts,
    int? difficultyLevel,
  }) async {
    // We'll use the user's skill level to determine difficulty

    // Get user's skill level
    final skillLevel = await _calculateUserSkillLevel(userId);

    // Get user's learning path type
    final learningPathType = await _getUserLearningPathType(userId);

    // Determine appropriate difficulty level
    final targetDifficulty = difficultyLevel ?? _calculateAppropriateLevel(skillLevel);

    // Determine appropriate learning concepts
    final targetConcepts = learningConcepts ?? await _getAppropriateConceptsForUser(userId);

    // Generate story metadata
    final metadata = await _generateStoryMetadata(
      theme: theme,
      region: region,
      ageGroup: ageGroup,
      learningConcepts: targetConcepts,
      difficultyLevel: targetDifficulty,
      learningPathType: learningPathType,
    );

    // Generate story content
    final story = await _generateStoryContent(metadata);

    return story;
  }

  /// Generate a story based on educational standards.
  ///
  /// [standardIds] is the list of educational standard IDs to align with.
  /// [userId] is the ID of the user (optional).
  ///
  /// Returns a generated story aligned with the specified standards.
  Future<EnhancedStoryModel> generateStoryForStandards({
    required List<String> standardIds,
    String? userId,
  }) async {
    // Get user's skill level if userId is provided
    int skillLevel = 2; // Default to intermediate
    if (userId != null) {
      skillLevel = await _calculateUserSkillLevel(userId);
    }

    // Generate story metadata with standards alignment
    final metadata = await _generateStoryMetadataForStandards(
      standardIds: standardIds,
      skillLevel: skillLevel,
    );

    // Generate story content
    final story = await _generateStoryContent(metadata);

    return story;
  }

  /// Generate a story based on coding concepts.
  ///
  /// [conceptIds] is the list of coding concept IDs to cover.
  /// [userId] is the ID of the user (optional).
  ///
  /// Returns a generated story covering the specified coding concepts.
  Future<EnhancedStoryModel> generateStoryForConcepts({
    required List<String> conceptIds,
    String? userId,
  }) async {
    // Get user's skill level if userId is provided
    int skillLevel = 2; // Default to intermediate
    if (userId != null) {
      skillLevel = await _calculateUserSkillLevel(userId);
    }

    // Generate story metadata with concept coverage
    final metadata = await _generateStoryMetadataForConcepts(
      conceptIds: conceptIds,
      skillLevel: skillLevel,
    );

    // Generate story content
    final story = await _generateStoryContent(metadata);

    return story;
  }

  /// Generate a story for a learning path.
  ///
  /// [learningPathType] is the type of learning path.
  /// [userId] is the ID of the user (optional).
  ///
  /// Returns a generated story suitable for the specified learning path.
  Future<EnhancedStoryModel> generateStoryForLearningPath({
    required LearningPathType learningPathType,
    String? userId,
  }) async {
    // Get user's skill level if userId is provided
    int skillLevel = 2; // Default to intermediate
    if (userId != null) {
      skillLevel = await _calculateUserSkillLevel(userId);
    }

    // Generate story metadata for learning path
    final metadata = await _generateStoryMetadataForLearningPath(
      learningPathType: learningPathType,
      skillLevel: skillLevel,
    );

    // Generate story content
    final story = await _generateStoryContent(metadata);

    return story;
  }

  /// Generate story metadata.
  ///
  /// This is a placeholder implementation that would be replaced
  /// with actual AI-driven metadata generation.
  Future<Map<String, dynamic>> _generateStoryMetadata({
    String? theme,
    String? region,
    String? ageGroup,
    List<String>? learningConcepts,
    int? difficultyLevel,
    LearningPathType? learningPathType,
  }) async {
    // Default values
    theme = theme ?? _getRandomTheme();
    region = region ?? _getRandomRegion();
    ageGroup = ageGroup ?? '7-12';
    learningConcepts = learningConcepts ?? ['sequences', 'loops'];
    difficultyLevel = difficultyLevel ?? 2;

    // Adjust content based on learning path type
    List<String> adjustedConcepts = List<String>.from(learningConcepts);
    if (learningPathType != null) {
      switch (learningPathType) {
        case LearningPathType.logicBased:
          if (!adjustedConcepts.contains('algorithms')) {
            adjustedConcepts.add('algorithms');
          }
          break;
        case LearningPathType.creativityBased:
          if (!adjustedConcepts.contains('patterns')) {
            adjustedConcepts.add('patterns');
          }
          break;
        case LearningPathType.challengeBased:
          if (!adjustedConcepts.contains('conditionals')) {
            adjustedConcepts.add('conditionals');
          }
          break;
        default:
          break;
      }
    }

    // Generate educational standards based on concepts
    final educationalStandards = _generateStandardsForConcepts(adjustedConcepts);

    // Generate learning objectives based on concepts
    final learningObjectives = _generateLearningObjectivesForConcepts(adjustedConcepts);

    // Generate prerequisite concepts
    final prerequisiteConcepts = _generatePrerequisitesForConcepts(adjustedConcepts);

    return {
      'theme': theme,
      'region': region,
      'ageGroup': ageGroup,
      'learningConcepts': adjustedConcepts,
      'difficultyLevel': difficultyLevel,
      'educationalStandards': educationalStandards,
      'learningObjectives': learningObjectives,
      'prerequisiteConcepts': prerequisiteConcepts,
      'skillLevel': difficultyLevel,
      'estimatedTimeMinutes': difficultyLevel * 5 + 10,
    };
  }

  /// Generate story metadata for standards alignment.
  Future<Map<String, dynamic>> _generateStoryMetadataForStandards({
    required List<String> standardIds,
    int skillLevel = 2,
  }) async {
    // Generate concepts based on standards
    final concepts = _generateConceptsForStandards(standardIds);

    // Generate metadata with these concepts
    return _generateStoryMetadata(
      learningConcepts: concepts,
      difficultyLevel: skillLevel,
    );
  }

  /// Generate story metadata for concept coverage.
  Future<Map<String, dynamic>> _generateStoryMetadataForConcepts({
    required List<String> conceptIds,
    int skillLevel = 2,
  }) async {
    // Generate metadata with these concepts
    return _generateStoryMetadata(
      learningConcepts: conceptIds,
      difficultyLevel: skillLevel,
    );
  }

  /// Generate story metadata for a learning path.
  Future<Map<String, dynamic>> _generateStoryMetadataForLearningPath({
    required LearningPathType learningPathType,
    int skillLevel = 2,
  }) async {
    // Generate concepts based on learning path
    final concepts = _generateConceptsForLearningPath(learningPathType);

    // Generate metadata with these concepts and learning path
    return _generateStoryMetadata(
      learningConcepts: concepts,
      difficultyLevel: skillLevel,
      learningPathType: learningPathType,
    );
  }

  /// Generate story content based on metadata.
  ///
  /// This is a placeholder implementation that would be replaced
  /// with actual AI-driven content generation.
  Future<EnhancedStoryModel> _generateStoryContent(Map<String, dynamic> metadata) async {
    // Extract metadata
    final theme = metadata['theme'] as String;
    final region = metadata['region'] as String;
    final ageGroup = metadata['ageGroup'] as String;
    final learningConcepts = List<String>.from(metadata['learningConcepts']);
    final difficultyLevel = metadata['difficultyLevel'] as int;
    final educationalStandards = List<String>.from(metadata['educationalStandards']);
    final learningObjectives = List<String>.from(metadata['learningObjectives']);
    final prerequisiteConcepts = List<String>.from(metadata['prerequisiteConcepts']);
    final skillLevel = metadata['skillLevel'] as int;
    final estimatedTimeMinutes = metadata['estimatedTimeMinutes'] as int;

    // Generate a title
    final title = _generateTitle(theme, learningConcepts);

    // Generate a character name
    final characterName = _generateCharacterName(region);

    // Generate a description
    final description = _generateDescription(title, learningConcepts);

    // Content blocks will be generated later when needed

    // Create the story model
    return EnhancedStoryModel(
      title: title,
      theme: theme,
      region: region,
      characterName: characterName,
      ageGroup: ageGroup,
      content: [],
      learningConcepts: learningConcepts,
      difficultyLevel: difficultyLevel,
      description: description,
      educationalStandards: educationalStandards,
      learningObjectives: learningObjectives,
      prerequisiteConcepts: prerequisiteConcepts,
      skillLevel: skillLevel,
      estimatedTimeMinutes: estimatedTimeMinutes,
      educationalContext: _generateEducationalContext(learningConcepts),
    );
  }

  /// Calculate the user's skill level based on mastered concepts.
  Future<int> _calculateUserSkillLevel(String userId) async {
    // Get user's mastered concepts
    final masteredConcepts = await _storageService.getUserMasteredConcepts(userId);

    // Calculate skill level based on number of mastered concepts
    if (masteredConcepts.isEmpty) return 1;
    if (masteredConcepts.length < 3) return 2;
    if (masteredConcepts.length < 6) return 3;
    if (masteredConcepts.length < 10) return 4;
    return 5;
  }

  /// Get the user's learning path type.
  Future<LearningPathType> _getUserLearningPathType(String userId) async {
    // Get user's learning path type from preferences
    final preferences = await _storageService.getUserPreferences(userId);
    final pathTypeStr = preferences['learningPathType'] as String?;

    // Convert string to enum if available
    if (pathTypeStr != null) {
      if (pathTypeStr == 'logicBased') {
        return LearningPathType.logicBased;
      } else if (pathTypeStr == 'creativityBased') {
        return LearningPathType.creativityBased;
      } else if (pathTypeStr == 'challengeBased') {
        return LearningPathType.challengeBased;
      }
    }

    // Default to balanced
    return LearningPathType.balanced;
  }

  /// Calculate an appropriate difficulty level based on user skill level.
  int _calculateAppropriateLevel(int skillLevel) {
    // Slightly adjust difficulty to provide appropriate challenge
    return math.min(skillLevel + 1, 5);
  }

  /// Get appropriate concepts for a user based on their progress.
  Future<List<String>> _getAppropriateConceptsForUser(String userId) async {
    // Get user's mastered and in-progress concepts
    final masteredConcepts = await _storageService.getUserMasteredConcepts(userId);
    final inProgressConcepts = await _storageService.getUserInProgressConcepts(userId);

    // If user has in-progress concepts, prioritize those
    if (inProgressConcepts.isNotEmpty) {
      return inProgressConcepts.take(2).toList();
    }

    // If user has mastered concepts, introduce a new concept
    if (masteredConcepts.isNotEmpty) {
      final newConcept = _getNextConceptToLearn(masteredConcepts);
      return [masteredConcepts.first, newConcept];
    }

    // Default to basic concepts for beginners
    return ['sequences', 'loops'];
  }

  /// Get the next concept to learn based on mastered concepts.
  String _getNextConceptToLearn(List<String> masteredConcepts) {
    // Define concept progression
    final conceptProgression = [
      'sequences',
      'loops',
      'conditionals',
      'variables',
      'functions',
      'events',
      'operators',
      'data',
      'algorithms',
      'patterns',
    ];

    // Find the first concept not yet mastered
    for (final concept in conceptProgression) {
      if (!masteredConcepts.contains(concept)) {
        return concept;
      }
    }

    // Default to a random advanced concept
    final advancedConcepts = ['algorithms', 'patterns', 'data'];
    return advancedConcepts[math.Random().nextInt(advancedConcepts.length)];
  }

  /// Generate educational standards based on concepts.
  List<String> _generateStandardsForConcepts(List<String> concepts) {
    // Map concepts to standards (simplified implementation)
    final standardsMap = {
      'sequences': ['CSTA-1A-AP-10', 'K12CS-P4.1'],
      'loops': ['CSTA-1A-AP-11', 'K12CS-P4.2'],
      'conditionals': ['CSTA-1A-AP-12', 'K12CS-P4.3'],
      'variables': ['CSTA-1A-AP-13', 'K12CS-P4.4'],
      'functions': ['CSTA-1A-AP-14', 'K12CS-P4.5'],
      'events': ['CSTA-1A-AP-15', 'K12CS-P4.6'],
      'operators': ['CSTA-1A-AP-16', 'K12CS-P4.7'],
      'data': ['CSTA-1A-DA-07', 'K12CS-P7.1'],
      'algorithms': ['CSTA-1A-AP-08', 'K12CS-P4.4'],
      'patterns': ['CSTA-1A-AP-09', 'K12CS-P4.1'],
    };

    // Collect standards for the given concepts
    final standards = <String>[];
    for (final concept in concepts) {
      if (standardsMap.containsKey(concept)) {
        standards.addAll(standardsMap[concept]!);
      }
    }

    return standards.toSet().toList(); // Remove duplicates
  }

  /// Generate learning objectives based on concepts.
  List<String> _generateLearningObjectivesForConcepts(List<String> concepts) {
    // Map concepts to learning objectives (simplified implementation)
    final objectivesMap = {
      'sequences': ['Create a sequence of instructions', 'Understand program flow'],
      'loops': ['Use loops to repeat actions', 'Identify patterns that can be looped'],
      'conditionals': ['Use if statements to make decisions', 'Create branching logic'],
      'variables': ['Store and retrieve data using variables', 'Modify variable values'],
      'functions': ['Create reusable functions', 'Pass parameters to functions'],
      'events': ['Respond to user input', 'Trigger actions based on events'],
      'operators': ['Use arithmetic operators', 'Compare values using operators'],
      'data': ['Collect and analyze data', 'Represent information as data'],
      'algorithms': ['Design step-by-step solutions', 'Optimize algorithms for efficiency'],
      'patterns': ['Identify repeating patterns', 'Create patterns using code'],
    };

    // Collect objectives for the given concepts
    final objectives = <String>[];
    for (final concept in concepts) {
      if (objectivesMap.containsKey(concept)) {
        objectives.addAll(objectivesMap[concept]!);
      }
    }

    return objectives;
  }

  /// Generate prerequisite concepts based on target concepts.
  List<String> _generatePrerequisitesForConcepts(List<String> concepts) {
    // Map concepts to prerequisites (simplified implementation)
    final prerequisitesMap = {
      'loops': ['sequences'],
      'conditionals': ['sequences'],
      'variables': ['sequences'],
      'functions': ['sequences', 'variables'],
      'events': ['sequences', 'conditionals'],
      'operators': ['variables'],
      'data': ['variables'],
      'algorithms': ['sequences', 'loops', 'conditionals'],
      'patterns': ['sequences', 'loops'],
    };

    // Collect prerequisites for the given concepts
    final prerequisites = <String>[];
    for (final concept in concepts) {
      if (prerequisitesMap.containsKey(concept)) {
        prerequisites.addAll(prerequisitesMap[concept]!);
      }
    }

    // Remove concepts that are already in the target list
    prerequisites.removeWhere((prerequisite) => concepts.contains(prerequisite));

    return prerequisites.toSet().toList(); // Remove duplicates
  }

  /// Generate concepts based on standards.
  List<String> _generateConceptsForStandards(List<String> standardIds) {
    // Map standards to concepts (simplified implementation)
    final conceptsMap = {
      'CSTA-1A-AP-10': ['sequences'],
      'CSTA-1A-AP-11': ['loops'],
      'CSTA-1A-AP-12': ['conditionals'],
      'CSTA-1A-AP-13': ['variables'],
      'CSTA-1A-AP-14': ['functions'],
      'CSTA-1A-AP-15': ['events'],
      'CSTA-1A-AP-16': ['operators'],
      'CSTA-1A-DA-07': ['data'],
      'CSTA-1A-AP-08': ['algorithms'],
      'CSTA-1A-AP-09': ['patterns'],
      'K12CS-P4.1': ['sequences', 'patterns'],
      'K12CS-P4.2': ['loops'],
      'K12CS-P4.3': ['conditionals'],
      'K12CS-P4.4': ['variables', 'algorithms'],
      'K12CS-P4.5': ['functions'],
      'K12CS-P4.6': ['events'],
      'K12CS-P4.7': ['operators'],
      'K12CS-P7.1': ['data'],
    };

    // Collect concepts for the given standards
    final concepts = <String>[];
    for (final standardId in standardIds) {
      if (conceptsMap.containsKey(standardId)) {
        concepts.addAll(conceptsMap[standardId]!);
      }
    }

    return concepts.toSet().toList(); // Remove duplicates
  }

  /// Generate concepts based on learning path.
  List<String> _generateConceptsForLearningPath(LearningPathType learningPathType) {
    switch (learningPathType) {
      case LearningPathType.logicBased:
        return ['sequences', 'conditionals', 'algorithms'];
      case LearningPathType.creativityBased:
        return ['sequences', 'loops', 'patterns'];
      case LearningPathType.challengeBased:
        return ['conditionals', 'functions', 'algorithms'];
      case LearningPathType.balanced:
        return ['sequences', 'loops', 'conditionals'];
    }
  }

  /// Generate a title for a story.
  String _generateTitle(String theme, List<String> concepts) {
    // Simplified implementation
    final conceptWord = concepts.isNotEmpty ? _getConceptWord(concepts.first) : 'Pattern';
    return 'The $conceptWord of ${theme.capitalize()}';
  }

  /// Generate a character name based on region.
  String _generateCharacterName(String region) {
    // Simplified implementation with region-specific names
    final namesMap = {
      'Ghana': ['Kwame', 'Ama', 'Kofi', 'Akua', 'Yaw'],
      'Nigeria': ['Chinua', 'Ngozi', 'Oluwaseun', 'Adebayo', 'Folami'],
      'Kenya': ['Kamau', 'Wanjiku', 'Ochieng', 'Akinyi', 'Muthoni'],
      'South Africa': ['Thabo', 'Nomsa', 'Sipho', 'Thandi', 'Mandla'],
      'Ethiopia': ['Abebe', 'Makeda', 'Desta', 'Seble', 'Hakim'],
    };

    final names = namesMap[region] ?? ['Anansi', 'Mwezi', 'Tafari', 'Zola', 'Amara'];
    return names[math.Random().nextInt(names.length)];
  }

  /// Generate a description for a story.
  String _generateDescription(String title, List<String> concepts) {
    // Simplified implementation
    final conceptsText = concepts.map((c) => c.capitalize()).join(', ');
    return 'Join us on an adventure to learn about $conceptsText through the art of Kente weaving. In "$title", you will discover how traditional patterns connect to coding concepts.';
  }

  /// Generate educational context for a story.
  String _generateEducationalContext(List<String> concepts) {
    // Simplified implementation
    final conceptsText = concepts.map((c) => c.capitalize()).join(', ');
    return 'This story teaches $conceptsText through the cultural context of Kente weaving. Students will learn how traditional patterns and coding concepts share similar structures and principles.';
  }

  /// Get a word related to a concept for use in titles.
  String _getConceptWord(String concept) {
    // Map concepts to related words for titles
    final wordMap = {
      'sequences': 'Journey',
      'loops': 'Pattern',
      'conditionals': 'Choice',
      'variables': 'Transformation',
      'functions': 'Craft',
      'events': 'Celebration',
      'operators': 'Magic',
      'data': 'Wisdom',
      'algorithms': 'Method',
      'patterns': 'Design',
    };

    return wordMap[concept] ?? 'Adventure';
  }

  /// Get a random theme.
  String _getRandomTheme() {
    final themes = [
      'wisdom',
      'courage',
      'unity',
      'heritage',
      'creativity',
      'perseverance',
      'harmony',
      'transformation',
    ];

    return themes[math.Random().nextInt(themes.length)];
  }

  /// Get a random region.
  String _getRandomRegion() {
    final regions = [
      'Ghana',
      'Nigeria',
      'Kenya',
      'South Africa',
      'Ethiopia',
    ];

    return regions[math.Random().nextInt(regions.length)];
  }
}

/// Extension to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
