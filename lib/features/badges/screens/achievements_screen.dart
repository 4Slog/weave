import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/badges/providers/badge_provider.dart';
import 'package:kente_codeweaver/features/badges/models/badge_model.dart';

/// Screen for displaying user achievements and badges
class AchievementsScreen extends StatefulWidget {
  /// User ID
  final String userId;

  /// Constructor
  const AchievementsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  /// Animation controller
  late AnimationController _animationController;
  
  /// Animation
  late Animation<double> _animation;
  
  /// Selected category
  String _selectedCategory = 'all';
  
  /// Badge provider
  late BadgeProvider _badgeProvider;
  
  /// Is loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Initialize animation
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _animationController.forward();
    
    // Initialize badge provider
    _badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
    _initializeBadgeProvider();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Initialize badge provider
  Future<void> _initializeBadgeProvider() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (!_badgeProvider.isInitialized) {
        await _badgeProvider.initialize(widget.userId);
      } else {
        await _badgeProvider.refreshEarnedBadges();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load badges: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeBadgeProvider,
            tooltip: 'Refresh Badges',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
  
  /// Build the body of the screen
  Widget _buildBody() {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, _) {
        final earnedBadges = badgeProvider.earnedBadges;
        final allBadges = badgeProvider.badges;
        
        if (allBadges.isEmpty) {
          return const Center(
            child: Text('No badges available'),
          );
        }
        
        return Column(
          children: [
            // Category selector
            _buildCategorySelector(),
            
            // Badge stats
            _buildBadgeStats(earnedBadges.length, allBadges.length),
            
            // Badge grid
            Expanded(
              child: FadeTransition(
                opacity: _animation,
                child: _buildBadgeGrid(badgeProvider),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Build the category selector
  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('all', 'All Badges'),
          _buildCategoryChip('1', 'Beginner'),
          _buildCategoryChip('2', 'Intermediate'),
          _buildCategoryChip('3', 'Advanced'),
        ],
      ),
    );
  }
  
  /// Build a category chip
  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            // Restart animation
            _animationController.reset();
            _animationController.forward();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }
  
  /// Build badge stats
  Widget _buildBadgeStats(int earned, int total) {
    final progress = total > 0 ? earned / total : 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            'Earned $earned out of $total badges (${(progress * 100).toInt()}%)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  /// Build the badge grid
  Widget _buildBadgeGrid(BadgeProvider badgeProvider) {
    List<BadgeModel> badges;
    
    if (_selectedCategory == 'all') {
      badges = badgeProvider.badges;
    } else {
      badges = badgeProvider.getBadgesByCategory(_selectedCategory);
    }
    
    if (badges.isEmpty) {
      return const Center(
        child: Text('No badges in this category'),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isEarned = badgeProvider.hasBadge(badge.id);
        
        return _buildBadgeCard(badge, isEarned);
      },
    );
  }
  
  /// Build a badge card
  Widget _buildBadgeCard(BadgeModel badge, bool isEarned) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEarned ? _getBadgeTierColor(badge.tier) : Colors.grey[300]!,
          width: isEarned ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showBadgeDetails(badge, isEarned),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge image or icon
              Expanded(
                child: Opacity(
                  opacity: isEarned ? 1.0 : 0.5,
                  child: Image.asset(
                    badge.imageAssetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.emoji_events,
                        size: 60,
                        color: isEarned 
                            ? _getBadgeTierColor(badge.tier) 
                            : Colors.grey[400],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Badge name
              Text(
                badge.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEarned ? Colors.black : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Badge status
              Text(
                isEarned ? 'Earned' : 'Locked',
                style: TextStyle(
                  fontSize: 12,
                  color: isEarned ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Show badge details
  void _showBadgeDetails(BadgeModel badge, bool isEarned) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge image
            Image.asset(
              badge.imageAssetPath,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.emoji_events,
                  size: 100,
                  color: _getBadgeTierColor(badge.tier),
                );
              },
            ),
            const SizedBox(height: 16),
            // Badge description
            Text(
              badge.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Badge status
            Text(
              isEarned ? 'You have earned this badge!' : 'Keep learning to earn this badge!',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: isEarned ? Colors.green : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (badge.storyReward != null && isEarned) ...[
              const SizedBox(height: 16),
              Text(
                'This badge has unlocked a special story!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// Get color based on badge tier
  Color _getBadgeTierColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.green[700]!;
      case 2:
        return Colors.blue[700]!;
      case 3:
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
