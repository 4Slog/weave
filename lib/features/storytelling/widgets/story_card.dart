import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/content_block_model.dart';

class StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      story.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(story.difficultyLevel),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level ${story.difficultyLevel}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                _getTruncatedContent(_getContentText(story.content)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getLearningConceptsAsStrings(story)
                    .take(3)
                    .map((concept) => Chip(
                          label: Text(concept),
                          backgroundColor: Colors.blue.shade100,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to get content text from ContentBlockModel list
  String _getContentText(List<ContentBlockModel> content) {
    if (content.isEmpty) return "No content available";

    // Combine the first few content blocks
    String combinedText = "";
    for (var i = 0; i < math.min(3, content.length); i++) {
      combinedText += "${content[i].text} ";
    }

    return combinedText;
  }

  /// Helper method to truncate content for preview
  String _getTruncatedContent(String content) {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  /// Helper method to get learning concepts as strings
  List<String> _getLearningConceptsAsStrings(StoryModel story) {
    return story.learningConcepts;
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
