import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider.dart';
import 'package:kente_codeweaver/core/navigation/app_router.dart';

/// Welcome screen for the application
class WelcomeScreen extends StatefulWidget {
  /// Constructor
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  /// Animation controller
  late AnimationController _animationController;

  /// Fade animation
  late Animation<double> _fadeAnimation;

  /// Scale animation
  late Animation<double> _scaleAnimation;

  /// Is loading
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Initialize providers after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize providers
  Future<void> _initializeProviders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final learningProvider = Provider.of<LearningProvider>(context, listen: false);
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);

      // Initialize providers with timeouts to prevent indefinite waiting
      await Future.wait([
        learningProvider.initialize('default_user').timeout(
          Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Learning provider initialization timed out');
            return; // Return without throwing to continue
          },
        ),
        storyProvider.initialize().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Story provider initialization timed out');
            return; // Return without throwing to continue
          },
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error during provider initialization: $e');

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Some features may be limited: ${e.toString()}'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _initializeProviders(),
          ),
        ),
      );
    }
  }

  /// Start the app journey by going to the home screen
  void _startJourney() {
    AppRouter.goHome(context);
  }

  /// Open settings
  void _openSettings() {
    AppRouter.goToSettings(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple[700]!,
              Colors.deepPurple[900]!,
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Icon(
                          Icons.auto_awesome,
                          size: 100,
                          color: Colors.white,
                        ),
                        SizedBox(height: 24),

                        // Title
                        Text(
                          'Kente Codeweaver',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Learn coding through storytelling',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 48),

                        // Start button
                        ElevatedButton(
                          onPressed: _startJourney,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Start Adventure'),
                        ),
                        SizedBox(height: 16),

                        // Settings button
                        OutlinedButton(
                          onPressed: _openSettings,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
