import 'package:flutter/material.dart';

class SuggestedMealsScreen extends StatefulWidget {
  const SuggestedMealsScreen({super.key});

  @override
  _SuggestedMealsScreenState createState() => _SuggestedMealsScreenState();
}

class _SuggestedMealsScreenState extends State<SuggestedMealsScreen> {
  String? _mealType;
  String? _spiceLevel;
  String? _carbPreference;
  String? _caloriePreference;
  bool _hasAllergy = false;
  TextEditingController _allergyController = TextEditingController();

  final List<String> mealOptions = [
    "Light meal",
    "Heavy meal",
    "Something quick",
    "Any",
  ];
  final List<String> spiceOptions = [
    "Spicy",
    "Medium Spicy",
    "Not too spicy",
    "Sweet",
    "Any",
  ];
  final List<String> carbOptions = [
    "High carbs",
    "Low carbs",
    "High protein",
    "I don’t mind",
  ];
  final List<String> calorieOptions = [
    "High calories",
    "Low calories",
    "I don’t mind",
  ];

  void _suggestMeal() {
    // Example logic (can be replaced with actual AI suggestions)
    String mealSuggestion = "Grilled Chicken with Quinoa";
    if (_mealType == "Light meal" && _spiceLevel == "Sweet") {
      mealSuggestion = "Fruit Salad with Honey";
    } else if (_mealType == "Heavy meal" && _carbPreference == "High carbs") {
      mealSuggestion = "Pasta with Alfredo Sauce";
    } else if (_spiceLevel == "Spicy") {
      mealSuggestion = "Spicy Chicken Curry";
    }

    // Show suggested meal
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: Text(
              "Suggested Meal",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              mealSuggestion,
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.green.shade900],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Center(
                child: Text(
                  "What do you feel like eating?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Meal Type Selection
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Meal Type",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children:
                            mealOptions.map((option) {
                              return ChoiceChip(
                                label: Text(
                                  option,
                                  style: TextStyle(
                                    color:
                                        _mealType == option
                                            ? Colors.black
                                            : Colors.black,
                                  ),
                                ),
                                selected: _mealType == option,
                                onSelected: (selected) {
                                  setState(() {
                                    _mealType = selected ? option : null;
                                  });
                                },
                                backgroundColor: Colors.white10,
                                selectedColor: Colors.green,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Spice Level Selection
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.green,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Spice Level",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children:
                            spiceOptions.map((option) {
                              return ChoiceChip(
                                label: Text(
                                  option,
                                  style: TextStyle(
                                    color:
                                        _spiceLevel == option
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                selected: _spiceLevel == option,
                                onSelected: (selected) {
                                  setState(() {
                                    _spiceLevel = selected ? option : null;
                                  });
                                },
                                backgroundColor: Colors.white10,
                                selectedColor: Colors.green,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Carb Preference Selection
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fastfood, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Carb Preference",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children:
                            carbOptions.map((option) {
                              return ChoiceChip(
                                label: Text(
                                  option,
                                  style: TextStyle(
                                    color:
                                        _carbPreference == option
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                selected: _carbPreference == option,
                                onSelected: (selected) {
                                  setState(() {
                                    _carbPreference = selected ? option : null;
                                  });
                                },
                                backgroundColor: Colors.white10,
                                selectedColor: Colors.green,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Calorie Preference Selection
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Calorie Preference",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children:
                            calorieOptions.map((option) {
                              return ChoiceChip(
                                label: Text(
                                  option,
                                  style: TextStyle(
                                    color:
                                        _caloriePreference == option
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                selected: _caloriePreference == option,
                                onSelected: (selected) {
                                  setState(() {
                                    _caloriePreference =
                                        selected ? option : null;
                                  });
                                },
                                backgroundColor: Colors.white10,
                                selectedColor: Colors.green,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Allergy Option
              Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Do you have any allergies?",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _hasAllergy,
                            onChanged: (value) {
                              setState(() {
                                _hasAllergy = value!;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Text("Yes", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      if (_hasAllergy)
                        TextField(
                          controller: _allergyController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter your allergies",
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Suggest Meal Button
              Center(
                child: ElevatedButton(
                  onPressed: _suggestMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Suggest Meal",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
