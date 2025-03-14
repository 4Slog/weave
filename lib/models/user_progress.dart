class UserProgress {
  final String userId;
  final List<String> completedStories;
  final Map<String, int> storyScores;
  final int totalBlocks;
  final int currentLevel;

  UserProgress({
    required this.userId,
    this.completedStories = const [],
    this.storyScores = const {},
    this.totalBlocks = 0,
    this.currentLevel = 1,
  });

  UserProgress copyWith({
    String? userId,
    List<String>? completedStories,
    Map<String, int>? storyScores,
    int? totalBlocks,
    int? currentLevel,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      completedStories: completedStories ?? this.completedStories,
      storyScores: storyScores ?? this.storyScores,
      totalBlocks: totalBlocks ?? this.totalBlocks,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'],
      completedStories: List<String>.from(json['completedStories']),
      storyScores: Map<String, int>.from(json['storyScores']),
      totalBlocks: json['totalBlocks'],
      currentLevel: json['currentLevel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'completedStories': completedStories,
      'storyScores': storyScores,
      'totalBlocks': totalBlocks,
      'currentLevel': currentLevel,
    };
  }
}