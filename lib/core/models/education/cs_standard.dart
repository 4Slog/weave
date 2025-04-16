/// Model representing a Computer Science Teachers Association (CSTA) standard.
/// 
/// This model contains information about a specific CSTA standard,
/// including its identifier, description, and grade level.
class CSStandard {
  /// Unique identifier for the standard (e.g., "1A-AP-09").
  final String id;
  
  /// The concept area this standard belongs to (e.g., "Algorithms and Programming").
  final String conceptArea;
  
  /// The specific concept within the area (e.g., "Variables").
  final String concept;
  
  /// Detailed description of the standard.
  final String description;
  
  /// Grade level range for this standard (e.g., "K-2", "3-5", "6-8", "9-12").
  final String gradeLevel;
  
  /// Additional practices associated with this standard.
  final List<String> practices;
  
  /// Subcategory or strand within the concept area.
  final String subcategory;
  
  /// Creates a new CSStandard.
  CSStandard({
    required this.id,
    required this.conceptArea,
    required this.concept,
    required this.description,
    required this.gradeLevel,
    this.practices = const [],
    this.subcategory = '',
  });
  
  /// Create a copy of this CSStandard with some fields replaced.
  CSStandard copyWith({
    String? id,
    String? conceptArea,
    String? concept,
    String? description,
    String? gradeLevel,
    List<String>? practices,
    String? subcategory,
  }) {
    return CSStandard(
      id: id ?? this.id,
      conceptArea: conceptArea ?? this.conceptArea,
      concept: concept ?? this.concept,
      description: description ?? this.description,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      practices: practices ?? this.practices,
      subcategory: subcategory ?? this.subcategory,
    );
  }
  
  /// Convert this CSStandard to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conceptArea': conceptArea,
      'concept': concept,
      'description': description,
      'gradeLevel': gradeLevel,
      'practices': practices,
      'subcategory': subcategory,
    };
  }
  
  /// Create a CSStandard from a JSON map.
  factory CSStandard.fromJson(Map<String, dynamic> json) {
    return CSStandard(
      id: json['id'],
      conceptArea: json['conceptArea'],
      concept: json['concept'],
      description: json['description'],
      gradeLevel: json['gradeLevel'],
      practices: List<String>.from(json['practices'] ?? []),
      subcategory: json['subcategory'] ?? '',
    );
  }
  
  @override
  String toString() {
    return 'CSStandard: $id - $description';
  }
}
