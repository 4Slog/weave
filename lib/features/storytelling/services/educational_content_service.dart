import 'package:kente_codeweaver/core/services/storage/storage_service_refactored.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/enhanced_story_model.dart';
import '../models/story_metadata_model.dart';
import '../repositories/story_repository.dart';

/// Service for managing educational content in stories.
///
/// This service provides methods for aligning stories with educational
/// standards, managing learning objectives, and creating educational
/// assessments.
class EducationalContentService {
  final StoryRepository _repository;
  final StorageService _storageService;

  /// Create a new EducationalContentService.
  EducationalContentService({
    StoryRepository? repository,
    StorageService? storageService,
  }) :
    _repository = repository ?? StoryRepository(StorageService().storage),
    _storageService = storageService ?? StorageService();

  /// Initialize the service.
  Future<void> initialize() async {
    await _repository.initialize();
  }

  /// Align a story with educational standards.
  ///
  /// [story] is the story to align.
  /// [standardIds] is the list of standard IDs to align with.
  ///
  /// Returns the aligned story.
  Future<EnhancedStoryModel> alignStoryWithStandards(
    EnhancedStoryModel story,
    List<String> standardIds,
  ) async {
    // Get existing metadata or create new metadata
    StoryMetadataModel metadata = await _repository.getStoryMetadata(story.id) ??
                                 StoryMetadataModel(
                                   storyId: story.id,
                                   ageRange: AgeRange(minAge: 7, maxAge: 15),
                                   difficultyLevel: story.difficultyLevel,
                                 );

    // Create standard alignments
    final standardsAlignment = <StandardAlignment>[];
    for (final standardId in standardIds) {
      final standardInfo = await _getStandardInfo(standardId);
      if (standardInfo != null) {
        standardsAlignment.add(StandardAlignment(
          standardId: standardId,
          standardType: standardInfo['type'] ?? '',
          description: standardInfo['description'] ?? '',
          alignmentDescription: _generateAlignmentDescription(story, standardId),
        ));
      }
    }

    // Update metadata
    final updatedMetadata = metadata.copyWith(
      standardsAlignment: standardsAlignment,
    );

    // Save metadata
    await _repository.saveStoryMetadata(updatedMetadata);

    // Update story with standards
    final updatedStory = story.copyWithEnhanced(
      educationalStandards: standardIds,
    );

    // Save updated story
    await _repository.saveStory(updatedStory);

    return updatedStory;
  }

  /// Add learning objectives to a story.
  ///
  /// [story] is the story to update.
  /// [objectives] is the list of learning objectives to add.
  ///
  /// Returns the updated story.
  Future<EnhancedStoryModel> addLearningObjectives(
    EnhancedStoryModel story,
    List<String> objectives,
  ) async {
    // Get existing metadata or create new metadata
    StoryMetadataModel metadata = await _repository.getStoryMetadata(story.id) ??
                                 StoryMetadataModel(
                                   storyId: story.id,
                                   ageRange: AgeRange(minAge: 7, maxAge: 15),
                                   difficultyLevel: story.difficultyLevel,
                                 );

    // Create learning objectives
    final learningObjectives = <LearningObjective>[];
    for (final objective in objectives) {
      learningObjectives.add(LearningObjective(
        description: objective,
        implementation: _generateObjectiveImplementation(story, objective),
        assessmentMethod: _generateAssessmentMethod(objective),
      ));
    }

    // Update metadata
    final updatedMetadata = metadata.copyWith(
      learningObjectives: learningObjectives,
    );

    // Save metadata
    await _repository.saveStoryMetadata(updatedMetadata);

    // Update story with learning objectives
    final updatedStory = story.copyWithEnhanced(
      learningObjectives: objectives,
    );

    // Save updated story
    await _repository.saveStory(updatedStory);

    return updatedStory;
  }

