import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/learning/models/learning_path_type.dart';
import 'package:kente_codeweaver/features/learning/models/user_progress.dart';
import 'package:kente_codeweaver/features/learning/providers/adaptive_learning_provider.dart';
import 'package:kente_codeweaver/features/learning/widgets/analytics_chart.dart';
import 'package:kente_codeweaver/features/learning/widgets/concept_mastery_heatmap.dart';
import 'package:kente_codeweaver/features/learning/widgets/learning_metrics_card.dart';
import 'package:kente_codeweaver/features/learning/widgets/user_engagement_timeline.dart';

/// A dashboard for monitoring and analyzing learning performance
class LearningAnalyticsDashboard extends StatefulWidget {
  /// The user ID
  final String userId;

  /// Whether this is an admin view (shows more detailed analytics)
  final bool isAdminView;

  /// Create a learning analytics dashboard
  const LearningAnalyticsDashboard({
    super.key,
    required this.userId,
    this.isAdminView = false,
  });

  @override
  State<LearningAnalyticsDashboard> createState() => _LearningAnalyticsDashboardState();
}

class _LearningAnalyticsDashboardState extends State<LearningAnalyticsDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  UserProgress? _userProgress;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AdaptiveLearningProvider>(context, listen: false);
    await provider.initialize(widget.userId);

    setState(() {
      _userProgress = provider.userProgress;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminView ? 'Learning Analytics Dashboard' : 'Your Learning Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Concepts'),
            Tab(text: 'Engagement'),
            Tab(text: 'Recommendations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildConceptsTab(),
                _buildEngagementTab(),
                _buildRecommendationsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_userProgress == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Progress Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Summary metrics
          Row(
            children: [
              Expanded(
                child: LearningMetricsCard(
                  title: 'Concepts Mastered',
                  value: _userProgress!.masteredConceptsCount.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LearningMetricsCard(
                  title: 'Challenges Completed',
                  value: _userProgress!.completedChallengesCount.toString(),
                  icon: Icons.assignment_turned_in,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LearningMetricsCard(
                  title: 'Current Streak',
                  value: '${_userProgress!.streak} days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Level progress
          Text(
            'Level ${_userProgress!.level} Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _userProgress!.levelProgressPercentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 10,
          ),
          const SizedBox(height: 4),
          Text(
            '${_userProgress!.experiencePoints} XP / ${_userProgress!.experienceForNextLevel} XP needed for Level ${_userProgress!.level + 1}',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 24),

          // Learning style
          Text(
            'Learning Style',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your preferred learning style is ${_userProgress!.preferredLearningStyle.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_userProgress!.preferredLearningStyle.description),
                  const SizedBox(height: 16),
                  if (widget.isAdminView) ...[
                    const Text('Learning Style Confidence Scores:'),
                    const SizedBox(height: 8),
                    AnalyticsChart(
                      data: _getLearningStyleData(),
                      height: 200,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Engagement score
          Text(
            'Engagement Score',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(_userProgress!.calculateEngagementScore() * 100).round()}%',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const Text('Overall Engagement'),
                          ],
                        ),
                      ),
                      if (widget.isAdminView)
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to detailed engagement analytics
                          },
                          child: const Text('View Details'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptsTab() {
    if (_userProgress == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Concept Mastery',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Concept mastery heatmap
          const Text('Mastery Heatmap'),
          const SizedBox(height: 8),
          ConceptMasteryHeatmap(
            userId: widget.userId,
            skillProficiency: _userProgress!.skillProficiency,
          ),

          const SizedBox(height: 24),

          // Mastered concepts
          Text(
            'Mastered Concepts (${_userProgress!.conceptsMastered.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildConceptList(_userProgress!.conceptsMastered, true),

          const SizedBox(height: 24),

          // In-progress concepts
          Text(
            'Concepts In Progress (${_userProgress!.conceptsInProgress.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildConceptList(_userProgress!.conceptsInProgress, false),

          if (widget.isAdminView) ...[
            const SizedBox(height: 24),

            // Learning rate
            Text(
              'Learning Rate Analysis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Concepts mastered over time:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChart(
                      data: _getLearningRateData(),
                      height: 200,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementTab() {
    if (_userProgress == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Metrics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Session history
          Text(
            'Session History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          UserEngagementTimeline(
            sessionHistory: _userProgress!.sessionHistory,
          ),

          const SizedBox(height: 24),

          // Challenge completion rate
          Text(
            'Challenge Completion Rate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_userProgress!.completedChallengesCount} / ${_userProgress!.totalChallengeAttempts}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const Text('Challenges Completed'),
                          ],
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue[50],
                        ),
                        child: Center(
                          child: Text(
                            '${(_getCompletionRate() * 100).round()}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (widget.isAdminView) ...[
            const SizedBox(height: 24),

            // Frustration indicators
            Text(
              'Frustration Analysis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frustration indicators over time:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChart(
                      data: _getFrustrationData(),
                      height: 200,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_userProgress == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalized Recommendations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Recommended learning path
          Text(
            'Recommended Learning Path',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Consumer<AdaptiveLearningProvider>(
            builder: (context, provider, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getPathIcon(provider.learningPathType),
                            size: 32,
                            color: _getPathColor(provider.learningPathType),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.learningPathType.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(provider.learningPathType.description),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'This path is recommended based on your learning style, performance, and engagement patterns.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Switch to this learning path
                          provider.changeLearningPathType(provider.learningPathType);
                        },
                        child: const Text('Follow This Path'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Next concepts to focus on
          Text(
            'Recommended Next Steps',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: Provider.of<AdaptiveLearningProvider>(context, listen: false)
                .recommendNextConcepts(count: 3),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No recommendations available at this time.'),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.map((conceptId) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.lightbulb, color: Colors.amber),
                      title: Text(_getConceptName(conceptId)),
                      subtitle: Text('Recommended next concept to learn'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // Navigate to a challenge for this concept
                        },
                        child: const Text('Start'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          if (widget.isAdminView) ...[
            const SizedBox(height: 24),

            // Parameter tuning
            Text(
              'Adaptive Parameters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adjust adaptive learning parameters:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildParameterSlider(
                      'Difficulty Adjustment Rate',
                      0.5,
                      (value) {
                        // Update parameter
                      },
                    ),
                    _buildParameterSlider(
                      'Frustration Sensitivity',
                      0.7,
                      (value) {
                        // Update parameter
                      },
                    ),
                    _buildParameterSlider(
                      'Learning Path Switching Threshold',
                      0.3,
                      (value) {
                        // Update parameter
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Save parameters
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Parameters saved')),
                        );
                      },
                      child: const Text('Save Parameters'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConceptList(List<String> concepts, bool isMastered) {
    if (concepts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No concepts in this category yet.'),
        ),
      );
    }

    return Column(
      children: concepts.map((conceptId) {
        final proficiency = _userProgress!.skillProficiency[conceptId] ?? 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isMastered ? Colors.green : Colors.blue,
              child: Icon(
                isMastered ? Icons.check : Icons.trending_up,
                color: Colors.white,
              ),
            ),
            title: Text(_getConceptName(conceptId)),
            subtitle: LinearProgressIndicator(
              value: proficiency,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isMastered ? Colors.green : Colors.blue,
              ),
            ),
            trailing: Text(
              '${(proficiency * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMastered ? Colors.green : Colors.blue,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParameterSlider(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: onChanged,
              ),
            ),
            Text('${(value * 100).round()}%'),
          ],
        ),
      ],
    );
  }

  String _getConceptName(String conceptId) {
    // In a real app, this would come from a service or database
    final conceptNames = {
      'loops': 'Loops',
      'conditionals': 'Conditionals',
      'variables': 'Variables',
      'functions': 'Functions',
      'arrays': 'Arrays',
      'objects': 'Objects',
      'classes': 'Classes',
      'inheritance': 'Inheritance',
      'recursion': 'Recursion',
      'algorithms': 'Algorithms',
      'data_structures': 'Data Structures',
      'pattern_design': 'Pattern Design',
      'sequence': 'Sequences',
      'logic': 'Logic',
      'debugging': 'Debugging',
    };

    return conceptNames[conceptId] ?? 'Unknown Concept';
  }

  IconData _getPathIcon(LearningPathType pathType) {
    return switch (pathType) {
      LearningPathType.logicBased => Icons.psychology,
      LearningPathType.creativityBased => Icons.palette,
      LearningPathType.challengeBased => Icons.fitness_center,
      LearningPathType.balanced => Icons.balance,
    };
  }

  Color _getPathColor(LearningPathType pathType) {
    return switch (pathType) {
      LearningPathType.logicBased => Colors.blue,
      LearningPathType.creativityBased => Colors.purple,
      LearningPathType.challengeBased => Colors.orange,
      LearningPathType.balanced => Colors.green,
    };
  }

  double _getCompletionRate() {
    if (_userProgress!.totalChallengeAttempts == 0) {
      return 0.0;
    }
    return _userProgress!.completedChallengesCount / _userProgress!.totalChallengeAttempts;
  }

  List<Map<String, dynamic>> _getLearningStyleData() {
    // In a real app, this would come from actual data
    return [
      {'name': 'Visual', 'value': 0.8},
      {'name': 'Logical', 'value': 0.6},
      {'name': 'Practical', 'value': 0.4},
      {'name': 'Verbal', 'value': 0.3},
      {'name': 'Social', 'value': 0.2},
      {'name': 'Reflective', 'value': 0.5},
    ];
  }

  List<Map<String, dynamic>> _getLearningRateData() {
    // In a real app, this would come from actual data
    return [
      {'date': 'Week 1', 'concepts': 2},
      {'date': 'Week 2', 'concepts': 3},
      {'date': 'Week 3', 'concepts': 5},
      {'date': 'Week 4', 'concepts': 6},
      {'date': 'Week 5', 'concepts': 9},
      {'date': 'Week 6', 'concepts': 10},
    ];
  }

  List<Map<String, dynamic>> _getFrustrationData() {
    // In a real app, this would come from actual data
    return [
      {'date': 'Day 1', 'level': 0.2},
      {'date': 'Day 2', 'level': 0.3},
      {'date': 'Day 3', 'level': 0.5},
      {'date': 'Day 4', 'level': 0.4},
      {'date': 'Day 5', 'level': 0.2},
      {'date': 'Day 6', 'level': 0.1},
      {'date': 'Day 7', 'level': 0.3},
    ];
  }
}
