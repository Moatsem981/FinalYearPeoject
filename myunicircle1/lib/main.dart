import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myunicircle1/screens/authentication_screen.dart';
import 'package:myunicircle1/screens/AppFace.dart';
import 'package:myunicircle1/screens/scanIngredients.dart';
import 'package:myunicircle1/screens/SuggestedMeals.dart';
import 'package:myunicircle1/screens/ChatbotOnboardingScreen.dart';
import 'package:myunicircle1/screens/SocialInsights.dart';
import 'package:myunicircle1/screens/ProfileScreen.dart';
import 'package:myunicircle1/screens/SuggestedMeals.dart' as suggestedMeals;
import 'package:myunicircle1/screens/InitialRedirectScreen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ add this
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("🔥 Firebase Initialized Successfully!");
  } catch (e) {
    print("🔥 Firebase Initialization Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uni Circle',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthenticationScreen(),

      routes: {
        "/scanIngredients": (context) => ScanIngredientsScreen(),
        "/suggestedMeals":
            (context) => const suggestedMeals.SuggestedMealsScreen(),
        "/socialInsights": (context) => const SocialInsightsScreen(),
        "/profileScreen": (context) => const ProfileScreen(),
        "/chatbotOnboarding": (context) => ChatbotOnboardingScreen(),
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                // Logo at the top
                Image.asset(
                  "assets/UNICIRCLELOGO2.png",
                  height: 210,
                  width: 210,
                ),
                const SizedBox(height: 20),

                // App Title
                const Text(
                  "Welcome to Uni Circle",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7F56BB),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  "Connect with students based on shared interests, "
                  "language preferences, and social activities. "
                  "Build friendships and expand your university network effortlessly!",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthenticationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7F56BB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InitialRedirectScreen extends StatefulWidget {
  const InitialRedirectScreen({super.key});

  @override
  _InitialRedirectScreenState createState() => _InitialRedirectScreenState();
}

class _InitialRedirectScreenState extends State<InitialRedirectScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(Duration(seconds: 1)); // Optional: show splash effect

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthenticationScreen()),
      );
    } else {
      final userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      final onboardingComplete = userDoc.data()?["onboardingComplete"] ?? false;

      if (onboardingComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppFace()),
        );
      } else {
        Navigator.pushReplacementNamed(context, "/chatbotOnboarding");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.green)),
    );
  }
}