  /// Add coding concepts to a story.
  ///
  /// [story] is the story to update.
  /// [concepts] is the map of concept IDs to descriptions.
  ///
  /// Returns the updated story.
  Future<EnhancedStoryModel> addCodingConcepts(
    EnhancedStoryModel story,
    Map<String, String> concepts,
  ) async {
    // Get existing metadata or create new metadata
    StoryMetadataModel metadata = await _repository.getStoryMetadata(story.id) ??
                                 StoryMetadataModel(
                                   storyId: story.id,
                                   ageRange: AgeRange(minAge: 7, maxAge: 15),
                                   difficultyLevel: story.difficultyLevel,
                                 );

    // Create coding concept coverage
    final codingConcepts = <CodingConceptCoverage>[];
    for (final entry in concepts.entries) {
      final conceptId = entry.key;
      final description = entry.value;

      codingConcepts.add(CodingConceptCoverage(
        conceptId: conceptId,
        conceptName: _getConceptName(conceptId),
        description: description,
        coverageDescription: _generateConceptCoverageDescription(story, conceptId),
        depthOfCoverage: _calculateConceptDepth(story, conceptId),
      ));
    }

    // Update metadata
    final updatedMetadata = metadata.copyWith(
      codingConcepts: codingConcepts,
    );

    // Save metadata
    await _repository.saveStoryMetadata(updatedMetadata);

    // Update story with coding concepts explained
    final updatedStory = story.copyWithEnhanced(
      codingConceptsExplained: concepts,
    );

    // Save updated story
    await _repository.saveStory(updatedStory);

    return updatedStory;
  }

  /// Add cultural elements to a story.
  ///
  /// [story] is the story to update.
  /// [elements] is the list of cultural elements to add.
  ///
  /// Returns the updated story.
  Future<EnhancedStoryModel> addCulturalElements(
    EnhancedStoryModel story,
    List<Map<String, String>> elements,
  ) async {
    // Get existing metadata or create new metadata
    StoryMetadataModel metadata = await _repository.getStoryMetadata(story.id) ??
                                 StoryMetadataModel(
                                   storyId: story.id,
                                   ageRange: AgeRange(minAge: 7, maxAge: 15),
                                   difficultyLevel: story.difficultyLevel,
                                 );

    // Create cultural elements
    final culturalElements = <CulturalElement>[];
    for (final element in elements) {
      culturalElements.add(CulturalElement(
        name: element['name'] ?? '',
        description: element['description'] ?? '',
        significance: element['significance'] ?? '',
        incorporation: element['incorporation'] ?? '',
        region: element['region'] ?? story.region,
      ));
    }

    // Update metadata
    final updatedMetadata = metadata.copyWith(
      culturalElements: culturalElements,
    );

    // Save metadata
    await _repository.saveStoryMetadata(updatedMetadata);

    // Update story with cultural significance
    final culturalSignificance = <String, String>{};
    for (final element in elements) {
      final name = element['name'] ?? '';
      final significance = element['significance'] ?? '';
      if (name.isNotEmpty && significance.isNotEmpty) {
        culturalSignificance[name] = significance;
      }
    }

    final updatedStory = story.copyWithEnhanced(
      culturalSignificance: culturalSignificance,
    );

    // Save updated story
    await _repository.saveStory(updatedStory);

    return updatedStory;
  }

  /// Create assessment questions for a story.
  ///
  /// [story] is the story to create questions for.
  /// [count] is the number of questions to create.
  ///
  /// Returns the updated story with assessment questions.
  Future<EnhancedStoryModel> createAssessmentQuestions(
    EnhancedStoryModel story,
    int count,
  ) async {
    // Generate assessment questions based on story content and concepts
    final questions = <StoryAssessmentQuestion>[];

    // Get concepts from the story
    final concepts = story.learningConcepts;

    // Generate questions for each concept
    for (final concept in concepts) {
      if (questions.length >= count) break;

      // Generate a question for this concept
      final question = _generateQuestionForConcept(concept);
      if (question != null) {
        questions.add(question);
      }
    }

    // If we need more questions, generate general questions
    while (questions.length < count) {
      final question = _generateGeneralQuestion(story);
      if (question != null) {
        questions.add(question);
      }
    }

    // Update story with assessment questions
    final updatedStory = story.copyWithEnhanced(
      assessmentQuestions: questions,
    );

    // Save updated story
    await _repository.saveStory(updatedStory);

    return updatedStory;
  }

