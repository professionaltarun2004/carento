import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ChatAnalyticsScreen extends StatefulWidget {
  const ChatAnalyticsScreen({super.key});

  @override
  State<ChatAnalyticsScreen> createState() => _ChatAnalyticsScreenState();
}

class _ChatAnalyticsScreenState extends State<ChatAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {
    'totalChats': 0,
    'totalMessages': 0,
    'averageResponseTime': 0,
    'messagesByHour': List.filled(24, 0),
    'messagesByDay': List.filled(7, 0),
    'commonTopics': [],
  };

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get all chat sessions
      final chatSessions = await FirebaseFirestore.instance
          .collection('chat_sessions')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Get all messages
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Calculate analytics
      final now = DateTime.now();
      final messagesByHour = List.filled(24, 0);
      final messagesByDay = List.filled(7, 0);
      final responseTimes = <int>[];
      final topics = <String, int>{};

      for (final doc in messages.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        
        // Messages by hour
        messagesByHour[timestamp.hour]++;
        
        // Messages by day
        final dayDiff = now.difference(timestamp).inDays;
        if (dayDiff < 7) {
          messagesByDay[dayDiff]++;
        }

        // Response time
        if (!data['isUser']) {
          final userMessage = messages.docs
              .where((d) => d.data()['chatId'] == data['chatId'] && d.data()['isUser'])
              .lastOrNull;
          if (userMessage != null) {
            final userTimestamp = (userMessage.data()['timestamp'] as Timestamp).toDate();
            responseTimes.add(timestamp.difference(userTimestamp).inSeconds);
          }
        }

        // Common topics
        if (data['isUser']) {
          final words = data['message'].toString().toLowerCase().split(' ');
          for (final word in words) {
            if (word.length > 3) {
              topics[word] = (topics[word] ?? 0) + 1;
            }
          }
        }
      }

      setState(() {
        _analytics = {
          'totalChats': chatSessions.docs.length,
          'totalMessages': messages.docs.length,
          'averageResponseTime': responseTimes.isEmpty
              ? 0
              : responseTimes.reduce((a, b) => a + b) ~/ responseTimes.length,
          'messagesByHour': messagesByHour,
          'messagesByDay': messagesByDay,
          'commonTopics': (() {
            final sortedEntries = topics.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            return sortedEntries
                .take(5)
                .map((e) => {'word': e.key, 'count': e.value})
                .toList();
          })(),
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildMessagesByHourChart(),
            const SizedBox(height: 24),
            _buildMessagesByDayChart(),
            const SizedBox(height: 24),
            _buildCommonTopicsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Total Chats',
          _analytics['totalChats'].toString(),
          Icons.chat_bubble_outline,
        ),
        _buildSummaryCard(
          'Total Messages',
          _analytics['totalMessages'].toString(),
          Icons.message_outlined,
        ),
        _buildSummaryCard(
          'Avg Response Time',
          '${(_analytics['averageResponseTime'] / 60).toStringAsFixed(1)} min',
          Icons.timer_outlined,
        ),
        _buildSummaryCard(
          'Active Days',
          _analytics['messagesByDay'].where((count) => count > 0).length.toString(),
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesByHourChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages by Hour',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _analytics['messagesByHour'].reduce((a, b) => a > b ? a : b).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    24,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _analytics['messagesByHour'][index].toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesByDayChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages by Day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(enabled: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        7,
                        (index) => FlSpot(
                          index.toDouble(),
                          _analytics['messagesByDay'][index].toDouble(),
                        ),
                      ),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonTopicsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Topics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._analytics['commonTopics'].map<Widget>((topic) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic['word'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topic['count'].toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 