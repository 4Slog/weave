import 'dart:math';
import 'package:kente_codeweaver/core/services/storage_service.dart';

/// Service for providing cultural context data
class CulturalDataService {
  // Singleton implementation
  static final CulturalDataService _instance = CulturalDataService._internal();

  factory CulturalDataService() {
    return _instance;
  }

  CulturalDataService._internal();

  // Storage service for caching
  final StorageService _storageService = StorageService();

  // Cultural data cache
  final Map<String, Map<String, dynamic>> _cache = {};

  /// Get cultural information for a specific region
  Future<Map<String, dynamic>> getCulturalInfo(String region) async {
    // Check cache first
    if (_cache.containsKey(region)) {
      return _cache[region]!;
    }

    // Check storage
    final cachedData = await _storageService.getCachedData('cultural_$region');
    if (cachedData != null) {
      _cache[region] = Map<String, dynamic>.from(cachedData);
      return _cache[region]!;
    }

    // If not in cache or storage, return default data
    final defaultData = _getDefaultCulturalInfo(region);

    // Cache the data
    _cache[region] = defaultData;
    await _storageService.cacheData('cultural_$region', defaultData);

    return defaultData;
  }

  /// Get cultural information for a specific pattern
  Future<Map<String, dynamic>> getPatternInfo(String patternName) async {
    // Check cache first
    final cacheKey = 'pattern_$patternName';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Check storage
    final cachedData = await _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      _cache[cacheKey] = Map<String, dynamic>.from(cachedData);
      return _cache[cacheKey]!;
    }

    // If not in cache or storage, return default data
    final defaultData = _getDefaultPatternInfo(patternName);

    // Cache the data
    _cache[cacheKey] = defaultData;
    await _storageService.cacheData(cacheKey, defaultData);

    return defaultData;
  }

  /// Get default cultural information for a region
  Map<String, dynamic> _getDefaultCulturalInfo(String region) {
    final lowerRegion = region.toLowerCase();

    switch (lowerRegion) {
      case 'ghana':
        return {
          'region': 'Ghana',
          'description': 'Ghana is known for its rich cultural heritage, including Kente cloth weaving, which originated with the Ashanti people.',
          'traditions': [
            'Kente cloth weaving',
            'Adinkra symbols',
            'Traditional drumming and dance',
          ],
          'significance': 'Kente cloth is not just decorative; each pattern has symbolic meaning and is often worn during important ceremonies.',
        };
      case 'nigeria':
        return {
          'region': 'Nigeria',
          'description': 'Nigeria has a diverse cultural landscape with over 250 ethnic groups, each with unique textile traditions.',
          'traditions': [
            'Adire cloth (indigo-dyed textile)',
            'Aso Oke weaving',
            'Akwete cloth weaving',
          ],
          'significance': 'Nigerian textiles often tell stories of community history and values through their patterns and colors.',
        };
      case 'mali':
        return {
          'region': 'Mali',
          'description': 'Mali has a long tradition of textile arts, particularly known for mudcloth (bogolanfini).',
          'traditions': [
            'Mudcloth (Bogolanfini)',
            'Indigo dyeing',
            'Strip-weaving techniques',
          ],
          'significance': 'Malian textiles often feature geometric patterns that represent concepts from nature and daily life.',
        };
      default:
        return {
          'region': region,
          'description': 'This region has its own unique cultural traditions and textile arts.',
          'traditions': [
            'Traditional weaving',
            'Symbolic patterns',
            'Cultural ceremonies',
          ],
          'significance': 'Textiles in many cultures serve as a form of communication, preserving history and cultural values.',
        };
    }
  }

  /// Get default information for a specific pattern
  Map<String, dynamic> _getDefaultPatternInfo(String patternName) {
    final lowerPattern = patternName.toLowerCase();

    switch (lowerPattern) {
      case 'kente':
        return {
          'name': 'Kente',
          'origin': 'Ghana (Ashanti and Ewe people)',
          'description': 'Kente is a type of silk and cotton fabric made of interwoven cloth strips. It is native to the Akan ethnic group of South Ghana.',
          'significance': 'Each pattern and color in Kente has specific meaning. It was originally worn by royalty during ceremonial events.',
          'colors': {
            'gold': 'Symbolizes status and serenity',
            'yellow': 'Symbolizes fertility and precious minerals',
            'green': 'Symbolizes growth and spiritual renewal',
            'blue': 'Symbolizes peace and harmony',
            'red': 'Symbolizes political and spiritual moods',
            'black': 'Symbolizes maturity and spiritual energy',
          },
          'patterns': [
            'Adweneasa (my thinking)',
            'Babadua (strong staff)',
            'Emaa Da (novel design)',
            'Sika Futuro (gold dust)',
          ],
        };
      case 'adinkra':
        return {
          'name': 'Adinkra',
          'origin': 'Ghana (Ashanti people)',
          'description': 'Adinkra are visual symbols that represent concepts or aphorisms. They are printed on cloth and used in pottery and logos.',
          'significance': 'Adinkra symbols express various themes that relate to the history, beliefs, and philosophy of the Ashanti.',
          'symbols': [
            'Adinkrahene (chief of Adinkra symbols) - greatness, charisma',
            'Dwennimmen (ram\'s horns) - humility and strength',
            'Sankofa (return and get it) - learning from the past',
            'Aya (fern) - endurance and resourcefulness',
          ],
        };
      case 'mudcloth':
        return {
          'name': 'Mudcloth (Bogolanfini)',
          'origin': 'Mali (Bamana people)',
          'description': 'Mudcloth is a handmade Malian cotton fabric traditionally dyed with fermented mud, giving it a brown color.',
          'significance': 'The patterns on mudcloth tell stories, record historical events, or represent proverbs and mythological concepts.',
          'process': [
            'Cotton is woven into strips',
            'Designs are painted with mud that has been fermented',
            'The cloth is sun-dried',
            'Areas not painted with mud are bleached, creating contrast',
          ],
        };
      default:
        return {
          'name': patternName,
          'origin': 'Various regions of Africa',
          'description': 'This pattern is part of the rich textile tradition found across Africa.',
          'significance': 'African textile patterns often communicate cultural values, history, and social status.',
        };
    }
  }
}