  /// Get stories aligned with educational standards.
  ///
  /// [standardIds] is the list of standard IDs to filter by.
  ///
  /// Returns a list of stories aligned with the specified standards.
  Future<List<EnhancedStoryModel>> getStoriesAlignedWithStandards(
    List<String> standardIds,
  ) async {
    final allStories = await _repository.getAllStories();

    // Filter stories that align with any of the specified standards
    return allStories.where((story) {
      for (final standardId in standardIds) {
        if (story.educationalStandards.contains(standardId)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Get stories covering specific coding concepts.
  ///
  /// [conceptIds] is the list of concept IDs to filter by.
  ///
  /// Returns a list of stories covering the specified concepts.
  Future<List<EnhancedStoryModel>> getStoriesCoveringConcepts(
    List<String> conceptIds,
  ) async {
    final allStories = await _repository.getAllStories();

    // Filter stories that cover any of the specified concepts
    return allStories.where((story) {
      for (final conceptId in conceptIds) {
        if (story.learningConcepts.contains(conceptId)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Get stories appropriate for a learning path.
  ///
  /// [learningPathType] is the type of learning path.
  ///
  /// Returns a list of stories appropriate for the specified learning path.
  Future<List<EnhancedStoryModel>> getStoriesForLearningPath(
    LearningPathType learningPathType,
  ) async {
    final allStories = await _repository.getAllStories();

    // Filter stories based on learning path type
    switch (learningPathType) {
      case LearningPathType.logicBased:
        // For logic-based paths, prioritize stories with logical concepts
        return allStories.where((story) =>
          story.learningConcepts.any((concept) =>
            ['sequences', 'loops', 'conditionals', 'functions', 'algorithms'].contains(concept)
          )
        ).toList();

      case LearningPathType.creativityBased:
        // For creativity-based paths, prioritize stories with creative concepts
        return allStories.where((story) =>
          story.learningConcepts.any((concept) =>
            ['patterns', 'design', 'creativity', 'expression', 'art'].contains(concept)
          )
        ).toList();

      case LearningPathType.challengeBased:
        // For challenge-based paths, prioritize more difficult stories
        return allStories.where((story) => story.difficultyLevel >= 3).toList();

      case LearningPathType.balanced:
        // For balanced paths, return all stories
        return allStories;
    }
  }

  /// Get stories appropriate for a user's skill level.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of stories appropriate for the user's skill level.
  Future<List<EnhancedStoryModel>> getStoriesForUserSkillLevel(
    String userId,
  ) async {
    // Calculate user's skill level
    final skillLevel = await _calculateUserSkillLevel(userId);

    // Get stories appropriate for this skill level
    return _repository.getStoriesForSkillLevel(skillLevel);
  }

  /// Get stories with prerequisites satisfied by a user.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns a list of stories with prerequisites satisfied by the user.
  Future<List<EnhancedStoryModel>> getStoriesWithPrerequisitesSatisfied(
    String userId,
  ) async {
    // Get user's mastered concepts
    final masteredConcepts = await _storageService.getUserMasteredConcepts(userId);

    // Get stories with prerequisites satisfied
    return _repository.getStoriesWithPrerequisitesSatisfied(masteredConcepts);
  }

  /// Get recommended stories for a user.
  ///
  /// [userId] is the ID of the user.
  /// [count] is the number of stories to recommend.
  ///
  /// Returns a list of recommended stories for the user.
  Future<List<EnhancedStoryModel>> getRecommendedStories(
    String userId,
    int count,
  ) async {
    // Get user's mastered concepts
    final masteredConcepts = await _storageService.getUserMasteredConcepts(userId);

    // Get user's in-progress concepts
    final inProgressConcepts = await _storageService.getUserInProgressConcepts(userId);

    // Get user's learning path type
    final learningPathType = await _getUserLearningPathType(userId);

    // Get stories with prerequisites satisfied
    final eligibleStories = await _repository.getStoriesWithPrerequisitesSatisfied(masteredConcepts);

    // Filter stories that haven't been completed
    final completedStories = await _repository.getCompletedStories(userId);
    final completedIds = completedStories.map((s) => s.id).toSet();
    final uncompletedStories = eligibleStories.where((s) => !completedIds.contains(s.id)).toList();

    // If there are no uncompleted stories, return completed stories for review
    if (uncompletedStories.isEmpty) {
      return completedStories.take(count).toList();
    }

    // Score stories based on relevance to user's learning needs
    final scoredStories = <MapEntry<EnhancedStoryModel, double>>[];
    for (final story in uncompletedStories) {
      double score = 0.0;

      // Higher score for stories covering in-progress concepts
      for (final concept in story.learningConcepts) {
        if (inProgressConcepts.contains(concept)) {
          score += 2.0;
        }
      }

      // Higher score for stories aligned with learning path
      if (learningPathType == LearningPathType.logicBased &&
          story.learningConcepts.any((c) => ['sequences', 'loops', 'conditionals', 'functions', 'algorithms'].contains(c))) {
        score += 1.0;
      } else if (learningPathType == LearningPathType.creativityBased &&
                story.learningConcepts.any((c) => ['patterns', 'design', 'creativity', 'expression', 'art'].contains(c))) {
        score += 1.0;
      } else if (learningPathType == LearningPathType.challengeBased &&
                story.difficultyLevel >= 3) {
        score += 1.0;
      }

      // Higher score for stories with appropriate difficulty
      final skillLevel = await _calculateUserSkillLevel(userId);
      if (story.difficultyLevel == skillLevel) {
        score += 1.0;
      } else if (story.difficultyLevel == skillLevel + 1) {
        score += 0.5; // Slightly challenging
      }

      scoredStories.add(MapEntry(story, score));
    }

    // Sort stories by score (highest first)
    scoredStories.sort((a, b) => b.value.compareTo(a.value));

    // Return top stories
    return scoredStories.take(count).map((entry) => entry.key).toList();
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

  /// Get information about an educational standard.
  Future<Map<String, String>?> _getStandardInfo(String standardId) async {
    // This is a simplified implementation
    // A more sophisticated approach would use a standards repository

    final standardsInfo = {
      'CSTA-1A-AP-10': {
        'type': 'CSTA',
        'description': 'Develop programs with sequences and simple loops, to express ideas or address a problem.',
      },
      'CSTA-1A-AP-11': {
        'type': 'CSTA',
        'description': 'Decompose (break down) the steps needed to solve a problem into a precise sequence of instructions.',
      },
      'CSTA-1A-AP-12': {
        'type': 'CSTA',
        'description': 'Develop plans that describe a program\'s sequence of events, goals, and expected outcomes.',
      },
      'K12CS-P4.1': {
        'type': 'K12CS',
        'description': 'The ability to recognize patterns and use pattern recognition to understand complicated phenomena.',
      },
      'K12CS-P4.2': {
        'type': 'K12CS',
        'description': 'The ability to identify, understand, and use repetition in programming and algorithms.',
      },
      'K12CS-P4.3': {
        'type': 'K12CS',
        'description': 'The ability to use conditional statements to make decisions in algorithms and programs.',
      },
    };

    return standardsInfo[standardId];
  }

  /// Generate a description of how a story aligns with a standard.
  String _generateAlignmentDescription(EnhancedStoryModel story, String standardId) {
    // This is a simplified implementation
    // A more sophisticated approach would analyze the story content

    if (standardId.contains('AP-10')) {
      return 'This story demonstrates sequences and simple loops through the Kente weaving process, where patterns are created through repeated sequences of actions.';
    } else if (standardId.contains('AP-11')) {
      return 'The story breaks down the Kente weaving process into a precise sequence of instructions, helping students understand decomposition.';
    } else if (standardId.contains('AP-12')) {
      return 'Through the story, students develop a plan for creating a Kente pattern, including the sequence of events and expected outcomes.';
    } else if (standardId.contains('P4.1')) {
      return 'The story helps students recognize patterns in Kente designs and relate them to patterns in code.';
    } else if (standardId.contains('P4.2')) {
      return 'Students learn about repetition by identifying repeating elements in Kente patterns and implementing them using loops.';
    } else if (standardId.contains('P4.3')) {
      return 'The story introduces conditional logic through decision points in the Kente design process.';
    } else {
      return 'This story aligns with the standard by providing a cultural context for learning coding concepts.';
    }
  }

  /// Generate a description of how a learning objective is implemented in a story.
  String _generateObjectiveImplementation(EnhancedStoryModel story, String objective) {
    // This is a simplified implementation
    // A more sophisticated approach would analyze the story content

    if (objective.contains('sequence')) {
      return 'The story presents the Kente weaving process as a sequence of steps, helping students understand program flow.';
    } else if (objective.contains('loop')) {
      return 'Students identify repeating patterns in Kente designs and implement them using loops in their code.';
    } else if (objective.contains('conditional') || objective.contains('decision')) {
      return 'The story includes decision points where different design choices lead to different outcomes, illustrating conditional logic.';
    } else if (objective.contains('variable')) {
      return 'Students learn to use variables to store and modify values representing different aspects of their Kente designs.';
    } else if (objective.contains('function')) {
      return 'The story introduces functions as reusable weaving techniques that can be applied in different contexts.';
    } else if (objective.contains('pattern')) {
      return 'Students identify and create patterns in their Kente designs, connecting traditional patterns to coding concepts.';
    } else {
      return 'This objective is implemented through guided activities and reflections throughout the story.';
    }
  }

  /// Generate an assessment method for a learning objective.
  String _generateAssessmentMethod(String objective) {
    // This is a simplified implementation
    // A more sophisticated approach would use a variety of assessment methods

    if (objective.contains('create') || objective.contains('design')) {
      return 'Students will create a project demonstrating their understanding of the concept.';
    } else if (objective.contains('identify') || objective.contains('recognize')) {
      return 'Students will identify examples of the concept in given scenarios.';
    } else if (objective.contains('use') || objective.contains('apply')) {
      return 'Students will apply the concept to solve a problem.';
    } else if (objective.contains('understand') || objective.contains('explain')) {
      return 'Students will explain the concept in their own words.';
    } else {
      return 'Students will complete a multiple-choice assessment to demonstrate understanding.';
    }
  }

  /// Generate a description of how a coding concept is covered in a story.
  String _generateConceptCoverageDescription(EnhancedStoryModel story, String conceptId) {
    // This is a simplified implementation
    // A more sophisticated approach would analyze the story content

    switch (conceptId) {
      case 'sequences':
        return 'The story presents the Kente weaving process as a sequence of steps, showing how instructions are executed in order.';
      case 'loops':
        return 'Students identify repeating patterns in Kente designs and learn how loops can efficiently create repetition in code.';
      case 'conditionals':
        return 'The story includes decision points where different choices lead to different outcomes, illustrating how conditionals work in code.';
      case 'variables':
        return 'Students learn how variables can store and represent different aspects of their Kente designs, such as colors and pattern elements.';
      case 'functions':
        return 'The story introduces functions as reusable weaving techniques that can be named and called in different contexts.';
      case 'patterns':
        return 'Students explore how patterns in Kente designs can be represented and created using code.';
      case 'algorithms':
        return 'The story presents the Kente weaving process as an algorithm with specific steps to achieve a desired outcome.';
      default:
        return 'This concept is covered through examples and activities integrated throughout the story.';
    }
  }

  /// Calculate the depth of coverage for a concept in a story.
  int _calculateConceptDepth(EnhancedStoryModel story, String conceptId) {
    // This is a simplified implementation
    // A more sophisticated approach would analyze the story content

    // Check if the concept is explicitly mentioned in learning concepts
    if (story.learningConcepts.contains(conceptId)) {
      // Primary concepts get higher depth
      if (story.learningConcepts.indexOf(conceptId) < 2) {
        return 4; // Advanced coverage
      } else {
        return 3; // Intermediate coverage
      }
    }

    // Check if the concept is mentioned in the description
    if (story.description.toLowerCase().contains(conceptId.toLowerCase())) {
      return 2; // Basic coverage
    }

    // Otherwise, assume introductory coverage
    return 1;
  }

  /// Get a human-readable name for a concept.
  String _getConceptName(String conceptId) {
    // Map concept IDs to human-readable names
    final conceptNames = {
      'sequences': 'Sequences',
      'loops': 'Loops',
      'conditionals': 'Conditionals',
      'variables': 'Variables',
      'functions': 'Functions',
      'events': 'Events',
      'operators': 'Operators',
      'data': 'Data',
      'algorithms': 'Algorithms',
      'patterns': 'Patterns',
    };

    return conceptNames[conceptId] ?? conceptId.capitalize();
  }

  /// Generate an assessment question for a specific concept.
  StoryAssessmentQuestion? _generateQuestionForConcept(String concept) {
    // This is a simplified implementation
    // A more sophisticated approach would generate questions based on story content

    switch (concept) {
      case 'sequences':
        return StoryAssessmentQuestion(
          question: 'What is the correct order for creating a basic Kente pattern?',
          options: [
            'Design, Weave, Plan, Color',
            'Plan, Design, Color, Weave',
            'Color, Plan, Design, Weave',
            'Weave, Color, Plan, Design',
          ],
          correctAnswerIndex: 1,
          explanation: 'Creating a Kente pattern follows a sequence: first plan the pattern, then design the layout, choose colors, and finally weave the pattern.',
          conceptAssessed: 'sequences',
        );
      case 'loops':
        return StoryAssessmentQuestion(
          question: 'Why do weavers use repeated patterns in Kente cloth?',
          options: [
            'To save time only',
            'Because they can\'t create new patterns',
            'To create visual rhythm and meaning',
            'Because the loom requires it',
          ],
          correctAnswerIndex: 2,
          explanation: 'Repeated patterns in Kente cloth create visual rhythm and convey cultural meaning, similar to how loops in code create repetition efficiently.',
          conceptAssessed: 'loops',
        );
      case 'conditionals':
        return StoryAssessmentQuestion(
          question: 'In the story, when does the weaver decide to change colors?',
          options: [
            'At random points',
            'When specific conditions in the pattern are met',
            'Only at the beginning of each row',
            'Never - colors are fixed throughout',
          ],
          correctAnswerIndex: 1,
          explanation: 'The weaver changes colors when specific conditions in the pattern are met, similar to how conditional statements in code execute different actions based on conditions.',
          conceptAssessed: 'conditionals',
        );
      case 'variables':
        return StoryAssessmentQuestion(
          question: 'What does the color variable represent in Kente patterns?',
          options: [
            'Only decoration',
            'The weaver\'s personal preference',
            'Cultural meanings and values',
            'The type of thread used',
          ],
          correctAnswerIndex: 2,
          explanation: 'Colors in Kente patterns represent cultural meanings and values, similar to how variables in code can represent meaningful data.',
          conceptAssessed: 'variables',
        );
      case 'functions':
        return StoryAssessmentQuestion(
          question: 'How are named pattern techniques in Kente weaving similar to functions in code?',
          options: [
            'They aren\'t similar at all',
            'They both have colorful names',
            'They are reusable procedures that can be called when needed',
            'They both require special tools',
          ],
          correctAnswerIndex: 2,
          explanation: 'Named pattern techniques in Kente weaving are reusable procedures that can be called when needed, similar to functions in code.',
          conceptAssessed: 'functions',
        );
      case 'patterns':
        return StoryAssessmentQuestion(
          question: 'What is the relationship between patterns in Kente cloth and patterns in code?',
          options: [
            'There is no relationship',
            'Both use repetition and structure to create meaning',
            'Kente patterns are always more complex',
            'Code patterns are always more precise',
          ],
          correctAnswerIndex: 1,
          explanation: 'Both Kente patterns and code patterns use repetition and structure to create meaning and achieve specific outcomes.',
          conceptAssessed: 'patterns',
        );
      default:
        return null;
    }
  }

  /// Generate a general question about the story.
  StoryAssessmentQuestion? _generateGeneralQuestion(EnhancedStoryModel story) {
    // This is a simplified implementation
    // A more sophisticated approach would generate questions based on story content

    return StoryAssessmentQuestion(
      question: 'What is the main connection between Kente weaving and coding in the story?',
      options: [
        'There is no connection',
        'Both require computers',
        'Both use patterns and sequences to create something meaningful',
        'Both originated in the same region',
      ],
      correctAnswerIndex: 2,
      explanation: 'The story shows how both Kente weaving and coding use patterns and sequences to create something meaningful, connecting traditional crafts to modern technology.',
      conceptAssessed: 'general',
    );
  }
}

/// Extension to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
