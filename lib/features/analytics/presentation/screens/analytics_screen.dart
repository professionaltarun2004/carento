import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:carento/core/constants/app_constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedTimeRange = 'Last 7 Days';
  final List<String> _timeRanges = ['Last 7 Days', 'Last 30 Days', 'Last 3 Months', 'Last Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          DropdownButton<String>(
            value: _selectedTimeRange,
            items: _timeRanges.map((range) {
              return DropdownMenuItem(
                value: range,
                child: Text(range),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedTimeRange = value);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildBookingTrendsChart(),
            const SizedBox(height: 24),
            _buildRevenueChart(),
            const SizedBox(height: 24),
            _buildPopularCarsChart(),
            const SizedBox(height: 24),
            _buildCancellationStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        final now = DateTime.now();
        final startDate = _getStartDate();

        // Filter bookings based on selected time range
        final filteredBookings = bookings.where((doc) {
          final bookingDate = (doc.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
          return bookingDate.toDate().isAfter(startDate);
        }).toList();

        // Calculate statistics
        final totalBookings = filteredBookings.length;
        final totalRevenue = filteredBookings.fold<double>(
          0,
          (sum, doc) => sum + ((doc.data() as Map<String, dynamic>)['totalAmount'] ?? 0.0),
        );
        final completedBookings = filteredBookings.where((doc) {
          return (doc.data() as Map<String, dynamic>)['status'] == AppConstants.bookingCompleted;
        }).length;
        final cancelledBookings = filteredBookings.where((doc) {
          return (doc.data() as Map<String, dynamic>)['status'] == AppConstants.bookingCancelled;
        }).length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard(
              'Total Bookings',
              totalBookings.toString(),
              Icons.calendar_today,
              Colors.blue,
            ),
            _buildSummaryCard(
              'Total Revenue',
              '₹${totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildSummaryCard(
              'Completed',
              completedBookings.toString(),
              Icons.check_circle,
              Colors.teal,
            ),
            _buildSummaryCard(
              'Cancelled',
              cancelledBookings.toString(),
              Icons.cancel,
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTrendsChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        final startDate = _getStartDate();
        final days = _getDaysInRange();

        // Prepare data for the chart
        final Map<DateTime, int> bookingsByDay = {};
        for (var i = 0; i < days; i++) {
          final date = startDate.add(Duration(days: i));
          bookingsByDay[date] = 0;
        }

        for (var doc in bookings) {
          final bookingDate = (doc.data() as Map<String, dynamic>)['createdAt'] as Timestamp;
          final date = bookingDate.toDate();
          if (date.isAfter(startDate)) {
            final day = DateTime(date.year, date.month, date.day);
            bookingsByDay[day] = (bookingsByDay[day] ?? 0) + 1;
          }
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= days) return const Text('');
                              final date = startDate.add(Duration(days: value.toInt()));
                              return Text(
                                DateFormat('dd/MM').format(date),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: bookingsByDay.entries.map((entry) {
                            final days = entry.key.difference(startDate).inDays;
                            return FlSpot(days.toDouble(), entry.value.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
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
      },
    );
  }

  Widget _buildRevenueChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        final startDate = _getStartDate();
        final days = _getDaysInRange();

        // Prepare data for the chart
        final Map<DateTime, double> revenueByDay = {};
        for (var i = 0; i < days; i++) {
          final date = startDate.add(Duration(days: i));
          revenueByDay[date] = 0;
        }

        for (var doc in bookings) {
          final data = doc.data() as Map<String, dynamic>;
          final bookingDate = data['createdAt'] as Timestamp;
          final date = bookingDate.toDate();
          if (date.isAfter(startDate)) {
            final day = DateTime(date.year, date.month, date.day);
            revenueByDay[day] = (revenueByDay[day] ?? 0) + (data['totalAmount'] ?? 0.0);
          }
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₹${value.toInt()}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= days) return const Text('');
                              final date = startDate.add(Duration(days: value.toInt()));
                              return Text(
                                DateFormat('dd/MM').format(date),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: revenueByDay.entries.map((entry) {
                        final days = entry.key.difference(startDate).inDays;
                        return BarChartGroupData(
                          x: days,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              color: Colors.green,
                              width: 8,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularCarsChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        final startDate = _getStartDate();

        // Count bookings per car
        final Map<String, int> carBookings = {};
        for (var doc in bookings) {
          final data = doc.data() as Map<String, dynamic>;
          final bookingDate = data['createdAt'] as Timestamp;
          if (bookingDate.toDate().isAfter(startDate)) {
            final carName = data['carName'] as String;
            carBookings[carName] = (carBookings[carName] ?? 0) + 1;
          }
        }

        // Sort cars by number of bookings
        final sortedCars = carBookings.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Take top 5 cars
        final topCars = sortedCars.take(5).toList();

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Cars',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: topCars.map((entry) {
                        final color = _getRandomColor(entry.key);
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '${entry.key}\n${entry.value}',
                          color: color,
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCancellationStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        final startDate = _getStartDate();

        // Calculate cancellation statistics
        int totalBookings = 0;
        int cancelledBookings = 0;
        double totalCancellationFees = 0;

        for (var doc in bookings) {
          final data = doc.data() as Map<String, dynamic>;
          final bookingDate = data['createdAt'] as Timestamp;
          if (bookingDate.toDate().isAfter(startDate)) {
            totalBookings++;
            if (data['status'] == AppConstants.bookingCancelled) {
              cancelledBookings++;
              totalCancellationFees += (data['cancellationFee'] ?? 0.0);
            }
          }
        }

        final cancellationRate = totalBookings > 0
            ? (cancelledBookings / totalBookings * 100).toStringAsFixed(1)
            : '0.0';

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancellation Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Cancellation Rate',
                      '$cancellationRate%',
                      Icons.trending_down,
                      Colors.red,
                    ),
                    _buildStatItem(
                      'Total Cancellations',
                      cancelledBookings.toString(),
                      Icons.cancel,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Cancellation Fees',
                      '₹${totalCancellationFees.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'Last 3 Months':
        return now.subtract(const Duration(days: 90));
      case 'Last Year':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  int _getDaysInRange() {
    switch (_selectedTimeRange) {
      case 'Last 7 Days':
        return 7;
      case 'Last 30 Days':
        return 30;
      case 'Last 3 Months':
        return 90;
      case 'Last Year':
        return 365;
      default:
        return 7;
    }
  }

  Color _getRandomColor(String seed) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }
} 