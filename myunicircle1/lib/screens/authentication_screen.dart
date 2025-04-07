import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myunicircle1/screens/AppFace.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;

  void _authenticate() async {
    setState(() => isLoading = true);

    try {
      UserCredential userCredential;

      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // 🔹 Fetch user data from Firestore on login
        DocumentSnapshot userDoc =
            await _firestore
                .collection("users")
                .doc(userCredential.user!.uid)
                .get();

        if (userDoc.exists) {
          print("✅ User logged in: ${userDoc["username"]}");
        }
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // 🔹 Save user data to Firestore
        await _firestore.collection("users").doc(userCredential.user!.uid).set({
          "username": usernameController.text.trim(),
          "email": emailController.text.trim(),
          "profileImage": "",
          "createdAt": Timestamp.now(),
        });

        print("✅ New user added to Firestore!");
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (isLogin) {
          // Go straight to app if logging in
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AppFace()),
          );
        } else {
          // Go to onboarding if it's a new signup
          Navigator.pushReplacementNamed(context, "/chatbotOnboarding");
        }
      }
    } catch (error) {
      _showErrorDialog(error.toString());
    }

    setState(() => isLoading = false);
  }

  void _resetPassword() async {
    if (emailController.text.isEmpty) {
      _showErrorDialog("Please enter your email to reset your password.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      _showSuccessDialog("A password reset email has been sent.");
    } catch (error) {
      _showErrorDialog(error.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text("Error", style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text("Success", style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: Text(isLogin ? "Login" : "Sign Up"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset("assets/UNICIRCLELOGO2.png", height: 150, width: 150),
              const SizedBox(height: 30),

              if (!isLogin)
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Username"),
                ),
              const SizedBox(height: 20),

              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Email"),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: _inputDecoration("Password"),
              ),
              const SizedBox(height: 10),

              if (isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Color(0xFF7F56BB)),
                    ),
                  ),
                ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F56BB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            isLogin ? "Login" : "Sign Up",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  setState(() => isLogin = !isLogin);
                },
                child: Text(
                  isLogin
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Login",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
