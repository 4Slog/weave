import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/education/cs_standard.dart';
import '../../models/education/iste_standard.dart';
import '../../models/education/k12_framework_element.dart';
import '../../models/education/coding_skill.dart';
import '../../models/education/skill_tree.dart';
import '../../models/education/learning_style_profile.dart';
import '../../../features/learning/models/user_progress.dart' as app_models;
import 'storage_strategy.dart';
import 'hive_storage_strategy.dart';
import 'shared_prefs_storage_strategy.dart';
import 'repositories/user_data_repository.dart';
import 'repositories/cs_standards_repository.dart';
import 'repositories/iste_standards_repository.dart';
import 'repositories/k12_framework_repository.dart';
import 'repositories/coding_skill_repository.dart';
import 'repositories/learning_style_repository.dart';

/// Service for managing data storage and retrieval.
///
/// This service provides a unified interface for storing and retrieving
/// various types of data, including user data, educational standards,
/// coding skills, and learning style profiles.
class StorageService {
  // Storage strategies
  late HiveStorageStrategy _hiveStorage;
  late SharedPrefsStorageStrategy _sharedPrefsStorage;

  // Repositories
  late UserDataRepository _userDataRepository;
  late CSStandardsRepository _csStandardsRepository;
  late ISTEStandardsRepository _isteStandardsRepository;
  late K12FrameworkRepository _k12FrameworkRepository;
  late CodingSkillRepository _codingSkillRepository;
  late LearningStyleRepository _learningStyleRepository;

  bool _isInitialized = false;

  // Singleton implementation
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal() {
    _hiveStorage = HiveStorageStrategy('kente_codeweaver');
    _sharedPrefsStorage = SharedPrefsStorageStrategy();

    _userDataRepository = UserDataRepository(_hiveStorage);
    _csStandardsRepository = CSStandardsRepository(_hiveStorage);
    _isteStandardsRepository = ISTEStandardsRepository(_hiveStorage);
    _k12FrameworkRepository = K12FrameworkRepository(_hiveStorage);
    _codingSkillRepository = CodingSkillRepository(_hiveStorage);
    _learningStyleRepository = LearningStyleRepository(_hiveStorage);
  }

  /// Initialize the storage service.
  ///
  /// This must be called before using any other methods.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);

      // Initialize storage strategies
      await _hiveStorage.initialize();
      await _sharedPrefsStorage.initialize();

      // Initialize repositories
      await _userDataRepository.initialize();
      await _csStandardsRepository.initialize();
      await _isteStandardsRepository.initialize();
      await _k12FrameworkRepository.initialize();
      await _codingSkillRepository.initialize();
      await _learningStyleRepository.initialize();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing StorageService: $e');

