import 'package:kente_codeweaver/features/storytelling/models/emotional_tone.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';

/// Manager for AI prompt templates
///
/// This class provides templates for different types of AI prompts,
/// ensuring consistent and high-quality prompts for story generation.
class PromptTemplateManager {
  /// Create a prompt for generating a basic story
  ///
  /// Parameters:
  /// - `learningConcepts`: Concepts to focus on in the story
  /// - `skillLevel`: User's skill level (1-5)
  /// - `culturalContext`: Cultural context to include
  /// - `emotionalTone`: Emotional tone for the story
  /// - `previousStories`: Previous stories for continuity
  static String createStoryPrompt({
    required List<String> learningConcepts,
    required int skillLevel,
    required String culturalContext,
    required EmotionalTone emotionalTone,
    required List<Map<String, dynamic>> previousStories,
  }) {
    final skillLevelText = _getSkillLevelText(skillLevel);
    final emotionalToneText = emotionalTone.name;
    final previousStoriesText = _formatPreviousStories(previousStories);
    final conceptsText = learningConcepts.join(', ');

    return """
You are an expert storyteller creating an educational story about coding concepts through the lens of Kente weaving from Ghana.

EDUCATIONAL PARAMETERS:
- Learning concepts to focus on: $conceptsText
- Skill level: $skillLevelText
- Emotional tone: $emotionalToneText
- Cultural context: $culturalContext
$previousStoriesText

STORY REQUIREMENTS:
Create an engaging, culturally rich story that teaches the specified learning concepts. The story should be appropriate for the user's skill level, not mentioning age but focusing on their coding knowledge. Incorporate the cultural context naturally into the narrative.

The story should have the following elements:
1. A clear beginning, middle, and end
2. Characters that the reader can relate to
3. A problem or challenge related to the learning concepts
4. A resolution that demonstrates the learning concepts
5. Cultural elements that enrich the story
6. An emotional tone that matches the specified tone

STORY STRUCTURE:
- 2-3 content blocks for introduction/context setting
- 3-5 blocks for concept development through narrative
- 1-2 blocks for challenge introduction
- 2-3 blocks for conclusion/reflection

EDUCATIONAL APPROACH:
- Teach coding concepts subtly through the narrative
- Use Kente weaving as a metaphor for coding concepts
- Avoid explicit instruction; instead, show concepts in action
- Make connections between patterns in weaving and patterns in code

OUTPUT FORMAT:
Format your response as a JSON object with the following structure:
{
  "title": "Story title",
  "theme": "Story theme (e.g., 'loops', 'conditionals', 'cultural')",
  "region": "Cultural region (e.g., 'Ashanti', 'Ghana')",
  "characterName": "Main character name",
  "content": "Full story content with paragraphs",
  "hasChoices": true/false (whether the story should have branching choices),
  "choicePrompt": "Text prompting the user to make a choice (if hasChoices is true)",
  "culturalNotes": {
    "key1": "Cultural note 1",
    "key2": "Cultural note 2"
  }
}

Make the story approximately 300-500 words long, engaging, and educational.
""";
  }

