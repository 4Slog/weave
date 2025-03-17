import 'package:flutter/material.dart';
import 'package:kente_codeweaver/models/badge_model.dart';

/// A widget that displays badges in a grid or list
class BadgeDisplayWidget extends StatelessWidget {
  /// List of badges to display
  final List<BadgeModel> badges;
  
  /// Callback when a badge is tapped
  final void Function(BadgeModel)? onBadgeTap;
  
  /// Whether to show badges in a grid (true) or list (false)
  final bool isGrid;
  
  /// Number of columns in grid mode
  final int gridColumns;
  
  /// Whether to show empty state when no badges
  final bool showEmptyState;
  
  /// Custom empty state message
  final String? emptyStateMessage;
  
  const BadgeDisplayWidget({
    Key? key,
    required this.badges,
    this.onBadgeTap,
    this.isGrid = true,
    this.gridColumns = 3,
    this.showEmptyState = true,
    this.emptyStateMessage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty && showEmptyState) {
      return _buildEmptyState(context);
    }
    
    return isGrid ? _buildBadgeGrid() : _buildBadgeList();
  }
  
  /// Build a grid of badges
  Widget _buildBadgeGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeItem(badge);
      },
    );
  }
  
  /// Build a list of badges
  Widget _buildBadgeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildBadgeListItem(badge),
        );
      },
    );
  }
  
  /// Build an individual badge item for the grid
  Widget _buildBadgeItem(BadgeModel badge) {
    return InkWell(
      onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _getTierColor(badge.tier).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getTierColor(badge.tier),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              badge.imageAssetPath,
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: _getTierColor(badge.tier),
                );
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _getTierColor(badge.tier),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build an individual badge item for the list
  Widget _buildBadgeListItem(BadgeModel badge) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getTierColor(badge.tier),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getTierColor(badge.tier).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    badge.imageAssetPath,
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.emoji_events,
                        size: 44,
                        color: _getTierColor(badge.tier),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getTierColor(badge.tier),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (badge.storyReward != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unlocks special story!',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _getTierColor(badge.tier),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build the empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            emptyStateMessage ?? 'No badges earned yet.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete challenges to earn badges!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Get color based on badge tier
  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.green[700]!; // Basic tier
      case 2:
        return Colors.blue[700]!; // Intermediate tier
      case 3:
        return Colors.purple[700]!; // Advanced tier
      default:
        return Colors.grey[700]!;
    }
  }
}