      // If Hive fails, try to initialize with SharedPreferences only
      try {
        await _sharedPrefsStorage.initialize();

        // Recreate repositories with SharedPreferences
        _userDataRepository = UserDataRepository(_sharedPrefsStorage);
        _csStandardsRepository = CSStandardsRepository(_sharedPrefsStorage);
        _isteStandardsRepository = ISTEStandardsRepository(_sharedPrefsStorage);
        _k12FrameworkRepository = K12FrameworkRepository(_sharedPrefsStorage);
        _codingSkillRepository = CodingSkillRepository(_sharedPrefsStorage);
        _learningStyleRepository = LearningStyleRepository(_sharedPrefsStorage);

        // Initialize repositories
        await _userDataRepository.initialize();
        await _csStandardsRepository.initialize();
        await _isteStandardsRepository.initialize();
        await _k12FrameworkRepository.initialize();
        await _codingSkillRepository.initialize();
        await _learningStyleRepository.initialize();

        _isInitialized = true;
        debugPrint('Initialized StorageService with SharedPreferences fallback');
      } catch (e) {
        debugPrint('Error initializing StorageService with fallback: $e');
        rethrow;
      }
    }
  }

  /// Check if the storage service is initialized.
  bool isInitialized() {
    return _isInitialized;
  }

  /// Get the primary storage strategy.
  ///
  /// This is used by repositories and services that need direct access
  /// to the storage mechanism.
  StorageStrategy get storage => _hiveStorage;

  //
  // User Data Methods
  //

  /// Save user progress data.
  ///
  /// This method accepts both the repository UserProgress model and the app UserProgress model.
  Future<void> saveUserProgress(dynamic progress) async {
    _checkInitialized();
    await _userDataRepository.saveUserProgress(progress);
  }

  /// Get user progress data.
  Future<UserProgress?> getUserProgress(String userId) async {
    _checkInitialized();
    return await _userDataRepository.getUserProgress(userId);
  }

  /// Get the list of concepts that the user has mastered.
  Future<List<String>> getUserMasteredConcepts(String userId) async {
    _checkInitialized();
    final appUserProgress = await _convertToAppUserProgress(userId);
    return appUserProgress?.conceptsMastered ?? [];
  }

  /// Get the list of concepts that the user is currently learning.
  Future<List<String>> getUserInProgressConcepts(String userId) async {
    _checkInitialized();
    final appUserProgress = await _convertToAppUserProgress(userId);
    return appUserProgress?.conceptsInProgress ?? [];
  }

  /// Helper method to convert repository UserProgress to app UserProgress.
  Future<app_models.UserProgress?> _convertToAppUserProgress(String userId) async {
    final repoProgress = await _userDataRepository.getUserProgress(userId);
    if (repoProgress == null) return null;

    // Create a basic app UserProgress with the data we have
    return app_models.UserProgress(
      userId: repoProgress.userId,
      name: 'User', // Default name
      completedChallenges: repoProgress.completedChallenges,
      completedStories: repoProgress.completedStories,
      challengeAttempts: repoProgress.challengeAttempts,
      conceptsMastered: repoProgress.conceptMastery.keys.where(
        (key) => repoProgress.conceptMastery[key]! >= 0.8
      ).toList(),
      conceptsInProgress: repoProgress.conceptMastery.keys.where(
        (key) => repoProgress.conceptMastery[key]! < 0.8 && repoProgress.conceptMastery[key]! > 0.0
      ).toList(),
      experiencePoints: repoProgress.totalPoints,
      lastActiveDate: repoProgress.lastUpdated,
    );
  }

  /// Save user preferences.
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    _checkInitialized();
    await _userDataRepository.saveUserPreferences(userId, preferences);
  }

  /// Get user preferences.
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    _checkInitialized();
    return await _userDataRepository.getUserPreferences(userId);
  }

  /// Save user settings.
  Future<void> saveUserSettings(String userId, Map<String, dynamic> settings) async {
    _checkInitialized();
    await _userDataRepository.saveUserSettings(userId, settings);
  }

  /// Get user settings.
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    _checkInitialized();
    return await _userDataRepository.getUserSettings(userId);
  }

  /// Delete all data for a user.
  Future<void> deleteUserData(String userId) async {
    _checkInitialized();
    await _userDataRepository.deleteUserData(userId);
  }

  //
  // CS Standards Methods
  //

  /// Save a CS standard.
  Future<void> saveCSStandard(CSStandard standard) async {
    _checkInitialized();
    await _csStandardsRepository.saveStandard(standard);
  }

  /// Get a CS standard by ID.
  Future<CSStandard?> getCSStandard(String standardId) async {
    _checkInitialized();
    return await _csStandardsRepository.getStandard(standardId);
  }

  /// Get all CS standards.
  Future<List<CSStandard>> getAllCSStandards() async {
    _checkInitialized();
    return await _csStandardsRepository.getAllStandards();
  }

  /// Get CS standards by grade level.
  Future<List<CSStandard>> getCSStandardsByGradeLevel(String gradeLevel) async {
    _checkInitialized();
    return await _csStandardsRepository.getStandardsByGradeLevel(gradeLevel);
  }

  /// Get CS standards by concept area.
  Future<List<CSStandard>> getCSStandardsByConceptArea(String conceptArea) async {
    _checkInitialized();
    return await _csStandardsRepository.getStandardsByConceptArea(conceptArea);
  }

  /// Import a list of CS standards.
  Future<int> importCSStandards(List<CSStandard> standards) async {
    _checkInitialized();
    return await _csStandardsRepository.importStandards(standards);
  }

  //
  // ISTE Standards Methods
  //

  /// Save an ISTE standard.
  Future<void> saveISTEStandard(ISTEStandard standard) async {
    _checkInitialized();
    await _isteStandardsRepository.saveStandard(standard);
  }

  /// Get an ISTE standard by ID.
  Future<ISTEStandard?> getISTEStandard(String standardId) async {
    _checkInitialized();
    return await _isteStandardsRepository.getStandard(standardId);
  }

  /// Get all ISTE standards.
  Future<List<ISTEStandard>> getAllISTEStandards() async {
    _checkInitialized();
    return await _isteStandardsRepository.getAllStandards();
  }

  /// Get ISTE standards by category.
  Future<List<ISTEStandard>> getISTEStandardsByCategory(String category) async {
    _checkInitialized();
    return await _isteStandardsRepository.getStandardsByCategory(category);
  }

  /// Get ISTE standards by age range.
  Future<List<ISTEStandard>> getISTEStandardsByAgeRange(String ageRange) async {
    _checkInitialized();
    return await _isteStandardsRepository.getStandardsByAgeRange(ageRange);
  }

  /// Import a list of ISTE standards.
  Future<int> importISTEStandards(List<ISTEStandard> standards) async {
    _checkInitialized();
    return await _isteStandardsRepository.importStandards(standards);
  }

  //
  // K-12 CS Framework Methods
  //

  /// Save a K-12 CS Framework element.
  Future<void> saveK12FrameworkElement(K12CSFrameworkElement element) async {
    _checkInitialized();
    await _k12FrameworkRepository.saveElement(element);
  }

  /// Get a K-12 CS Framework element by ID.
  Future<K12CSFrameworkElement?> getK12FrameworkElement(String elementId) async {
    _checkInitialized();
    return await _k12FrameworkRepository.getElement(elementId);
  }

  /// Get all K-12 CS Framework elements.
  Future<List<K12CSFrameworkElement>> getAllK12FrameworkElements() async {
    _checkInitialized();
    return await _k12FrameworkRepository.getAllElements();
  }

  /// Get K-12 CS Framework elements by core concept.
  Future<List<K12CSFrameworkElement>> getK12FrameworkElementsByCoreConcept(String coreConcept) async {
    _checkInitialized();
    return await _k12FrameworkRepository.getElementsByCoreConcept(coreConcept);
  }

  /// Get K-12 CS Framework elements by grade band.
  Future<List<K12CSFrameworkElement>> getK12FrameworkElementsByGradeBand(String gradeBand) async {
    _checkInitialized();
    return await _k12FrameworkRepository.getElementsByGradeBand(gradeBand);
  }

  /// Import a list of K-12 CS Framework elements.
  Future<int> importK12FrameworkElements(List<K12CSFrameworkElement> elements) async {
    _checkInitialized();
    return await _k12FrameworkRepository.importElements(elements);
  }

  //
  // Coding Skill Methods
  //

  /// Save a coding skill.
  Future<void> saveCodingSkill(CodingSkill skill) async {
    _checkInitialized();
    await _codingSkillRepository.saveSkill(skill);
  }

  /// Get a coding skill by ID.
  Future<CodingSkill?> getCodingSkill(String skillId) async {
    _checkInitialized();
    return await _codingSkillRepository.getSkill(skillId);
  }

  /// Get all coding skills.
  Future<List<CodingSkill>> getAllCodingSkills() async {
    _checkInitialized();
    return await _codingSkillRepository.getAllSkills();
  }

  /// Get coding skills by category.
  Future<List<CodingSkill>> getCodingSkillsByCategory(String category) async {
    _checkInitialized();
    return await _codingSkillRepository.getSkillsByCategory(category);
  }

  /// Get coding skills by difficulty level.
  Future<List<CodingSkill>> getCodingSkillsByDifficultyLevel(int difficultyLevel) async {
    _checkInitialized();
    return await _codingSkillRepository.getSkillsByDifficultyLevel(difficultyLevel);
  }

  /// Save a skill tree.
  Future<void> saveSkillTree(SkillTree skillTree) async {
    _checkInitialized();
    await _codingSkillRepository.saveSkillTree(skillTree);
  }

  /// Get a skill tree by ID.
  Future<SkillTree?> getSkillTree({String skillTreeId = 'main'}) async {
    _checkInitialized();
    return await _codingSkillRepository.getSkillTree(skillTreeId);
  }

  /// Save user skill mastery data.
  Future<void> saveUserSkillMastery(String userId, String skillId, double masteryLevel) async {
    _checkInitialized();
    await _codingSkillRepository.saveUserSkillMastery(userId, skillId, masteryLevel);
  }

  /// Get user skill mastery data.
  Future<double> getUserSkillMastery(String userId, String skillId) async {
    _checkInitialized();
    return await _codingSkillRepository.getUserSkillMastery(userId, skillId);
  }

  /// Get all skill mastery data for a user.
  Future<Map<String, double>> getAllUserSkillMastery(String userId) async {
    _checkInitialized();
    return await _codingSkillRepository.getAllUserSkillMastery(userId);
  }

  /// Get recommended next skills for a user.
  Future<List<CodingSkill>> getRecommendedNextSkills(
    String userId,
    {String skillTreeId = 'main', int count = 3}
  ) async {
    _checkInitialized();
    return await _codingSkillRepository.getRecommendedNextSkills(userId, skillTreeId, count: count);
  }

  //
  // Learning Style Methods
  //

  /// Save a learning style profile.
  Future<void> saveLearningStyleProfile(LearningStyleProfile profile) async {
    _checkInitialized();
    await _learningStyleRepository.saveProfile(profile);
  }

  /// Get a learning style profile by user ID.
  Future<LearningStyleProfile?> getLearningStyleProfile(String userId) async {
    _checkInitialized();
    return await _learningStyleRepository.getProfile(userId);
  }

  /// Update a user's learning style scores.
  Future<LearningStyleProfile> updateLearningStyleScores(
    String userId,
    Map<LearningStyle, double> scores
  ) async {
    _checkInitialized();
    return await _learningStyleRepository.updateLearningStyleScores(userId, scores);
  }

  /// Update a user's learning preferences.
  Future<LearningStyleProfile> updateLearningPreferences(
    String userId,
    Map<String, bool> preferences
  ) async {
    _checkInitialized();
    return await _learningStyleRepository.updateLearningPreferences(userId, preferences);
  }

  /// Detect a user's learning style based on interaction data.
  Future<LearningStyleProfile> detectLearningStyle(
    String userId,
    Map<String, dynamic> interactionData
  ) async {
    _checkInitialized();
    return await _learningStyleRepository.detectLearningStyle(userId, interactionData);
  }

  //
  // Legacy Methods (for backward compatibility)
  //

  /// Cache data with a key.
  ///
  /// This is a legacy method for backward compatibility.
  /// New code should use the specific repository methods instead.
  Future<void> cacheData(String key, dynamic data) async {
    _checkInitialized();

    try {
      // Try Hive first
      await _hiveStorage.saveData(key, data);
    } catch (e) {
      debugPrint('Error caching data with Hive, falling back to SharedPreferences: $e');

      // Fall back to SharedPreferences
      try {
        await _sharedPrefsStorage.saveData(key, data);
      } catch (e) {
        debugPrint('Error caching data with SharedPreferences: $e');
        rethrow;
      }
    }
  }

  /// Get cached data by key.
  ///
  /// This is a legacy method for backward compatibility.
  /// New code should use the specific repository methods instead.
  Future<dynamic> getCachedData(String key) async {
    _checkInitialized();

    try {
      // Try Hive first
      final data = await _hiveStorage.getData(key);
      if (data != null) return data;

      // If not found in Hive, try SharedPreferences
      return await _sharedPrefsStorage.getData(key);
    } catch (e) {
      debugPrint('Error getting cached data: $e');
      return null;
    }
  }

  /// Remove cached data by key.
  ///
  /// This is a legacy method for backward compatibility.
  /// New code should use the specific repository methods instead.
  Future<void> removeCachedData(String key) async {
    _checkInitialized();

    try {
      // Remove from both storage strategies
      await _hiveStorage.removeData(key);
      await _sharedPrefsStorage.removeData(key);
    } catch (e) {
      debugPrint('Error removing cached data: $e');
      rethrow;
    }
  }

  /// Clear all cached data.
  ///
  /// This is a legacy method for backward compatibility.
  /// New code should use the specific repository methods instead.
  Future<void> clearCache() async {
    _checkInitialized();

    try {
      // Clear both storage strategies
      await _hiveStorage.clear();
      await _sharedPrefsStorage.clear();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      rethrow;
    }
  }

  // Legacy methods from original StorageService

  /// Load user progress (legacy method)
  Future<UserProgress?> loadUserProgress(String userId) async {
    return await getUserProgress(userId);
  }

  // Legacy methods removed to avoid duplication with the new implementations

  /// Save app settings (legacy method)
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await cacheData(_settingsKey, settings);
  }

  /// Load app settings (legacy method)
  Future<Map<String, dynamic>> loadSettings() async {
    final data = await getCachedData(_settingsKey);
    return data != null ? Map<String, dynamic>.from(data) : {};
  }

  /// Save a block collection (legacy method)
  Future<void> saveBlockCollection(String id, dynamic collection) async {
    await cacheData(_blocksKeyPrefix + id, collection);
  }

  /// Load a block collection (legacy method)
  Future<dynamic> loadBlockCollection(String id) async {
    return await getCachedData(_blocksKeyPrefix + id);
  }

  /// Save a pattern (legacy method)
  Future<void> savePattern(dynamic pattern) async {
    await cacheData(_patternsKeyPrefix + pattern.id, pattern);
  }

  /// Load a pattern (legacy method)
  Future<dynamic> loadPattern(String id) async {
    return await getCachedData(_patternsKeyPrefix + id);
  }

  /// Delete a pattern (legacy method)
  Future<void> deletePattern(String id, String userId) async {
    await removeCachedData(_patternsKeyPrefix + id);
  }

  /// Save a badge (legacy method)
  Future<void> saveBadge(dynamic badge, String userId) async {
    await cacheData(badge.id, badge);
  }

  /// Load a badge (legacy method)
  Future<dynamic> loadBadge(String id) async {
    return await getCachedData(id);
  }

  /// Save blocks for a specific challenge (legacy method)
  Future<void> saveBlocks(String challengeId, String blocksJson) async {
    await cacheData(_blocksKeyPrefix + challengeId, blocksJson);
  }

  /// Get blocks for a specific challenge (legacy method)
  Future<String?> getBlocks(String challengeId) async {
    final data = await getCachedData(_blocksKeyPrefix + challengeId);
    return data is String ? data : null;
  }

  /// Save progress data (legacy method)
  Future<void> saveProgress(String key, String data) async {
    await cacheData(_progressKeyPrefix + key, data);
  }

  /// Get progress data (legacy method)
  Future<String?> getProgress(String key) async {
    final data = await getCachedData(_progressKeyPrefix + key);
    return data is String ? data : null;
  }

  /// Save a setting (legacy method)
  Future<void> saveSetting(String key, String value) async {
    await cacheData(key, value);
  }

  /// Get a setting (legacy method)
  Future<String?> getSetting(String key) async {
    final data = await getCachedData(key);
    return data is String ? data : null;
  }

  /// Get all keys (legacy method)
  Future<List<String>> getAllKeys() async {
    _checkInitialized();

    final hiveKeys = await _hiveStorage.getAllKeys();
    final prefsKeys = await _sharedPrefsStorage.getAllKeys();

    final allKeys = <String>{};
    allKeys.addAll(hiveKeys);
    allKeys.addAll(prefsKeys);

    return allKeys.toList();
  }

  /// Remove progress data (legacy method)
  Future<void> removeProgress(String key) async {
    await removeCachedData(_progressKeyPrefix + key);
  }

  /// Clear all data (legacy method)
  Future<void> clearAllData() async {
    await clearCache();
  }

  /// Ensures the storage service is initialized before performing operations.
  ///
  /// Throws an exception if the service is not initialized.
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }

  // Legacy key constants
  static const String _settingsKey = 'app_settings';
  static const String _blocksKeyPrefix = 'saved_blocks_';
  static const String _patternsKeyPrefix = 'pattern_';
  static const String _progressKeyPrefix = 'user_progress_';
}
