import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/providers/settings_provider.dart';
import 'package:kente_codeweaver/services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  final StorageService _storageService = StorageService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: Text('Text-to-Speech'),
                subtitle: Text('Enable voice narration for stories'),
                value: settings.ttsEnabled,
                onChanged: (value) {
                  settings.setTtsEnabled(value);
                },
              ),
              Divider(),
              ListTile(
                title: Text('TTS Speed'),
                subtitle: Slider(
                  value: settings.ttsSpeed,
                  min: 0.5,
                  max: 1.5,
                  divisions: 4,
                  label: settings.ttsSpeed.toString(),
                  onChanged: (value) {
                    settings.setTtsSpeed(value);
                  },
                ),
              ),
              Divider(),
              SwitchListTile(
                title: Text('Dark Mode'),
                subtitle: Text('Switch between light and dark theme'),
                value: settings.darkModeEnabled,
                onChanged: (value) {
                  settings.setDarkModeEnabled(value);
                },
              ),
              Divider(),
              SwitchListTile(
                title: Text('Sound Effects'),
                subtitle: Text('Play sounds during interaction'),
                value: settings.soundEffectsEnabled,
                onChanged: (value) {
                  settings.setSoundEffectsEnabled(value);
                },
              ),
              Divider(),
              ListTile(
                title: Text('Clear Cache'),
                subtitle: Text('Delete saved stories and progress'),
                trailing: Icon(Icons.delete_forever),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Clear Cache'),
                      content: Text('Are you sure you want to clear all saved data? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('CLEAR'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await _storageService.clearAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cache cleared successfully'))
                    );
                  }
                },
              ),
              Divider(),
              ListTile(
                title: Text('About'),
                subtitle: Text('Kente Codeweaver v1.0.0'),
                trailing: Icon(Icons.info_outline),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Kente Codeweaver',
                    applicationVersion: '1.0.0',
                    applicationIcon: Image.asset(
                      'assets/images/ananse.png',
                      width: 50,
                      height: 50,
                    ),
                    children: [
                      Text('An AI-driven storytelling and block-based coding app designed to teach coding concepts to children through cultural storytelling.'),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}