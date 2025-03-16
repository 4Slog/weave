import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/screens/welcome_screen.dart';

void main() {
  testWidgets('Welcome Screen UI Elements', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: WelcomeScreen()));

    // Check if app title is displayed
    expect(find.text('Welcome to Kente Codeweaver'), findsOneWidget);
    
    // Check if the start button is present
    expect(find.text('Start Story'), findsOneWidget);
    
    // Tap the button and ensure navigation
    await tester.tap(find.text('Start Story'));
    await tester.pumpAndSettle();
  });
  
  testWidgets('Welcome Screen displays theme options', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: WelcomeScreen()));
    
    // Check if theme selection is available
    expect(find.text('Select a Theme'), findsOneWidget);
    expect(find.text('Loops'), findsOneWidget);
    expect(find.text('Conditionals'), findsOneWidget);
    expect(find.text('Variables'), findsOneWidget);
    
    // Test theme selection interaction
    await tester.tap(find.text('Loops'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
  
  testWidgets('Welcome Screen allows age selection', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: WelcomeScreen()));
    
    // Check if age selection is available
    expect(find.text('Select Age Range'), findsOneWidget);
    
    // Test age slider functionality
    final Finder ageSlider = find.byType(Slider);
    expect(ageSlider, findsOneWidget);
    
    await tester.drag(ageSlider, const Offset(50.0, 0.0));
    await tester.pump();
    
    // Verify age display updates
    expect(find.textContaining('Age: '), findsOneWidget);
  });
}