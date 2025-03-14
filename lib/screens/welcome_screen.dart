import 'package:flutter/material.dart';
import 'package:kente_codeweaver/screens/story_screen.dart';
import 'package:kente_codeweaver/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/providers/story_provider.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _characterController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initialize the story service
    Future.microtask(() => 
      Provider.of<StoryProvider>(context, listen: false).initialize()
    );
  }
  
  @override
  void dispose() {
    _ageController.dispose();
    _themeController.dispose();
    _characterController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kente Codeweaver'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => SettingsScreen())
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/ananse.png', width: 150),
              SizedBox(height: 20),
              Text(
                'Welcome to Kente Codeweaver',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 30),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _themeController,
                decoration: InputDecoration(
                  labelText: 'Story Theme (e.g., Space, Animals, Ocean)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _characterController,
                decoration: InputDecoration(
                  labelText: 'Character Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 30),
              Consumer<StoryProvider>(
                builder: (context, storyProvider, child) {
                  if (storyProvider.isLoading) {
                    return CircularProgressIndicator();
                  }
                  
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: () async {
                      // Validate inputs
                      final age = int.tryParse(_ageController.text);
                      final theme = _themeController.text.trim();
                      
                      if (age == null || age < 7 || age > 15) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a valid age between 7-15'))
                        );
                        return;
                      }
                      
                      if (theme.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a story theme'))
                        );
                        return;
                      }
                      
                      // Generate story and navigate
                      await storyProvider.generateStory(
                        age: age,
                        theme: theme,
                        characterName: _characterController.text.isNotEmpty 
                            ? _characterController.text 
                            : null,
                      );
                      
                      if (storyProvider.error == null) {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => StoryScreen())
                        );
                      }
                    },
                    child: Text('Start Story', style: TextStyle(fontSize: 18)),
                  );
                },
              ),
              
              // Show error if any
              Consumer<StoryProvider>(
                builder: (context, provider, child) {
                  if (provider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Error: ${provider.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}