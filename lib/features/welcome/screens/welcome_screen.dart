import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider.dart';

/// Welcome screen for the application
class WelcomeScreen extends StatefulWidget {
  /// Constructor
  const WelcomeScreen({Key? key}) : super(key: key);
  
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
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
    
    // Initialize providers
    _initializeProviders();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Initialize providers
  Future<void> _initializeProviders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final learningProvider = Provider.of<LearningProvider>(context, listen: false);
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      
      // Initialize providers
      await learningProvider.initialize('default_user');
      await storyProvider.initialize();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize: ${e.toString()}')),
      );
    }
  }
  
  /// Start a story
  void _startStory() {
    Navigator.pushNamed(
      context,
      '/story',
      arguments: {'storyId': 'story_001'},
    );
  }
  
  /// Open settings
  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
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
                          onPressed: _startStory,
                          child: Text('Start Adventure'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Settings button
                        OutlinedButton(
                          onPressed: _openSettings,
                          child: Text('Settings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
