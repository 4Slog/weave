import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/block_workspace/models/block_collection.dart';
import 'package:kente_codeweaver/features/welcome/screens/welcome_screen.dart';
import 'package:kente_codeweaver/features/home/screens/home_screen.dart';
import 'package:kente_codeweaver/features/storytelling/screens/story_screen.dart';
import 'package:kente_codeweaver/features/block_workspace/screens/block_workspace_screen.dart';
import 'package:kente_codeweaver/features/settings/screens/settings_screen.dart';
import 'package:kente_codeweaver/features/badges/screens/achievements_screen.dart';
import 'package:kente_codeweaver/features/home/screens/asset_demo_screen.dart';

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
  static const String assetDemo = '/asset-demo';

  /// Generate a route based on the route settings
  /// Page transition animation duration
  static const Duration transitionDuration = Duration(milliseconds: 300);

  /// Generate a route based on the route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if available
    final args = settings.arguments;
    final routeName = settings.name;

    if (routeName == home) {
      // Check if we're coming from welcome screen
      if (args is bool && args) {
        // If true, go to HomeScreen
        return _createRoute(HomeScreen(), settings);
      }
      // Otherwise, go to WelcomeScreen
      return _createRoute(WelcomeScreen(), settings);
    } else if (routeName == story) {
      // Check if we have a StoryModel or Map as argument
      if (args is StoryModel) {
        return _createRoute(StoryScreen(), settings);
      } else if (args is Map<String, dynamic> && args.containsKey('storyId')) {
        // Handle story ID passed as a map
        // We need to get the StoryModel from the StoryProvider
        // For now, we'll pass the map and let the StoryScreen handle it
        return _createRoute(StoryScreen(), settings);
      }
      // If no story provided, navigate to home
      return _createRoute(WelcomeScreen(), settings);
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
        return _createRoute(AchievementsScreen(userId: args), settings);
      } else if (args is Map<String, dynamic> && args.containsKey('userId')) {
        // Handle user ID passed as a map
        return _createRoute(AchievementsScreen(userId: args['userId']), settings);
      }
      // If no user ID provided, use default
      return _createRoute(AchievementsScreen(userId: 'default_user'), settings);
    } else if (routeName == AppRouter.assetDemo) {
      // Asset demo screen
      return _createRoute(AssetDemoScreen(), settings);
    } else {
      // If route is not recognized, navigate to home
      return _createRoute(WelcomeScreen(), settings);
    }
  }

  /// Create a route with transition animation
  static Route _createRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
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
    navigateAndReplace(context, home, arguments: true);
  }

  /// Navigate to welcome screen
  static void goToWelcome(BuildContext context) {
    navigateAndReplace(context, home, arguments: false);
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

