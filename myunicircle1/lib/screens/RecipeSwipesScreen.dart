import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'dart:io';

class RecipeSwipesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;
  final File? scannedImage;
  final Function(Map<String, dynamic> recipe)? onSaveForLater;
  final Function(Map<String, dynamic> recipe)? onViewRecipe;
  final Function(Map<String, dynamic> recipe)? onSkipRecipe;

  const RecipeSwipesScreen({
    super.key,
    required this.recipes,
    this.scannedImage,
    this.onSaveForLater,
    this.onViewRecipe,
    this.onSkipRecipe,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Colors.green;
    final Color cardBackgroundColor = Colors.grey.shade50;
    final Color scaffoldBackgroundColor = Colors.white;
    final Color swipeInstructionsBg = primaryGreen.withOpacity(0.9);
    const Color lightText = Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: lightText,
        title: const Text("Swipe Meals"),
      ),
      body:
          recipes.isEmpty
              ? Center(
                child: Text(
                  "No recipes found.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              )
              : Stack(
                children: [
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
                        color: swipeInstructionsBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe_left,
                            color: Colors.lightGreenAccent[100],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Like Recipe",
                            style: TextStyle(color: lightText, fontSize: 14),
                          ),
                          const SizedBox(width: 24),
                          Icon(
                            Icons.swipe_right,
                            color: Colors.red[200],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Skip Recipe",
                            style: TextStyle(color: lightText, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: CardSwiper(
                      cardsCount: recipes.length,
                      isLoop: true,
                      scale: 0.95,
                      cardBuilder: (context, index) {
                        final recipeIndex = index % recipes.length;
                        final recipe = recipes[recipeIndex];
                        return _buildRecipeCard(
                          context,
                          recipe,
                          cardBackgroundColor,
                        );
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 40,
                      ),
                      numberOfCardsDisplayed: 1,
                      onSwipe: (
                        int? prev,
                        int? current,
                        CardSwiperDirection direction,
                      ) {
                        if (prev == null) {
                          debugPrint('Swipe started without previous index.');
                          return;
                        }
                        final prevIndex = prev % recipes.length;
                        debugPrint('Swiped card $prevIndex to $direction');
                        if (direction == CardSwiperDirection.left) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "You liked ${recipes[prevIndex]['Recipe Name'] ?? 'Recipe'}",
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          if (onSaveForLater != null) {
                            onSaveForLater!(recipes[prevIndex]);
                          }
                        } else if (direction == CardSwiperDirection.right) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Skipped ${recipes[prevIndex]['Recipe Name'] ?? 'Recipe'}",
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                          if (onSkipRecipe != null) {
                            onSkipRecipe!(recipes[prevIndex]);
                          }
                        }
                      },
                      onEnd: () {
                        debugPrint("Reached end of cards");
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    Map<String, dynamic> recipe,
    Color cardBgColor,
  ) {
    final Color primaryTextColor = Colors.black87;
    final Color secondaryTextColor = Colors.black54;

    return Card(
      color: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRecipeImage(recipe),
                    const SizedBox(height: 20),
                    Text(
                      recipe['Recipe Name'] ?? 'No Name',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getShortIngredients(
                        recipe['Cleaned_Ingredients'] ?? recipe['Ingredients'],
                      ),
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (onViewRecipe != null) {
                      onViewRecipe!(recipe);
                    }
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("View"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (onSaveForLater != null) {
                      onSaveForLater!(recipe);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Saved ${recipe['Recipe Name'] ?? 'Recipe'}",
                          ),
                          backgroundColor: Colors.blue,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text("Save"),
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
  }

  Widget _buildRecipeImage(Map<String, dynamic> recipe) {
    Widget placeholder = _buildPlaceholderImage(
      recipe['Recipe Name'],
      Colors.grey.shade300,
      Colors.grey.shade600,
    );
    const double imageHeight = 200;

    if (scannedImage != null && scannedImage!.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          scannedImage!,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder:
              (c, e, s) => _buildPlaceholderImage(
                "Ingredient",
                Colors.grey.shade300,
                Colors.grey.shade600,
              ),
        ),
      );
    }

    String? recipeName = recipe['Recipe Name'] as String?;
    if (recipeName != null && recipeName.isNotEmpty) {
      String assetPath = 'assets/recipes2/$recipeName.avif';
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            assetPath,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint(
                "Error loading AVIF asset '$assetPath': $error. Falling back...",
              );
              return _tryNetworkOrOtherAsset(recipe, placeholder, imageHeight);
            },
          ),
        );
      } catch (e) {
        debugPrint(
          "Exception loading AVIF asset '$assetPath': $e. Falling back...",
        );
        return _tryNetworkOrOtherAsset(recipe, placeholder, imageHeight);
      }
    }

    return _tryNetworkOrOtherAsset(recipe, placeholder, imageHeight);
  }

  Widget _tryNetworkOrOtherAsset(
    Map<String, dynamic> recipe,
    Widget placeholder,
    double imageHeight,
  ) {
    dynamic imageValueUrl = recipe['imageUrl'] ?? recipe['Image_Name'];
    if (imageValueUrl != null &&
        imageValueUrl is String &&
        (imageValueUrl.startsWith('http://') ||
            imageValueUrl.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageValueUrl,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => placeholder,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: imageHeight,
              width: double.infinity,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
        ),
      );
    }

    dynamic imageValueAsset = recipe['Image_Name'];
    if (imageValueAsset != null &&
        imageValueAsset is String &&
        imageValueAsset.isNotEmpty &&
        !imageValueAsset.startsWith('http')) {
      String assetPath = imageValueAsset;
      if (!assetPath.startsWith('assets/')) {
        assetPath = 'assets/recipe_images/$assetPath';
      }
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            assetPath,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => placeholder,
          ),
        );
      } catch (e) {
        debugPrint("Exception loading fallback asset '$assetPath': $e");
        return placeholder;
      }
    }

    return placeholder;
  }

  Widget _buildPlaceholderImage(
    String? recipeName,
    Color bgColor,
    Color iconTextColor,
  ) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 50,
            color: iconTextColor.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            recipeName ?? "Recipe Image",
            style: TextStyle(color: iconTextColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getShortIngredients(dynamic ingredients) {
    if (ingredients == null) return 'Ingredients not listed';
    List<String> parts = [];
    if (ingredients is String) {
      parts =
          ingredients
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    } else if (ingredients is List) {
      parts =
          ingredients
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
    }
    return parts.take(4).join(', ');
  }
}
