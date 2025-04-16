
/// Model representing a coding challenge in the block workspace
class Challenge {
  /// Unique identifier for the challenge
  final String id;
  
  /// Title of the challenge
  final String title;
  
  /// Description of the challenge
  final String description;
  
  /// Difficulty level (1-5)
  final double difficulty;
  
  /// Concept being taught (e.g., "loops", "conditionals")
  final String conceptId;
  
  /// Block types required for this challenge
  final List<String> requiredBlockTypes;
  
  /// Minimum number of connections required
  final int minConnections;
  
  /// Maximum number of blocks allowed (optional)
  final int? maxBlocks;
  
  /// Template ID to load as a starting point (optional)
  final String? templateId;
  
  /// Hints to provide to the user
  final List<String> hints;
  
  /// Additional requirements for the challenge
  final Map<String, dynamic> requirements;
  
  /// Constructor
  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.conceptId,
    required this.requiredBlockTypes,
    required this.minConnections,
    this.maxBlocks,
    this.templateId,
    this.hints = const [],
    this.requirements = const {},
  });
  
  /// Create a Challenge from JSON
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: (json['difficulty'] as num).toDouble(),
      conceptId: json['conceptId'] as String,
      requiredBlockTypes: (json['requiredBlockTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      minConnections: json['minConnections'] as int,
      maxBlocks: json['maxBlocks'] as int?,
      templateId: json['templateId'] as String?,
      hints: json['hints'] != null
          ? (json['hints'] as List<dynamic>).map((e) => e as String).toList()
          : [],
      requirements: json['requirements'] as Map<String, dynamic>? ?? {},
    );
  }
  
  /// Convert Challenge to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'conceptId': conceptId,
      'requiredBlockTypes': requiredBlockTypes,
      'minConnections': minConnections,
      'maxBlocks': maxBlocks,
      'templateId': templateId,
      'hints': hints,
      'requirements': requirements,
    };
  }
}
