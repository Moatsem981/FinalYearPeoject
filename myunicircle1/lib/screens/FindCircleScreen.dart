import 'package:flutter/material.dart';

class FindCircleScreen extends StatefulWidget {
  const FindCircleScreen({super.key});

  @override
  _FindCircleScreenState createState() => _FindCircleScreenState();
}

class _FindCircleScreenState extends State<FindCircleScreen> {
  String? selectedInterest;
  String? selectedLanguage;
  String? selectedLocation;

  final List<String> interests = [
    "Sports",
    "Music",
    "Technology",
    "Gaming",
    "Art",
    "Travel",
    "Food",
  ];
  final List<String> languages = [
    "English",
    "Spanish",
    "French",
    "Chinese",
    "Japanese",
  ];
  final List<String> locations = [
    "Campus",
    "City Center",
    "Library",
    "Cafe",
    "Online",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: const Text("Find a Circle"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select your preferences:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // Interest Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: selectedInterest,
              decoration: _dropdownDecoration("Interest"),
              items:
                  interests.map((interest) {
                    return DropdownMenuItem(
                      value: interest,
                      child: Text(
                        interest,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedInterest = value),
            ),
            const SizedBox(height: 15),

            // Language Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: selectedLanguage,
              decoration: _dropdownDecoration("Preferred Language"),
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

            // Location Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: selectedLocation,
              decoration: _dropdownDecoration("Location"),
              items:
                  locations.map((loc) {
                    return DropdownMenuItem(
                      value: loc,
                      child: Text(
                        loc,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedLocation = value),
            ),
            const SizedBox(height: 20),

            // Search Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print(
                    "Searching Circles for: $selectedInterest, $selectedLanguage, $selectedLocation",
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
                  "Find Circles",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Suggested Circles (Placeholder)
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Placeholder: 5 suggested circles
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.group,
                        color: Color(0xFF7F56BB),
                      ),
                      title: Text(
                        "Circle ${index + 1}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "A group of students interested in $selectedInterest",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          print("Joined Circle ${index + 1}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F56BB),
                        ),
                        child: const Text(
                          "Join",
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