/// Enhanced cultural data service with additional features
class EnhancedCulturalDataService extends CulturalDataService {
  // Singleton implementation
  static final EnhancedCulturalDataService _instance = EnhancedCulturalDataService._internal();

  factory EnhancedCulturalDataService() {
    return _instance;
  }

  EnhancedCulturalDataService._internal() : super._internal();

  /// Get cultural information with educational context
  Future<Map<String, dynamic>> getCulturalInfoWithEducationalContext(
    String region,
    String educationalTopic
  ) async {
    final baseInfo = await getCulturalInfo(region);

    // Add educational context
    final educationalContext = _getEducationalContext(region, educationalTopic);

    return {
      ...baseInfo,
      'educationalContext': educationalContext,
    };
  }

  /// Get pattern information with coding parallels
  Future<Map<String, dynamic>> getPatternInfoWithCodingParallels(
    String patternName,
    String codingConcept
  ) async {
    final baseInfo = await getPatternInfo(patternName);

    // Add coding parallels
    final codingParallels = _getCodingParallels(patternName, codingConcept);

    return {
      ...baseInfo,
      'codingParallels': codingParallels,
    };
  }

  /// Get educational context for a region and topic
  Map<String, dynamic> _getEducationalContext(String region, String topic) {
    final lowerTopic = topic.toLowerCase();

    switch (lowerTopic) {
      case 'patterns':
        return {
          'topic': 'Patterns',
          'description': 'Patterns in $region textiles demonstrate mathematical concepts like symmetry, repetition, and geometric transformations.',
          'learningPoints': [
            'Identifying repeating units in patterns',
            'Understanding how patterns can be extended',
            'Recognizing symmetry in cultural designs',
          ],
        };
      case 'sequences':
        return {
          'topic': 'Sequences',
          'description': 'The weaving process in $region follows specific sequences that can be related to algorithmic thinking.',
          'learningPoints': [
            'Following step-by-step procedures',
            'Understanding how sequences build complex results',
            'Recognizing patterns in sequences',
          ],
        };
      case 'loops':
        return {
          'topic': 'Loops',
          'description': 'Repetitive elements in $region textiles demonstrate the concept of loops in programming.',
          'learningPoints': [
            'Identifying repeated actions in weaving',
            'Understanding how loops create patterns',
            'Recognizing when to use iteration',
          ],
        };
      case 'conditions':
        return {
          'topic': 'Conditions',
          'description': 'Pattern variations in $region textiles can demonstrate conditional logic similar to if-statements in programming.',
          'learningPoints': [
            'Understanding how pattern choices depend on context',
            'Recognizing decision points in design',
            'Seeing how conditions affect outcomes',
          ],
        };
      default:
        return {
          'topic': topic,
          'description': 'The cultural traditions of $region provide rich context for learning about various concepts.',
          'learningPoints': [
            'Connecting cultural practices to educational concepts',
            'Understanding the knowledge embedded in traditional crafts',
            'Appreciating the wisdom of cultural traditions',
          ],
        };
    }
  }

