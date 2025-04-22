import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:io';
import 'package:myunicircle1/screens/RecipeDetailScreen.dart';

class RecipeSwipesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;
  final File? scannedImage; // Made optional for chatbot flow
  final Function(Map<String, dynamic>)? onSaveForLater;
  final Function(Map<String, dynamic>)? onViewRecipe;

  const RecipeSwipesScreen({
    super.key,
    required this.recipes,
    this.scannedImage, // Now optional
    this.onSaveForLater,
    this.onViewRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Swipe Meals"),
      ),
      body:
          recipes.isEmpty
              ? const Center(
                child: Text(
                  "No recipes found.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
              : Stack(
                children: [
                  // Swipe instructions
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.swipe_left,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Like Recipe",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 24),
                          const Icon(
                            Icons.swipe_right,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Next Recipe",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Card swiper
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: CardSwiper(
                      cardsCount: recipes.length,
                      isLoop: false,
                      scale: 1.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 30,
                      ),
                      numberOfCardsDisplayed: 1,
                      onSwipe: (prev, current, direction) {
                        if (direction == CardSwiperDirection.left &&
                            prev != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "You liked ${recipes[prev]['Recipe Name']}",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          if (onSaveForLater != null) {
                            onSaveForLater!(recipes[prev]);
                          }
                        }
                      },
                      cardBuilder: (context, index) {
                        final recipe = recipes[index];
                        return Card(
                          color: Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Dynamic image handling
                                _buildRecipeImage(recipe),
                                const SizedBox(height: 20),
                                Text(
                                  recipe['Recipe Name'] ?? 'No Name',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  recipe['Cleaned_Ingredients'] ??
                                      'No Ingredients',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (onViewRecipe != null) {
                                          onViewRecipe!(recipe);
                                        }
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: const Text("View Recipe"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (onSaveForLater != null) {
                                          onSaveForLater!(recipe);
                                        }
                                      },
                                      icon: const Icon(Icons.bookmark_add),
                                      label: const Text("Save for Later"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildRecipeImage(Map<String, dynamic> recipe) {
    // If we have a scanned image, use that
    if (scannedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          scannedImage!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    // Otherwise try to use recipe image
    final imageUrl = recipe['Image_Name'] ?? recipe['imageUrl'];
    if (imageUrl != null && imageUrl is String) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => _buildPlaceholderImage(),
        ),
      );
    }

    // Fallback to placeholder
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      color: Colors.grey[800],
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, size: 60, color: Colors.white70),
    );
  }
}
