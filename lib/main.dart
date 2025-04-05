import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart' as block;
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider.dart';
import 'package:kente_codeweaver/features/settings/providers/settings_provider.dart';
import 'package:kente_codeweaver/core/navigation/app_router.dart';
import 'package:kente_codeweaver/core/utils/service_locator.dart';

/// Main entry point for the application
void main() {
  runApp(const MyApp());
}

/// Main application widget
class MyApp extends StatelessWidget {
  /// Constructor
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Block provider
        ChangeNotifierProvider(
          create: (_) => block.BlockProvider(),
        ),

        // Learning provider
        ChangeNotifierProvider(
          create: (_) => LearningProvider(),
        ),

        // Story provider
        ChangeNotifierProvider(
          create: (_) => StoryProvider(),
        ),

        // Settings provider
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Initialize service locator
          ServiceLocator.initialize(context);

          return MaterialApp(
            title: 'Kente Codeweaver',
            theme: ThemeData(
              primarySwatch: Colors.deepPurple,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: 'Roboto',
            ),
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRouter.home,
          );
        },
      ),
    );
  }
}