  /// Create a prompt for generating an enhanced story with more personalization
  ///
  /// Parameters:
  /// - `learningConcepts`: Concepts to focus on in the story
  /// - `skillLevel`: User's skill level (1-5)
  /// - `culturalContext`: Cultural context to include
  /// - `emotionalTone`: Emotional tone for the story
  /// - `previousStories`: Previous stories for continuity
  /// - `characterName`: Optional character name for continuity
  /// - `narrativeContext`: Optional narrative context for continuity
  /// - `theme`: Optional theme for the story
  static String createEnhancedStoryPrompt({
    required List<String> learningConcepts,
    required int skillLevel,
    required String culturalContext,
    required EmotionalTone emotionalTone,
    required List<Map<String, dynamic>> previousStories,
    String? characterName,
    Map<String, dynamic>? narrativeContext,
    String? theme,
  }) {
    final skillLevelText = _getSkillLevelText(skillLevel);
    final emotionalToneText = emotionalTone.name;
    final previousStoriesText = _formatPreviousStories(previousStories);
    final conceptsText = learningConcepts.join(', ');
    final characterText = characterName != null ? "Character name: $characterName" : "Create a relatable character";
    final themeText = theme != null ? "Theme: $theme" : "Choose an appropriate theme";
    
    // Format narrative context if provided
    String narrativeContextText = "";
    if (narrativeContext != null && narrativeContext.isNotEmpty) {
      narrativeContextText = "\nNARRATIVE CONTEXT:";
      narrativeContext.forEach((key, value) {
        narrativeContextText += "\n- $key: $value";
      });
    }

    return """
You are an expert storyteller creating an educational story about coding concepts through the lens of Kente weaving from Ghana.

EDUCATIONAL PARAMETERS:
- Learning concepts to focus on: $conceptsText
- Skill level: $skillLevelText
- Emotional tone: $emotionalToneText
- Cultural context: $culturalContext
$characterText
$themeText
$previousStoriesText
$narrativeContextText

STORY REQUIREMENTS:
Create an engaging, culturally rich story that teaches the specified learning concepts. The story should be appropriate for the user's skill level, not mentioning age but focusing on their coding knowledge. Incorporate the cultural context naturally into the narrative.

The story should have the following elements:
1. A clear beginning, middle, and end
2. Characters that the reader can relate to
3. A problem or challenge related to the learning concepts
4. A resolution that demonstrates the learning concepts
5. Cultural elements that enrich the story
6. An emotional tone that matches the specified tone

STORY STRUCTURE:
- 2-3 content blocks for introduction/context setting
- 3-5 blocks for concept development through narrative
- 1-2 blocks for challenge introduction
- 2-3 blocks for conclusion/reflection

EDUCATIONAL APPROACH:
- Teach coding concepts subtly through the narrative
- Use Kente weaving as a metaphor for coding concepts
- Avoid explicit instruction; instead, show concepts in action
- Make connections between patterns in weaving and patterns in code
- Adapt difficulty based on the user's skill level

OUTPUT FORMAT:
Format your response as a JSON object with the following structure:
{
  "title": "Story title",
  "theme": "Story theme (e.g., 'loops', 'conditionals', 'cultural')",
  "region": "Cultural region (e.g., 'Ashanti', 'Ghana')",
  "characterName": "Main character name",
  "content": "Full story content with paragraphs",
  "hasChoices": true/false (whether the story should have branching choices),
  "choicePrompt": "Text prompting the user to make a choice (if hasChoices is true)",
  "culturalNotes": {
    "key1": "Cultural note 1",
    "key2": "Cultural note 2"
  },
  "challenge": {
    "title": "Challenge title",
    "description": "Challenge description",
    "availableBlockTypes": ["move", "turn", "repeat", "if"],
    "difficulty": 1-5 (matching the skill level)
  }
}

Make the story approximately 300-500 words long, engaging, and educational.
""";
  }

  /// Create a prompt for generating story branches
  ///
  /// Parameters:
  /// - `parentStory`: The parent story to branch from
  /// - `skillLevel`: User's skill level (1-5)
  /// - `choiceCount`: Number of choices to generate
  static String createBranchPrompt({
    required StoryModel parentStory,
    required int skillLevel,
    required int choiceCount,
  }) {
    final skillLevelText = _getSkillLevelText(skillLevel);
    final conceptsText = parentStory.learningConcepts.join(', ');
    
    // Extract a summary of the parent story content
    final contentSummary = parentStory.content.map((block) => block.text).join('\n\n');

    return """
You are creating branching choices for an educational story about coding concepts through Kente weaving.

STORY CONTEXT:
- Parent story title: ${parentStory.title}
- Parent story content: $contentSummary
- Learning concepts: $conceptsText
- Skill level: $skillLevelText
- Number of choices to generate: $choiceCount

BRANCH REQUIREMENTS:
Create $choiceCount different story branches that could follow from this story. Each branch should:
1. Start with a clear choice the user can make
2. Continue the story in a different direction
3. Still teach the same learning concepts
4. Maintain cultural relevance to Kente weaving
5. Have a different emotional tone if possible
6. Be appropriate for the user's skill level

EDUCATIONAL APPROACH:
- Each branch should continue teaching the learning concepts
- Different branches can emphasize different aspects of the concepts
- Maintain the metaphor of Kente weaving for coding concepts
- Adapt difficulty based on the branch chosen (some can be more challenging)

OUTPUT FORMAT:
Format your response as a JSON array of branch objects with the following structure:
[
  {
    "choiceText": "Short text describing the choice (e.g., 'Follow the river')",
    "description": "Brief description of this branch path",
    "content": "Content that continues the story based on this choice (100-200 words)",
    "emotionalTone": "One of: happy, sad, excited, tense, curious, neutral, etc.",
    "focusConcept": "Main concept this branch focuses on (from the learning concepts)"
  },
  {
    "choiceText": "...",
    "description": "...",
    "content": "...",
    "emotionalTone": "...",
    "focusConcept": "..."
  }
]

Make each branch distinct and interesting, with different potential outcomes.
""";
  }

