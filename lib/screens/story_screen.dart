import 'package:flutter/material.dart';
import 'package:kente_codeweaver/screens/block_workspace.dart';
import 'package:kente_codeweaver/providers/story_provider.dart';
import 'package:kente_codeweaver/providers/block_provider.dart';
import 'package:kente_codeweaver/services/tts_service.dart';
import 'package:provider/provider.dart';

class StoryScreen extends StatefulWidget {
  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TTSService _ttsService = TTSService();
  bool _isSpeaking = false;
  
  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }
  
  Future<void> _initializeTTS() async {
    await _ttsService.initialize();
  }
  
  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story'),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleSpeech,
          ),
        ],
      ),
      body: Consumer<StoryProvider>(
        builder: (context, storyProvider, child) {
          final story = storyProvider.currentStory;
          
          if (story == null) {
            return Center(child: Text('No story available'));
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Difficulty Level: ${story.difficultyLevel}/5',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 20),
                Text(
                  story.content,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Set available blocks in the provider
                      final blockProvider = Provider.of<BlockProvider>(context, listen: false);
                      blockProvider.setAvailableBlocks(story.codeBlocks);
                      
                      // Navigate to block workspace
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BlockWorkspace()),
                      );
                    },
                    child: Text('Start Coding'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _toggleSpeech() async {
    final story = Provider.of<StoryProvider>(context, listen: false).currentStory;
    
    if (story == null) return;
    
    setState(() {
      _isSpeaking = !_isSpeaking;
    });
    
    if (_isSpeaking) {
      await _ttsService.speak(story.content);
    } else {
      await _ttsService.stop();
    }
  }
}