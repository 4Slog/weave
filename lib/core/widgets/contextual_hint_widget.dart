import 'package:flutter/material.dart';
import 'package:kente_codeweaver/core/models/emotional_tone.dart';
import 'package:kente_codeweaver/core/services/audio_service.dart';

/// Widget for displaying contextual hints with cultural elements.
class ContextualHintWidget extends StatefulWidget {
  /// The hint text to display
  final String text;

  /// The emotional tone of the hint
  final EmotionalTone tone;

  /// Optional image path to display with the hint
  final String? imagePath;

  /// Whether this hint is particularly important
  final bool isImportant;

  /// Callback when the hint is dismissed
  final VoidCallback? onDismiss;

  /// Audio service for hint sounds
  final AudioService? audioService;

  const ContextualHintWidget({
    super.key,
    required this.text,
    this.tone = EmotionalTone.neutral,
    this.imagePath,
    this.isImportant = false,
    this.onDismiss,
    this.audioService,
  });

  @override
  State<ContextualHintWidget> createState() => _ContextualHintWidgetState();
}

class _ContextualHintWidgetState extends State<ContextualHintWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isImportant ? 800 : 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Play hint sound if important
    if (widget.isImportant && widget.audioService != null) {
      widget.audioService!.playEffect(AudioType.hint);
    }

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Card(
          margin: const EdgeInsets.all(16.0),
          elevation: widget.isImportant ? 6.0 : 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: _getToneColor().withAlpha(179),
              width: widget.isImportant ? 2.0 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with character image and dismiss button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Character image
                    if (widget.imagePath != null) ...[
                      Image.asset(
                        widget.imagePath!,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildCharacterIcon();
                        },
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      _buildCharacterIcon(),
                      const SizedBox(width: 12),
                    ],

                    // Hint text
                    Expanded(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: _getToneColor(),
                          fontWeight: widget.isImportant ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),

                    // Dismiss button
                    if (widget.onDismiss != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                  ],
                ),

                // Hint image if available
                if (widget.imagePath != null && !widget.imagePath!.contains('character'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        widget.imagePath!,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          // If image loading fails, don't show anything
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a character icon based on the emotional tone
  Widget _buildCharacterIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getToneColor().withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getToneIcon(),
        color: _getToneColor(),
        size: 24,
      ),
    );
  }

  /// Get the appropriate icon for the emotional tone
  IconData _getToneIcon() {
    switch (widget.tone) {
      case EmotionalTone.happy:
        return Icons.sentiment_very_satisfied;
      case EmotionalTone.excited:
        return Icons.emoji_emotions;
      case EmotionalTone.calm:
        return Icons.spa;
      case EmotionalTone.encouraging:
        return Icons.thumb_up;
      case EmotionalTone.dramatic:
        return Icons.theater_comedy;
      case EmotionalTone.curious:
        return Icons.psychology;
      case EmotionalTone.concerned:
        return Icons.sentiment_dissatisfied;
      case EmotionalTone.sad:
        return Icons.sentiment_very_dissatisfied;
      case EmotionalTone.proud:
        return Icons.emoji_events;
      case EmotionalTone.thoughtful:
        return Icons.lightbulb;
      case EmotionalTone.wise:
        return Icons.school;
      case EmotionalTone.neutral:
      default:
        return Icons.face;
    }
  }

  /// Get the appropriate color for the emotional tone
  Color _getToneColor() {
    switch (widget.tone) {
      case EmotionalTone.happy:
        return Colors.green;
      case EmotionalTone.excited:
        return Colors.amber;
      case EmotionalTone.calm:
        return Colors.blue[200] ?? Colors.blue;
      case EmotionalTone.encouraging:
        return Colors.teal;
      case EmotionalTone.dramatic:
        return Colors.purple;
      case EmotionalTone.curious:
        return Colors.blue;
      case EmotionalTone.concerned:
        return Colors.orange;
      case EmotionalTone.sad:
        return Colors.deepOrange;
      case EmotionalTone.proud:
        return Colors.purple;
      case EmotionalTone.thoughtful:
        return Colors.teal;
      case EmotionalTone.wise:
        return Colors.indigo;
      case EmotionalTone.neutral:
      default:
        return Colors.grey.shade700;
    }
  }
}
