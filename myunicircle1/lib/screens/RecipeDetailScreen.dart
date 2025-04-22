import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final File? scannedImage;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.scannedImage,
  });

  Future<void> _markAsCooked(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cookedMeals')
            .add({
              'recipeId':
                  recipe['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              'recipeData': recipe,
              'cookedAt': FieldValue.serverTimestamp(),
              'rating': null, // Can be updated later
              'notes': null, // Can be added later
            });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meal marked as cooked!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as cooked: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe['Recipe Name'] ?? 'Recipe Details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (scannedImage != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(scannedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    recipe['Recipe Name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Main Ingredient: ${recipe['Main_Ingredients'] ?? 'Unknown'}",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Ingredients:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatIngredients(
                      recipe['Cleaned_Ingredients'] ?? recipe['Ingredients'],
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Instructions:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recipe['Instructions'] ?? 'No instructions available',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (recipe['Nutritional_Info'] != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Nutritional Information:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (recipe['Nutritional_Info'] is Map)
                      ..._buildNutritionInfo(recipe['Nutritional_Info'])
                    else
                      Text(
                        recipe['Nutritional_Info'].toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ],
              ),
            ),
          ),
          // Add the "Mark as Cooked" button at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _markAsCooked(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Mark as Cooked',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatIngredients(dynamic ingredients) {
    if (ingredients is String) {
      try {
        final cleaned = ingredients
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .replaceAll("'", '');
        return cleaned.split(',').map((e) => '• ${e.trim()}').join('\n');
      } catch (e) {
        return ingredients;
      }
    } else if (ingredients is List) {
      return ingredients.map((e) => '• ${e.toString().trim()}').join('\n');
    }
    return ingredients?.toString() ?? 'No ingredients listed';
  }

  List<Widget> _buildNutritionInfo(Map<String, dynamic> nutrition) {
    return nutrition.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          '• ${entry.key}: ${entry.value}',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }).toList();
  }
}
