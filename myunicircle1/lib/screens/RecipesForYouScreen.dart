import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myunicircle1/screens/RecipeDetailScreen.dart';

class RecipesForYouScreen extends StatefulWidget {
  const RecipesForYouScreen({super.key});

  @override
  State<RecipesForYouScreen> createState() => _RecipesForYouScreenState();
}

class _RecipesForYouScreenState extends State<RecipesForYouScreen> {
  List<Map<String, dynamic>> _suggestedRecipes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, String> _userContext = {};

  @override
  void initState() {
    super.initState();
    _loadDataAndGenerateSuggestions();
  }

  Future<void> _loadDataAndGenerateSuggestions() async {
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
        _errorMessage = "Please log in to see personalized recipes.";
      });
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists && userDoc.data()?['lastMealContext'] != null) {
        _userContext = Map<String, String>.from(
          userDoc.data()!['lastMealContext'],
        );
      }

      final savedRecipesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('savedRecipes')
              .orderBy('savedAt', descending: true)
              .limit(20)
              .get();

      if (savedRecipesSnapshot.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _suggestedRecipes = [];
        });
        return;
      }

      Map<String, int> cuisineCounts = {};
      Map<String, int> mealTypeCounts = {};

      for (var doc in savedRecipesSnapshot.docs) {
        final data = doc.data()['recipeData'] as Map<String, dynamic>?;
        if (data != null) {
          final cuisine = (data['Cuisine'] as String?)?.trim().toLowerCase();
          final mealType = (data['Meal_Type'] as String?)?.trim().toLowerCase();
          if (cuisine != null && cuisine.isNotEmpty) {
            cuisineCounts[cuisine] = (cuisineCounts[cuisine] ?? 0) + 1;
          }
          if (mealType != null && mealType.isNotEmpty) {
            mealTypeCounts[mealType] = (mealTypeCounts[mealType] ?? 0) + 1;
          }
        }
      }

      final List<MapEntry<String, int>> sortedCuisines =
          cuisineCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final Set<String> topLikedCuisines =
          sortedCuisines.take(2).map((e) => e.key).toSet();
      final List<MapEntry<String, int>> sortedMealTypes =
          mealTypeCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final Set<String> topLikedMealTypes =
          sortedMealTypes.take(2).map((e) => e.key).toSet();

      debugPrint("Top Liked Cuisines: $topLikedCuisines");
      debugPrint("Top Liked Meal Types: $topLikedMealTypes");

      final allRecipesSnapshot =
          await FirebaseFirestore.instance.collection("recipes2").get();
      final allRecipes =
          allRecipesSnapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                final recipeData = Map<String, dynamic>.from(data);
                recipeData['id'] = doc.id;
                return recipeData;
              })
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList();

      if (allRecipes.isEmpty) {
        throw Exception("No recipes found in 'recipes2' collection.");
      }

      final scoredRecipes =
          allRecipes.map((recipe) {
            double score = _calculatePersonalizedScore(
              recipe,
              _userContext,
              topLikedCuisines,
              topLikedMealTypes,
            );
            return {'data': recipe, 'score': score};
          }).toList();

      scoredRecipes.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );
      _suggestedRecipes =
          scoredRecipes
              .take(10)
              .map((e) => e['data'] as Map<String, dynamic>)
              .toList();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_suggestedRecipes.isEmpty) {
          _errorMessage =
              "Couldn't generate personalized suggestions based on your saved recipes.";
        }
      });
    } catch (e) {
      debugPrint("Error loading personalized recipes: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load suggestions. Please try again.";
      });
    }
  }

  double _calculatePersonalizedScore(
    Map<String, dynamic> recipe,
    Map<String, String> userContext,
    Set<String> topCuisines,
    Set<String> topMealTypes,
  ) {
    double score = 0.0;
    const double topMatchBoost = 100.0;
    const double contextMatchBoost = 1.0;
    final String recipeCuisine =
        (recipe['Cuisine'] ?? '').toString().toLowerCase();
    final String recipeMealType =
        (recipe['Meal_Type'] ?? '').toString().toLowerCase();

    if (recipeCuisine.isNotEmpty && topCuisines.contains(recipeCuisine)) {
      score += topMatchBoost;
    }
    if (recipeMealType.isNotEmpty && topMealTypes.contains(recipeMealType)) {
      score += topMatchBoost;
    }

    final String dietGoal = userContext['dietGoal']?.toLowerCase() ?? '';
    if (dietGoal.contains('muscle') && _isYes(recipe, 'High_Protein'))
      score += contextMatchBoost;
    if (dietGoal.contains('weight') && _isYes(recipe, 'Low_Calorie'))
      score += contextMatchBoost;

    return score;
  }

  Set<String> _splitTags(dynamic tagValue) {
    if (tagValue == null || tagValue is! String || tagValue.isEmpty) {
      return <String>{};
    }
    return tagValue
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();
  }

  bool _isYes(Map<String, dynamic> recipe, String field) {
    final value = recipe[field];
    if (value == null) return false;
    if (value is bool) return value;
    return ['yes', 'true', '1'].contains(value.toString().trim().toLowerCase());
  }

  void _navigateToDetail(Map<String, dynamic> recipe) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipes Just For You ✨"),
        backgroundColor: Colors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDataAndGenerateSuggestions,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }
    if (_suggestedRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Save recipes you like, and personalized suggestions will appear here!\n(Pull down to refresh)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _suggestedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _suggestedRecipes[index];
        return _buildRecipeGridCard(recipe);
      },
    );
  }

  Widget _buildRecipeGridCard(Map<String, dynamic> recipe) {
    return InkWell(
      onTap: () => _navigateToDetail(recipe),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGridImage(recipe)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['Recipe Name'] ?? 'Recipe',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe['Cuisine'] ?? recipe['Meal_Type'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridImage(Map<String, dynamic> recipe) {
    Widget placeholder = Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.restaurant_menu, color: Colors.grey),
      ),
    );
    const double imageHeight = 150;

    String? recipeName = recipe['Recipe Name'] as String?;
    if (recipeName != null && recipeName.isNotEmpty) {
      String assetPath = 'assets/recipes2/$recipeName.avif';
      try {
        return Image.asset(
          assetPath,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
              "Error loading AVIF asset '$assetPath': $error. Falling back...",
            );
            return _tryNetworkOrOtherAssetGrid(
              recipe,
              placeholder,
              imageHeight,
            );
          },
        );
      } catch (e) {
        debugPrint(
          "Exception loading AVIF asset '$assetPath': $e. Falling back...",
        );
        return _tryNetworkOrOtherAssetGrid(recipe, placeholder, imageHeight);
      }
    }

    return _tryNetworkOrOtherAssetGrid(recipe, placeholder, imageHeight);
  }

  Widget _tryNetworkOrOtherAssetGrid(
    Map<String, dynamic> recipe,
    Widget placeholder,
    double imageHeight,
  ) {
    dynamic imageValueUrl = recipe['imageUrl'] ?? recipe['Image_Name'];
    if (imageValueUrl != null &&
        imageValueUrl is String &&
        (imageValueUrl.startsWith('http://') ||
            imageValueUrl.startsWith('https://'))) {
      return Image.network(
        imageValueUrl,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
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
        return Image.asset(
          assetPath,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => placeholder,
        );
      } catch (e) {
        debugPrint("Exception loading fallback asset '$assetPath': $e");
        return placeholder;
      }
    }

    return placeholder;
  }
}
