import 'package:flutter/material.dart';
import 'package:myunicircle1/screens/ProfileScreen.dart';

class AppFace extends StatefulWidget {
  const AppFace({super.key});

  @override
  _AppFaceState createState() => _AppFaceState();
}

class _AppFaceState extends State<AppFace> {
  int _selectedIndex = 0; // Track selected tab

  final List<Widget> _screens = [
    HomeScreen(), // Home content with features
    SearchScreen(), // Search Page (Placeholder)
    const ProfileScreen(), // Profile Page
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF7F56BB),
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// ✅ HomeScreen with All Features
class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _features = [
    {
      "icon": Icons.group,
      "title": "Find a Circle",
      "subtitle": "Find like-minded students and grow your network.",
      "route": "/findCircle",
    },
    {
      "icon": Icons.translate,
      "title": "Language Exchange",
      "subtitle": "Practice new languages and connect with native speakers.",
      "route": "/languageExchange",
    },
    {
      "icon": Icons.event,
      "title": "Events",
      "subtitle": "Join student-friendly events in your city and campus.",
      "route": "/eventsScreen",
    },
    {
      "icon": Icons.map,
      "title": "Nearby Friends",
      "subtitle": "Connect with students near you and grow your circle.",
      "route": "/nearbyFriends",
    },
    {
      "icon": Icons.book,
      "title": "Smart Study Planner",
      "subtitle": "AI-powered study scheduling & productivity tracking.",
      "route": "/SmartStudyPlanner",
    },
    {
      "icon": Icons.analytics,
      "title": "Social Insights",
      "subtitle": "Track your connections & events participation over time.",
      "route": "/socialInsights",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: const Text("MyUniCircle"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              print("Notifications Clicked");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back, Student! 🎓",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Find new friends, join events, and engage in meaningful conversations!",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                return _buildFeatureCard(
                  context,
                  _features[index]["icon"] as IconData,
                  _features[index]["title"] as String,
                  _features[index]["subtitle"] as String,
                  _features[index]["route"] as String?,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String? route,
  ) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Card(
        color: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF7F56BB)),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ SearchScreen Placeholder
class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Search Screen (Coming Soon!)",
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
