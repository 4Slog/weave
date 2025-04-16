import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import '../models/enhanced_story_model.dart';
import '../models/story_metadata_model.dart';
import 'story_provider_refactored.dart';

/// Extension of StoryProviderRefactored with educational features.
///
/// This class adds educational features to the StoryProviderRefactored,
/// such as standards alignment, learning objectives, and assessments.
class StoryProviderEducational extends StoryProviderRefactored {
  /// Create a new StoryProviderEducational.
  StoryProviderEducational({
    super.repository,
    super.generationService,
    super.educationalService,
    super.storageService,
  });

  /// Align a story with educational standards.
  Future<EnhancedStoryModel?> alignStoryWithStandards(
    String storyId,
    List<String> standardIds,
  ) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      // Get the story
      final story = await protectedRepository.getStory(storyId);
      if (story == null) {
        protectedErrorMessage = 'Story not found: $storyId';
        protectedIsLoading = false;
        notifyListeners();
        return null;
      }

      // Align the story with standards
      final alignedStory = await protectedEducationalService.alignStoryWithStandards(
        story,
        standardIds,
      );

      // Update in stories list
      final index = protectedStories.indexWhere((s) => s.id == storyId);
      if (index >= 0) {
        protectedStories[index] = alignedStory;
      }

      // Update current story if needed
      if (protectedCurrentStory?.id == storyId) {
        protectedCurrentStory = alignedStory;
      }

      protectedIsLoading = false;
      notifyListeners();

