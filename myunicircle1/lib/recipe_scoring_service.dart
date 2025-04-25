// lib/services/recipe_scoring_service.dart
import 'dart:math';

/// Splits a comma-separated tag string into a Set of lowercase tags.
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

/// Calculates a score for a given recipe based on user preferences/context
/// and recently liked/skipped attributes (Cuisine, Meal Type, Mood Tags).
///
/// [recipe]: A map representing the recipe data (from Firestore 'recipes2' collection).
/// [userContext]: A map representing the user's answers from the chatbot.
/// [likedCuisines]: A Set of lowercase cuisine names the user recently liked/saved.
/// [likedMealTypes]: A Set of lowercase meal types the user recently liked/saved.
/// [likedMoodTags]: A Set of lowercase mood tags the user recently liked/saved.
/// [skippedCuisines]: A Set of lowercase cuisine names the user recently skipped.
/// [skippedMealTypes]: A Set of lowercase meal types the user recently skipped.
/// [skippedMoodTags]: A Set of lowercase mood tags the user recently skipped.
/// Returns a double score, where higher means a better match.
double calculateRecipeScore(
  Map<String, dynamic> recipe,
  Map<String, String> userContext,
  Set<String> likedCuisines,
  Set<String> likedMealTypes,
  Set<String> likedMoodTags, // Added
  Set<String> skippedCuisines,
  Set<String> skippedMealTypes,
  Set<String> skippedMoodTags, // Added
) {
  double score = 0.0;
  String recipeName = recipe['Recipe Name'] ?? 'Unknown Recipe';

  // --- User Context Extraction ---
  final String dietGoal = userContext['dietGoal']?.toLowerCase() ?? '';
  final String mealType = userContext['mealType']?.toLowerCase() ?? '';
  final String spiceLevel = userContext['spiceLevel']?.toLowerCase() ?? '';
  final String carbPreference =
      userContext['carbPreference']?.toLowerCase() ?? '';
  final String caloriePreference =
      userContext['caloriePreference']?.toLowerCase() ?? '';
  final String userTime = userContext['userTime']?.toLowerCase() ?? '';
  final String userCuisine = userContext['userCuisine']?.toLowerCase() ?? '';
  final String userSkill = userContext['userSkill']?.toLowerCase() ?? '';
  final String currentMood = userContext['currentMood']?.toLowerCase() ?? '';

  // --- Recipe Data Extraction & Parsing ---
  final int cookingTime = _parseCookingTime(recipe['Cooking_Time_Min']);
  final String difficulty =
      (recipe['Difficulty'] ?? '').toString().toLowerCase();
  final String recipeSpice =
      (recipe['Spice_Level'] ?? '').toString().toLowerCase();
  final String recipeMealType =
      (recipe['Meal_Type'] ?? '').toString().toLowerCase();
  final String recipeCuisine =
      (recipe['Cuisine'] ?? '').toString().toLowerCase();
  // Split recipe's mood tags into a set for easier comparison
  final Set<String> recipeMoodTags = _splitTags(recipe['Mood_Tags']);

  // --- Scoring Rules ---

  // 1. Diet Goal Matching
  if (dietGoal.contains('muscle') && _isYes(recipe, 'High_Protein'))
    score += 20;
  if (dietGoal.contains('weight') && _isYes(recipe, 'Low_Calorie')) score += 15;
  if (dietGoal.isNotEmpty &&
      (recipe['Diet_Goal_Tag'] ?? '').toString().toLowerCase().contains(
        dietGoal,
      )) {
    score += 5;
  }

  // 2. Cooking Time Match
  if (userTime.contains('less than 15 mins') &&
      cookingTime > 0 &&
      cookingTime <= 15) {
    score += 20;
  } else if (userTime.contains('15-30 mins') &&
      cookingTime > 0 &&
      cookingTime <= 30) {
    score += 15;
  }
  if ((userTime.contains('less than 15') || userTime.contains('15-30')) &&
      cookingTime > 45) {
    score -= 10;
  }

  // 3. Cooking Skill Match
  if (userSkill.contains('beginner') && difficulty == 'easy') {
    score += 15;
  }
  if (userSkill.contains('beginner') && difficulty == 'hard') {
    score -= 10;
  }

  // 4. Context Sensitivity (Mood - Direct)
  if ((currentMood.contains('tired') || currentMood.contains('stressed')) &&
      difficulty == 'easy') {
    score += 10;
  }
  if ((currentMood.contains('tired') || currentMood.contains('stressed')) &&
      cookingTime <= 20) {
    score += 10;
  }
  // ADDED: Boost if recipe mood tag matches current mood (e.g., "Comforting" if "Sad")
  // This requires mapping user moods to potential recipe tags
  if (currentMood.contains('happy') && recipeMoodTags.contains('celebratory'))
    score += 5;
  if (currentMood.contains('sad') && recipeMoodTags.contains('comforting'))
    score += 8; // Higher boost for comfort?
  if (currentMood.contains('stressed') && recipeMoodTags.contains('quick'))
    score += 5; // Already handled by time check mostly

  // 5. Cuisine Match (Direct Preference)
  if (userCuisine.isNotEmpty &&
      userCuisine != 'anything!' &&
      recipeCuisine.contains(userCuisine)) {
    score += 10;
  }

  // 6. Meal Type (Basic Match)
  if (mealType.isNotEmpty &&
      mealType != "i'm open to anything!" &&
      recipeMealType.contains(mealType)) {
    score += 5;
  }

  // 7. Spice Level Match
  if (spiceLevel == 'no spice please' &&
      (recipeSpice.contains('none') ||
          recipeSpice.contains('mild') ||
          recipeSpice.isEmpty)) {
    score += 10;
  } else if (spiceLevel.contains('very spicy') &&
      (recipeSpice.contains('high') ||
          recipeSpice.contains('hot') ||
          recipeSpice.contains('very spicy'))) {
    score += 15;
  } else if (spiceLevel.isNotEmpty &&
      !spiceLevel.contains('sweet') &&
      recipeSpice.contains(spiceLevel.split(' ')[0])) {
    score += 10;
  }

  // 8. Carb Preference Match
  if (carbPreference.contains('low') && _isYes(recipe, 'Low_Carb')) {
    score += 10;
  }

  // 9. Calorie Preference Match
  if (caloriePreference.contains('light') && _isYes(recipe, 'Low_Calorie')) {
    score += 10;
  }

  // --- History-Based Adjustments ---
  double historyBoost = 0;
  double historyPenalty = 0;
  String debugHistory = ""; // For optional debug print

  // Cuisine History
  if (recipeCuisine.isNotEmpty) {
    if (likedCuisines.contains(recipeCuisine)) historyBoost += 5;
    if (skippedCuisines.contains(recipeCuisine)) historyPenalty -= 7;
  }
  // Meal Type History
  if (recipeMealType.isNotEmpty) {
    if (likedMealTypes.contains(recipeMealType)) historyBoost += 5;
    if (skippedMealTypes.contains(recipeMealType)) historyPenalty -= 7;
  }
  // Mood Tag History
  // Check intersection between recipe tags and liked/skipped tags
  if (recipeMoodTags.isNotEmpty) {
    if (recipeMoodTags.any((tag) => likedMoodTags.contains(tag)))
      historyBoost += 3; // Smaller boost for mood tag match
    if (recipeMoodTags.any((tag) => skippedMoodTags.contains(tag)))
      historyPenalty -= 5; // Smaller penalty for mood tag match
  }

  // Apply history adjustments
  score += historyBoost;
  score += historyPenalty;

  // --- Debug Print (Optional) ---
  // if (historyBoost > 0 || historyPenalty < 0) {
  //   debugHistory = "(Boost: $historyBoost, Penalty: $historyPenalty)";
  // }
  // print("Recipe: $recipeName, Score: $score $debugHistory");

  return score;
}

// --- Helper Functions ---

int _parseCookingTime(dynamic timeValue) {
  if (timeValue == null) return 999;
  if (timeValue is num) return timeValue.toInt();
  String timeString = timeValue.toString();
  final match = RegExp(r'\d+').firstMatch(timeString);
  if (match != null) {
    return int.tryParse(match.group(0)!) ?? 999;
  }
  return 999;
}

bool _isYes(Map<String, dynamic> recipe, String field) {
  final value = recipe[field];
  if (value == null) return false;
  if (value is bool) return value;
  return ['yes', 'true', '1'].contains(value.toString().trim().toLowerCase());
}
