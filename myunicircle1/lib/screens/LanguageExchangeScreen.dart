import 'package:flutter/material.dart';

class LanguageExchangeScreen extends StatefulWidget {
  const LanguageExchangeScreen({super.key});

  @override
  _LanguageExchangeScreenState createState() => _LanguageExchangeScreenState();
}

class _LanguageExchangeScreenState extends State<LanguageExchangeScreen> {
  String? selectedLanguage;
  String? selectedLearningLanguage;
  String? searchUsername = "";
  TextEditingController searchController = TextEditingController();

  final List<String> languages = [
    "English",
    "Spanish",
    "French",
    "Chinese",
    "Japanese",
    "German",
    "Korean",
    "Arabic",
  ];

  final List<Map<String, String>> suggestedPartners = [
    {"username": "JohnDoe123", "fluent": "English", "learning": "Spanish"},
    {"username": "LinguaMaster", "fluent": "Chinese", "learning": "English"},
    {"username": "FrenchLover", "fluent": "French", "learning": "Japanese"},
    {"username": "TravelSpeak", "fluent": "Spanish", "learning": "Korean"},
    {"username": "LanguageGuru", "fluent": "Arabic", "learning": "French"},
  ];

  // Filter partners based on search input
  List<Map<String, String>> getFilteredPartners() {
    if (searchUsername == null || searchUsername!.isEmpty) {
      return suggestedPartners; // Show all if search is empty
    }
    return suggestedPartners
        .where(
          (partner) => partner["username"]!.toLowerCase().contains(
            searchUsername!.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: const Text("Language Exchange"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select your languages:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // Native Language Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: selectedLanguage,
              decoration: _dropdownDecoration("Your Native Language"),
              items:
                  languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(
                        lang,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedLanguage = value),
            ),
            const SizedBox(height: 15),

            // Learning Language Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: selectedLearningLanguage,
              decoration: _dropdownDecoration("Language You Want to Learn"),
              items:
                  languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(
                        lang,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged:
                  (value) => setState(() => selectedLearningLanguage = value),
            ),
            const SizedBox(height: 20),

            // Find Partners Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print(
                    "Matching with partners for: $selectedLanguage -> $selectedLearningLanguage",
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F56BB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Find Language Partners",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search for a Friend
            const Text(
              "Search for a friend:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                labelText: "Enter username",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => searchUsername = value);
              },
            ),
            const SizedBox(height: 20),

            // Suggested Partners List
            Expanded(
              child: ListView.builder(
                itemCount: getFilteredPartners().length,
                itemBuilder: (context, index) {
                  final partner = getFilteredPartners()[index];
                  return Card(
                    color: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFF7F56BB),
                      ),
                      title: Text(
                        partner["username"]!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Fluent in ${partner["fluent"]} | Learning ${partner["learning"]}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          print("Connected with ${partner["username"]}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F56BB),
                        ),
                        child: const Text(
                          "Connect",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
