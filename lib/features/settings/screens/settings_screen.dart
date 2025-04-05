import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/settings/providers/settings_provider.dart';

/// Settings screen for the application
class SettingsScreen extends StatefulWidget {
  /// Constructor
  const SettingsScreen({Key? key}) : super(key: key);
  
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Settings provider
  late SettingsProvider _settingsProvider;
  
  /// Text-to-speech enabled
  bool _ttsEnabled = true;
  
  /// Sound effects enabled
  bool _soundEffectsEnabled = true;
  
  /// Music enabled
  bool _musicEnabled = true;
  
  /// Dark mode enabled
  bool _darkModeEnabled = false;
  
  /// Text size
  double _textSize = 16.0;
  
  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _loadSettings();
  }
  
  /// Load settings
  void _loadSettings() {
    // For now, use default values
    // In a real implementation, these would be loaded from the settings provider
    setState(() {
      _ttsEnabled = true;
      _soundEffectsEnabled = true;
      _musicEnabled = true;
      _darkModeEnabled = false;
      _textSize = 16.0;
    });
  }
  
  /// Save settings
  void _saveSettings() {
    // For now, just show a snackbar
    // In a real implementation, these would be saved to the settings provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Audio settings
          _buildSectionHeader('Audio'),
          SwitchListTile(
            title: Text('Text-to-Speech'),
            subtitle: Text('Enable voice narration'),
            value: _ttsEnabled,
            onChanged: (value) {
              setState(() {
                _ttsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Sound Effects'),
            subtitle: Text('Enable sound effects'),
            value: _soundEffectsEnabled,
            onChanged: (value) {
              setState(() {
                _soundEffectsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Music'),
            subtitle: Text('Enable background music'),
            value: _musicEnabled,
            onChanged: (value) {
              setState(() {
                _musicEnabled = value;
              });
            },
          ),
          Divider(),
          
          // Appearance settings
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Enable dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          ListTile(
            title: Text('Text Size'),
            subtitle: Slider(
              value: _textSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              label: _textSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  _textSize = value;
                });
              },
            ),
          ),
          Divider(),
          
          // About section
          _buildSectionHeader('About'),
          ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            title: Text('Credits'),
            onTap: () {
              // Show credits dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Credits'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Developed by: Kente Codeweaver Team'),
                      SizedBox(height: 8),
                      Text('Artwork: Creative Commons'),
                      SizedBox(height: 8),
                      Text('Music: Creative Commons'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: Text('Privacy Policy'),
            onTap: () {
              // Show privacy policy dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Privacy Policy'),
                  content: Text(
                    'Kente Codeweaver respects your privacy. '
                    'We do not collect any personal information. '
                    'All data is stored locally on your device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
