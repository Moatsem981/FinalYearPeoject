import 'package:flutter/material.dart';

class GroupChatsScreen extends StatefulWidget {
  const GroupChatsScreen({super.key});

  @override
  _GroupChatsScreenState createState() => _GroupChatsScreenState();
}

class _GroupChatsScreenState extends State<GroupChatsScreen> {
  String? selectedFilter = "All"; // Default filter
  final List<String> filters = ["All", "Tech", "Music", "Gaming", "Travel"];

  final List<Map<String, dynamic>> chatGroups = [
    {
      "name": "Tech Enthusiasts 💻",
      "category": "Tech",
      "members": "23 Members",
      "lastMessage": "AI is the future! 🚀",
      "moderation": "AI Moderated",
      "image": "assets/chat1.jpg",
    },
    {
      "name": "Music Lovers 🎵",
      "category": "Music",
      "members": "18 Members",
      "lastMessage": "What’s your favorite band? 🎸",
      "moderation": "AI Moderated",
      "image": "assets/chat2.jpg",
    },
    {
      "name": "Gamers Unite 🎮",
      "category": "Gaming",
      "members": "32 Members",
      "lastMessage": "Who’s up for a match tonight? ⚔",
      "moderation": "Community Moderated",
      "image": "assets/chat3.jpg",
    },
    {
      "name": "Travel Explorers 🌍",
      "category": "Travel",
      "members": "14 Members",
      "lastMessage": "Best city to visit this year? ✈",
      "moderation": "AI Moderated",
      "image": "assets/chat4.jpg",
    },
  ];

  // ✅ Filter chats based on category selection
  List<Map<String, dynamic>> getFilteredChats() {
    if (selectedFilter == "All") return chatGroups;
    return chatGroups
        .where((chat) => chat["category"] == selectedFilter)
        .toList();
  }

  void _createGroupChat() {
    showDialog(
      context: context,
      builder: (context) {
        String? groupName;
        String? category = filters[1]; // Default to first category

        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            "Create Group Chat",
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Group Name",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) => groupName = value,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                value: category,
                decoration: InputDecoration(
                  labelText: "Category",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items:
                    filters
                        .where(
                          (f) => f != "All",
                        ) // Exclude "All" from selection
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) => category = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (groupName != null && groupName!.isNotEmpty) {
                  setState(() {
                    chatGroups.add({
                      "name": groupName!,
                      "category": category,
                      "members": "1 Member",
                      "lastMessage": "Welcome to $groupName!",
                      "moderation": "New Group",
                      "image": "assets/chat_default.jpg",
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F56BB),
              ),
              child: const Text(
                "Create",
                style: TextStyle(color: Colors.white),
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
        title: const Text("Group Chats"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createGroupChat, // Create a new group chat
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Dropdown
            DropdownButtonFormField<String>(
              dropdownColor: Colors.black,
              value: selectedFilter,
              decoration: InputDecoration(
                labelText: "Filter by Category",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items:
                  filters.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(
                        filter,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedFilter = value),
            ),
            const SizedBox(height: 15),

            // Chat Groups List
            Expanded(
              child: ListView.builder(
                itemCount: getFilteredChats().length,
                itemBuilder: (context, index) {
                  final chat = getFilteredChats()[index];
                  return Card(
                    color: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(chat["image"]),
                      ),
                      title: Text(
                        chat["name"],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat["category"], // ✅ Now showing the category!
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            chat["members"],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            chat["lastMessage"],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          print("Joining ${chat["name"]}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F56BB),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
}
