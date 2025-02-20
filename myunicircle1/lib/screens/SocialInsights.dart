import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // ✅ Make sure this package is installed!

class SocialInsightsScreen extends StatelessWidget {
  const SocialInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: const Text("Social Insights"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Social Activity 📊",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Statistics Cards (Total Friends, Circles Joined, Messages Sent)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatsCard("Friends", "24", Icons.people),
                _buildStatsCard("Circles", "5", Icons.group),
                _buildStatsCard("Messages", "289", Icons.message),
              ],
            ),

            const SizedBox(height: 30),

            // Activity Chart (Using FL Chart)
            const Text(
              "Engagement Over Time",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildLineChart()),

            const SizedBox(height: 20),

            // AI Insights
            const Text(
              "AI Insights 🔍",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _buildInsightCard(
              "🔥 Most Active Time",
              "You are most active between 6PM - 10PM",
              Icons.access_time,
            ),
            _buildInsightCard(
              "📅 Event Engagement",
              "You've joined 3 events this month!",
              Icons.event_available,
            ),
            _buildInsightCard(
              "👥 Friendship Growth",
              "You've added 5 new friends this week",
              Icons.person_add,
            ),
          ],
        ),
      ),
    );
  }

  // Function to create statistics card
  Widget _buildStatsCard(String label, String value, IconData icon) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF7F56BB)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // Function to create AI insight card
  Widget _buildInsightCard(String title, String description, IconData icon) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, size: 30, color: const Color(0xFF7F56BB)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  // Function to create the line chart
  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 2),
              const FlSpot(1, 3),
              const FlSpot(2, 1),
              const FlSpot(3, 4),
              const FlSpot(4, 5),
              const FlSpot(5, 3),
            ],
            isCurved: true,
            color: const Color(0xFF7F56BB),
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
