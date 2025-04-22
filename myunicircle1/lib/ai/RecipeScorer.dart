import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeScorer {
  static double scoreRecipe({
    required Map<String, dynamic> recipe,
    List<String> scannedIngredients = const [],
    required Map<String, String> preferences,
    required Set<String> likedIngredients,
  }) {
    double score = 0;

    // 1. Ingredient Match (20 pts max)
    final ingredients = _parseIngredients(recipe['Main_Ingredients']);
    final matchCount =
        ingredients
            .where((ing) => scannedIngredients.contains(ing.toLowerCase()))
            .length;
    score += (matchCount * 5).clamp(0, 20);

    // 2. Preference Match (40 pts max)
    if (_matchesPreference(preferences['dietGoal'], recipe['Diet_Goal_Tag'])) {
      score += 15;
    }
    if (_matchesPreference(preferences['carbPreference'], recipe['Low_Carb'])) {
      score += 10;
    }
    if (_matchesPreference(preferences['spiceLevel'], recipe['Spice_Level'])) {
      score += 10;
    }
    if (_matchesPreference(preferences['mealType'], recipe['Meal_Type'])) {
      score += 5;
    }

    // 3. Behavior Boost (10 pts max)
    final likedMatch =
        ingredients
            .where((ing) => likedIngredients.contains(ing.toLowerCase()))
            .length;
    score += (likedMatch * 2).clamp(0, 10);

    return score;
  }

  // Helper: Parse ingredients from Firestore (handles List<dynamic> or String)
  static List<String> _parseIngredients(dynamic ingredients) {
    if (ingredients is List) {
      return ingredients.map((e) => e.toString().toLowerCase()).toList();
    }
    return ingredients?.toString().split(',').map((e) => e.trim()).toList() ??
        [];
  }

  // Helper: Safe preference matching
  static bool _matchesPreference(String? preference, dynamic recipeValue) {
    if (preference == null || recipeValue == null) return false;
    return recipeValue.toString().toLowerCase().contains(
      preference.toLowerCase(),
    );
  }

  // Updated to handle your schema
  static Future<Set<String>> fetchLikedIngredients(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final history = doc.data()?['history'] as Map<String, dynamic>? ?? {};

    final liked = <String>{};
    final engagedRecipes = [
      ...(history['swipes'] as List? ?? []).where(
        (s) => s['action'] == 'right',
      ),
      ...(history['cooked'] as List? ?? []),
      ...(history['favorites'] as List? ?? []),
    ];

    if (engagedRecipes.isEmpty) return liked;

    final recipes =
        await FirebaseFirestore.instance
            .collection('recipes')
            .where(
              FieldPath.documentId,
              whereIn: engagedRecipes.map((r) => r['id'].toString()).toList(),
            )
            .get();

    for (final doc in recipes.docs) {
      liked.addAll(_parseIngredients(doc['Main_Ingredients']));
    }

    return liked;
  }
}
