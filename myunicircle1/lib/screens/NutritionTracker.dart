import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class NutritionTracker extends StatefulWidget {
  const NutritionTracker({Key? key}) : super(key: key);

  @override
  State<NutritionTracker> createState() => _NutritionTrackerState();
}

class _NutritionTrackerState extends State<NutritionTracker> {
  DateTime selectedDate = DateTime.now();

  final List<Meal> todaysMeals = [
    Meal(
      name: 'Banana Smoothie',
      calories: 180,
      protein: 3,
      carbs: 25,
      fats: 2,
      completed: true,
    ),
    Meal(
      name: 'Chickpea Salad',
      calories: 250,
      protein: 12,
      carbs: 30,
      fats: 8,
      completed: true,
    ),
    Meal(
      name: 'Grilled Chicken',
      calories: 320,
      protein: 35,
      carbs: 5,
      fats: 15,
      completed: true,
    ),
    Meal(
      name: 'Greek Yogurt',
      calories: 150,
      protein: 15,
      carbs: 10,
      fats: 5,
      completed: false,
    ),
  ];

  final Map<String, double> nutritionGoals = {
    'calories': 2000,
    'protein': 120,
    'carbs': 250,
    'fats': 65,
    'fiber': 30,
  };

  final List<double> weeklyProtein = [85, 95, 110, 90, 120, 100, 105];

  int getTotalCalories() => todaysMeals.fold(0, (sum, m) => sum + m.calories);

  double getTotal(String nutrient) {
    switch (nutrient) {
      case 'protein':
        return todaysMeals.fold(0.0, (sum, m) => sum + m.protein);
      case 'carbs':
        return todaysMeals.fold(0.0, (sum, m) => sum + m.carbs);
      case 'fats':
        return todaysMeals.fold(0.0, (sum, m) => sum + m.fats);
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Nutrition Tracker"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildMealsCard(),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildSuggestionsCard(),
          const SizedBox(height: 16),
          _buildWeeklyStatsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back,",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  "Alex",
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2025),
            );
            if (picked != null) setState(() => selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.teal, size: 16),
                const SizedBox(width: 8),
                Text(
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  "Today's Meals",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text("Add Meal")),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Meal")),
                  DataColumn(label: Text("Cal")),
                  DataColumn(label: Text("Protein")),
                  DataColumn(label: Text("Carbs")),
                  DataColumn(label: Text("Fats")),
                ],
                rows:
                    todaysMeals
                        .map(
                          (m) => DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Icon(
                                      m.completed
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      size: 16,
                                      color:
                                          m.completed
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(m.name),
                                  ],
                                ),
                              ),
                              DataCell(Text("${m.calories}")),
                              DataCell(Text("${m.protein}g")),
                              DataCell(Text("${m.carbs}g")),
                              DataCell(Text("${m.fats}g")),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  "Nutrition Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildCalorieRing(),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressBar(
              "Calories",
              getTotalCalories().toDouble(),
              nutritionGoals["calories"]!,
              Colors.orange,
            ),
            _buildProgressBar(
              "Protein",
              getTotal("protein"),
              nutritionGoals["protein"]!,
              Colors.red,
            ),
            _buildProgressBar(
              "Carbs",
              getTotal("carbs"),
              nutritionGoals["carbs"]!,
              Colors.blue,
            ),
            _buildProgressBar(
              "Fats",
              getTotal("fats"),
              nutritionGoals["fats"]!,
              Colors.green,
            ),
            _buildProgressBar(
              "Fiber",
              12.0,
              nutritionGoals["fiber"]!,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieRing() {
    final double percentage = getTotalCalories() / nutritionGoals["calories"]!;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 1 ? Colors.red : Colors.orange,
            ),
          ),
          Center(
            child: Text(
              "${(percentage * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    double value,
    double goal,
    Color color,
  ) {
    final percent = value / goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(
              "${value.toInt()} / ${goal.toInt()} ${label == "Calories" ? "kcal" : "g"}",
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          minHeight: 8,
          color: color,
          backgroundColor: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildSuggestionsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  "Suggestions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "• You're low on protein today. Try adding tofu, eggs, or beans.",
            ),
            Text("• Great progress on fiber this week."),
            Text("• Don’t forget to hydrate!"),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  "Weekly Protein",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 150,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, m) {
                          const days = ["M", "T", "W", "T", "F", "S", "S"];
                          return Text(
                            days[v.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups:
                      weeklyProtein.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color:
                                  e.value >= 100
                                      ? Colors.teal
                                      : Colors.teal[200],
                              width: 18,
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
  }
}

class Meal {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final bool completed;

  Meal({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.completed,
  });
}