  /// Create a prompt for continuing a story from a branch
  ///
  /// Parameters:
  /// - `selectedBranch`: The branch to continue from
  /// - `skillLevel`: User's skill level (1-5)
  static String createContinuationPrompt({
    required StoryBranchModel selectedBranch,
    required int skillLevel,
  }) {
    final skillLevelText = _getSkillLevelText(skillLevel);
    final conceptsText = selectedBranch.learningConcepts.join(', ');

    return """
You are continuing an educational story about coding concepts through Kente weaving based on a user's choice.

BRANCH CONTEXT:
- Selected branch content: ${selectedBranch.content}
- Learning concepts: $conceptsText
- Emotional tone: ${selectedBranch.emotionalTone.name}
- Skill level: $skillLevelText

CONTINUATION REQUIREMENTS:
Continue the story based on the selected branch. The continuation should:
1. Flow naturally from the branch content
2. Develop the story further with a clear middle and end
3. Reinforce the learning concepts
4. Maintain the emotional tone
5. Keep the cultural context of Kente weaving
6. Be appropriate for the user's skill level

STORY STRUCTURE:
- 1-2 content blocks for continuing from the branch choice
- 3-4 blocks for concept development through narrative
- 1-2 blocks for challenge introduction
- 2-3 blocks for conclusion/reflection

EDUCATIONAL APPROACH:
- Continue teaching coding concepts subtly through the narrative
- Use Kente weaving as a metaphor for coding concepts
- Avoid explicit instruction; instead, show concepts in action
- Make connections between patterns in weaving and patterns in code

OUTPUT FORMAT:
Format your response as a JSON object with the following structure:
{
  "title": "Title for the continued story",
  "content": "Content that continues the story (200-400 words)",
  "culturalNotes": {
    "key1": "Cultural note 1",
    "key2": "Cultural note 2"
  },
  "hasChoices": true/false (whether this continuation should have further choices),
  "choicePrompt": "Text prompting the user to make another choice (if hasChoices is true)",
  "challenge": {
    "title": "Challenge title",
    "description": "Challenge description",
    "availableBlockTypes": ["move", "turn", "repeat", "if"],
    "difficulty": 1-5 (matching the skill level)
  }
}

Make the continuation engaging, educational, and satisfying.
""";
  }

  /// Create a prompt for generating a challenge based on a story
  ///
  /// Parameters:
  /// - `story`: The story to create a challenge for
  /// - `skillLevel`: User's skill level (1-5)
  static String createChallengePrompt({
    required StoryModel story,
    required int skillLevel,
  }) {
    final skillLevelText = _getSkillLevelText(skillLevel);
    final conceptsText = story.learningConcepts.join(', ');

    return """
You are creating a coding challenge based on a story about Kente weaving.

STORY CONTEXT:
- Story title: ${story.title}
- Learning concepts: $conceptsText
- Skill level: $skillLevelText

CHALLENGE REQUIREMENTS:
Create a coding challenge that:
1. Relates directly to the story
2. Tests the user's understanding of the learning concepts
3. Is appropriate for the user's skill level
4. Incorporates Kente weaving patterns
5. Has clear success criteria

AVAILABLE BLOCK TYPES:
- move: Moves the weaver forward
- turn: Changes direction
- repeat: Repeats a sequence of actions
- if: Conditional logic
- variable: Stores and uses values
- function: Defines reusable patterns

OUTPUT FORMAT:
Format your response as a JSON object with the following structure:
{
  "title": "Challenge title",
  "description": "Challenge description (instructions for the user)",
  "difficulty": 1-5 (matching the skill level),
  "availableBlockTypes": ["move", "turn", "repeat", "if", "variable", "function"],
  "successCriteria": {
    "requiredBlockTypes": ["move", "repeat"],
    "minBlocks": 5,
    "maxBlocks": 15,
    "patternComplexity": 1-5
  }
}

Make the challenge engaging, educational, and directly connected to the story.
""";
  }

  /// Helper method to get skill level text
  static String _getSkillLevelText(int skillLevel) {
    switch (skillLevel) {
      case 1:
        return 'beginner';
      case 2:
        return 'basic';
      case 3:
        return 'intermediate';
      case 4:
        return 'advanced';
      case 5:
        return 'expert';
      default:
        return 'beginner';
    }
  }

  /// Helper method to format previous stories
  static String _formatPreviousStories(List<Map<String, dynamic>> previousStories) {
    if (previousStories.isEmpty) {
      return "PREVIOUS STORIES: This is the user's first story.";
    }

    final buffer = StringBuffer("PREVIOUS STORIES:");
    for (final story in previousStories) {
      buffer.write("\n- ${story['title']} (concepts: ${story['learningConcepts']?.join(', ') ?? 'none'})");
    }
    return buffer.toString();
  }
}
