import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/welcome/screens/welcome_screen.dart';
import 'package:kente_codeweaver/features/storytelling/screens/story_screen.dart';
import 'package:kente_codeweaver/features/block_workspace/screens/block_workspace_screen.dart';
import 'package:kente_codeweaver/features/settings/screens/settings_screen.dart';

/// Central routing configuration for the Kente Codeweaver application.
///
/// This router handles navigation between different screens and passing
/// appropriate arguments to each screen.
class AppRouter {
  // Route names as constants
  static const String home = '/home';
  static const String story = '/story';
  static const String challenge = '/challenge';
  static const String weaving = '/weaving';
  static const String tutorial = '/tutorial';
  static const String settings = '/settings';
  static const String achievements = '/achievements';

  /// Generate a route based on the route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if available
    final args = settings.arguments;
    final routeName = settings.name;

    if (routeName == home) {
      return MaterialPageRoute(builder: (_) => WelcomeScreen());
    } else if (routeName == story) {
      // Check if we have a StoryModel as argument
      if (args is StoryModel) {
        return MaterialPageRoute(
          builder: (_) => StoryScreen(),
          settings: RouteSettings(name: story, arguments: args),
        );
      }
      // If no story provided, navigate to home
      return MaterialPageRoute(builder: (_) => WelcomeScreen());
    } else if (routeName == challenge) {
      // Challenge screen requires a StoryModel and/or challenge ID
      if (args is Map<String, dynamic>) {
        // Extract story and challenge ID from arguments
        final StoryModel? story = args['story'];
        final String? challengeId = args['challengeId'];

        if (story != null || challengeId != null) {
          return MaterialPageRoute(
            builder: (_) => BlockWorkspaceScreen(
              challengeId: challengeId ?? story?.challenge?.id ?? 'default_challenge',
            ),
            settings: settings,
          );
        }
      } else if (args is StoryModel) {
        // If just the story is provided
        return MaterialPageRoute(
          builder: (_) => BlockWorkspaceScreen(
            challengeId: args.challenge?.id ?? 'default_challenge',
          ),
          settings: settings,
        );
      }
      // If improper arguments, navigate to home
      return MaterialPageRoute(builder: (_) => WelcomeScreen());
    } else if (routeName == weaving) {
      // Weaving screen requires difficulty and optional block collection
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (_) => BlockWorkspaceScreen(
            challengeId: 'pattern_challenge',
          ),
          settings: settings,
        );
      }
      // If improper arguments, use default values
      return MaterialPageRoute(
        builder: (_) => BlockWorkspaceScreen(
          challengeId: 'default_challenge',
        ),
        settings: settings,
      );
    } else if (routeName == tutorial) {
      // Tutorial screen with optional parameters
      if (args is Map<String, dynamic>) {
        final String tutorialType = args['type'] ?? 'general';

        // The tutorial could be implemented as a special mode in other screens
        // or as separate screens. For now, we'll redirect to block workspace with tutorial flag
        return MaterialPageRoute(
          builder: (_) => BlockWorkspaceScreen(
            challengeId: 'tutorial_$tutorialType',
          ),
          settings: settings,
        );
      }
      // Default tutorial
      return MaterialPageRoute(
        builder: (_) => BlockWorkspaceScreen(
          challengeId: 'tutorial_introduction',
        ),
        settings: settings,
      );
    } else if (routeName == AppRouter.settings) {
      return MaterialPageRoute(builder: (_) => SettingsScreen());
    } else if (routeName == AppRouter.achievements) {
      // Achievements screen requires user ID
      if (args is String) {
        // TODO: Create AchievementsScreen
        // For now, navigate back home
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
      }
      // If no user ID provided, navigate to home
      return MaterialPageRoute(builder: (_) => WelcomeScreen());
    } else {
      // If route is not recognized, navigate to home
      return MaterialPageRoute(builder: (_) => WelcomeScreen());
    }
  }



  /// Navigate to a screen by route name
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigate to a screen and remove all previous screens
  static void navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a screen and remove all screens until a specific route
  static void navigateAndRemoveUntil(BuildContext context, String routeName, String untilRoute, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (Route<dynamic> route) => route.settings.name == untilRoute,
      arguments: arguments,
    );
  }

  /// Navigate back to the previous screen
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  /// Navigate back to a specific route
  static void goBackTo(BuildContext context, String routeName) {
    Navigator.popUntil(context, (route) => route.settings.name == routeName);
  }

  /// Navigate to home screen
  static void goHome(BuildContext context) {
    navigateAndReplace(context, home);
  }

  /// Navigate to a story
  static void goToStory(BuildContext context, StoryModel storyModel) {
    navigateTo(context, story, arguments: storyModel);
  }

  /// Navigate to a challenge
  static void goToChallenge(BuildContext context, {
    StoryModel? story,
    String? challengeId,
    UserProgress? userProgress,
  }) {
    navigateTo(
      context,
      challenge,
      arguments: {
        'story': story,
        'challengeId': challengeId,
        'userProgress': userProgress,
      },
    );
  }

  /// Navigate to pattern weaving screen
  static void goToWeaving(BuildContext context, {
    int difficulty = 1,
    BlockCollection? initialBlocks,
    String title = 'Pattern Creation',
    bool showTutorial = false,
  }) {
    navigateTo(
      context,
      weaving,
      arguments: {
        'difficulty': difficulty,
        'initialBlocks': initialBlocks,
        'title': title,
        'showTutorial': showTutorial,
      },
    );
  }

  /// Navigate to settings
  static void goToSettings(BuildContext context) {
    navigateTo(context, settings);
  }

  /// Navigate to achievements
  static void goToAchievements(BuildContext context, String userId) {
    navigateTo(context, achievements, arguments: userId);
  }

  /// Navigate to tutorial
  static void goToTutorial(BuildContext context, String tutorialType) {
    navigateTo(
      context,
      tutorial,
      arguments: {'type': tutorialType},
    );
  }
}

