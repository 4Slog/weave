import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/providers/adaptive_learning_provider.dart';
import 'package:kente_codeweaver/features/learning/widgets/learning_path_selector.dart';
import 'package:kente_codeweaver/features/learning/widgets/concept_mastery_card.dart';
import 'package:kente_codeweaver/features/learning/widgets/learning_path_progress.dart';
import 'package:kente_codeweaver/features/learning/widgets/adaptive_difficulty_indicator.dart';

/// A dashboard that displays the user's adaptive learning progress
class AdaptiveLearningDashboard extends StatefulWidget {
  /// The user ID
  final String userId;
  
  /// Create an adaptive learning dashboard
  const AdaptiveLearningDashboard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AdaptiveLearningDashboard> createState() => _AdaptiveLearningDashboardState();
}

class _AdaptiveLearningDashboardState extends State<AdaptiveLearningDashboard> {
  bool _isLoading = true;
  List<String> _recommendedConcepts = [];
  
  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }
  
  Future<void> _initializeProvider() async {
    final provider = Provider.of<AdaptiveLearningProvider>(context, listen: false);
    await provider.initialize(widget.userId);
    
    // Get recommended concepts
    _recommendedConcepts = await provider.recommendNextConcepts();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Consumer<AdaptiveLearningProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Learning path selector
                  LearningPathSelector(
                    selectedPathType: provider.learningPathType,
                    onPathSelected: (pathType) {
                      provider.changeLearningPathType(pathType);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Current session status
                  if (provider.currentSession != null)
                    _buildSessionStatus(provider),
                  
                  const SizedBox(height: 16),
                  
                  // Learning path progress
                  if (provider.currentPath != null)
                    LearningPathProgress(
                      learningPath: provider.currentPath!,
                      userProgress: provider.userProgress,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Recommended concepts
                  _buildRecommendedConcepts(),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  _buildActionButtons(provider),
                ],
              );
            },
          );
  }
  
  Widget _buildSessionStatus(AdaptiveLearningProvider provider) {
    final session = provider.currentSession!;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Learning Session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusItem(
                  'Challenges',
                  '${session.challengesCompleted}/${session.challengesAttempted}',
                  Icons.assignment_turned_in,
                ),
                _buildStatusItem(
                  'Time',
                  '${session.timeSpentMinutes} min',
                  Icons.timer,
                ),
                AdaptiveDifficultyIndicator(
                  difficultyLevel: provider.difficultyLevel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: session.engagementScore,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getEngagementColor(session.engagementScore),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Engagement: ${(session.engagementScore * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            
            // Show adaptive messages based on user state
            if (provider.isUserStruggling)
              _buildAdaptiveMessage(
                'You seem to be finding this challenging. Would you like some help?',
                Colors.orange[100]!,
                Icons.help_outline,
              ),
            if (provider.isUserExcelling)
              _buildAdaptiveMessage(
                'Great work! You\'re mastering these concepts quickly!',
                Colors.green[100]!,
                Icons.star,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
  
  Widget _buildAdaptiveMessage(String message, Color backgroundColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendedConcepts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Next Concepts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedConcepts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ConceptMasteryCard(
                  conceptId: _recommendedConcepts[index],
                  userId: widget.userId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(AdaptiveLearningProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Session'),
          onPressed: provider.currentSession?.isActive ?? false
              ? null
              : () => provider.startSession(),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text('End Session'),
          onPressed: provider.currentSession?.isActive ?? false
              ? () => provider.endSession()
              : null,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          onPressed: () async {
            setState(() {
              _isLoading = true;
            });
            await _initializeProvider();
          },
        ),
      ],
    );
  }
  
  Color _getEngagementColor(double engagement) {
    if (engagement > 0.7) {
      return Colors.green;
    } else if (engagement > 0.4) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }
}
