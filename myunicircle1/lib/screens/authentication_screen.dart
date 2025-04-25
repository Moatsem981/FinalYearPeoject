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
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      UserCredential userCredential;

      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        DocumentSnapshot userDoc =
            await _firestore
                .collection("users")
                .doc(userCredential.user!.uid)
                .get();

        if (userDoc.exists) {
          String username = userDoc.get('username') ?? 'User';
          print("User logged in: $username");
        } else {
          print("User logged in, but no Firestore profile found.");
        }
      } else {
        if (usernameController.text.trim().isEmpty) {
          _showErrorDialog("Please enter a username to sign up.");
          setState(() => isLoading = false);
          return;
        }

        userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await _firestore.collection("users").doc(userCredential.user!.uid).set({
          "username": usernameController.text.trim(),
          "email": emailController.text.trim(),
          "profileImage": "",
          "createdAt": Timestamp.now(),
        });

        print(" New user created and added to Firestore!");
      }

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        if (isLogin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppFace()),
          );
        } else {
          Navigator.pushReplacementNamed(context, "/chatbotOnboarding");
        }
      }
    } on FirebaseAuthException catch (error) {
      String errorMessage = "An error occurred. Please try again.";
      if (error.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (error.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else if (error.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (error.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (error.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      print(" Authentication Error: ${error.code} - ${error.message}");
      _showErrorDialog(errorMessage);
    } catch (error) {
      print(" General Error during authentication: $error");
      _showErrorDialog("An unexpected error occurred: ${error.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog(
        "Please enter your email address to reset your password.",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccessDialog(
        "A password reset link has been sent to $email. Please check your inbox (and spam folder).",
      );
    } on FirebaseAuthException catch (error) {
      String errorMessage = "Failed to send reset email. Please try again.";
      if (error.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (error.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      print(" Password Reset Error: ${error.code} - ${error.message}");
      _showErrorDialog(errorMessage);
    } catch (error) {
      print(" General Error during password reset: $error");
      _showErrorDialog("An unexpected error occurred during password reset.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Error",
              style: TextStyle(color: Colors.redAccent),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Success",
              style: TextStyle(color: Colors.greenAccent),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Colors.green;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: Text(isLogin ? "Login" : "Sign Up"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // *** IMAGE WIDGET ***
                Image.asset(
                  "assets/plate.png",
                  height: 180,

                  color: primaryGreen,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.restaurant_menu,
                        size: 150,
                        color: primaryGreen,
                      ),
                ),
                const SizedBox(height: 40),

                if (!isLogin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Username"),
                      keyboardType: TextInputType.text,
                    ),
                  ),

                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Email"),
                  keyboardType: TextInputType.emailAddress,
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
                      onPressed: isLoading ? null : _resetPassword,
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: primaryGreen),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                            : Text(isLogin ? "Login" : "Sign Up"),
                  ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            setState(() => isLogin = !isLogin);
                          },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
