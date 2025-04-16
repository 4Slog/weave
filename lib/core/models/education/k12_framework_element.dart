/// Model representing a K-12 Computer Science Framework element.
/// 
/// This model contains information about a specific element from the
/// K-12 Computer Science Framework, including its identifier, description,
/// and concept area.
class K12CSFrameworkElement {
  /// Unique identifier for the framework element.
  final String id;
  
  /// The core concept this element belongs to (e.g., "Computing Systems").
  final String coreConcept;
  
  /// The subconcept within the core concept (e.g., "Devices").
  final String subconcept;
  
  /// Detailed description of the framework element.
  final String description;
  
  /// Grade band for this element (e.g., "K-2", "3-5", "6-8", "9-12").
  final String gradeBand;
  
  /// Practices associated with this framework element.
  final List<String> practices;
  
  /// Creates a new K12CSFrameworkElement.
  K12CSFrameworkElement({
    required this.id,
    required this.coreConcept,
    required this.subconcept,
    required this.description,
    required this.gradeBand,
    this.practices = const [],
  });
  
  /// Create a copy of this K12CSFrameworkElement with some fields replaced.
  K12CSFrameworkElement copyWith({
    String? id,
    String? coreConcept,
    String? subconcept,
    String? description,
    String? gradeBand,
    List<String>? practices,
  }) {
    return K12CSFrameworkElement(
      id: id ?? this.id,
      coreConcept: coreConcept ?? this.coreConcept,
      subconcept: subconcept ?? this.subconcept,
      description: description ?? this.description,
      gradeBand: gradeBand ?? this.gradeBand,
      practices: practices ?? this.practices,
    );
  }
  
  /// Convert this K12CSFrameworkElement to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coreConcept': coreConcept,
      'subconcept': subconcept,
      'description': description,
      'gradeBand': gradeBand,
      'practices': practices,
    };
  }
  
  /// Create a K12CSFrameworkElement from a JSON map.
  factory K12CSFrameworkElement.fromJson(Map<String, dynamic> json) {
    return K12CSFrameworkElement(
      id: json['id'],
      coreConcept: json['coreConcept'],
      subconcept: json['subconcept'],
      description: json['description'],
      gradeBand: json['gradeBand'],
      practices: List<String>.from(json['practices'] ?? []),
    );
  }
  
  @override
  String toString() {
    return 'K12CSFrameworkElement: $id - $description';
  }
}
