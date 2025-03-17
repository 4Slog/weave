// Define achievements structure
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String imageAssetPath;
  final Map<String, double> requiredSkills; // Skills and min proficiency required
  final String? storyReward; // Reward story unlocked by this badge
  final int tier; // 1=basic, 2=intermediate, 3=advanced
  
  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAssetPath,
    this.requiredSkills = const {},
    this.storyReward,
    this.tier = 1,
  });
  
  // Badge tiers represent the difficulty level:
  // Tier 1: Basic achievements - accessible to beginners (ages 7-9)
  // Tier 2: Intermediate achievements - require some skill development (ages 9-12)
  // Tier 3: Advanced achievements - require significant mastery (ages 12+)
  
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageAssetPath: json['imageAssetPath'],
      requiredSkills: json['requiredSkills'] != null
          ? Map<String, double>.from(json['requiredSkills'])
          : {},
      storyReward: json['storyReward'],
      tier: json['tier'] ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageAssetPath': imageAssetPath,
      'requiredSkills': requiredSkills,
      'storyReward': storyReward,
      'tier': tier,
    };
  }
}