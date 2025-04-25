import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelpers {
  static Future<Map<String, String>> getUserPreferences(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return Map<String, String>.from(doc.data()?['preferences'] ?? {});
  }

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

  static Future<void> updateTopIngredients(String userId) async {
    final history =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final swipes = (history.data()?['history']['swipes'] as List?) ?? [];
  }
}
