import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myunicircle1/screens/RecipeSwipesScreen.dart';

class ScanIngredientsScreen extends StatefulWidget {
  @override
  _ScanIngredientsScreenState createState() => _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState extends State<ScanIngredientsScreen> {
  List<File> _selectedImages = [];
  List<String> _predictions = [];
  List<String> _labels = [];
  bool _isLoading = false;
  List<Map<String, String>> _recipes = [];

  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadRecipes();
  }

  Future<void> _loadModel() async {
    try {
      _labels = await _loadLabels("assets/labels.txt");
      final byteData = await rootBundle.load('assets/FVmodel.tflite');
      if (byteData.lengthInBytes == 0) {
        print("❌ FVmodel.tflite exists but is empty!");
        return;
      }

      _interpreter = await Interpreter.fromAsset('assets/FVmodel.tflite');
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> _loadRecipes() async {
    try {
      final csvString = await rootBundle.loadString(
        'assets/healthy_fruit_veg_recipes_FINAL.csv',
      );
      List<List<dynamic>> csvTable = CsvToListConverter().convert(csvString);

      // Debug: Print the first few rows of the CSV file
      print("CSV File Loaded. First few rows:");
      for (int i = 0; i < (csvTable.length > 5 ? 5 : csvTable.length); i++) {
        print(csvTable[i]);
      }

      // Assuming the first row is the header
      List<String> headers = csvTable[0].map((e) => e.toString()).toList();
      for (int i = 1; i < csvTable.length; i++) {
        Map<String, String> recipe = {};
        for (int j = 0; j < headers.length; j++) {
          recipe[headers[j]] = csvTable[i][j].toString();
        }
        _recipes.add(recipe);
      }

      // Debug: Print number of recipes loaded
      print("Number of Recipes Loaded: ${_recipes.length}");
    } catch (e) {
      print("❌ Failed to load recipes: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
      _predictImage(File(pickedFile.path));
    }
  }

  Future<void> _predictImage(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      print("❌ Model or labels not loaded");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var inputImage = await _preprocessImage(imageFile);
      if (inputImage.isEmpty) return;

      print("📌 Number of labels: ${_labels.length}");

      var output = List.filled(
        _labels.length,
        0.0,
      ).reshape([1, _labels.length]);

      _interpreter!.run(inputImage, output);

      List<double> outputList = List<double>.from(output[0]);

      int predictedIndex = outputList.indexOf(
        outputList.reduce((a, b) => a > b ? a : b),
      );

      String predictedLabel = _labels[predictedIndex];

      setState(() {
        _predictions.add(predictedLabel);
      });

      print("✅ Prediction: $predictedLabel");
    } catch (e) {
      print("❌ Error during prediction: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
    File imageFile,
  ) async {
    var imageBytes = await imageFile.readAsBytes();
    var image = img.decodeImage(imageBytes);

    if (image == null) {
      print("❌ Failed to decode image");
      return [];
    }

    var resizedImage = img.copyResize(image, width: 150, height: 150);

    var normalizedImage = List.generate(
      150,
      (y) => List.generate(150, (x) {
        var pixel = resizedImage.getPixel(x, y);
        return [
          img.getRed(pixel) / 255.0,
          img.getGreen(pixel) / 255.0,
          img.getBlue(pixel) / 255.0,
        ];
      }),
    );

    return [normalizedImage];
  }

  Future<List<String>> _loadLabels(String labelsPath) async {
    final labels = await rootBundle.loadString(labelsPath);
    return labels.split('\n').where((label) => label.isNotEmpty).toList();
  }

  void _clearAll() {
    setState(() {
      _selectedImages.clear();
      _predictions.clear();
    });
  }

  void _suggestMeals() async {
    if (_predictions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No ingredients predicted yet!")));
      return;
    }

    print("🔍 Searching Firestore for recipes with ingredients: $_predictions");

    try {
      final recipesCollection = FirebaseFirestore.instance.collection(
        "recipes",
      );
      List<Map<String, String>> suggestedRecipes = [];

      for (String ingredient in _predictions) {
        ingredient = ingredient.trim().toLowerCase(); // Normalize input

        // 🔹 Try searching with arrayContains
        var querySnapshot =
            await recipesCollection
                .where("Main_Ingredients", arrayContains: ingredient)
                .limit(20) // ✅ Limit results to 20
                .get();

        // 🔹 If no results, try substring search (for string-based Main_Ingredients)
        if (querySnapshot.docs.isEmpty) {
          querySnapshot =
              await recipesCollection
                  .where("Main_Ingredients", isGreaterThanOrEqualTo: ingredient)
                  .where(
                    "Main_Ingredients",
                    isLessThanOrEqualTo: ingredient + '\uf8ff',
                  )
                  .limit(20) // ✅ Limit results to 20
                  .get();
        }

        for (var doc in querySnapshot.docs) {
          Map<String, String> recipe = {};
          doc.data().forEach((key, value) {
            recipe[key] = value.toString();
          });

          // 🔹 Add image path dynamically from local assets
          String imageName = recipe['Image_Name'] ?? 'default_image';
          recipe['Image_Path'] = 'assets/recipe_images/$imageName.jpg';

          suggestedRecipes.add(recipe);
        }

        // ✅ If we reach 20 recipes, stop fetching more
        if (suggestedRecipes.length >= 20) break;
      }

      print("✅ Found ${suggestedRecipes.length} matching recipes!");

      if (suggestedRecipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No recipes found for predicted ingredients!"),
          ),
        );
        return;
      }

      // ✅ Ensure we only take the first 20 results
      suggestedRecipes = suggestedRecipes.take(20).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeSwipesScreen(recipes: suggestedRecipes),
        ),
      );
    } catch (e) {
      print("❌ Error fetching recipes: $e");
    }
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                              subtitle:
                                  _predictions.length > index
                                      ? Text(
                                        "Prediction: ${_predictions[index]}",
                                        style: TextStyle(color: Colors.green),
                                      )
                                      : Text(
                                        "Processing...",
                                        style: TextStyle(color: Colors.white70),
                                      ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                    _predictions.removeAt(index);
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
              if (_isLoading) CircularProgressIndicator(),
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
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _suggestMeals,
                    icon: Icon(Icons.restaurant, color: Colors.white),
                    label: Text(
                      "Suggest Meals",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
    );
  }
}

class SuggestedMealsScreen extends StatelessWidget {
  final List<Map<String, String>> recipes;

  SuggestedMealsScreen({required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Suggested Meals")),
      body:
          recipes.isEmpty
              ? Center(
                child: Text(
                  "No recipes found for the predicted ingredients.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(recipe['Recipe Name'] ?? 'No Name'),
                      subtitle: Text(
                        recipe['Cleaned_Ingredients'] ?? 'No Ingredients',
                      ),
                      onTap: () {
                        // You can add more details here if needed
                      },
                    ),
                  );
                },
              ),
    );
  }
}
