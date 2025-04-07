import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class RecipeSwipesScreen extends StatelessWidget {
  final List<Map<String, String>> recipes;

  const RecipeSwipesScreen({super.key, required this.recipes});

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
              : CardSwiper(
                cardsCount: recipes.length,
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
                          if (recipe["Image_Path"] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                recipe["Image_Path"]!,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
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
                            recipe['Cleaned_Ingredients'] ?? 'No Ingredients',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onSwipe: (previousIndex, currentIndex, direction) {
                  // Handle swipe - no return value needed
                  // Remove the 'return true' statement
                },
                isLoop: true,
                padding: const EdgeInsets.all(24.0),
                scale: 0.8,
              ),
    );
  }
}
