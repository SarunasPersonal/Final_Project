// lib/admin/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logging/logging.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalBookings = 0;
  int _totalUsers = 0;
  int _todayBookings = 0;
  bool _isLoading = true;
  final BookingService _bookingService = BookingService();

  // Data for charts
  List<FlSpot> _weeklyBookingSpots = [];
  List<PieChartSectionData> _roomTypeSections = [];
  Map<String, int> _bookingsByLocation = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get all bookings
      final allBookings = _bookingService.getAllBookings();
      final _logger = Logger('DashboardScreen');

      // Get today's bookings
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayBookings = allBookings
          .where((booking) =>
              booking.dateTime.year == today.year &&
              booking.dateTime.month == today.month &&
              booking.dateTime.day == today.day)
          .toList();

      // Process data for weekly bookings chart
      _weeklyBookingSpots = _generateWeeklyBookingData(allBookings);

      // Process data for room type pie chart
      _roomTypeSections = _generateRoomTypeData(allBookings);

      // Process data for bookings by location
      _bookingsByLocation = _generateLocationData(allBookings);

      // Mock user count - in a real app, fetch from Firebase
      int userCount = 0;
      try {
        final userSnapshot =
            await FirebaseFirestore.instance.collection('users').get();
        userCount = userSnapshot.docs.length;
      } catch (e) {
        // Fallback if Firestore connection fails
        userCount = 25; // Mock value
      }

      if (mounted) {
        setState(() {
          _totalBookings = allBookings.length;
          _totalUsers = userCount;
          _todayBookings = todayBookings.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.warning('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Generate weekly booking data for charts
  List<FlSpot> _generateWeeklyBookingData(List<Booking> bookings) {
    // Map to store count of bookings by day of week (0 = Monday, 6 = Sunday)
    final Map<int, int> bookingsByDay = {
      0: 0,
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0
    };

    // Get the current date
    final now = DateTime.now();

    // Calculate the date for Monday of the current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    // Count bookings for each day of the current week
    for (var booking in bookings) {
      // Skip bookings from previous weeks
      if (booking.dateTime.isBefore(monday)) continue;

      // Skip bookings from next weeks
      if (booking.dateTime.isAfter(monday.add(const Duration(days: 7))))
        continue;

      // Get day of week (0 = Monday, 6 = Sunday)
      final dayOfWeek = booking.dateTime.weekday - 1;

      // Increment count for this day
      bookingsByDay[dayOfWeek] = (bookingsByDay[dayOfWeek] ?? 0) + 1;
    }

    // Convert to list of FlSpot for chart
    return bookingsByDay.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.toDouble()))
        .toList();
  }

  // Generate room type data for pie chart
  List<PieChartSectionData> _generateRoomTypeData(List<Booking> bookings) {
    // Count bookings by room type
    final Map<RoomType, int> bookingsByType = {};

    for (var booking in bookings) {
      bookingsByType[booking.roomType] =
          (bookingsByType[booking.roomType] ?? 0) + 1;
    }

    // Define colors for each room type
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.amber,
    ];

    // Convert to list of PieChartSectionData
    List<PieChartSectionData> sections = [];
    int i = 0;

    bookingsByType.forEach((type, count) {
      final double percentage = count / bookings.length;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: count.toDouble(),
          title: '${(percentage * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  // Generate location data for bar chart
  Map<String, int> _generateLocationData(List<Booking> bookings) {
    // Count bookings by location
    final Map<String, int> bookingsByLocation = {};

    for (var booking in bookings) {
      bookingsByLocation[booking.location] =
          (bookingsByLocation[booking.location] ?? 0) + 1;
    }

    return bookingsByLocation;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColor));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),

            // Stats cards row
            _buildStatsRow(context),

            const SizedBox(height: 32),

            // Charts section
            _buildChartsSection(context),

            const SizedBox(height: 32),

            // Recent bookings table
            Text(
              'Recent Bookings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRecentBookingsTable(),
          ],
        ),
      ),
    );
  }

  // Build the stats cards row
  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          context,
          'Total Bookings',
          _totalBookings.toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context,
          'Total Users',
          _totalUsers.toString(),
          Icons.people,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context,
          'Today\'s Bookings',
          _todayBookings.toString(),
          Icons.today,
          primaryColor,
        ),
      ],
    );
  }

  // Build a single stat card
  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the charts section
  Widget _buildChartsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Weekly bookings chart
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Bookings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildWeeklyBookingsChart(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Room type and location distribution charts
        Row(
          children: [
            // Room type pie chart
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room Types',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildRoomTypePieChart(),
                      ),
                      const SizedBox(height: 8),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(Colors.blue, 'Quiet Room'),
                          const SizedBox(width: 12),
                          _buildLegendItem(Colors.green, 'Conference Room'),
                          const SizedBox(width: 12),
                          _buildLegendItem(Colors.amber, 'Study Room'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Location distribution chart
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Locations',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildLocationBarChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build the weekly bookings line chart
  Widget _buildWeeklyBookingsChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(value.toInt().toString()),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value >= 0 && value < days.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(days[value.toInt()]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: _weeklyBookingSpots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: true,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withAlpha(
                  25), // Lighten the color for the area below the line,
            ),
          ),
        ],
      ),
    );
  }

  // Build the room type pie chart
  Widget _buildRoomTypePieChart() {
    return PieChart(
      PieChartData(
        sections: _roomTypeSections,
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
      ),
    );
  }

  // Build a legend item for the pie chart
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // Build the location bar chart
  Widget _buildLocationBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _bookingsByLocation.values.isEmpty
            ? 10
            : _bookingsByLocation.values
                    .reduce((a, b) => a > b ? a : b)
                    .toDouble() *
                1.2,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(value.toInt().toString()),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final locations = _bookingsByLocation.keys.toList();
                if (value >= 0 && value < locations.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      locations[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        barGroups: _getLocationBarGroups(),
      ),
    );
  }

  // Get bar groups for the location chart
  List<BarChartGroupData> _getLocationBarGroups() {
    final List<BarChartGroupData> barGroups = [];
    final locations = _bookingsByLocation.keys.toList();

    for (int i = 0; i < locations.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _bookingsByLocation[locations[i]]!.toDouble(),
              color: Colors.orange,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  // Build the recent bookings table
  Widget _buildRecentBookingsTable() {
    final bookings = _bookingService.getAllBookings();

    // Sort bookings by date (newest first)
    bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Take only the 5 most recent
    final recentBookings = bookings.take(5).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Room Type')),
          DataColumn(label: Text('Date & Time')),
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Actions')),
        ],
        rows: recentBookings.map((booking) {
          return DataRow(
            cells: [
              DataCell(Text(booking.location)),
              DataCell(Text(booking.roomType.displayName)),
              DataCell(
                  Text(DateFormat('MMM d, y HH:mm').format(booking.dateTime))),
              DataCell(
                  Text(booking.userId)), // In a real app, fetch the user's name
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: primaryColor),
                      onPressed: () {
                        // View booking details
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.amber),
                      onPressed: () {
                        // Edit booking
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Delete booking
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