      return alignedStory;
    } catch (e) {
      protectedErrorMessage = 'Failed to align story with standards: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Add learning objectives to a story.
  Future<EnhancedStoryModel?> addLearningObjectives(
    String storyId,
    List<String> objectives,
  ) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      // Get the story
      final story = await protectedRepository.getStory(storyId);
      if (story == null) {
        protectedErrorMessage = 'Story not found: $storyId';
        protectedIsLoading = false;
        notifyListeners();
        return null;
      }

      // Add learning objectives
      final updatedStory = await protectedEducationalService.addLearningObjectives(
        story,
        objectives,
      );

      // Update in stories list
      final index = protectedStories.indexWhere((s) => s.id == storyId);
      if (index >= 0) {
        protectedStories[index] = updatedStory;
      }

      // Update current story if needed
      if (protectedCurrentStory?.id == storyId) {
        protectedCurrentStory = updatedStory;
      }

      protectedIsLoading = false;
      notifyListeners();

      return updatedStory;
    } catch (e) {
      protectedErrorMessage = 'Failed to add learning objectives: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Add coding concepts to a story.
  Future<EnhancedStoryModel?> addCodingConcepts(
    String storyId,
    Map<String, String> concepts,
  ) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      // Get the story
      final story = await protectedRepository.getStory(storyId);
      if (story == null) {
        protectedErrorMessage = 'Story not found: $storyId';
        protectedIsLoading = false;
        notifyListeners();
        return null;
      }

      // Add coding concepts
      final updatedStory = await protectedEducationalService.addCodingConcepts(
        story,
        concepts,
      );

      // Update in stories list
      final index = protectedStories.indexWhere((s) => s.id == storyId);
      if (index >= 0) {
        protectedStories[index] = updatedStory;
      }

      // Update current story if needed
      if (protectedCurrentStory?.id == storyId) {
        protectedCurrentStory = updatedStory;
      }

      protectedIsLoading = false;
      notifyListeners();

      return updatedStory;
    } catch (e) {
      protectedErrorMessage = 'Failed to add coding concepts: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Add cultural elements to a story.
  Future<EnhancedStoryModel?> addCulturalElements(
    String storyId,
    List<Map<String, String>> elements,
  ) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      // Get the story
      final story = await protectedRepository.getStory(storyId);
      if (story == null) {
        protectedErrorMessage = 'Story not found: $storyId';
        protectedIsLoading = false;
        notifyListeners();
        return null;
      }

      // Add cultural elements
      final updatedStory = await protectedEducationalService.addCulturalElements(
        story,
        elements,
      );

      // Update in stories list
      final index = protectedStories.indexWhere((s) => s.id == storyId);
      if (index >= 0) {
        protectedStories[index] = updatedStory;
      }

      // Update current story if needed
      if (protectedCurrentStory?.id == storyId) {
        protectedCurrentStory = updatedStory;
      }

      protectedIsLoading = false;
      notifyListeners();

      return updatedStory;
    } catch (e) {
      protectedErrorMessage = 'Failed to add cultural elements: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Create assessment questions for a story.
  Future<EnhancedStoryModel?> createAssessmentQuestions(
    String storyId,
    int count,
  ) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      // Get the story
      final story = await protectedRepository.getStory(storyId);
      if (story == null) {
        protectedErrorMessage = 'Story not found: $storyId';
        protectedIsLoading = false;
        notifyListeners();
        return null;
      }

      // Create assessment questions
      final updatedStory = await protectedEducationalService.createAssessmentQuestions(
        story,
        count,
      );

      // Update in stories list
      final index = protectedStories.indexWhere((s) => s.id == storyId);
      if (index >= 0) {
        protectedStories[index] = updatedStory;
      }

      // Update current story if needed
      if (protectedCurrentStory?.id == storyId) {
        protectedCurrentStory = updatedStory;
      }

      protectedIsLoading = false;
      notifyListeners();

      return updatedStory;
    } catch (e) {
      protectedErrorMessage = 'Failed to create assessment questions: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Generate a story based on educational standards.
  Future<EnhancedStoryModel?> generateStoryForStandards({
    required List<String> standardIds,
    String? userId,
  }) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      final story = await protectedGenerationService.generateStoryForStandards(
        standardIds: standardIds,
        userId: userId,
      );

      // Save the generated story
      await protectedRepository.saveStory(story);

      // Add to stories list
      protectedStories.add(story);

      protectedIsLoading = false;
      notifyListeners();

      return story;
    } catch (e) {
      protectedErrorMessage = 'Failed to generate story for standards: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Generate a story based on coding concepts.
  Future<EnhancedStoryModel?> generateStoryForConcepts({
    required List<String> conceptIds,
    String? userId,
  }) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      final story = await protectedGenerationService.generateStoryForConcepts(
        conceptIds: conceptIds,
        userId: userId,
      );

      // Save the generated story
      await protectedRepository.saveStory(story);

      // Add to stories list
      protectedStories.add(story);

      protectedIsLoading = false;
      notifyListeners();

      return story;
    } catch (e) {
      protectedErrorMessage = 'Failed to generate story for concepts: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Generate a story for a learning path.
  Future<EnhancedStoryModel?> generateStoryForLearningPath({
    required LearningPathType learningPathType,
    String? userId,
  }) async {
    protectedIsLoading = true;
    notifyListeners();

    try {
      final story = await protectedGenerationService.generateStoryForLearningPath(
        learningPathType: learningPathType,
        userId: userId,
      );

      // Save the generated story
      await protectedRepository.saveStory(story);

      // Add to stories list
      protectedStories.add(story);

      protectedIsLoading = false;
      notifyListeners();

      return story;
    } catch (e) {
      protectedErrorMessage = 'Failed to generate story for learning path: $e';
      protectedIsLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get story metadata.
  Future<StoryMetadataModel?> getStoryMetadata(String storyId) async {
    try {
      return await protectedRepository.getStoryMetadata(storyId);
    } catch (e) {
      protectedErrorMessage = 'Failed to get story metadata: $e';
      notifyListeners();
      return null;
    }
  }

  /// Get educational summary for a story.
  Future<Map<String, dynamic>> getEducationalSummary(String storyId) async {
    try {
      // Get the story
      final story = await protectedRepository.getStory(storyId);
      if (story == null) {
        return {
          'error': 'Story not found',
        };
      }

      // Get the metadata
      final metadata = await protectedRepository.getStoryMetadata(storyId);

      // Create summary
      final summary = {
        'learningObjectives': story.learningObjectives,
        'learningConcepts': story.learningConcepts,
        'educationalStandards': story.educationalStandards,
        'prerequisiteConcepts': story.prerequisiteConcepts,
        'skillLevel': story.skillLevel,
        'skillLevelName': story.skillLevelName,
        'educationalContext': story.educationalContext,
        'codingConceptsExplained': story.codingConceptsExplained,
      };

      // Add metadata if available
      if (metadata != null) {
        summary['metadata'] = metadata.getEducationalSummary();
      }

      return summary;
    } catch (e) {
      protectedErrorMessage = 'Failed to get educational summary: $e';
      notifyListeners();
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get cultural summary for a story.
  Future<Map<String, dynamic>> getCulturalSummary(String storyId) async {
    try {
      // Get the story
      final story = await protectedRepository.getStory(storyId);
      if (story == null) {
        return {
          'error': 'Story not found',
        };
      }

      // Create summary
      return story.getCulturalSummary();
    } catch (e) {
      protectedErrorMessage = 'Failed to get cultural summary: $e';
      notifyListeners();
      return {
        'error': e.toString(),
      };
    }
  }
}
