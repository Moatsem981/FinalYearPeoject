import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:myunicircle1/screens/AppFace.dart';

class ChatbotOnboardingScreen extends StatefulWidget {
  @override
  _ChatbotOnboardingScreenState createState() =>
      _ChatbotOnboardingScreenState();
}

class _ChatbotOnboardingScreenState extends State<ChatbotOnboardingScreen> {
  int currentQuestionIndex = -1;
  Map<String, dynamic> userResponses = {};
  bool isTyping = false;
  bool showConfirmation = false;

  final List<Map<String, dynamic>> questions = [
    {"question": "What is your age?", "field": "age", "type": "number"},
    {
      "question": "What is your height (in cm)?",
      "field": "height",
      "type": "number",
    },
    {
      "question": "What is your weight (in kg)?",
      "field": "weight",
      "type": "number",
    },
    {
      "question": "Do you have any food allergies?",
      "field": "allergies",
      "type": "text",
      "hint": "E.g., nuts, dairy, gluten",
    },
    {
      "question": "What is your main food goal?",
      "field": "goal",
      "options": ["High Protein", "More Veggies", "Quick Meals", "Balanced"],
    },
    {
      "question": "Which one of these meals do you prefer?",
      "field": "meal_preference",
      "options": [
        {
          "name": "Crispy Salt and Pepper Potatoes",
          "image": "assets/crispy-salt-and-pepper-potatoes-dan-kluger.jpg",
        },
        {
          "name": "Caramelized Plantain Parfait",
          "image": "assets/caramelized-plantain-parfait.jpg",
        },
        {
          "name": "Kale and Pumpkin Falafels With Pickled Carrot",
          "image":
              "assets/kale-and-pumpkin-falafels-with-pickled-carrot-slaw.jpg",
        },
        {
          "name": "Paneer Curry With Peas",
          "image": "assets/paneer-curry-with-peas-358211.jpg",
        },
        {
          "name": "Tomato and Cabbage Tabbouleh",
          "image": "assets/tomato-and-cabbage-tabbouleh-51239630.jpg",
        },
      ],
      "type": "image_options",
    },
    {
      "question": "Do you follow a specific diet?",
      "field": "diet",
      "options": ["Vegetarian", "Vegan", "Halal", "No Preference"],
    },
    {
      "question": "How much time do you usually have to cook?",
      "field": "time",
      "options": ["<15 mins", "15-30 mins", "30+ mins"],
    },
  ];

  List<Map<String, dynamic>> messages = [];
  TextEditingController _textInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showNextMessage(initial: true);
  }

  @override
  void dispose() {
    _textInputController.dispose();
    super.dispose();
  }

  void _showNextMessage({bool initial = false}) async {
    setState(() => isTyping = true);

    await Future.delayed(Duration(seconds: initial ? 1 : 2));

    if (initial) {
      messages.add({
        "from": "bot",
        "text": "Hi 👋, I'm your nutrition assistant!",
      });
      messages.add({
        "from": "bot",
        "text":
            "I'll help you personalize your meal suggestions to suit your goals.",
      });
    }

    if (currentQuestionIndex + 1 < questions.length) {
      currentQuestionIndex++;
      messages.add({
        "from": "bot",
        "text": questions[currentQuestionIndex]["question"],
      });
    } else {
      _showConfirmation();
    }

    setState(() => isTyping = false);
  }

  void _selectOption(dynamic option) {
    final field = questions[currentQuestionIndex]["field"];
    userResponses[field] = option is Map ? option["name"] : option;

    setState(() {
      messages.add({
        "from": "user",
        "text": option is Map ? option["name"] : option,
      });
    });

    _showNextMessage();
  }

  void _handleTextInput(String text) {
    final field = questions[currentQuestionIndex]["field"];
    userResponses[field] = text;

    setState(() {
      messages.add({"from": "user", "text": text});
      _textInputController.clear();
    });

    _showNextMessage();
  }

  void _showConfirmation() {
    setState(() {
      showConfirmation = true;
      messages.add({
        "from": "bot",
        "text":
            "Here are your preferences. Would you like to save or amend them?",
      });
      messages.add({"from": "bot", "text": _formatPreferences()});
    });
  }

  String _formatPreferences() {
    return userResponses.entries
        .map((entry) {
          return "${entry.key}: ${entry.value}";
        })
        .join("\n");
  }

  void _completeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"preferences": userResponses, "onboardingComplete": true},
      );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppFace()),
    );
  }

  void _amendPreferences() {
    setState(() {
      showConfirmation = false;
      currentQuestionIndex = -1;
      userResponses.clear();
      messages.add({
        "from": "bot",
        "text": "Let's start again. I'll ask you the questions one more time.",
      });
      _showNextMessage();
    });
  }

  Widget _buildImageOption(Map<String, String> option) {
    return GestureDetector(
      onTap: () => _selectOption(option),
      child: Container(
        margin: EdgeInsets.all(8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                option["image"]!,
                width: 120,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8),
            Text(
              option["name"]!,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion =
        currentQuestionIndex >= 0 && currentQuestionIndex < questions.length
            ? questions[currentQuestionIndex]
            : null;

    final isTextInput =
        currentQuestion != null && currentQuestion["type"] == "text";
    final isNumberInput =
        currentQuestion != null && currentQuestion["type"] == "number";
    final hasOptions =
        currentQuestion != null && currentQuestion["options"] != null;
    final isImageOptions =
        currentQuestion != null && currentQuestion["type"] == "image_options";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("Nutrition Assistant"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return _buildTypingIndicator();
                }
                final message = messages[index];
                return Align(
                  alignment:
                      message["from"] == "bot"
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color:
                          message["from"] == "bot"
                              ? Colors.white10
                              : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["text"],
                      style: TextStyle(
                        color:
                            message["from"] == "bot"
                                ? Colors.white70
                                : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!isTyping && !showConfirmation && currentQuestion != null) ...[
            Divider(color: Colors.white30),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isTextInput || isNumberInput) ...[
                    TextField(
                      controller: _textInputController,
                      decoration: InputDecoration(
                        hintText: currentQuestion["hint"] ?? "",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white10,
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType:
                          isNumberInput
                              ? TextInputType.number
                              : TextInputType.text,
                      onSubmitted: _handleTextInput,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        if (_textInputController.text.isNotEmpty) {
                          _handleTextInput(_textInputController.text);
                        }
                      },
                      child: Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  if (hasOptions && !isImageOptions) ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          currentQuestion["options"].map<Widget>((option) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => _selectOption(option),
                              child: Text(
                                option,
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                  if (isImageOptions) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            currentQuestion["options"]
                                .map<Widget>(
                                  (option) => _buildImageOption(option),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (showConfirmation) ...[
            Divider(color: Colors.white30),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: _amendPreferences,
                    child: Text(
                      "Amend Preferences",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: _completeOnboarding,
                    child: Text(
                      "Save Preferences",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Typing...",
          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
