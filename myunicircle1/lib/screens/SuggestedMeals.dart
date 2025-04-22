import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:myunicircle1/screens/RecipeSwipesScreen.dart';
import 'dart:io';
import 'package:myunicircle1/screens/RecipeDetailScreen.dart';

class MealChatbotScreen extends StatefulWidget {
  const MealChatbotScreen({super.key});

  @override
  _MealChatbotScreenState createState() => _MealChatbotScreenState();
}

class _MealChatbotScreenState extends State<MealChatbotScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _context = {};
  bool _isLoading = false;
  bool _isTyping = false;
  AnimationController? _typingAnimationController;
  Animation<double>? _typingAnimation;

  // Conversation flow state
  int _currentQuestionIndex = 0;

  // Colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color botBubbleColor = Color(0xFFFAFAFA);
  static const Color textColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);

  // Questions in a conversational tone
  final List<Map<String, dynamic>> _questions = [
    {
      'text': "Hey there! I'm your Meal Buddy 🍽️\nWhat's your name?",
      'isMultipleChoice': false,
      'options': null,
      'storageKey': 'name',
    },
    {
      'text': "Nice to meet you! How are you feeling today?",
      'isMultipleChoice': true,
      'options': [
        "Hungry 😋",
        "Craving something specific 🧐",
        "Not sure, surprise me! 🤷",
      ],
      'storageKey': 'currentMood',
    },
    {
      'text': "Got it! What kind of meal are you in the mood for?",
      'isMultipleChoice': true,
      'options': [
        "Something light and fresh 🥗",
        "A hearty, filling meal 🍛",
        "Quick and easy 🍕",
        "I'm open to anything!",
      ],
      'storageKey': 'mealType',
    },
    {
      'text': "How about spice level? Do you like it hot? 🔥",
      'isMultipleChoice': true,
      'options': [
        "Bring the heat! 🔥",
        "Medium spice is perfect 🌶️",
        "Just a little kick",
        "No spice please",
        "I have a sweet tooth 🍭",
      ],
      'storageKey': 'spiceLevel',
    },
    {
      'text': "Any preferences on carbs or protein?",
      'isMultipleChoice': true,
      'options': [
        "More carbs please 🍞",
        "High protein 🥩",
        "Low carb for me",
        "Balance is good",
        "I don't really mind",
      ],
      'storageKey': 'carbPreference',
    },
    {
      'text': "Thinking about calories?",
      'isMultipleChoice': true,
      'options': ["Load 'em up! 💪", "Keep it light", "Not really concerned"],
      'storageKey': 'caloriePreference',
    },
    {
      'text': "What's your diet goal right now?",
      'isMultipleChoice': true,
      'options': [
        "Losing weight ⚖️",
        "Building muscle 💪",
        "Maintaining",
        "Just eating happy 😊",
      ],
      'storageKey': 'dietGoal',
    },
    {
      'text':
          "Any food allergies or things you avoid? (If none, just say 'no')",
      'isMultipleChoice': false,
      'options': null,
      'storageKey': 'allergies',
    },
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController!,
      curve: Curves.easeInOut,
    );
    _loadPreviousContext();
    _addBotMessage(_questions[_currentQuestionIndex]['text']);
  }

  @override
  void dispose() {
    _typingAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousContext() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists && doc.data()?['lastMealContext'] != null) {
          setState(() {
            _context.addAll(
              Map<String, String>.from(doc.data()!['lastMealContext']),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading previous context: $e');
    }
  }

  Future<void> _saveContextToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastMealContext': _context,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving context: $e');
    }
  }

  void _addBotMessage(String text) {
    _messages.add(
      ChatMessage(
        text: text,
        isUser: false,
        animationController: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
    _messages.last.animationController?.forward();
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    _messages.add(
      ChatMessage(
        text: text,
        isUser: true,
        animationController: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
    _messages.last.animationController?.forward();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleTextInput(String text) async {
    if (text.trim().isEmpty) return;

    _addUserMessage(text);
    _textController.clear();

    // Store the response
    final currentQuestion = _questions[_currentQuestionIndex];
    final key = currentQuestion['storageKey'] as String;
    _context[key] = text;

    // Save to Firestore
    await _saveContextToFirestore();

    // Move to next question or generate suggestion
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _showTypingIndicator();
      await Future.delayed(const Duration(milliseconds: 800));
      _hideTypingIndicator();
      _addBotMessage(_questions[_currentQuestionIndex]['text']);
      if (_questions[_currentQuestionIndex]['isMultipleChoice']) {
        _showOptions(_questions[_currentQuestionIndex]['options']);
      }
    } else {
      await _generateMealSuggestion();
    }
  }

  void _showTypingIndicator() {
    setState(() {
      _isTyping = true;
    });
  }

  void _hideTypingIndicator() {
    setState(() {
      _isTyping = false;
    });
  }

  void _showOptions(List<String>? options) {
    if (options == null) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Choose an option:",
            isUser: false,
            options: options,
            animationController: AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 300),
            ),
          ),
        );
        _messages.last.animationController?.forward();
      });
      _scrollToBottom();
    });
  }

  Future<void> _generateMealSuggestion() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch all recipes
      final recipesCollection = FirebaseFirestore.instance.collection(
        "recipes2",
      );
      final querySnapshot = await recipesCollection.get();

      final allRecipes =
          querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

      // 2. Score each recipe
      final scored =
          allRecipes.map((recipe) {
            return {'data': recipe, 'score': _scoreRecipe(recipe, _context)};
          }).toList();

      // 3. Filter out allergens
      final allergy = _context['allergies']?.toLowerCase();
      final filtered =
          scored.where((entry) {
            if (allergy != null && allergy != 'no') {
              // inside your filter or loop:
              final data = entry['data'] as Map<String, dynamic>;
              final allergenField =
                  (data['Allergens'] ?? '').toString().toLowerCase();

              return !allergenField.contains(allergy);
            }
            return true;
          }).toList();

      if (filtered.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No suitable recipes found.")),
        );
        return;
      }

      // 4. Sort by score (highest first) and take top 10
      filtered.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );
      final topRecipes =
          filtered
              .take(10)
              .map((e) => e['data'] as Map<String, dynamic>)
              .toList();

      // 5. Navigate to the swipe screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => RecipeSwipesScreen(
                recipes: topRecipes, // <-- correct param name
                scannedImage: File(''), // <-- you must pass a File
                onSaveForLater: (recipe) => _saveRecipeToFirestore(recipe),
                onViewRecipe: (recipe) => _showRecipeDetails(context, recipe),
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching recipes: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Helper: convert any recipe[field] to a lowercase String
  String _asString(Map<String, dynamic> recipe, String field) {
    final v = recipe[field];
    return v == null ? '' : v.toString().toLowerCase();
  }

  /// Helper: check if recipe[field] == "yes" (case‐insensitive)
  bool _isYes(Map<String, dynamic> recipe, String field) {
    return _asString(recipe, field) == 'yes';
  }

  /// Robust cooking‐time parser
  int _cookingTime(Map<String, dynamic> recipe) {
    final raw = recipe['Cooking_Time_Min'];
    if (raw is num) return raw.toInt();
    final parsed = int.tryParse(raw?.toString() ?? '');
    return parsed ?? 0;
  }

  double _scoreRecipe(Map<String, dynamic> recipe, Map<String, String> ctx) {
    double score = 0;

    final dietGoal = ctx['dietGoal']?.toLowerCase() ?? '';
    final mealType = ctx['mealType']?.toLowerCase() ?? '';
    final spice = ctx['spiceLevel']?.toLowerCase() ?? '';
    final carbPref = ctx['carbPreference']?.toLowerCase() ?? '';
    final calPref = ctx['caloriePreference']?.toLowerCase() ?? '';

    // Diet goal
    if (dietGoal.contains('muscle') && _isYes(recipe, 'High_Protein')) {
      score += 20;
    }
    if (dietGoal.contains('weight') && _isYes(recipe, 'Low_Calorie')) {
      score += 15;
    }

    // Meal type
    if (mealType.isNotEmpty &&
        _asString(recipe, 'Meal_Type').contains(mealType)) {
      score += 10;
    }

    // Spice level
    if (spice.isNotEmpty && _asString(recipe, 'Spice_Level').contains(spice)) {
      score += 10;
    }

    // Carb preference
    if (carbPref.contains('low') && _isYes(recipe, 'Low_Carb')) {
      score += 8;
    }

    // Calorie preference
    if (calPref.contains('light') && _isYes(recipe, 'Low_Calorie')) {
      score += 5;
    }

    // Bonus for quick recipes
    if (_cookingTime(recipe) > 0 && _cookingTime(recipe) < 30) {
      score += 5;
    }

    return score;
  }

  Future<void> _saveRecipeToFirestore(Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedRecipes')
            .doc(recipe['id'])
            .set({
              'recipeId': recipe['id'],
              'savedAt': FieldValue.serverTimestamp(),
              'recipeData': recipe,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Saved ${recipe['Recipe Name']} for later!"),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save recipe: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRecipeDetails(BuildContext context, Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
              const SizedBox(height: 16),
              Text(
                "Finding the perfect meal...",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Meal Buddy 🍽️'),
        backgroundColor: primaryGreen,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (_currentQuestionIndex > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentQuestionIndex--;
                  _messages.removeLast(); // remove user answer
                  _messages.removeLast(); // remove bot question
                });
              },
              child: const Text(
                "Change Answer",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _currentQuestionIndex / _questions.length,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _messages[index];
                } else {
                  return _typingIndicator();
                }
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentQuestion = _questions[_currentQuestionIndex];
    final isMultipleChoice = currentQuestion['isMultipleChoice'];
    final options = currentQuestion['options'];

    if (isMultipleChoice && options != null) {
      return _buildOptionsSelector(options as List<String>);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.mic, color: primaryGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Speech-to-text coming soon!"),
                  backgroundColor: primaryGreen,
                ),
              );
            },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleTextInput,
                decoration: InputDecoration(
                  hintText: "Type your answer...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : secondaryTextColor,
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : textColor),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: primaryGreen),
            onPressed: () => _handleTextInput(_textController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSelector(List<String> options) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(options[index]),
              selected: false,
              onSelected: (_) => _handleTextInput(options[index]),
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: primaryGreen,
              labelStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              shape: StadiumBorder(
                side: BorderSide(color: primaryGreen.withOpacity(0.2)),
              ),
              elevation: 1,
              pressElevation: 2,
            ),
          );
        },
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryGreen.withOpacity(0.2),
            radius: 16,
            child: Icon(Icons.restaurant, size: 16, color: primaryGreen),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: botBubbleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0, controller: _typingAnimationController!),
                const SizedBox(width: 4),
                _TypingDot(delay: 200, controller: _typingAnimationController!),
                const SizedBox(width: 4),
                _TypingDot(delay: 400, controller: _typingAnimationController!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  final int delay;
  final AnimationController controller;

  const _TypingDot({required this.delay, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * controller.value),
          child: Opacity(opacity: controller.value, child: child),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _MealChatbotScreenState.primaryGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<String>? options;
  final AnimationController? animationController;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.options,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController!,
        curve: Curves.easeOut,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: _MealChatbotScreenState.primaryGreen
                      .withOpacity(0.2),
                  radius: 16,
                  child: Icon(
                    Icons.restaurant,
                    size: 16,
                    color: _MealChatbotScreenState.primaryGreen,
                  ),
                ),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Material(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 16 : 0),
                      topRight: Radius.circular(isUser ? 0 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    elevation: 1,
                    color:
                        isUser
                            ? _MealChatbotScreenState.lightGreen
                            : isDarkMode
                            ? Colors.grey[800]
                            : _MealChatbotScreenState.botBubbleColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color:
                              isDarkMode && !isUser
                                  ? Colors.white
                                  : _MealChatbotScreenState.textColor,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _formatTime(DateTime.now()),
                      style: TextStyle(
                        color: _MealChatbotScreenState.secondaryTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (options != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children:
                            options!.map((option) {
                              return InkWell(
                                onTap: () {},
                                child: Chip(
                                  label: Text(option),
                                  backgroundColor:
                                      isDarkMode
                                          ? Colors.grey[700]
                                          : _MealChatbotScreenState.lightGreen,
                                  labelStyle: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : _MealChatbotScreenState.textColor,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            if (isUser)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 16),
                child: IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 16,
                    color: _MealChatbotScreenState.secondaryTextColor,
                  ),
                  onPressed: () {},
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
