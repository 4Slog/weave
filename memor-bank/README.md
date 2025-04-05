# Memory Bank - Build Tracking System

A comprehensive system for tracking and analyzing builds of the Weave Flutter application.

## Purpose

The Memory Bank is designed to:
- Track build versions and timestamps
- Record changes between builds
- Measure build performance metrics
- Log build errors and warnings
- Monitor dependencies and their versions

## Directory Structure

```
memor-bank/
├── README.md                    # This documentation file
├── builds/                      # Directory to store build information
│   └── tracking/                # Directory to store code change tracking information
├── logs/                        # Directory to store build logs
├── metrics/                     # Directory to store performance metrics
├── reports/                     # Directory to store generated reports
├── scripts/                     # Helper scripts for the build tracking
│   ├── track_build.dart         # Script to record build information
│   ├── generate_report.dart     # Script to generate build reports
│   ├── auto_track.dart          # Script to automatically track code changes
│   ├── install_hooks.dart       # Script to install Git hooks
│   ├── extension.js             # VSCode extension implementation
│   └── vscode_extension.json    # VSCode extension configuration
└── config.json                  # Configuration for the build tracking system
```

## Configuration

The `config.json` file contains settings for the build tracking system:

- `appName`: The name of the application being tracked
- `trackMetrics`: Whether to track performance metrics
- `retentionPeriod`: Number of days to retain build information
- `notifyOnFailure`: Whether to send notifications on build failures
- `compareWithPreviousBuild`: Whether to compare builds with previous ones
- `buildTypes`: Types of builds to track (debug, profile, release)
- `metrics`: Specific metrics to track
- `notifications`: Notification methods to use

## Usage

### Tracking a Build

To track a build, run the `track_build.dart` script:

```bash
dart memor-bank/scripts/track_build.dart --type=debug
```

This will:
1. Capture the build timestamp
2. Record Flutter/Dart version
3. Log the build command and parameters
4. Store the build output (success/failure)
5. Measure the build duration
6. Track dependencies and their versions

### Generating Reports

To generate a report of builds, run the `generate_report.dart` script:

```bash
dart memor-bank/scripts/generate_report.dart --last=10
```

This will generate a report of the last 10 builds, including:
- Build summaries
- Comparison between builds
- Visualization of build metrics
- Potential issues or improvements

## Integration with Build Process

To automatically track builds, you can integrate the `track_build.dart` script with your build process:

1. Add a pre-build hook to capture the start time
2. Add a post-build hook to capture the end time and other metrics
3. Configure notifications based on build results

### Automatic Code Change Tracking

Memory Bank can automatically track code changes as you write code, using one of the following methods:

#### Git Hooks

To install Git hooks that automatically track code changes when you commit or push code:

```bash
dart memor-bank/scripts/install_hooks.dart
```

This will install the following Git hooks:
- `pre-commit`: Runs before a commit is created
- `post-commit`: Runs after a commit is created
- `pre-push`: Runs before changes are pushed to a remote repository

#### VSCode Extension

Memory Bank includes a VSCode extension that automatically tracks code changes when you save files in VSCode:

1. Install the extension:
   ```bash
   cd memor-bank/scripts
   npm install
   npm run compile
   ```

2. Enable the extension in VSCode:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
   - Type "Memory Bank: Enable Auto-Tracking" and press Enter

The extension provides the following commands:
- `Memory Bank: Track Changes`: Manually track changes
- `Memory Bank: Enable Auto-Tracking`: Enable automatic tracking
- `Memory Bank: Disable Auto-Tracking`: Disable automatic tracking

You can configure the extension in VSCode settings:
- `memory-bank.autoTrack`: Enable/disable automatic tracking
- `memory-bank.trackOnSave`: Track changes when files are saved
- `memory-bank.trackOnCommit`: Track changes when files are committed
- `memory-bank.excludePatterns`: Patterns to exclude from tracking

## Future Enhancements

Planned enhancements for the Memory Bank include:
- Web dashboard for visualizing build metrics
- Integration with CI/CD pipelines
- Automated performance regression detection
- Build optimization recommendations
- Real-time code change visualization
- Code quality metrics tracking
- Team collaboration features
