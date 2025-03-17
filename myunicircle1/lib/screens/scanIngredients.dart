import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ScanIngredientsScreen extends StatefulWidget {
  @override
  _ScanIngredientsScreenState createState() => _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState extends State<ScanIngredientsScreen> {
  List<File> _selectedImages = [];
  List<String> _detectedIngredients = [];
  List<String> _suggestedMeals = [];
  List<Map<String, dynamic>> _foodData = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _detectIngredients() async {
    await Future.delayed(Duration(seconds: 2));

    List<String> detectedIngredients = ["Chicken", "Rice", "Broccoli"];

    List<Map<String, dynamic>> matchingMeals =
        _foodData.where((meal) {
          List<String> ingredientsList = meal["ingredients"]
              .toLowerCase()
              .split(', ');
          return detectedIngredients.any(
            (ingredient) => ingredientsList.contains(ingredient.toLowerCase()),
          );
        }).toList();

    setState(() {
      _detectedIngredients = detectedIngredients;
      _suggestedMeals =
          matchingMeals.map((meal) => meal["food_name"].toString()).toList();
    });
  }

  Future<void> loadFoodData() async {
    final String jsonString = await rootBundle.loadString(
      'assets/food_data.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _foodData = jsonData.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
        _detectedIngredients = [];
        _suggestedMeals = [];
      });
    }
  }

  void _clearAll() {
    setState(() {
      _selectedImages.clear();
      _detectedIngredients.clear();
      _suggestedMeals.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    loadFoodData();
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
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Center(
                  child: Text(
                    "Scan Ingredients",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  color: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                _selectedImages.isEmpty
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          size: 50,
                                          color: Colors.green,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "Tap to Upload Image",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    )
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _selectedImages.last,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Upload or take a photo of your ingredients",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_selectedImages.isNotEmpty) ...[
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
                              Icon(Icons.image, color: Colors.green),
                              SizedBox(width: 10),
                              Text(
                                "Uploaded Images",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: Icon(Icons.image, color: Colors.green),
                                title: Text(
                                  "Image ${index + 1}",
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                if (_detectedIngredients.isNotEmpty) ...[
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
                              Icon(Icons.search, color: Colors.green),
                              SizedBox(width: 10),
                              Text(
                                "Detected Ingredients",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing:
                                8, // Add vertical spacing between ingredients
                            children:
                                _detectedIngredients.map((ingredient) {
                                  return Chip(
                                    label: Text(
                                      ingredient,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                if (_suggestedMeals.isNotEmpty) ...[
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
                                "AI Suggested Meals",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Column(
                            children:
                                _suggestedMeals.map((meal) {
                                  Map<String, dynamic> mealData = _foodData
                                      .firstWhere(
                                        (m) => m["food_name"] == meal,
                                        orElse: () => {},
                                      );
                                  return Card(
                                    color: Colors.white10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      leading:
                                          mealData["image_url"] != null
                                              ? Image.asset(
                                                "assets/${mealData["image_url"]}",
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              )
                                              : Icon(
                                                Icons.fastfood,
                                                color: Colors.green,
                                                size: 50,
                                              ),
                                      title: Text(
                                        meal,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Text(
                                        mealData["ingredients"] ??
                                            "No ingredients listed",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.green,
                                      ),
                                      onTap: () {},
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: Icon(Icons.camera, color: Colors.white),
                      label: Text(
                        "Take Photo",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: Icon(Icons.upload, color: Colors.white),
                      label: Text(
                        "Add Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (_selectedImages.isNotEmpty) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _detectIngredients(); // Trigger AI detection
                      },
                      icon: Icon(Icons.restaurant, color: Colors.white),
                      label: Text(
                        "Suggest a Meal",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
                if (_suggestedMeals.isNotEmpty) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _clearAll,
                      icon: Icon(Icons.clear, color: Colors.white),
                      label: Text(
                        "Clear All",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
