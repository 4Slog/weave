import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/widgets/asset_demo_widget.dart';

/// A screen that demonstrates the asset integration
class AssetDemoScreen extends StatelessWidget {
  /// Constructor
  const AssetDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const AssetDemoWidget(),
    );
  }
}
