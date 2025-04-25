import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InitialRedirectScreen extends StatefulWidget {
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/auth');
    } else {
      final userDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get();

      final onboardingComplete = userDoc.data()?["onboardingComplete"] ?? false;

      if (onboardingComplete) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/chatbotOnboarding');
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
