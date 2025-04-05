import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kente_codeweaver/features/storytelling/providers/story_provider.dart';
import 'package:kente_codeweaver/features/learning/providers/learning_provider.dart';
import 'package:kente_codeweaver/core/navigation/app_router.dart';

/// Home screen of the application
class HomeScreen extends StatefulWidget {
  /// Constructor
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Story provider
  late StoryProvider _storyProvider;

  /// Learning provider
  late LearningProvider _learningProvider;

  /// Selected tab index
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _storyProvider = Provider.of<StoryProvider>(context, listen: false);
    _learningProvider = Provider.of<LearningProvider>(context, listen: false);

    _initializeProviders();
  }

  /// Initialize providers
  Future<void> _initializeProviders() async {
    await _storyProvider.initialize();
    await _learningProvider.initialize('current_user');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kente Codeweaver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.settings);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.code),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Build the body based on the selected tab
  Widget _buildBody() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildStoriesTab();
      case 1:
        return _buildChallengesTab();
      case 2:
        return _buildProfileTab();
      default:
        return const Center(
          child: Text('Unknown tab'),
        );
    }
  }

  /// Build the stories tab
  Widget _buildStoriesTab() {
    return Consumer<StoryProvider>(
      builder: (context, storyProvider, _) {
        // Check if provider is initialized
        if (storyProvider.stories.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final stories = storyProvider.stories;

        if (stories.isEmpty) {
          return const Center(
            child: Text('No stories available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.story,
                    arguments: {'storyId': story.id},
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: 0.5, // Default progress value
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: 50%', // Default progress percentage
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build the challenges tab
  Widget _buildChallengesTab() {
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, _) {
        if (!learningProvider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final challenges = learningProvider.challenges;

        if (challenges.isEmpty) {
          return const Center(
            child: Text('No challenges available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final isCompleted = learningProvider.isChallengeCompleted(challenge['id']);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.challenge,
                    arguments: {'challengeId': challenge['id']},
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.circle_outlined,
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge['title'],
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              challenge['description'],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Difficulty: ${challenge['difficulty']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build the profile tab
  Widget _buildProfileTab() {
    return Consumer<LearningProvider>(
      builder: (context, learningProvider, _) {
        if (!learningProvider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final completedChallenges = learningProvider.completedChallengesCount;
        final totalChallenges = learningProvider.challenges.length;
        final progress = totalChallenges > 0 ? completedChallenges / totalChallenges : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenges Completed',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedChallenges / $totalChallenges',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Skills',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSkillRow('Logic', 0.7),
                      const SizedBox(height: 16),
                      _buildSkillRow('Loops', 0.5),
                      const SizedBox(height: 16),
                      _buildSkillRow('Conditions', 0.6),
                      const SizedBox(height: 16),
                      _buildSkillRow('Variables', 0.4),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAchievementRow('First Challenge', true),
                      const SizedBox(height: 16),
                      _buildAchievementRow('5 Challenges Completed', completedChallenges >= 5),
                      const SizedBox(height: 16),
                      _buildAchievementRow('All Challenges Completed', completedChallenges == totalChallenges),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a skill row
  Widget _buildSkillRow(String skillName, double progress) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(skillName),
        ),
        Expanded(
          flex: 5,
          child: LinearProgressIndicator(
            value: progress,
          ),
        ),
        const SizedBox(width: 8),
        Text('${(progress * 100).toInt()}%'),
      ],
    );
  }

  /// Build an achievement row
  Widget _buildAchievementRow(String achievementName, bool isUnlocked) {
    return Row(
      children: [
        Icon(
          isUnlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
          color: isUnlocked ? Colors.amber : Colors.grey,
        ),
        const SizedBox(width: 16),
        Text(
          achievementName,
          style: TextStyle(
            color: isUnlocked ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }
}
