import 'package:flutter/material.dart';

/// A widget that displays contextual hints with different tones and styles
class ContextualHintWidget extends StatelessWidget {
  /// The hint text to display
  final String text;
  
  /// The emotional tone of the hint (e.g., 'friendly', 'encouraging', 'technical')
  final String? tone;
  
  /// Optional image path to display with the hint
  final String? imagePath;
  
  /// Whether this hint is particularly important
  final bool isImportant;
  
  /// Callback when the hint is dismissed
  final VoidCallback onDismiss;

  /// Creates a contextual hint widget
  const ContextualHintWidget({
    super.key,
    required this.text,
    this.tone,
    this.imagePath,
    this.isImportant = false,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Choose color based on tone
    Color backgroundColor;
    Color textColor = Colors.white;
    
    switch (tone?.toLowerCase() ?? 'neutral') {
      case 'friendly':
        backgroundColor = Colors.blue.shade700;
        break;
      case 'encouraging':
        backgroundColor = Colors.green.shade700;
        break;
      case 'technical':
        backgroundColor = Colors.purple.shade700;
        break;
      case 'warning':
        backgroundColor = Colors.orange.shade700;
        break;
      case 'cultural':
        backgroundColor = Colors.deepPurple.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade800;
    }
    
    // Make important hints stand out more
    if (isImportant) {
      backgroundColor = Colors.red.shade700;
    }
    
    return Card(
      color: backgroundColor,
      elevation: isImportant ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isImportant 
          ? BorderSide(color: Colors.yellow, width: 2)
          : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display image if provided
                if (imagePath != null && imagePath!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imagePath!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(Icons.image_not_supported, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                
                // Hint text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                
                // Dismiss button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss hint',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
