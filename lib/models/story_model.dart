class StoryModel {
  final String id;
  final String title;
  final String content;
  final int difficultyLevel;
  final List<String> codeBlocks;
  final String imageUrl;

  StoryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.difficultyLevel,
    required this.codeBlocks,
    this.imageUrl = '',
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      difficultyLevel: json['difficultyLevel'],
      codeBlocks: List<String>.from(json['codeBlocks']),
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'difficultyLevel': difficultyLevel,
      'codeBlocks': codeBlocks,
      'imageUrl': imageUrl,
    };
  }
}