import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CookedMealLog {
  final String id;
  final String name;
  final DateTime cookedAt;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;

  CookedMealLog({
    required this.id,
    required this.name,
    required this.cookedAt,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

class NutritionTracker extends StatefulWidget {
  const NutritionTracker({Key? key}) : super(key: key);

  @override
  State<NutritionTracker> createState() => _NutritionTrackerState();
}

class _NutritionTrackerState extends State<NutritionTracker> {
  DateTime selectedDate = DateTime.now();
  List<CookedMealLog> _cookedMealsLast7Days = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _userName = 'User';

  final Map<String, double> nutritionGoals = {
    'calories': 2000,
    'protein': 120,
    'carbs': 250,
    'fats': 65,
    'fiber': 30,
  };

  @override
  void initState() {
    super.initState();

    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Please log in to track nutrition.";
      });
      return;
    }

    try {
      Future<DocumentSnapshot<Map<String, dynamic>>> userDocFuture =
          FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final DateTime sevenDaysAgo = todayStart.subtract(
        const Duration(days: 6),
      );
      final Timestamp startTimestamp = Timestamp.fromDate(sevenDaysAgo);

      final cookedMealsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cookedMeals')
              .where('cookedAt', isGreaterThanOrEqualTo: startTimestamp)
              .orderBy('cookedAt', descending: true)
              .get();

      List<CookedMealLog> fetchedMeals = [];
      for (var doc in cookedMealsSnapshot.docs) {
        final data = doc.data();
        final recipeData = data['recipeData'] as Map<String, dynamic>?;
        final cookedAtTimestamp = data['cookedAt'] as Timestamp?;

        if (recipeData != null && cookedAtTimestamp != null) {
          final nutritionValues = _parseNutritionInfo(
            recipeData['Nutritional_Info'],
          );
          fetchedMeals.add(
            CookedMealLog(
              id: doc.id,
              name: recipeData['Recipe Name'] ?? 'Unknown Meal',
              cookedAt: cookedAtTimestamp.toDate(),
              calories:
                  (nutritionValues['calories'] ?? 0.0)
                      .round(), // Convert to int
              protein: nutritionValues['protein'] ?? 0.0,
              carbs: nutritionValues['carbs'] ?? 0.0,
              fats: nutritionValues['fats'] ?? 0.0,
            ),
          );
        }
      }

      final userDoc = await userDocFuture;
      if (mounted && userDoc.exists) {
        _userName = userDoc.data()?['username'] ?? 'User';
      }

      if (!mounted) return;
      setState(() {
        _cookedMealsLast7Days = fetchedMeals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching nutrition data: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load nutrition data.";
      });
    }
  }

  Map<String, double> _parseNutritionInfo(dynamic info) {
    if (info == null || info is! String || info.isEmpty) {
      return {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fats': 0.0};
    }

    final Map<String, double> values = {
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fats': 0.0,
    };
    final String text = info.toLowerCase();

    try {
      final RegExp kcalRegex = RegExp(r'(\d+(\.\d+)?)\s*kcal');
      final RegExp proteinRegex = RegExp(r'(\d+(\.\d+)?)\s*g protein');
      final RegExp carbsRegex = RegExp(r'(\d+(\.\d+)?)\s*g carbs');
      final RegExp fatRegex = RegExp(r'(\d+(\.\d+)?)\s*g fat');

      final kcalMatch = kcalRegex.firstMatch(text);
      final proteinMatch = proteinRegex.firstMatch(text);
      final carbsMatch = carbsRegex.firstMatch(text);
      final fatMatch = fatRegex.firstMatch(text);

      if (kcalMatch != null)
        values['calories'] = double.tryParse(kcalMatch.group(1) ?? '') ?? 0.0;
      if (proteinMatch != null)
        values['protein'] = double.tryParse(proteinMatch.group(1) ?? '') ?? 0.0;
      if (carbsMatch != null)
        values['carbs'] = double.tryParse(carbsMatch.group(1) ?? '') ?? 0.0;
      if (fatMatch != null)
        values['fats'] = double.tryParse(fatMatch.group(1) ?? '') ?? 0.0;
    } catch (e) {
      debugPrint("Error parsing Nutritional_Info '$info': $e");
    }
    return values;
  }

  Map<String, double> _getTotalsForSelectedDate() {
    final totals = {
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fats': 0.0,
      'fiber': 0.0,
    };
    final selectedDayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

    for (var meal in _cookedMealsLast7Days) {
      if (!meal.cookedAt.isBefore(selectedDayStart) &&
          meal.cookedAt.isBefore(selectedDayEnd)) {
        totals['calories'] = totals['calories']! + meal.calories;
        totals['protein'] = totals['protein']! + meal.protein;
        totals['carbs'] = totals['carbs']! + meal.carbs;
        totals['fats'] = totals['fats']! + meal.fats;
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, double> selectedDateTotals =
        _isLoading ? {} : _getTotalsForSelectedDate();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white, // Ensure title/icons are white
        title: const Text("Nutrition Tracker"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData, // Allow pull-to-refresh
        child: _buildContent(theme, selectedDateTotals),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    Map<String, double> selectedDateTotals,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(theme),
        const SizedBox(height: 16),
        _buildMealsCard(), // Shows last 7 days
        const SizedBox(height: 16),
        _buildSummaryCard(selectedDateTotals), // Shows summary for selectedDate
        const SizedBox(height: 16),
        _buildSuggestionsCard(), // Still hardcoded
        const SizedBox(height: 16),
        // _buildWeeklyStatsCard(), // Still commented out
      ],
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
                  _userName,
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
            final DateTime now = DateTime.now();
            final DateTime initial = selectedDate;
            final DateTime first = DateTime(now.year - 1, now.month, now.day);
            final DateTime last = DateTime(now.year, now.month, now.day);

            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: first,
              lastDate: last,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(primary: Colors.teal),
                    buttonTheme: const ButtonThemeData(
                      textTheme: ButtonTextTheme.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null && picked != selectedDate && mounted) {
              setState(() {
                selectedDate = picked;
              });
            }
          },
          child: Container(
            // Date display
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.teal, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(selectedDate)),
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
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  "Meals You Ate (Last 7 Days)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),

            const SizedBox(height: 8),
            _cookedMealsLast7Days.isEmpty
                ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      "No meals logged in the last 7 days.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16.0,
                    headingRowHeight: 36,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 48,
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Meal",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Date",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Cal",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          "Prot",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          "Carb",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          "Fat",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        numeric: true,
                      ),
                    ],
                    rows:
                        _cookedMealsLast7Days
                            .map(
                              (meal) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      meal.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      DateFormat('dd/MM').format(meal.cookedAt),
                                    ),
                                  ),
                                  DataCell(Text("${meal.calories}")),
                                  DataCell(
                                    Text("${meal.protein.toStringAsFixed(0)}g"),
                                  ),
                                  DataCell(
                                    Text("${meal.carbs.toStringAsFixed(0)}g"),
                                  ),
                                  DataCell(
                                    Text("${meal.fats.toStringAsFixed(0)}g"),
                                  ),
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

  Widget _buildSummaryCard(Map<String, double> totals) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  "Summary for ${DateFormat('dd MMM').format(selectedDate)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildCalorieRing(totals['calories'] ?? 0.0),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              "Calories",
              totals['calories'] ?? 0.0,
              nutritionGoals["calories"]!,
              Colors.orange,
            ),
            _buildProgressBar(
              "Protein",
              totals['protein'] ?? 0.0,
              nutritionGoals["protein"]!,
              Colors.redAccent,
            ),
            _buildProgressBar(
              "Carbs",
              totals['carbs'] ?? 0.0,
              nutritionGoals["carbs"]!,
              Colors.lightBlue,
            ),
            _buildProgressBar(
              "Fats",
              totals['fats'] ?? 0.0,
              nutritionGoals["fats"]!,
              Colors.green,
            ),
            _buildProgressBar(
              "Fiber",
              0.0,
              nutritionGoals["fiber"]!,
              Colors.purpleAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieRing(double currentCalories) {
    final double goal = nutritionGoals["calories"]!;
    final double percentage = (goal > 0) ? currentCalories / goal : 0.0;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 1 ? Colors.red.shade700 : Colors.orange,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${currentCalories.toInt()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "kcal",
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ],
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
    final double percent = (goal > 0) ? value / goal : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                "${value.toStringAsFixed(label == 'Calories' ? 0 : 1)} / ${goal.toInt()} ${label == "Calories" ? "kcal" : "g"}",
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 10,
              color: color,
              backgroundColor: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  "Suggestions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              "• You're tracking well for ${DateFormat('dd MMM').format(selectedDate)}!",
            ),
            const Text("• Consider adding more leafy greens."),
            const Text("• Don’t forget to hydrate!"),
          ],
        ),
      ),
    );
  }
}
