import 'package:flutter/material.dart';

/// A widget that displays a timeline of user engagement
class UserEngagementTimeline extends StatelessWidget {
  /// The session history data
  final List<Map<String, dynamic>> sessionHistory;

  /// Create a user engagement timeline
  const UserEngagementTimeline({
    super.key,
    required this.sessionHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No session history available yet.'),
        ),
      );
    }

    // Sort sessions by date (most recent first)
    final sortedSessions = List<Map<String, dynamic>>.from(sessionHistory)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['timestamp'] as String);
        final dateB = DateTime.parse(b['timestamp'] as String);
        return dateB.compareTo(dateA);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedSessions.length.clamp(0, 5), // Show at most 5 sessions
              itemBuilder: (context, index) {
                final session = sortedSessions[index];
                return _buildSessionItem(context, session);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, Map<String, dynamic> session) {
    final timestamp = DateTime.parse(session['timestamp'] as String);
    final duration = session['duration'] as int? ?? 0;
    final challengesCompleted = session['challengesCompleted'] as int? ?? 0;
    final engagementScore = session['engagementScore'] as double? ?? 0.0;

    // Get the index of this session in the list
    final sessionIndex = sessionHistory.indexOf(session);
    final isLastSession = sessionIndex == sessionHistory.length - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getEngagementColor(engagementScore),
                ),
              ),
              // Show connecting line for all but the last item
              if (!isLastSession)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Session details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(timestamp),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${_formatDuration(duration)} • Challenges: $challengesCompleted',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: engagementScore,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getEngagementColor(engagementScore),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Engagement: ${(engagementScore * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Format time as HH:MM AM/PM
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $period';

    if (difference.inDays == 0) {
      return 'Today, $timeString';
    } else if (difference.inDays == 1) {
      return 'Yesterday, $timeString';
    } else if (difference.inDays < 7) {
      // Get day name
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = dayNames[date.weekday - 1]; // weekday is 1-7 where 1 is Monday
      return '$dayName, $timeString';
    } else {
      // Format as MMM DD, YYYY
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = monthNames[date.month - 1];
      final day = date.day;
      final year = date.year;
      return '$month $day, $year';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 1) {
      return '$seconds seconds';
    } else if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours hours, $remainingMinutes minutes';
    }
  }
}
