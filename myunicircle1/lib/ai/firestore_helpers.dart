import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelpers {
  // Fetch user preferences (for both flows)
  static Future<Map<String, String>> getUserPreferences(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return Map<String, String>.from(doc.data()?['preferences'] ?? {});
  }

  // Update swipe history (called from RecipeSwipesScreen)
  static Future<void> logSwipe({
    required String userId,
    required String recipeId,
    required bool isLiked,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'history.swipes': FieldValue.arrayUnion([
        {
          'id': recipeId,
          'action': isLiked ? 'right' : 'left',
          'timestamp': FieldValue.serverTimestamp(),
        },
      ]),
    });
  }

  // Weekly ingredient booster (optional)
  static Future<void> updateTopIngredients(String userId) async {
    final history =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final swipes = (history.data()?['history']['swipes'] as List?) ?? [];

    // Logic to find top 3 ingredients from swipes/cooked
    // ... (implement if using weekly boosting)
  }
}
