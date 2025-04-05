import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';
import 'package:kente_codeweaver/features/badges/providers/badge_provider.dart';
import 'package:provider/provider.dart';

/// Widget to display a badge or collection of badges
class BadgeDisplayWidget extends StatelessWidget {
  /// The badge ID to display (if showing a single badge)
  final String? badgeId;

  /// The category of badges to display (if showing multiple badges)
  final String? category;

  /// Whether to show only earned badges
  final bool earnedOnly;

  /// Size of each badge
  final double badgeSize;

  /// Whether to show badge details
  final bool showDetails;

  /// Whether to show a celebration animation when displayed
  final bool showCelebration;

  /// Callback when a badge is tapped
  final Function(BadgeModel)? onBadgeTap;

  /// Create a badge display widget
  const BadgeDisplayWidget({
    super.key,
    this.badgeId,
    this.category,
    this.earnedOnly = false,
    this.badgeSize = 80,
    this.showDetails = true,
    this.showCelebration = false,
    this.onBadgeTap,
  }) : assert(badgeId != null || category != null, 'Either badgeId or category must be provided');

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        if (!badgeProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (badgeId != null) {
          // Display a single badge
          final badge = badgeProvider.getBadge(badgeId!);
          if (badge == null) {
            return const SizedBox.shrink();
          }

          final isEarned = badgeProvider.hasBadge(badgeId!);
          if (earnedOnly && !isEarned) {
            return const SizedBox.shrink();
          }

          return _buildBadge(context, badge, isEarned);
        } else {
          // Display multiple badges by category
          List<BadgeModel> badges;
          if (earnedOnly) {
            badges = badgeProvider.getEarnedBadgesByCategory(category!);
          } else {
            badges = badgeProvider.getBadgesByCategory(category!);
          }

          if (badges.isEmpty) {
            return const Center(
              child: Text('No badges found'),
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: badges.map((badge) {
              final isEarned = badgeProvider.hasBadge(badge.id);
              return _buildBadge(context, badge, isEarned);
            }).toList(),
          );
        }
      },
    );
  }

  /// Build a single badge widget
  Widget _buildBadge(BuildContext context, BadgeModel badge, bool isEarned) {
    return GestureDetector(
      onTap: () {
        if (onBadgeTap != null) {
          onBadgeTap!(badge);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEarned ? Colors.amber.shade700 : Colors.grey.shade400,
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: Color.fromRGBO(255, 193, 7, 128), // Colors.amber with 50% opacity
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                _getIconForBadge(badge),
                size: badgeSize * 0.6,
                color: isEarned ? Colors.white : Color.fromRGBO(255, 255, 255, 128), // White with 50% opacity
              ),
            ),
          ),

          // Badge name
          if (showDetails)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                badge.name,
                style: TextStyle(
                  fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                  color: isEarned ? Colors.black : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Badge description
          if (showDetails && isEarned)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                badge.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Get an appropriate icon for the badge
  IconData _getIconForBadge(BadgeModel badge) {
    // Since BadgeModel doesn't have iconData or category fields,
    // we'll determine the icon based on the badge ID or name

    // Check if the badge ID contains certain keywords
    final badgeIdLower = badge.id.toLowerCase();
    final badgeNameLower = badge.name.toLowerCase();

    // Choose icon based on badge ID or name
    if (badgeIdLower.contains('loop') || badgeNameLower.contains('loop')) {
      return Icons.loop;
    } else if (badgeIdLower.contains('pattern') || badgeNameLower.contains('pattern')) {
      return Icons.grid_on;
    } else if (badgeIdLower.contains('story') || badgeNameLower.contains('story')) {
      return Icons.book;
    } else if (badgeIdLower.contains('creator') || badgeNameLower.contains('creator')) {
      return Icons.create;
    } else if (badgeIdLower.contains('master') || badgeNameLower.contains('master')) {
      return Icons.emoji_events;
    } else {
      // Default icon
      return Icons.star;
    }
  }
}
