import 'package:kente_codeweaver/features/learning/models/learning_path.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/skill_level.dart';
import 'package:kente_codeweaver/features/learning/models/learning_style.dart';

/// Data provider for learning paths
class LearningPathsData {
  /// Get a learning path template for a specific path type and learning style
  static LearningPath getLearningPathTemplate({
    required String userId,
    required LearningPathType pathType,
    LearningStyle? learningStyle,
  }) {
    switch (pathType) {
      case LearningPathType.logicBased:
        return _getLogicBasedPath(userId, learningStyle);
      case LearningPathType.creativityBased:
        return _getCreativityBasedPath(userId, learningStyle);
      case LearningPathType.challengeBased:
        return _getChallengeBasedPath(userId, learningStyle);
      case LearningPathType.balanced:
        // For balanced path, we combine elements from all paths
        return _getBalancedPath(userId, learningStyle);
    }
  }

  /// Get a logic-based learning path
  static LearningPath _getLogicBasedPath(String userId, LearningStyle? learningStyle) {
    final items = <LearningPathItem>[];

    // Core concepts for logic-based path
    items.add(
      LearningPathItem(
        concept: 'variables',
        title: 'Variables and Data',
        description: 'Learn how to store and manipulate data using variables.',
        skillLevel: SkillLevel.novice,
        estimatedTimeMinutes: 20,
        prerequisites: [],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'conditionals',
        title: 'Making Decisions',
        description: 'Learn how to make decisions in your code using conditional statements.',
        skillLevel: SkillLevel.novice,
        estimatedTimeMinutes: 25,
        prerequisites: ['variables'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'loops',
        title: 'Repeating Actions',
        description: 'Learn how to repeat actions using loops.',
        skillLevel: SkillLevel.beginner,
        estimatedTimeMinutes: 30,
        prerequisites: ['variables', 'conditionals'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'functions',
        title: 'Creating Functions',
        description: 'Learn how to organize your code into reusable functions.',
        skillLevel: SkillLevel.beginner,
        estimatedTimeMinutes: 35,
        prerequisites: ['variables', 'conditionals', 'loops'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'arrays',
        title: 'Working with Lists',
        description: 'Learn how to store and manipulate collections of data.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 40,
        prerequisites: ['variables', 'loops'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'algorithms',
        title: 'Basic Algorithms',
        description: 'Learn how to solve problems using algorithms.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 45,
        prerequisites: ['functions', 'arrays'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'debugging',
        title: 'Finding and Fixing Bugs',
        description: 'Learn how to identify and fix errors in your code.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 30,
        prerequisites: ['functions'],
      ),
    );

    // Add learning style specific items
    if (learningStyle != null) {
      switch (learningStyle) {
        case LearningStyle.visual:
          items.add(
            LearningPathItem(
              concept: 'pattern_design',
              title: 'Visual Pattern Design',
              description: 'Learn how to create visual patterns using code.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 40,
              prerequisites: ['loops', 'functions'],
            ),
          );
          break;
        case LearningStyle.logical:
          items.add(
            LearningPathItem(
              concept: 'logic',
              title: 'Advanced Logic',
              description: 'Learn advanced logical operations and problem-solving techniques.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 45,
              prerequisites: ['conditionals', 'functions'],
            ),
          );
          break;
        case LearningStyle.practical:
          items.add(
            LearningPathItem(
              concept: 'data_structures',
              title: 'Practical Data Structures',
              description: 'Learn how to use data structures to solve real-world problems.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 50,
              prerequisites: ['arrays', 'functions'],
            ),
          );
          break;
        case LearningStyle.verbal:
          items.add(
            LearningPathItem(
              concept: 'sequence',
              title: 'Storytelling with Code',
              description: 'Learn how to create interactive stories using code.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 40,
              prerequisites: ['conditionals', 'functions'],
            ),
          );
          break;
        case LearningStyle.social:
          items.add(
            LearningPathItem(
              concept: 'objects',
              title: 'Object Interactions',
              description: 'Learn how objects can interact with each other in code.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 45,
              prerequisites: ['functions', 'arrays'],
            ),
          );
          break;
        case LearningStyle.reflective:
          items.add(
            LearningPathItem(
              concept: 'recursion',
              title: 'Recursive Thinking',
              description: 'Learn how to solve problems using recursive techniques.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 50,
              prerequisites: ['functions'],
            ),
          );
          break;
        case LearningStyle.auditory:
          items.add(
            LearningPathItem(
              concept: 'sequence',
              title: 'Audio Learning',
              description: 'Learn through audio-based tutorials and exercises.',
              skillLevel: SkillLevel.beginner,
              estimatedTimeMinutes: 40,
              prerequisites: [],
            ),
          );
          break;
        case LearningStyle.reading:
          items.add(
            LearningPathItem(
              concept: 'documentation',
              title: 'Text-Based Learning',
              description: 'Learn through comprehensive written materials.',
              skillLevel: SkillLevel.beginner,
              estimatedTimeMinutes: 35,
              prerequisites: [],
            ),
          );
          break;
        case LearningStyle.kinesthetic:
          items.add(
            LearningPathItem(
              concept: 'interactive_design',
              title: 'Hands-on Learning',
              description: 'Learn through interactive exercises and activities.',
              skillLevel: SkillLevel.beginner,
              estimatedTimeMinutes: 45,
              prerequisites: [],
            ),
          );
          break;
        case LearningStyle.solitary:
          items.add(
            LearningPathItem(
              concept: 'self_study',
              title: 'Independent Learning',
              description: 'Self-paced learning modules for independent study.',
              skillLevel: SkillLevel.beginner,
              estimatedTimeMinutes: 50,
              prerequisites: [],
            ),
          );
          break;
      }
    }

    // Advanced concepts
    items.add(
      LearningPathItem(
        concept: 'classes',
        title: 'Object-Oriented Programming',
        description: 'Learn how to organize your code using classes and objects.',
        skillLevel: SkillLevel.advanced,
        estimatedTimeMinutes: 60,
        prerequisites: ['functions', 'arrays'],
      ),
    );

    return LearningPath(
      pathType: LearningPathType.logicBased,
      items: items,
      userId: userId,
    );
  }

  /// Get a creativity-based learning path
  static LearningPath _getCreativityBasedPath(String userId, LearningStyle? learningStyle) {
    final items = <LearningPathItem>[];

    // Core concepts for creativity-based path
    items.add(
      LearningPathItem(
        concept: 'variables',
        title: 'Creative Variables',
        description: 'Learn how to use variables to create dynamic content.',
        skillLevel: SkillLevel.novice,
        estimatedTimeMinutes: 20,
        prerequisites: [],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'pattern_design',
        title: 'Pattern Creation',
        description: 'Learn how to create beautiful patterns using code.',
        skillLevel: SkillLevel.novice,
        estimatedTimeMinutes: 30,
        prerequisites: ['variables'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'loops',
        title: 'Creative Repetition',
        description: 'Learn how to use loops to create complex patterns and animations.',
        skillLevel: SkillLevel.beginner,
        estimatedTimeMinutes: 35,
        prerequisites: ['variables', 'pattern_design'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'conditionals',
        title: 'Dynamic Designs',
        description: 'Learn how to create designs that change based on conditions.',
        skillLevel: SkillLevel.beginner,
        estimatedTimeMinutes: 30,
        prerequisites: ['variables', 'pattern_design'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'functions',
        title: 'Reusable Art Components',
        description: 'Learn how to create reusable components for your designs.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 40,
        prerequisites: ['loops', 'conditionals'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'arrays',
        title: 'Collections of Designs',
        description: 'Learn how to work with collections of design elements.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 45,
        prerequisites: ['functions'],
      ),
    );

    // Add learning style specific items
    if (learningStyle != null) {
      switch (learningStyle) {
        case LearningStyle.visual:
          items.add(
            LearningPathItem(
              concept: 'sequence',
              title: 'Visual Storytelling',
              description: 'Learn how to tell stories through visual sequences.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 50,
              prerequisites: ['pattern_design', 'functions'],
            ),
          );
          break;
        case LearningStyle.logical:
          items.add(
            LearningPathItem(
              concept: 'algorithms',
              title: 'Algorithmic Art',
              description: 'Learn how to create art using algorithms.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 55,
              prerequisites: ['functions', 'arrays'],
            ),
          );
          break;
        case LearningStyle.practical:
          items.add(
            LearningPathItem(
              concept: 'objects',
              title: 'Interactive Objects',
              description: 'Learn how to create interactive objects in your designs.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 45,
              prerequisites: ['functions', 'conditionals'],
            ),
          );
          break;
        case LearningStyle.verbal:
          items.add(
            LearningPathItem(
              concept: 'sequence',
              title: 'Narrative Design',
              description: 'Learn how to incorporate narratives into your designs.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 40,
              prerequisites: ['pattern_design', 'conditionals'],
            ),
          );
          break;
        case LearningStyle.social:
          items.add(
            LearningPathItem(
              concept: 'objects',
              title: 'Collaborative Design',
              description: 'Learn how to create designs that can be collaborated on.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 50,
              prerequisites: ['functions', 'arrays'],
            ),
          );
          break;
        case LearningStyle.reflective:
          items.add(
            LearningPathItem(
              concept: 'recursion',
              title: 'Recursive Patterns',
              description: 'Learn how to create complex patterns using recursion.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 60,
              prerequisites: ['functions', 'pattern_design'],
            ),
          );
          break;
        case LearningStyle.auditory:
          items.add(
            LearningPathItem(
              concept: 'sequence',
              title: 'Audio Storytelling',
              description: 'Learn how to incorporate audio elements into your designs.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 45,
              prerequisites: ['pattern_design', 'functions'],
            ),
          );
          break;
        case LearningStyle.reading:
          items.add(
            LearningPathItem(
              concept: 'documentation',
              title: 'Documentation Design',
              description: 'Learn how to create clear and effective documentation.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 40,
              prerequisites: ['functions', 'arrays'],
            ),
          );
          break;
        case LearningStyle.kinesthetic:
          items.add(
            LearningPathItem(
              concept: 'interactive_design',
              title: 'Hands-on Design',
              description: 'Learn through hands-on interactive design exercises.',
              skillLevel: SkillLevel.intermediate,
              estimatedTimeMinutes: 50,
              prerequisites: ['functions', 'conditionals'],
            ),
          );
          break;
        case LearningStyle.solitary:
          items.add(
            LearningPathItem(
              concept: 'advanced_algorithms',
              title: 'Independent Study',
              description: 'Self-paced learning of advanced algorithmic concepts.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 55,
              prerequisites: ['algorithms', 'functions'],
            ),
          );
          break;
      }
    }

    // Advanced concepts
    items.add(
      LearningPathItem(
        concept: 'classes',
        title: 'Design Systems',
        description: 'Learn how to create comprehensive design systems using object-oriented programming.',
        skillLevel: SkillLevel.advanced,
        estimatedTimeMinutes: 70,
        prerequisites: ['functions', 'arrays'],
      ),
    );

    return LearningPath(
      pathType: LearningPathType.creativityBased,
      items: items,
      userId: userId,
    );
  }

  /// Get a challenge-based learning path
  static LearningPath _getChallengeBasedPath(String userId, LearningStyle? learningStyle) {
    final items = <LearningPathItem>[];

    // Core concepts for challenge-based path
    items.add(
      LearningPathItem(
        concept: 'variables',
        title: 'Variable Challenge',
        description: 'Master variables through increasingly difficult challenges.',
        skillLevel: SkillLevel.novice,
        estimatedTimeMinutes: 25,
        prerequisites: [],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'conditionals',
        title: 'Conditional Logic Challenge',
        description: 'Test your conditional logic skills with challenging problems.',
        skillLevel: SkillLevel.beginner,
        estimatedTimeMinutes: 30,
        prerequisites: ['variables'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'loops',
        title: 'Loop Mastery Challenge',
        description: 'Solve complex problems using loops.',
        skillLevel: SkillLevel.beginner,
        estimatedTimeMinutes: 35,
        prerequisites: ['variables', 'conditionals'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'debugging',
        title: 'Debugging Challenge',
        description: 'Find and fix bugs in increasingly complex code.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 40,
        prerequisites: ['variables', 'conditionals', 'loops'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'functions',
        title: 'Function Challenge',
        description: 'Create efficient functions to solve complex problems.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 45,
        prerequisites: ['loops', 'conditionals'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'arrays',
        title: 'Array Challenge',
        description: 'Master arrays through challenging problems.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 50,
        prerequisites: ['functions'],
      ),
    );

    // Add learning style specific items
    if (learningStyle != null) {
      switch (learningStyle) {
        case LearningStyle.visual:
          items.add(
            LearningPathItem(
              concept: 'pattern_design',
              title: 'Pattern Challenge',
              description: 'Create complex patterns to solve visual challenges.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 55,
              prerequisites: ['loops', 'functions'],
            ),
          );
          break;
        case LearningStyle.logical:
          items.add(
            LearningPathItem(
              concept: 'algorithms',
              title: 'Algorithm Challenge',
              description: 'Solve complex algorithmic problems.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 60,
              prerequisites: ['functions', 'arrays'],
            ),
          );
          break;
        case LearningStyle.practical:
          items.add(
            LearningPathItem(
              concept: 'data_structures',
              title: 'Data Structure Challenge',
              description: 'Solve real-world problems using advanced data structures.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 65,
              prerequisites: ['arrays', 'functions'],
            ),
          );
          break;
        case LearningStyle.verbal:
          items.add(
            LearningPathItem(
              concept: 'sequence',
              title: 'Storytelling Challenge',
              description: 'Create complex interactive stories with branching narratives.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 55,
              prerequisites: ['conditionals', 'functions'],
            ),
          );
          break;
        case LearningStyle.social:
          items.add(
            LearningPathItem(
              concept: 'objects',
              title: 'Object Interaction Challenge',
              description: 'Create complex systems of interacting objects.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 60,
              prerequisites: ['functions', 'arrays'],
            ),
          );
          break;
        case LearningStyle.reflective:
          items.add(
            LearningPathItem(
              concept: 'recursion',
              title: 'Recursion Challenge',
              description: 'Solve complex problems using recursive techniques.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 70,
              prerequisites: ['functions'],
            ),
          );
          break;
        case LearningStyle.auditory:
          items.add(
            LearningPathItem(
              concept: 'sequence',
              title: 'Audio Challenge',
              description: 'Create interactive audio experiences with code.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 55,
              prerequisites: ['conditionals', 'functions'],
            ),
          );
          break;
        case LearningStyle.reading:
          items.add(
            LearningPathItem(
              concept: 'documentation',
              title: 'Documentation Challenge',
              description: 'Create comprehensive documentation for complex code.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 50,
              prerequisites: ['functions', 'arrays'],
            ),
          );
          break;
        case LearningStyle.kinesthetic:
          items.add(
            LearningPathItem(
              concept: 'interactive_design',
              title: 'Interactive Design Challenge',
              description: 'Create highly interactive and engaging designs.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 60,
              prerequisites: ['functions', 'conditionals'],
            ),
          );
          break;
        case LearningStyle.solitary:
          items.add(
            LearningPathItem(
              concept: 'advanced_algorithms',
              title: 'Independent Algorithm Challenge',
              description: 'Solve complex algorithmic problems independently.',
              skillLevel: SkillLevel.advanced,
              estimatedTimeMinutes: 65,
              prerequisites: ['algorithms', 'functions'],
            ),
          );
          break;
      }
    }

    // Advanced concepts
    items.add(
      LearningPathItem(
        concept: 'classes',
        title: 'Object-Oriented Challenge',
        description: 'Design and implement complex object-oriented systems.',
        skillLevel: SkillLevel.advanced,
        estimatedTimeMinutes: 75,
        prerequisites: ['functions', 'arrays'],
      ),
    );

    items.add(
      LearningPathItem(
        concept: 'inheritance',
        title: 'Inheritance Challenge',
        description: 'Master inheritance and polymorphism through challenging problems.',
        skillLevel: SkillLevel.advanced,
        estimatedTimeMinutes: 80,
        prerequisites: ['classes'],
      ),
    );

    return LearningPath(
      pathType: LearningPathType.challengeBased,
      items: items,
      userId: userId,
    );
  }

  /// Get a balanced learning path that combines elements from all other paths
  static LearningPath _getBalancedPath(String userId, LearningStyle? learningStyle) {
    final items = <LearningPathItem>[];

    // Include a mix of items from all paths
    // Logic-based items (fundamentals)
    items.add(
      LearningPathItem(
        concept: 'variables',
        title: 'Variables and Data Types',
        description: 'Learn about variables and data types in a balanced approach.',
        skillLevel: SkillLevel.beginner,
        estimatedTimeMinutes: 30,
        prerequisites: [],
      ),
    );

    // Creativity-based items
    items.add(
      LearningPathItem(
        concept: 'ui_design',
        title: 'UI Design Principles',
        description: 'Explore UI design with a balance of logic and creativity.',
        skillLevel: SkillLevel.intermediate,
        estimatedTimeMinutes: 45,
        prerequisites: ['variables'],
      ),
    );

    // Challenge-based items
    items.add(
      LearningPathItem(
        concept: 'algorithms',
        title: 'Algorithm Challenges',
        description: 'Solve algorithm challenges with a balanced approach.',
        skillLevel: SkillLevel.advanced,
        estimatedTimeMinutes: 60,
        prerequisites: ['variables', 'ui_design'],
      ),
    );

    return LearningPath(
      pathType: LearningPathType.balanced,
      items: items,
      userId: userId,
    );
  }

  /// Get challenge data for a specific concept and difficulty level
  static Map<String, dynamic> getChallengeData({
    required String conceptId,
    required int difficultyLevel,
    required LearningPathType pathType,
  }) {
    // In a real app, this would come from a database or API
    // This is just a placeholder implementation

    final title = _getConceptName(conceptId);
    final description = 'A challenge to test your knowledge of $title.';

    // Adjust difficulty based on path type
    String difficultyDescription;
    switch (pathType) {
      case LearningPathType.logicBased:
        difficultyDescription = 'This challenge focuses on logical reasoning and problem-solving.';
        break;
      case LearningPathType.creativityBased:
        difficultyDescription = 'This challenge focuses on creative expression and design.';
        break;
      case LearningPathType.challengeBased:
        difficultyDescription = 'This is a challenging problem that will test your skills.';
        break;
      case LearningPathType.balanced:
        difficultyDescription = 'This challenge balances logical thinking, creativity, and problem-solving.';
        break;
    }

    return {
      'id': '${conceptId}_${difficultyLevel}_${pathType.toString().split('.').last}',
      'title': '$title Challenge (Level $difficultyLevel)',
      'description': description,
      'difficultyLevel': difficultyLevel,
      'conceptId': conceptId,
      'pathType': pathType.toString().split('.').last,
      'difficultyDescription': difficultyDescription,
      'estimatedTimeMinutes': 15 + (difficultyLevel * 5),
      'hints': [
        'Think about how to use $title effectively.',
        'Break down the problem into smaller steps.',
        'Consider edge cases in your solution.',
      ],
      'tags': [
        conceptId,
        pathType.toString().split('.').last,
        'level_$difficultyLevel',
      ],
    };
  }

  /// Get the display name for a concept
  static String _getConceptName(String conceptId) {
    // In a real app, this would come from a service or database
    final conceptNames = {
      'loops': 'Loops',
      'conditionals': 'Conditionals',
      'variables': 'Variables',
      'functions': 'Functions',
      'arrays': 'Arrays',
      'objects': 'Objects',
      'classes': 'Classes',
      'inheritance': 'Inheritance',
      'recursion': 'Recursion',
      'algorithms': 'Algorithms',
      'data_structures': 'Data Structures',
      'pattern_design': 'Pattern Design',
      'sequence': 'Sequences',
      'logic': 'Logic',
      'debugging': 'Debugging',
    };

    return conceptNames[conceptId] ?? 'Unknown Concept';
  }
}
