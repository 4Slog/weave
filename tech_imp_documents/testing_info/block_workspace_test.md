import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kente_codeweaver/screens/block_workspace.dart';

void main() {
  testWidgets('Block workspace allows adding blocks', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: BlockWorkspace()));
    
    // Verify that initially no blocks are present in the workspace
    expect(find.byKey(ValueKey('workspace-blocks')), findsOneWidget);
    expect(find.byKey(ValueKey('block-item')), findsNothing);
    
    // Simulate adding a block
    final workspaceState = tester.state(find.byType(BlockWorkspace)) as BlockWorkspaceState;
    workspaceState.addBlock('Loop Block');
    await tester.pump();
    
    // Verify that a block has been added
    expect(find.text('Loop Block'), findsOneWidget);
  });
  
  testWidgets('Block workspace toolbar contains coding blocks', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: BlockWorkspace()));
    
    // Check if toolbar is present
    expect(find.byKey(ValueKey('blocks-toolbar')), findsOneWidget);
    
    // Check if standard block types are available
    expect(find.text('Loop'), findsOneWidget);
    expect(find.text('If-Else'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
  });
  
  testWidgets('Blocks can be dragged and dropped', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: BlockWorkspace()));
    
    // Get references to the toolbar and workspace
    final toolbar = find.byKey(ValueKey('blocks-toolbar'));
    final workspace = find.byKey(ValueKey('workspace-blocks'));
    
    // Find a draggable block in the toolbar
    final loopBlock = find.text('Loop').first;
    
    // Perform a drag operation from toolbar to workspace
    await tester.drag(loopBlock, Offset(0, 200)); // Move down to workspace area
    await tester.pumpAndSettle();
    
    // Verify that the block appears in the workspace
    expect(find.descendant(
      of: workspace,
      matching: find.text('Loop'),
    ), findsOneWidget);
  });
  
  testWidgets('Run button executes block code', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: BlockWorkspace()));
    
    // Add blocks to the workspace
    final workspaceState = tester.state(find.byType(BlockWorkspace)) as BlockWorkspaceState;
    workspaceState.addBlock('Loop Block');
    workspaceState.addBlock('Print Block');
    await tester.pump();
    
    // Find and press the run button
    await tester.tap(find.byKey(ValueKey('run-button')));
    await tester.pumpAndSettle();
    
    // Verify execution output appears
    expect(find.byKey(ValueKey('execution-output')), findsOneWidget);
    // This would need to be adapted to your specific output format
  });
}