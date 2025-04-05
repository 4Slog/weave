import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;

/// Helper methods for the GeminiStoryService
class GeminiStoryServiceHelper {
  /// Extract text from a Gemini response
  static String extractTextFromResponse(gemini.GeminiResponse? response) {
    if (response == null) {
      return '';
    }
    
    // Since we don't know the exact structure of GeminiResponse,
    // we'll use toString() and then clean it up
    final responseStr = response.toString();
    
    // Remove any markdown code blocks or formatting
    final cleanedText = responseStr
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    
    return cleanedText;
  }
  
  /// Extract JSON from text that might contain markdown or other formatting
  static String extractJsonFromText(String text) {
    // Look for JSON content in the text
    final jsonRegex = RegExp(r'({[\s\S]*}|\[[\s\S]*\])');
    final match = jsonRegex.firstMatch(text);
    
    if (match != null) {
      return match.group(0) ?? '';
    }
    
    // If no JSON found, return the original text
    return text;
  }
  
  /// Get difficulty level (1-5) from skill level
  static int getDifficultyFromSkillLevel(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return 1;
      case SkillLevel.intermediate:
        return 3;
      case SkillLevel.advanced:
        return 5;
      default:
        return 1;
    }
  }
  
  /// Get difficulty level from user progress
  static int getDifficultyFromUserProgress(UserProgress userProgress) {
    // Get the highest skill level from the skills map
    final skillLevels = userProgress.skills.values.toList();
    if (skillLevels.isEmpty) {
      return 1; // Default to beginner difficulty
    }
    
    final highestSkill = skillLevels.reduce((a, b) => a.index > b.index ? a : b);
    return getDifficultyFromSkillLevel(highestSkill);
  }
  
  /// Extract a summary of a story for use in generating branches
  static String extractStorySummary(StoryModel story) {
    final buffer = StringBuffer();
    
    // Add the title
    buffer.writeln(story.title);
    
    // Add a brief description
    buffer.writeln('Theme: ${story.theme}');
    buffer.writeln('Character: ${story.characterName}');
    
    // Add the first content block
    if (story.content.isNotEmpty) {
      final firstBlock = story.content.first.text;
      final sentences = firstBlock.split(RegExp(r'(?<=[.!?])\s+'));
      
      // Take up to 3 sentences
      final summary = sentences.take(3).join(' ');
      buffer.writeln(summary);
    }
    
    return buffer.toString();
  }
  
  /// Create default branches for a story when AI generation fails
  static List<StoryBranchModel> createDefaultBranches(
    StoryModel currentStory,
    UserProgress userProgress,
  ) {
    final uuid = DateTime.now().millisecondsSinceEpoch.toString();
    final difficultyLevel = getDifficultyFromUserProgress(userProgress);
    
    return [
      StoryBranchModel(
        id: 'default_branch_1_$uuid',
        description: 'Continue the adventure with ${currentStory.characterName}',
        targetStoryId: 'next_story_1_$uuid',
        difficultyLevel: difficultyLevel,
        focusConcept: 'Pattern recognition',
      ),
      StoryBranchModel(
        id: 'default_branch_2_$uuid',
        description: 'Try a more challenging path',
        targetStoryId: 'next_story_2_$uuid',
        difficultyLevel: difficultyLevel + 1 > 5 ? 5 : difficultyLevel + 1,
        focusConcept: 'Problem solving',
      ),
    ];
  }
}

