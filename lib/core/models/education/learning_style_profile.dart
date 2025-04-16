/// Enum representing different learning styles based on the VARK model.
enum LearningStyle {
  /// Visual learners prefer using images, pictures, colors, and maps.
  visual,
  
  /// Auditory learners prefer using sound, music, recordings, rhymes, and rhythms.
  auditory,
  
  /// Reading/writing learners prefer using words, reading texts, and writing notes.
  reading,
  
  /// Kinesthetic learners prefer using their hands and bodies through touch, movement, and physical activity.
  kinesthetic,
  
  /// Multimodal learners have multiple preferences and can adapt to different learning styles.
  multimodal,
}

/// Model representing a user's learning style profile.
/// 
/// This model contains information about a user's learning style preferences,
/// including their dominant style and specific preferences.
class LearningStyleProfile {
  /// Unique identifier for the user.
  final String userId;
  
  /// The user's dominant learning style.
  final LearningStyle dominantStyle;
  
  /// Scores for each learning style (0.0 to 1.0).
  final Map<LearningStyle, double> scores;
  
  /// Specific preferences within each learning style.
  final Map<String, bool> preferences;
  
  /// When this profile was last updated.
  final DateTime lastUpdated;
  
  /// Creates a new LearningStyleProfile.
  LearningStyleProfile({
    required this.userId,
    required this.dominantStyle,
    required this.scores,
    this.preferences = const {},
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();
  
  /// Create a copy of this LearningStyleProfile with some fields replaced.
  LearningStyleProfile copyWith({
    String? userId,
    LearningStyle? dominantStyle,
    Map<LearningStyle, double>? scores,
    Map<String, bool>? preferences,
    DateTime? lastUpdated,
  }) {
    return LearningStyleProfile(
      userId: userId ?? this.userId,
      dominantStyle: dominantStyle ?? this.dominantStyle,
      scores: scores ?? this.scores,
      preferences: preferences ?? this.preferences,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
  
  /// Convert this LearningStyleProfile to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dominantStyle': dominantStyle.toString().split('.').last,
      'scores': scores.map((key, value) => 
          MapEntry(key.toString().split('.').last, value)),
      'preferences': preferences,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Create a LearningStyleProfile from a JSON map.
  factory LearningStyleProfile.fromJson(Map<String, dynamic> json) {
    // Parse the dominant style
    final dominantStyleStr = json['dominantStyle'] as String;
    final dominantStyle = LearningStyle.values.firstWhere(
      (style) => style.toString().split('.').last == dominantStyleStr,
      orElse: () => LearningStyle.multimodal,
    );
    
    // Parse the scores
    final scoresMap = <LearningStyle, double>{};
    (json['scores'] as Map<String, dynamic>).forEach((key, value) {
      final style = LearningStyle.values.firstWhere(
        (style) => style.toString().split('.').last == key,
        orElse: () => LearningStyle.multimodal,
      );
      scoresMap[style] = (value as num).toDouble();
    });
    
    return LearningStyleProfile(
      userId: json['userId'],
      dominantStyle: dominantStyle,
      scores: scoresMap,
      preferences: (json['preferences'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as bool)
      ) ?? {},
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }
  
  /// Get the score for a specific learning style.
  double getScoreForStyle(LearningStyle style) {
    return scores[style] ?? 0.0;
  }
  
  /// Check if a specific preference is enabled.
  bool hasPreference(String preference) {
    return preferences[preference] ?? false;
  }
  
  /// Get all enabled preferences.
  List<String> getEnabledPreferences() {
    return preferences.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get the top N learning styles by score.
  List<LearningStyle> getTopStyles(int count) {
    final sortedStyles = LearningStyle.values.toList()
      ..sort((a, b) => (scores[b] ?? 0.0).compareTo(scores[a] ?? 0.0));
    
    return sortedStyles.take(count).toList();
  }
  
  /// Check if this profile has a strong preference for a specific style.
  /// 
  /// A strong preference is defined as a score at least 0.2 higher than the next highest score.
  bool hasStrongPreference() {
    final sortedScores = scores.values.toList()..sort((a, b) => b.compareTo(a));
    
    if (sortedScores.length < 2) return true;
    
    return (sortedScores[0] - sortedScores[1]) >= 0.2;
  }
}
