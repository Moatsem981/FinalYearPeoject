import 'package:flutter/material.dart';
import '../utils/UploadRecipes.dart'; // Import RecipeUploader

class UploadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Recipes")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await RecipeUploader.uploadRecipesToFirestore();
              },
              child: Text("Upload Recipes"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await RecipeUploader.verifyFirestoreConnection();
              },
              child: Text("Verify Firestore"),
            ),
          ],
        ),
      ),
    );
  }
}
