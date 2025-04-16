/// Model representing an International Society for Technology in Education (ISTE) standard.
/// 
/// This model contains information about a specific ISTE standard,
/// including its identifier, description, and category.
class ISTEStandard {
  /// Unique identifier for the standard (e.g., "1.c").
  final String id;
  
  /// The category this standard belongs to (e.g., "Empowered Learner").
  final String category;
  
  /// The category number (1-7).
  final int categoryNumber;
  
  /// Detailed description of the standard.
  final String description;
  
  /// Age range for this standard (e.g., "5-8", "8-11", "11-14", "14-18").
  final String ageRange;
  
  /// Additional indicators or examples for this standard.
  final List<String> indicators;
  
  /// Creates a new ISTEStandard.
  ISTEStandard({
    required this.id,
    required this.category,
    required this.categoryNumber,
    required this.description,
    required this.ageRange,
    this.indicators = const [],
  });
  
  /// Create a copy of this ISTEStandard with some fields replaced.
  ISTEStandard copyWith({
    String? id,
    String? category,
    int? categoryNumber,
    String? description,
    String? ageRange,
    List<String>? indicators,
  }) {
    return ISTEStandard(
      id: id ?? this.id,
      category: category ?? this.category,
      categoryNumber: categoryNumber ?? this.categoryNumber,
      description: description ?? this.description,
      ageRange: ageRange ?? this.ageRange,
      indicators: indicators ?? this.indicators,
    );
  }
  
  /// Convert this ISTEStandard to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'categoryNumber': categoryNumber,
      'description': description,
      'ageRange': ageRange,
      'indicators': indicators,
    };
  }
  
  /// Create an ISTEStandard from a JSON map.
  factory ISTEStandard.fromJson(Map<String, dynamic> json) {
    return ISTEStandard(
      id: json['id'],
      category: json['category'],
      categoryNumber: json['categoryNumber'],
      description: json['description'],
      ageRange: json['ageRange'],
      indicators: List<String>.from(json['indicators'] ?? []),
    );
  }
  
  @override
  String toString() {
    return 'ISTEStandard: $id - $description';
  }
}
