import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/screens/story_screen.dart';
import 'package:kente_codeweaver/models/story.dart';

void main() {
  final testStory = Story(
    id: 'story123',
    title: 'Ananse and the Coding Web',
    content: 'Once upon a time in the village of Ntonso, Ananse the spider wanted to learn coding...',
    theme: 'loops',
    age: 10,
    createdAt: DateTime.now(),
  );

  testWidgets('Story Screen displays story content', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoryScreen(story: testStory),
    ));

    // Check if story title is displayed
    expect(find.text('Ananse and the Coding Web'), findsOneWidget);
    
    // Check if story content is displayed
    expect(find.text('Once upon a time in the village of Ntonso, Ananse the spider wanted to learn coding...'), findsOneWidget);
    
    // Check if TTS controls are displayed
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
  
  testWidgets('Story Screen has navigation to block workspace', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoryScreen(story: testStory),
    ));
    
    // Check if the "Try Coding" button is present
    expect(find.text('Try Coding'), findsOneWidget);
    
    // Tap the button and ensure navigation
    await tester.tap(find.text('Try Coding'));
    await tester.pumpAndSettle();
    
    // At this point, we'd expect to be on the BlockWorkspace screen
    // This would need to be verified depending on your navigation implementation
  });
  
  testWidgets('Story Screen TTS controls function properly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoryScreen(story: testStory),
    ));
    
    // Test play button
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    
    // Capture the state to verify TTS is playing
    final state = tester.state(find.byType(StoryScreen)) as StoryScreenState;
    expect(state.isPlaying, true);
    
    // Test pause button
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    expect(state.isPlaying, false);
  });
}