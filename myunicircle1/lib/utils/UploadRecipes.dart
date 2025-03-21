import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

class RecipeUploader {
  static const String collectionName = "recipes";

  static Future<void> uploadRecipesToFirestore() async {
    try {
      print("🔄 Starting recipe upload...");

      // ✅ Load CSV file from assets
      final String csvData = await rootBundle.loadString(
        'assets/healthy_fruit_veg_recipes_FINAL.csv',
      );
      print("📂 CSV file loaded successfully!");

      // ✅ Convert CSV to List
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvData,
      );

      // ✅ Ensure headers exist
      if (csvTable.isEmpty || csvTable.first.length < 2) {
        print("❌ CSV format is incorrect!");
        return;
      }

      // ✅ Extract headers (column names)
      List<String> headers = csvTable.first.map((e) => e.toString()).toList();
      print("📌 CSV Headers: $headers");

      // ✅ Get Firestore reference
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final CollectionReference recipesCollection = _firestore.collection(
        collectionName,
      );

      // ✅ Upload each row as a Firestore document
      for (int i = 1; i < csvTable.length; i++) {
        Map<String, dynamic> recipeData = {};

        for (int j = 0; j < headers.length; j++) {
          recipeData[headers[j]] =
              csvTable[i][j].toString(); // Convert values to String
        }

        print(
          "📤 Uploading recipe $i: ${recipeData['Recipe Name'] ?? 'Unknown'}",
        );

        // ✅ Use set() instead of add() for better debugging
        await recipesCollection.doc("recipe_${i}").set(recipeData);
        print("✅ Recipe $i uploaded successfully!");
      }

      print("✅ All recipes uploaded successfully to Firestore!");
    } catch (e) {
      print("❌ Error uploading recipes: $e");
    }
  }

  static Future<void> verifyFirestoreConnection() async {
    try {
      print("🔄 Checking Firestore connection...");

      // ✅ Write a test document to a "test_connection" collection
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      await _firestore.collection("test_connection").doc("ping").set({
        "status": "connected",
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("✅ Firestore connection is working!");
    } catch (e) {
      print("❌ Firestore connection failed: $e");
    }
  }
}
