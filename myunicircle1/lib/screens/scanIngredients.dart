import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart'
    show rootBundle, FilteringTextInputFormatter, TextInputFormatter;
import 'package:image/image.dart' as img; // image package imported as img
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myunicircle1/screens/RecipeSwipesScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myunicircle1/screens/RecipeDetailScreen.dart';
import 'dart:math' as math;

class ScanIngredientsScreen extends StatefulWidget {
  const ScanIngredientsScreen({super.key});

  @override
  _ScanIngredientsScreenState createState() => _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState extends State<ScanIngredientsScreen> {
  final List<File> _selectedImages = [];
  List<String> _predictions = [];
  List<String> _labels = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _labels = await _loadLabels("assets/labels.txt");
      _interpreter = await Interpreter.fromAsset('assets/FVmodel.tflite');
      print("TFLite Model loaded successfully!");
    } catch (e) {
      print("Failed to load TFLite model: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading ingredient model: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _selectedImages.add(imageFile);
          _predictions.add("Processing...");
        });
        _predictImage(imageFile, _selectedImages.length - 1);
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _predictImage(File imageFile, int predictionIndex) async {
    if (_interpreter == null || _labels.isEmpty) {
      print("Model or labels not loaded, cannot predict.");
      if (mounted) {
        setState(() {
          if (predictionIndex < _predictions.length) {
            _predictions[predictionIndex] = "Error: Model not ready";
          }
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ingredient recognition model not ready."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      var inputImage = await _preprocessImage(imageFile);
      if (inputImage.isEmpty || !mounted) {
        if (mounted && predictionIndex < _predictions.length) {
          setState(() {
            _predictions[predictionIndex] = "Error: Image processing failed";
          });
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      ;

      if (_interpreter!.getOutputTensor(0).shape.length < 2 ||
          _interpreter!.getOutputTensor(0).shape[1] != _labels.length) {
        throw Exception(
          "Model output shape (${_interpreter!.getOutputTensor(0).shape}) mismatch with labels count (${_labels.length}).",
        );
      }
      var output = List.filled(
        1 * _labels.length,
        0.0,
      ).reshape([1, _labels.length]);

      _interpreter!.run(inputImage, output);

      List<double> outputList = List<double>.from(output[0]);
      double maxScore = outputList.reduce(math.max);
      int predictedIndex = outputList.indexOf(maxScore);

      String predictedLabel = "Unknown";
      if (predictedIndex >= 0 && predictedIndex < _labels.length) {
        predictedLabel = _labels[predictedIndex];
      } else {
        print("Predicted index out of bounds: $predictedIndex");
      }

      if (mounted && predictionIndex < _predictions.length) {
        setState(() {
          _predictions[predictionIndex] = predictedLabel;
        });
      }

      print(
        "Prediction for image $predictionIndex: $predictedLabel (Score: $maxScore)",
      );
    } catch (e) {
      print("Error during prediction for image $predictionIndex: $e");
      if (mounted) {
        setState(() {
          if (predictionIndex < _predictions.length) {
            _predictions[predictionIndex] = "Error predicting";
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error recognizing ingredient: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImage(
    File imageFile,
  ) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        print("❌ Failed to decode image");
        return [];
      }

      const int inputSize = 150;

      img.Image resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );

      var normalizedImage = List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          int pixel = resizedImage.getPixel(x, y);
          return [
            img.getRed(pixel) / 255.0,
            img.getGreen(pixel) / 255.0,
            img.getBlue(pixel) / 255.0,
          ];
        }),
      );

      return [normalizedImage];
    } catch (e) {
      print("Error during image preprocessing: $e");
      return [];
    }
  }

  Future<List<String>> _loadLabels(String labelsPath) async {
    try {
      final labelsString = await rootBundle.loadString(labelsPath);
      return labelsString
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error loading labels: $e");
      return [];
    }
  }

  void _clearAll() {
    if (!mounted) return;
    setState(() {
      _selectedImages.clear();
      _predictions.clear();
    });
  }

  void _suggestMeals() async {
    final validPredictions =
        _predictions
            .where((p) => p != "Processing..." && !p.startsWith("Error"))
            .toSet()
            .toList();

    if (validPredictions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please scan some ingredients first!")),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    print(
      "🔍 Searching Firestore 'recipes' collection for ingredients: $validPredictions",
    );

    try {
      final recipesCollection = FirebaseFirestore.instance.collection(
        "recipes",
      );
      List<Map<String, dynamic>> suggestedRecipes = [];
      Set<String> addedRecipeIds = {};

      for (String ingredient in validPredictions) {
        if (suggestedRecipes.length >= 10) break;

        String searchTerm = ingredient.trim().toLowerCase();
        if (searchTerm.isEmpty) continue;

        QuerySnapshot querySnapshot =
            await recipesCollection
                .where("Main_Ingredients", isEqualTo: searchTerm)
                .limit(5)
                .get();

        for (var doc in querySnapshot.docs) {
          if (suggestedRecipes.length >= 10) break;

          final recipeId = doc.id;
          if (!addedRecipeIds.contains(recipeId)) {
            Map<String, dynamic> recipe = doc.data() as Map<String, dynamic>;
            recipe['id'] = recipeId;
            suggestedRecipes.add(recipe);
            addedRecipeIds.add(recipeId);
          }
        }
      }

      if (!mounted) return;

      print("Found ${suggestedRecipes.length} potentially matching recipes!");

      if (suggestedRecipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No recipes found matching the scanned ingredients in the 'recipes' collection.",
            ),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => RecipeSwipesScreen(
                recipes: suggestedRecipes,
                scannedImage:
                    _selectedImages.isNotEmpty ? _selectedImages.last : null,
                onSaveForLater: (recipe) => _saveRecipeToFirestore(recipe),
                onViewRecipe: (recipe) => _showRecipeDetails(context, recipe),
                onSkipRecipe: (recipe) => _logSkippedRecipe(recipe),
              ),
        ),
      );
    } catch (e) {
      print("Error fetching recipes based on ingredients: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error suggesting meals: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRecipeToFirestore(Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final recipeId = recipe['id'] as String?;
      if (user != null && recipeId != null && mounted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedRecipes')
            .doc(recipeId)
            .set({
              'recipeId': recipeId,
              'savedAt': FieldValue.serverTimestamp(),
              'recipeData': recipe,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Saved ${recipe['Recipe Name'] ?? 'Recipe'} for later!",
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else if (recipeId == null) {
        debugPrint("Error saving recipe: Recipe ID is null.");
      }
    } catch (e) {
      debugPrint("Error saving recipe: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save recipe: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logSkippedRecipe(Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final recipeId = recipe['id'] as String?;
      if (user != null && recipeId != null && mounted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('skippedRecipes')
            .doc(recipeId)
            .set({
              'recipeId': recipeId,
              'skippedAt': FieldValue.serverTimestamp(),
              'cuisine': recipe['Cuisine'],
              'mealType': recipe['Meal_Type'],
              'mainIngredient': recipe['Main_Ingredients'],
            });
        debugPrint("Logged skip for recipe: $recipeId");
      } else if (recipeId == null) {
        debugPrint("Error logging skipped recipe: Recipe ID is null.");
      }
    } catch (e) {
      debugPrint("Error logging skipped recipe: $e");
    }
  }

  void _showRecipeDetails(BuildContext context, Map<String, dynamic> recipe) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RecipeDetailScreen(
              recipe: recipe,
              scannedImage:
                  _selectedImages.isNotEmpty ? _selectedImages.last : null,
            ),
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
            colors: [Colors.grey.shade900, Colors.green.shade900],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Scan Ingredients",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Scan fruits & veggies to get recipe ideas!",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Card(
                  color: Colors.black.withOpacity(0.3),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: InkWell(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child:
                                _selectedImages.isEmpty
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 60,
                                          color: Colors.greenAccent,
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
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Center(
                                            child: Text(
                                              "Error loading image",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Take Photo",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Add Image",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedImages.isNotEmpty) ...[
                  Card(
                    color: Colors.black.withOpacity(0.3),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.image_search,
                                color: Colors.greenAccent,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Scanned Items",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedImages.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _clearAll,
                                  icon: const Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    "Clear All",
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              final predictionText =
                                  (index < _predictions.length)
                                      ? _predictions[index]
                                      : "Waiting...";
                              final bool isError = predictionText.startsWith(
                                "Error",
                              );
                              final bool isProcessing =
                                  predictionText == "Processing...";

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 0,
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  "Item ${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  "Prediction: $predictionText",
                                  style: TextStyle(
                                    color:
                                        isError
                                            ? Colors.redAccent
                                            : (isProcessing
                                                ? Colors.orangeAccent
                                                : Colors.greenAccent),
                                    fontSize: 14,
                                    fontStyle:
                                        isProcessing
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent.withOpacity(0.8),
                                  ),
                                  tooltip: "Remove this item",
                                  onPressed: () {
                                    if (!mounted) return;
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                      if (index < _predictions.length) {
                                        _predictions.removeAt(index);
                                      }
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
                  const SizedBox(height: 20),
                ],

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  ),

                if (_selectedImages.isNotEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _suggestMeals,
                        icon: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Suggest Meals",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
