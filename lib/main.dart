import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/block_workspace/providers/block_provider.dart' as block;
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider.dart';
import 'package:kente_codeweaver/features/settings/providers/settings_provider.dart';
import 'package:kente_codeweaver/features/badges/providers/badge_provider.dart';
import 'package:kente_codeweaver/core/navigation/app_router.dart';
import 'package:kente_codeweaver/core/utils/service_locator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kente_codeweaver/core/services/gemini_service.dart';

/// Main entry point for the application
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize the shared Gemini service
  await GeminiService().initialize();

  // Run the app
  runApp(const MyApp());
}

/// Main application widget
class MyApp extends StatelessWidget {
  /// Constructor
  const MyApp({super.key});

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

        // Badge provider
        ChangeNotifierProvider(
          create: (_) => BadgeProvider(),
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
