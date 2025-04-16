
/// Represents a user's mastery of a specific coding concept
class ConceptMastery {
  /// The concept identifier
  final String conceptId;
  
  /// Proficiency level from 0.0 (not started) to 1.0 (mastered)
  final double proficiency;
  
  /// Number of successful applications of this concept
  final int successfulApplications;
  
  /// Number of failed applications of this concept
  final int failedApplications;
  
  /// Last time this concept was practiced
  final DateTime lastPracticed;
  
  /// When this concept was first introduced
  final DateTime firstIntroduced;
  
  /// Practical demonstrations of understanding (e.g., challenge completions)
  final List<String> demonstrations;
  
  /// Related concepts that build on this one
  final List<String> relatedConcepts;
  
  /// Create a concept mastery object
  ConceptMastery({
    required this.conceptId,
    this.proficiency = 0.0,
    this.successfulApplications = 0,
    this.failedApplications = 0,
    DateTime? lastPracticed,
    DateTime? firstIntroduced,
    this.demonstrations = const [],
    this.relatedConcepts = const [],
  }) : 
    lastPracticed = lastPracticed ?? DateTime.now(),
    firstIntroduced = firstIntroduced ?? DateTime.now();
  
  /// Create a concept mastery object from a map
  factory ConceptMastery.fromMap(Map<String, dynamic> map) {
    return ConceptMastery(
      conceptId: map['conceptId'] as String,
      proficiency: map['proficiency'] as double,
      successfulApplications: map['successfulApplications'] as int,
      failedApplications: map['failedApplications'] as int,
      lastPracticed: DateTime.parse(map['lastPracticed'] as String),
      firstIntroduced: DateTime.parse(map['firstIntroduced'] as String),
      demonstrations: List<String>.from(map['demonstrations'] ?? []),
      relatedConcepts: List<String>.from(map['relatedConcepts'] ?? []),
    );
  }
  
  /// Convert this concept mastery to a map
  Map<String, dynamic> toMap() {
    return {
      'conceptId': conceptId,
      'proficiency': proficiency,
      'successfulApplications': successfulApplications,
      'failedApplications': failedApplications,
      'lastPracticed': lastPracticed.toIso8601String(),
      'firstIntroduced': firstIntroduced.toIso8601String(),
      'demonstrations': demonstrations,
      'relatedConcepts': relatedConcepts,
    };
  }
  
  /// Create a copy with updated fields
  ConceptMastery copyWith({
    String? conceptId,
    double? proficiency,
    int? successfulApplications,
    int? failedApplications,
    DateTime? lastPracticed,
    DateTime? firstIntroduced,
    List<String>? demonstrations,
    List<String>? relatedConcepts,
  }) {
    return ConceptMastery(
      conceptId: conceptId ?? this.conceptId,
      proficiency: proficiency ?? this.proficiency,
      successfulApplications: successfulApplications ?? this.successfulApplications,
      failedApplications: failedApplications ?? this.failedApplications,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      firstIntroduced: firstIntroduced ?? this.firstIntroduced,
      demonstrations: demonstrations ?? this.demonstrations,
      relatedConcepts: relatedConcepts ?? this.relatedConcepts,
    );
  }
  
  /// Record a successful application of this concept
  ConceptMastery recordSuccess() {
    final newSuccessCount = successfulApplications + 1;
    final totalAttempts = newSuccessCount + failedApplications;
    
    // Calculate new proficiency based on success rate and number of attempts
    // More attempts with high success rate = higher proficiency
    final successRate = newSuccessCount / totalAttempts;
    final attemptFactor = 1.0 - (1.0 / (totalAttempts + 1)); // Approaches 1.0 as attempts increase
    final newProficiency = successRate * attemptFactor;
    
    // Cap at 1.0
    final cappedProficiency = newProficiency > 1.0 ? 1.0 : newProficiency;
    
    return copyWith(
      successfulApplications: newSuccessCount,
      proficiency: cappedProficiency,
      lastPracticed: DateTime.now(),
    );
  }
  
  /// Record a failed application of this concept
  ConceptMastery recordFailure() {
    final newFailedCount = failedApplications + 1;
    final totalAttempts = successfulApplications + newFailedCount;
    
    // Calculate new proficiency based on success rate and number of attempts
    final successRate = successfulApplications / totalAttempts;
    final attemptFactor = 1.0 - (1.0 / (totalAttempts + 1));
    final newProficiency = successRate * attemptFactor;
    
    // Cap at 1.0
    final cappedProficiency = newProficiency > 1.0 ? 1.0 : newProficiency;
    
    return copyWith(
      failedApplications: newFailedCount,
      proficiency: cappedProficiency,
      lastPracticed: DateTime.now(),
    );
  }
  
  /// Add a demonstration of this concept
  ConceptMastery addDemonstration(String demonstrationId) {
    if (demonstrations.contains(demonstrationId)) {
      return this;
    }
    
    final newDemonstrations = List<String>.from(demonstrations)..add(demonstrationId);
    
    // Increase proficiency slightly for each new demonstration
    final demonstrationBonus = 0.05 * newDemonstrations.length;
    final newProficiency = proficiency + 0.05;
    
    // Cap at 1.0
    final cappedProficiency = newProficiency > 1.0 ? 1.0 : newProficiency;
    
    return copyWith(
      demonstrations: newDemonstrations,
      proficiency: cappedProficiency,
    );
  }
  
  /// Check if this concept is considered mastered (proficiency >= 0.8)
  bool get isMastered => proficiency >= 0.8;
  
  /// Get the time since this concept was last practiced
  Duration get timeSinceLastPractice => DateTime.now().difference(lastPracticed);
  
  /// Check if this concept needs review (mastered but not practiced recently)
  bool get needsReview => isMastered && timeSinceLastPractice.inDays > 14;
}
