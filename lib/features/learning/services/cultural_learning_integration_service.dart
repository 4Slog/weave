import 'package:flutter/foundation.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_data_service.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_progression_service.dart';
import 'package:kente_codeweaver/features/cultural_context/services/cultural_tradition_service.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path.dart';

/// Service for integrating cultural elements with learning paths
class CulturalLearningIntegrationService {
  /// Cultural data service for retrieving cultural information
  final CulturalDataService _culturalDataService;

  /// Cultural progression service for tracking user progression
  final CulturalProgressionService _culturalProgressionService;

  /// Cultural tradition service for managing traditions
  final CulturalTraditionService _culturalTraditionService;

  /// Flag indicating if the service is initialized
  bool _isInitialized = false;

  /// Create a new cultural learning integration service
  CulturalLearningIntegrationService({
    CulturalDataService? culturalDataService,
    CulturalProgressionService? culturalProgressionService,
    CulturalTraditionService? culturalTraditionService,
  }) :
    _culturalDataService = culturalDataService ?? CulturalDataService(),
    _culturalProgressionService = culturalProgressionService ?? CulturalProgressionService(),
    _culturalTraditionService = culturalTraditionService ?? CulturalTraditionService();

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _culturalDataService.initialize();
    await _culturalProgressionService.initialize();
    await _culturalTraditionService.initialize();

    _isInitialized = true;
    debugPrint('CulturalLearningIntegrationService initialized successfully');
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Enhance a learning path with cultural elements
  Future<LearningPath> enhanceLearningPathWithCulturalElements(
    LearningPath path
  ) async {
    await _ensureInitialized();

    // Create a new list of items with cultural elements added
    final enhancedItems = <LearningPathItem>[];

    for (final item in path.items) {
      // Get cultural elements for this concept
      final culturalElements = await _getCulturalElementsForConcept(
        path.userId,
        item.concept,
      );

      // Get cultural connection for this concept
      final culturalConnection = await _culturalDataService.getCulturalConnectionForConcept(item.concept);

      // Create an enhanced item with cultural elements
      final enhancedItem = LearningPathItem(
        concept: item.concept,
        title: item.title,
        description: item.description,
        skillLevel: item.skillLevel,
        estimatedTimeMinutes: item.estimatedTimeMinutes,
        prerequisites: item.prerequisites,
        resources: item.resources,
        challenges: item.challenges,
        culturalElements: culturalElements,
        culturalConnection: culturalConnection,
      );

      enhancedItems.add(enhancedItem);
    }

    // Create a new learning path with the enhanced items
    return LearningPath(
      pathType: path.pathType,
      items: enhancedItems,
      userId: path.userId,
      generatedAt: path.generatedAt,
    );
  }

  /// Get cultural elements for a concept
  Future<List<Map<String, dynamic>>> _getCulturalElementsForConcept(
    String userId,
    String conceptId,
  ) async {
    // Get the active tradition
    final activeTradition = await _culturalTraditionService.getActiveTradition();
    if (activeTradition == null) {
      return [];
    }

    // Get cultural elements from the tradition service
    final elements = await _culturalTraditionService.getElementsForCodingConcept(
      conceptId,
      traditionId: activeTradition.id,
    );

    // Convert to the format expected by LearningPathItem
    final result = <Map<String, dynamic>>[];

    for (final element in elements) {
      result.add({
        'id': element.id,
        'name': element.name,
        'englishName': element.englishName,
        'type': element.type,
        'description': element.description,
        'culturalSignificance': element.culturalSignificance,
        'tradition': element.tradition,
        'imagePath': element.imagePath,
        'educationalValue': element.educationalValue,
      });

      // Record exposure to this element
      await _recordElementExposure(userId, element);
    }

    return result;
  }

  /// Record exposure to a cultural element
  Future<void> _recordElementExposure(
    String userId,
    dynamic element,
  ) async {
    final type = element.type;
    final id = element.id;

    switch (type) {
      case 'pattern':
        await _culturalProgressionService.recordPatternExposure(userId, id);
        break;
      case 'symbol':
        await _culturalProgressionService.recordSymbolExposure(userId, id);
        break;
      case 'color':
        await _culturalProgressionService.recordColorExposure(userId, id);
        break;
      default:
        // Unknown element type
        break;
    }
  }

  /// Get the best cultural elements to teach a concept
  Future<Map<String, dynamic>> getBestCulturalElementsForConcept(
    String userId,
    String conceptId,
  ) async {
    await _ensureInitialized();

    return await _culturalProgressionService.getCulturalElementsForConcept(
      userId,
      conceptId,
    );
  }

  /// Record teaching a concept with a cultural element
  Future<void> recordConceptTeaching(
    String userId,
    String conceptId,
    String elementId,
  ) async {
    await _ensureInitialized();

    await _culturalProgressionService.recordConceptTeaching(
      userId,
      conceptId,
      elementId,
    );
  }

  /// Get a user's cultural diversity score
  Future<double> getUserCulturalDiversityScore(String userId) async {
    await _ensureInitialized();

    return await _culturalProgressionService.getUserCulturalDiversityScore(userId);
  }

  /// Get a summary of a user's cultural progression
  Future<Map<String, dynamic>> getUserCulturalProgressionSummary(String userId) async {
    await _ensureInitialized();

    return await _culturalProgressionService.getUserProgressionSummary(userId);
  }
}
