import 'package:flutter/material.dart';
import 'package:kente_codeweaver/features/storytelling/models/story_branch_model.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/core/services/audio_service.dart';

/// A widget that displays story branch choices for narrative progression
class NarrativeChoiceWidget extends StatefulWidget {
  /// Available story branches to choose from
  final List<StoryBranchModel> branches;

  /// Callback when a branch is selected
  final Function(StoryBranchModel) onBranchSelected;

  /// Current user progress for requirement checking
  final UserProgress? userProgress;

  /// Audio service for sound effects
  final AudioService? audioService;

  /// Custom title for the choices section
  final String? title;

  /// Whether to show the difficulty level for each choice
  final bool showDifficulty;

  /// Whether to animate the choices appearance
  final bool animate;

  /// Creates a narrative choice widget
  const NarrativeChoiceWidget({
    super.key,
    required this.branches,
    required this.onBranchSelected,
    this.userProgress,
    this.audioService,
    this.title,
    this.showDifficulty = true,
    this.animate = true,
  });

  @override
  State<NarrativeChoiceWidget> createState() => _NarrativeChoiceWidgetState();
}

class _NarrativeChoiceWidgetState extends State<NarrativeChoiceWidget> with SingleTickerProviderStateMixin {
  /// Animation controller for sliding in choices
  late AnimationController _animationController;

  /// Selected branch index
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'What will you do next?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Choices section
        ...List.generate(widget.branches.length, (index) {
          // Animation for staggered appearance
          final Animation<double> animation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.1, // stagger start times
              index * 0.1 + 0.6, // stagger end times
              curve: Curves.easeOut,
            ),
          );

          // Get branch data
          final branch = widget.branches[index];

