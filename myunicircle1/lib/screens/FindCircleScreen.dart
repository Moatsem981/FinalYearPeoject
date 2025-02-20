import 'package:flutter/material.dart';
import 'dart:math';

class FindCircleScreen extends StatefulWidget {
  const FindCircleScreen({super.key});

  @override
  _FindCircleScreenState createState() => _FindCircleScreenState();
}

class _FindCircleScreenState extends State<FindCircleScreen> {
  String? selectedInterest;
  String? selectedLanguage;
  String? selectedActivityType;
  String? selectedSize;
  String searchCircleName = "";

  TextEditingController searchController = TextEditingController();
  TextEditingController circleNameController = TextEditingController();
  List<Map<String, dynamic>> joinedCircles = [];

  final List<String> interests = [
    "Sports",
    "Music",
    "Technology",
    "Gaming",
    "Art",
    "Travel",
    "Food",
    "Academics",
    "Networking",
  ];

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

  final List<String> activityTypes = [
    "Study Group",
    "Casual Hangout",
    "Career Networking",
    "Gaming Session",
    "Online Community",
  ];

  final List<String> sizes = ["Small (2-10)", "Medium (11-50)", "Large (50+)"];

  List<Map<String, dynamic>> circles = [
    {
      "name": "Tech Innovators",
      "description": "A group for tech enthusiasts and innovators!",
      "interest": "Technology",
      "language": "English",
      "activity": "Career Networking",
      "size": "Medium (11-50)",
    },
    {
      "name": "Gaming Buddies",
      "description": "Casual gaming sessions every weekend!",
      "interest": "Gaming",
      "language": "English",
      "activity": "Gaming Session",
      "size": "Small (2-10)",
    },
    {
      "name": "Music Lovers",
      "description": "Jam sessions, music talks, and concerts!",
      "interest": "Music",
      "language": "Spanish",
      "activity": "Casual Hangout",
      "size": "Large (50+)",
    },
  ];

  List<Map<String, dynamic>> getFilteredCircles() {
    return circles.where((circle) {
      return (searchCircleName.isEmpty ||
              circle["name"].toLowerCase().contains(
                searchCircleName.toLowerCase(),
              ) ||
              circle["description"].toLowerCase().contains(
                searchCircleName.toLowerCase(),
              )) &&
          (selectedInterest == null ||
              circle["interest"] == selectedInterest) &&
          (selectedLanguage == null ||
              circle["language"] == selectedLanguage) &&
          (selectedActivityType == null ||
              circle["activity"] == selectedActivityType) &&
          (selectedSize == null || circle["size"] == selectedSize);
    }).toList();
  }

  void _showCreateCircleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Create New Circle",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: circleNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Circle Name"),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                value: selectedInterest,
                decoration: _inputDecoration("Select Interest"),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (circleNameController.text.isNotEmpty &&
                    selectedInterest != null) {
                  setState(() {
                    circles.add({
                      "name": circleNameController.text,
                      "description": "A new circle for ${selectedInterest!}",
                      "interest": selectedInterest!,
                      "language": "English",
                      "activity": "Casual Hangout",
                      "size": "Small (2-10)",
                    });
                  });
                  circleNameController.clear();
                  selectedInterest = null;
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Create",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              "Circles",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            Text(
              "Find a Circle",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showCreateCircleDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 **Search Bar**
            TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                "Search by Circle Name or Description",
              ),
              onChanged: (value) => setState(() => searchCircleName = value),
            ),
            const SizedBox(height: 20),

            // 📌 **Advanced Filters**
            _buildFilterDropdown(
              "Filter by Interest",
              selectedInterest,
              interests,
              (val) {
                setState(() => selectedInterest = val);
              },
            ),
            const SizedBox(height: 10),
            _buildFilterDropdown(
              "Filter by Language",
              selectedLanguage,
              languages,
              (val) {
                setState(() => selectedLanguage = val);
              },
            ),
            const SizedBox(height: 10),
            _buildFilterDropdown(
              "Filter by Activity Type",
              selectedActivityType,
              activityTypes,
              (val) {
                setState(() => selectedActivityType = val);
              },
            ),
            const SizedBox(height: 20),

            // 📃 **Filtered Results**
            Expanded(
              child: ListView.builder(
                itemCount: getFilteredCircles().length,
                itemBuilder: (context, index) {
                  final circle = getFilteredCircles()[index];
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
                        circle["name"],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        circle["description"],
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: ElevatedButton(
                        onPressed:
                            () => setState(() => joinedCircles.add(circle)),
                        child: const Text("Join"),
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

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.black,
      value: value,
      decoration: _inputDecoration(label),
      items:
          items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white10,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );
}
