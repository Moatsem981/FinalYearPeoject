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
        selectedItemColor: Colors.green,
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

// ✅ HomeScreen with AI Meal Suggestion Features
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _features = [
    {
      "icon": Icons.camera_alt,
      "title": "Scan Ingredients",
      "subtitle":
          "Upload food images to get meal suggestions based on your available ingredients.",
      "route": "/scanIngredients",
    },
    {
      "icon": Icons.restaurant,
      "title": "Suggested Meals",
      "subtitle": "AI-generated meal ideas based on your mood or cravings.",
      "route": "/suggestedMeals",
    },
    {
      "icon": Icons.restaurant_menu,
      "title": "Quick Recipes",
      "subtitle": "Discover easy and fast recipes.",
      "route": "/quickRecipes",
    },
    {
      "icon": Icons.analytics,
      "title": "Nutrition Tracker",
      "subtitle": "Monitor your daily food intake and macros.",
      "route": "/nutritionTracker",
    },
  ];

  // List of images for the slider
  final List<String> _sliderImages = [
    "assets/AppMainPic1.jpg",
    "assets/AppMainPic2.jpg",
    "assets/AppMainPic3.jpg",
  ];

  // Track the current page in the slider
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("AI Meal & Nutrition"),
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
              "Welcome to UniMeals 🍽️",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Healthy meals made just for you—based on your mood, taste, and ingredients. Plus, track your nutrition intake!",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Image Slider with Page Indicator
            Column(
              children: [
                SizedBox(
                  height: 200, // Adjust height as needed
                  child: PageView.builder(
                    itemCount: _sliderImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index; // Update the current page index
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            _sliderImages[index],
                            fit:
                                BoxFit
                                    .cover, // Ensure the image covers the area
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  "Error loading image: ${_sliderImages[index]}",
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Page Indicator (Dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _sliderImages.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Colors
                                    .green // Active dot color
                                : Colors.grey, // Inactive dot color
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Feature Grid
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
          padding: const EdgeInsets.all(7.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.green),
              const SizedBox(height: 5),
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
