import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String recipeName;
  final String cleanedIngredients;
  final String ingredients;
  final String instructions;
  final List<String> mainIngredients;
  final String? imageName;
  final Map<String, dynamic> nutritionalInfo;
  final bool isHighProtein;
  final Map<String, dynamic>? estimatedNutrients;
  final String mealType;
  final String spiceLevel;
  final bool isLowCarb;
  final bool isLowCalorie;
  final String? dietGoalTag;
  final List<String>? moodTags;
  final int cookingTimeMin;
  final String difficulty;
  final String cuisine;
  final String servingSize;
  final List<String>? allergens;
  final List<String>? tags;
  final Map<String, dynamic>? vitaminsMinerals;

  Recipe({
    required this.id,
    required this.recipeName,
    required this.cleanedIngredients,
    required this.ingredients,
    required this.instructions,
    required this.mainIngredients,
    this.imageName,
    required this.nutritionalInfo,
    required this.isHighProtein,
    this.estimatedNutrients,
    required this.mealType,
    required this.spiceLevel,
    required this.isLowCarb,
    required this.isLowCalorie,
    this.dietGoalTag,
    this.moodTags,
    required this.cookingTimeMin,
    required this.difficulty,
    required this.cuisine,
    required this.servingSize,
    this.allergens,
    this.tags,
    this.vitaminsMinerals,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Recipe(
      id: doc.id,
      recipeName: data['Recipe Name']?.toString() ?? 'Unnamed Recipe',
      cleanedIngredients: data['Cleaned_Ingredients']?.toString() ?? '',
      ingredients: data['Ingredients']?.toString() ?? '',
      instructions: data['Instructions']?.toString() ?? '',
      mainIngredients: _convertToList(data['Main_Ingredients']),
      imageName: data['Image_Name']?.toString(),
      nutritionalInfo: _convertToMap(data['Nutritional_Info']),
      isHighProtein: data['High_Protein']?.toString() == 'Yes',
      estimatedNutrients: _convertToMap(data['Estimated_Nutrients']),
      mealType: data['Meal_Type']?.toString() ?? 'Other',
      spiceLevel: data['Spice_Level']?.toString() ?? 'Medium',
      isLowCarb: data['Low_Carb']?.toString() == 'Yes',
      isLowCalorie: data['Low_Calorie']?.toString() == 'Yes',
      dietGoalTag: data['Diet_Goal_Tag']?.toString(),
      moodTags: _convertToList(data['Mood_Tags']),
      cookingTimeMin:
          int.tryParse(data['Cooking_Time_Min']?.toString() ?? '30') ?? 30,
      difficulty: data['Difficulty']?.toString() ?? 'Medium',
      cuisine: data['Cuisine']?.toString() ?? 'International',
      servingSize: data['Serving_Size']?.toString() ?? '1 serving',
      allergens: _convertToList(data['Allergens']),
      tags: _convertToList(data['Tags']),
      vitaminsMinerals: _convertToMap(data['Vitamins_Minerals']),
    );
  }

  static List<String> _convertToList(dynamic input) {
    if (input == null) return [];
    if (input is List) return input.map((e) => e.toString()).toList();
    if (input is String) return input.split(',').map((e) => e.trim()).toList();
    return [];
  }

  static Map<String, dynamic> _convertToMap(dynamic input) {
    if (input == null) return {};
    if (input is Map) return Map<String, dynamic>.from(input);
    return {};
  }

  Map<String, dynamic> toMap() {
    return {
      'Recipe Name': recipeName,
      'Cleaned_Ingredients': cleanedIngredients,
      'Ingredients': ingredients,
      'Instructions': instructions,
      'Main_Ingredients': mainIngredients,
      if (imageName != null) 'Image_Name': imageName,
      'Nutritional_Info': nutritionalInfo,
      'High_Protein': isHighProtein ? 'Yes' : 'No',
      if (estimatedNutrients != null) 'Estimated_Nutrients': estimatedNutrients,
      'Meal_Type': mealType,
      'Spice_Level': spiceLevel,
      'Low_Carb': isLowCarb ? 'Yes' : 'No',
      'Low_Calorie': isLowCalorie ? 'Yes' : 'No',
      if (dietGoalTag != null) 'Diet_Goal_Tag': dietGoalTag,
      if (moodTags != null) 'Mood_Tags': moodTags,
      'Cooking_Time_Min': cookingTimeMin,
      'Difficulty': difficulty,
      'Cuisine': cuisine,
      'Serving_Size': servingSize,
      if (allergens != null) 'Allergens': allergens,
      if (tags != null) 'Tags': tags,
      if (vitaminsMinerals != null) 'Vitamins_Minerals': vitaminsMinerals,
    };
  }
}