  /// Get coding parallels for a pattern and coding concept
  Map<String, dynamic> _getCodingParallels(String patternName, String codingConcept) {
    final lowerConcept = codingConcept.toLowerCase();

    switch (lowerConcept) {
      case 'algorithms':
        return {
          'concept': 'Algorithms',
          'description': 'The process of creating $patternName follows a specific algorithm or set of steps, similar to how computer programs execute instructions.',
          'examples': [
            'The weaving process follows a clear sequence of steps',
            'Each pattern has a specific "algorithm" for creation',
            'Modifications to the pattern follow logical rules',
          ],
        };
      case 'loops':
        return {
          'concept': 'Loops',
          'description': 'Repetitive elements in $patternName demonstrate the concept of loops in programming.',
          'examples': [
            'Repeated pattern elements are like for-loops',
            'Continuous borders use the same pattern repeatedly',
            'Nested patterns show nested loops',
          ],
        };
      case 'variables':
        return {
          'concept': 'Variables',
          'description': 'Different elements in $patternName can be seen as variables that change while the overall structure remains the same.',
          'examples': [
            'Colors can change while pattern structure remains constant',
            'Size of elements can vary like parameters',
            'Pattern density can be adjusted like a variable',
          ],
        };
      case 'conditionals':
        return {
          'concept': 'Conditionals',
          'description': 'Pattern variations in $patternName demonstrate conditional logic similar to if-statements in programming.',
          'examples': [
            'Pattern changes at borders show conditional logic',
            'Special elements appear only in certain contexts',
            'Color changes based on position show if-then relationships',
          ],
        };
      default:
        return {
          'concept': codingConcept,
          'description': 'The creation of $patternName involves concepts that parallel many aspects of computer programming.',
          'examples': [
            'Traditional crafts often involve computational thinking',
            'Cultural patterns encode knowledge in systematic ways',
            'Crafting techniques involve logical structures similar to code',
          ],
        };
    }
  }

  /// Get story themes related to a region
  Future<List<String>> getStoryThemes(String region) async {
    final culturalInfo = await getCulturalInfo(region);
    final traditions = culturalInfo['traditions'] as List<dynamic>;

    // Generate story themes based on cultural information
    final themes = [
      'Learning the art of ${traditions.first}',
      'The history of ${culturalInfo['region']}',
      'A journey through ${culturalInfo['region']} traditions',
      'The meaning behind the patterns',
      'Connecting past and present through craft',
    ];

    return themes;
  }

  /// Get character names appropriate for a region
  Future<List<String>> getCharacterNames(String region) async {
    final lowerRegion = region.toLowerCase();

    switch (lowerRegion) {
      case 'ghana':
        return [
          'Kofi', 'Ama', 'Kwame', 'Akua', 'Yaw', 'Abena',
          'Kwesi', 'Esi', 'Kojo', 'Adwoa', 'Kwabena', 'Afia',
        ];
      case 'nigeria':
        return [
          'Chidi', 'Amara', 'Emeka', 'Ngozi', 'Oluwaseun', 'Folami',
          'Adebayo', 'Chioma', 'Olufemi', 'Adanna', 'Tunde', 'Zainab',
        ];
      case 'mali':
        return [
          'Amadou', 'Fatoumata', 'Ibrahim', 'Aissata', 'Moussa', 'Kadiatou',
          'Oumar', 'Mariam', 'Seydou', 'Aminata', 'Modibo', 'Oumou',
        ];
      default:
        return [
          'Kofi', 'Ama', 'Ibrahim', 'Ngozi', 'Moussa', 'Chioma',
          'Kwame', 'Fatoumata', 'Olufemi', 'Aissata', 'Seydou', 'Adanna',
        ];
    }
  }

  /// Get random cultural information
  Future<Map<String, dynamic>> getRandomCulturalInfo() async {
    final regions = ['ghana', 'nigeria', 'mali', 'senegal', 'ethiopia'];
    final random = Random();
    final randomRegion = regions[random.nextInt(regions.length)];

    return await getCulturalInfo(randomRegion);
  }

  /// Initialize the service
  Future<void> initialize() async {
    // Preload some common cultural data
    await getCulturalInfo('ghana');
    await getPatternInfo('kente');
  }
}