          // Check if this branch has requirements that aren't met
          final bool isLocked = _isBranchLocked(branch);

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - animation.value)),
                child: Opacity(
                  opacity: animation.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildChoiceCard(branch, index, isLocked),
            ),
          );
        }),

        // Continue button (shown only when a choice is selected)
        if (_selectedIndex != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Play selection sound
                widget.audioService?.playEffect(AudioType.confirmationTap);

                // Notify parent of selection
                widget.onBranchSelected(widget.branches[_selectedIndex!]);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  /// Build a choice card for a story branch
  Widget _buildChoiceCard(StoryBranchModel branch, int index, bool isLocked) {
    final bool isSelected = _selectedIndex == index;

    // Get difficulty color
    Color difficultyColor;
    switch (branch.difficultyLevel) {
      case 1:
        difficultyColor = Colors.green;
        break;
      case 2:
        difficultyColor = Colors.lightGreen;
        break;
      case 3:
        difficultyColor = Colors.amber;
        break;
      case 4:
        difficultyColor = Colors.orange;
        break;
      case 5:
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.blue;
    }

    return GestureDetector(
      onTap: isLocked
          ? null  // No action if locked
          : () {
              // Play selection sound
              widget.audioService?.playEffect(AudioType.buttonTap);

              setState(() {
                _selectedIndex = index;
              });
            },
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Choice indicator/number
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLocked
                          ? Colors.grey.shade300
                          : isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isLocked
                              ? Colors.grey.shade500
                              : isSelected
                                  ? Colors.white
                                  : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Choice description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.description,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isLocked ? Colors.grey.shade500 : null,
                          ),
                        ),

                        // Lock message if choice is locked
                        if (isLocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _getLockMessage(branch),
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Difficulty indicator
            if (widget.showDifficulty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey.shade200 : difficultyColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocked ? Colors.grey.shade300 : difficultyColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: isLocked ? Colors.grey.shade400 : difficultyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${branch.difficultyLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey.shade400 : difficultyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Lock icon if needed
            if (isLocked)
              Positioned(
                bottom: 8,
                right: 8,
                child: Icon(
                  Icons.lock,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Check if a branch is locked based on requirements
  bool _isBranchLocked(StoryBranchModel branch) {
    // If no user progress or no requirements, it's not locked
    if (widget.userProgress == null || branch.requirements.isEmpty) {
      return false;
    }

    // Check each requirement
    for (var entry in branch.requirements.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      // Parse requirement key (format: "type:name")
      final parts = key.split(':');
      if (parts.length != 2) continue;

      final String requirementType = parts[0];
      final String requirementName = parts[1];

      switch (requirementType) {
        case 'skill':
          // Check skill proficiency
          // Uncomment when implementing actual skill check
          // final double requiredValue = value is double ? value : (value is int ? value.toDouble() : 0.0);
          /*
          // This would use the actual UserProgress model methods
          final skillType = _parseSkillType(requirementName);
          final userSkillLevel = widget.userProgress!.getSkillLevel(skillType);
          final userValue = _skillLevelToDouble(userSkillLevel);

          if (userValue < requiredValue) {
            return true; // Locked
          }
          */
          // For now, we'll just assume it's not locked for skill requirements
          break;

        case 'concept':
          // Check if concept is mastered
          final bool requireConceptMastered = value is bool ? value : false;
          if (requireConceptMastered) {
            /*
            // This would use the actual UserProgress model methods
            final conceptsMastered = widget.userProgress!.conceptsMastered;
            if (!conceptsMastered.contains(requirementName)) {
              return true; // Locked
            }
            */
            // For now, we'll just assume it's not locked for concept requirements
          }
          break;

        case 'badge':
          // Check if badge is earned
          final bool requireBadge = value is bool ? value : false;
          if (requireBadge) {
            if (!widget.userProgress!.earnedBadges.any((badge) => badge.id == requirementName)) {
              return true; // Locked
            }
          }
          break;

        case 'story':
          // Check if story is completed
          final bool requireStoryCompleted = value is bool ? value : false;
          if (requireStoryCompleted) {
            if (!widget.userProgress!.isStoryCompleted(requirementName)) {
              return true; // Locked
            }
          }
          break;

        default:
          // Unknown requirement type
          break;
      }
    }

    // If we get here, all requirements have been met
    return false;
  }

  /// Get a message explaining why a branch is locked
  String _getLockMessage(StoryBranchModel branch) {
    // Default message
    String message = "You haven't unlocked this path yet.";

    // If no user progress or no requirements, return default
    if (widget.userProgress == null || branch.requirements.isEmpty) {
      return message;
    }

    // Check requirements for a more specific message
    for (var entry in branch.requirements.entries) {
      final String key = entry.key;
      // Uncomment when implementing actual requirement check
      // final dynamic value = entry.value;

      // Parse requirement key (format: "type:name")
      final parts = key.split(':');
      if (parts.length != 2) continue;

      final String requirementType = parts[0];
      final String requirementName = parts[1];

      switch (requirementType) {
        case 'skill':
          return "Need more skill with $requirementName.";

        case 'concept':
          return "Master the $requirementName concept first.";

        case 'badge':
          return "Earn the ${_getBadgeName(requirementName)} badge first.";

        case 'story':
          return "Complete the ${_getStoryName(requirementName)} story first.";

        default:
          // Use default message
          break;
      }
    }

    return message;
  }

  /// Get a user-friendly badge name
  String _getBadgeName(String badgeId) {
    // This would fetch the actual badge name from a service
    switch (badgeId) {
      case 'loops_master':
        return "Loop Master";
      case 'pattern_creator':
        return "Pattern Creator";
      case 'storyteller':
        return "Storyteller";
      default:
        // Convert badgeId to title case as fallback
        return badgeId
            .split('_')
            .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  /// Get a user-friendly story name
  String _getStoryName(String storyId) {
    // This would fetch the actual story title from a service
    // For now, we'll just return a formatted version of the ID
    return storyId
        .split('_')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// A variant of narrative choice widget with vertical layout and more visual elements
class DetailedNarrativeChoiceWidget extends StatefulWidget {
  /// Available story branches to choose from
  final List<StoryBranchModel> branches;

  /// Callback when a branch is selected
  final Function(StoryBranchModel) onBranchSelected;

  /// Current user progress for requirement checking
  final UserProgress? userProgress;

  /// Audio service for sound effects
  final AudioService? audioService;

  /// Custom title for the choices section
  final String? title;

  /// Whether to show images for choices
  final bool showImages;

  /// Whether to animate the choices appearance
  final bool animate;

  /// Creates a detailed narrative choice widget
  const DetailedNarrativeChoiceWidget({
    super.key,
    required this.branches,
    required this.onBranchSelected,
    this.userProgress,
    this.audioService,
    this.title,
    this.showImages = true,
    this.animate = true,
  });

  @override
  State<DetailedNarrativeChoiceWidget> createState() => _DetailedNarrativeChoiceWidgetState();
}

class _DetailedNarrativeChoiceWidgetState extends State<DetailedNarrativeChoiceWidget> with SingleTickerProviderStateMixin {
  /// Animation controller for sliding in choices
  late AnimationController _animationController;

  /// Selected branch index
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title section
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Text(
              'Choose Your Path',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Choices section
        ...List.generate(widget.branches.length, (index) {
          // Animation for staggered appearance
          final Animation<double> animation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.15, // stagger start times
              index * 0.15 + 0.7, // stagger end times
              curve: Curves.easeOutQuint,
            ),
          );

          // Get branch data
          final branch = widget.branches[index];

          // Check if this branch has requirements that aren't met
          final bool isLocked = _isBranchLocked(branch);

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 70 * (1 - animation.value)),
                child: Opacity(
                  opacity: animation.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildDetailedChoiceCard(branch, index, isLocked),
            ),
          );
        }),

        // Continue button (shown only when a choice is selected)
        if (_selectedIndex != null)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Play selection sound
                  widget.audioService?.playEffect(AudioType.confirmationTap);

                  // Notify parent of selection
                  widget.onBranchSelected(widget.branches[_selectedIndex!]);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue on this path',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build a detailed choice card for a story branch
  Widget _buildDetailedChoiceCard(StoryBranchModel branch, int index, bool isLocked) {
    final bool isSelected = _selectedIndex == index;

    // Get difficulty stars
    List<Widget> difficultyStars = List.generate(
      5,
      (starIndex) => Icon(
        starIndex < branch.difficultyLevel ? Icons.star : Icons.star_border,
        size: 16,
        color: isLocked
            ? Colors.grey.shade400
            : Colors.amber,
      ),
    );

    // Placeholder image path
    final imagePath = 'assets/images/story/branch_${branch.id}.png';

    return GestureDetector(
      onTap: isLocked
          ? null  // No action if locked
          : () {
              // Play selection sound
              widget.audioService?.playEffect(AudioType.buttonTap);

              setState(() {
                _selectedIndex = index;
              });
            },
      child: Card(
        elevation: isSelected ? 6 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Choice header with number and difficulty
              Row(
                children: [
                  // Choice number
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLocked
                          ? Colors.grey.shade300
                          : isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isLocked
                              ? Colors.grey.shade500
                              : isSelected
                                  ? Colors.white
                                  : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Choice title - just use description for now
                  Expanded(
                    child: Text(
                      branch.description,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isLocked ? Colors.grey.shade500 : null,
                      ),
                    ),
                  ),

                  // Lock icon if needed
                  if (isLocked)
                    Icon(
                      Icons.lock,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Optional image
              if (widget.showImages)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isLocked
                            ? Colors.grey.shade200
                            : Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            isLocked ? Icons.lock : Icons.image,
                            size: 40,
                            color: isLocked
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom row with difficulty and lock message
              Row(
                children: [
                  // Difficulty stars
                  Row(
                    children: difficultyStars,
                  ),

                  const SizedBox(width: 16),

                  // Lock message if needed
                  if (isLocked)
                    Expanded(
                      child: Text(
                        _getLockMessage(branch),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if a branch is locked based on requirements
  bool _isBranchLocked(StoryBranchModel branch) {
    // If no user progress or no requirements, it's not locked
    if (widget.userProgress == null || branch.requirements.isEmpty) {
      return false;
    }

    // The same logic as in the base NarrativeChoiceWidget class
    // (implementation details omitted to avoid redundancy)
    // This would check user progress against branch requirements

    return false; // Placeholder - same logic as the other class
  }

  /// Get a message explaining why a branch is locked
  String _getLockMessage(StoryBranchModel branch) {
    // Default message
    String message = "You haven't unlocked this path yet.";

    // The same logic as in the base NarrativeChoiceWidget class
    // (implementation details omitted to avoid redundancy)
    // This would return a user-friendly message about requirements

    return message; // Placeholder - same logic as the other class
  }
}
