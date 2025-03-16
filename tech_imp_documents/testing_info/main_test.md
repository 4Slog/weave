import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/main.dart';

void main() {
  testWidgets('App should launch to welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KenteCodeweaverApp());

    // Verify that the welcome screen is displayed
    expect(find.text('Welcome to Kente Codeweaver'), findsOneWidget);
    
    // Check for theme selection option
    expect(find.text('Select a Theme'), findsOneWidget);
    
    // Check for app logo/icon
    expect(find.byKey(ValueKey('app_logo')), findsOneWidget);
  });
  
  testWidgets('App has proper theme applied', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KenteCodeweaverApp());
    
    // Get the MaterialApp widget
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    
    // Verify theme properties
    expect(app.theme!.primaryColor, isNotNull);
    expect(app.theme!.brightness, Brightness.light);
    
    // Check if theme has custom font
    expect(app.theme!.textTheme.bodyLarge!.fontFamily, 'Roboto');
  });
  
  testWidgets('Navigation drawer is accessible', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KenteCodeweaverApp());
    
    // Open the drawer
    await tester.dragFrom(
      tester.getTopLeft(find.byType(MaterialApp)), 
      const Offset(300, 0)
    );
    await tester.pumpAndSettle();
    
    // Verify drawer items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Stories'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
  
  testWidgets('App handles theme switching', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KenteCodeweaverApp());
    
    // Open the drawer
    await tester.dragFrom(
      tester.getTopLeft(find.byType(MaterialApp)), 
      const Offset(300, 0)
    );
    await tester.pumpAndSettle();
    
    // Navigate to settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    
    // Find dark mode toggle
    final darkModeSwitch = find.byKey(ValueKey('dark_mode_switch'));
    expect(darkModeSwitch, findsOneWidget);
    
    // Toggle dark mode
    await tester.tap(darkModeSwitch);
    await tester.pumpAndSettle();
    
    // Verify theme has changed
    final MaterialApp updatedApp = tester.widget(find.byType(MaterialApp));
    expect(updatedApp.theme!.brightness, Brightness.dark);
  });
}