import 'package:flutter/material.dart';

class NearbyFriendsScreen extends StatefulWidget {
  const NearbyFriendsScreen({super.key});

  @override
  _NearbyFriendsScreenState createState() => _NearbyFriendsScreenState();
}

class _NearbyFriendsScreenState extends State<NearbyFriendsScreen> {
  final List<Map<String, dynamic>> nearbyFriends = [
    {
      "name": "Sophia Zhang",
      "interest": "Technology & AI",
      "distance": "0.5 km away",
      "image": "assets/user1.jpg",
    },
    {
      "name": "Liam Smith",
      "interest": "Sports & Fitness",
      "distance": "1.2 km away",
      "image": "assets/user2.jpg",
    },
    {
      "name": "Emma Johnson",
      "interest": "Music & Arts",
      "distance": "2.0 km away",
      "image": "assets/user3.jpg",
    },
    {
      "name": "Lucas Wang",
      "interest": "Gaming & Esports",
      "distance": "2.5 km away",
      "image": "assets/user4.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: const Text("Nearby Friends"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              "Find students near you and connect instantly!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            // Nearby Friends List
            Expanded(
              child: ListView.builder(
                itemCount: nearbyFriends.length,
                itemBuilder: (context, index) {
                  final friend = nearbyFriends[index];
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
                        backgroundImage: AssetImage(friend["image"]),
                      ),
                      title: Text(
                        friend["name"],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend["interest"],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            friend["distance"],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          print("Connecting with ${friend["name"]}");
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
}
