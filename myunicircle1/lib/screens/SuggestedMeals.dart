import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:myunicircle1/screens/RecipeSwipesScreen.dart';
import 'dart:io';
import 'package:myunicircle1/screens/RecipeDetailScreen.dart';
import 'package:myunicircle1/recipe_scoring_service.dart';
import 'dart:math' as math;

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

  int _currentQuestionIndex = 0;

  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color botBubbleColor = Color(0xFFFAFAFA);
  static Color darkBotBubbleColor = Colors.grey.shade800;
  static const Color textColor = Color(0xFF212121);
  static Color lightTextColor = Colors.white;
  static Color darkTextColor = Colors.white70;
  static const Color secondaryTextColor = Color(0xFF757575);

  final List<Map<String, dynamic>> _questions = [
    {
      'text': "Hey, I am QHM How are you feeling today?",
      'isMultipleChoice': true,
      'options': ["Hungry 😋", "Tired 💤", "Stressed 😩", "Happy 😊", "Sad 😔"],
      'storageKey': 'currentMood',
    },
    {
      'text': "Got it! What kind of meal are you in the mood for?",
      'isMultipleChoice': true,
      'options': [
        "Something light and fresh 🥗",
        "A hearty, filling meal 🍛",
        "I'm open to anything!",
      ],
      'storageKey': 'mealType',
    },
    {
      'text': "How much time do you have to cook right now?",
      'isMultipleChoice': true,
      'options': ["Less than 15 mins", "15-30 mins", "More than 30 mins"],
      'storageKey': 'userTime',
    },
    {
      'text': "How about spice level? Do you like it hot? 🔥",
      'isMultipleChoice': true,
      'options': [
        "Very Spicy! 🔥",
        "Medium spice is perfect 🌶️",
        "Just a little kick",
        "No spice please",
        "I have a sweet tooth 🍭",
      ],
      'storageKey': 'spiceLevel',
    },
    {
      'text': "Any particular cuisine you're feeling?",
      'isMultipleChoice': true,
      'options': [
        "Italian",
        "Asian",
        "Mexican",
        "Indian",
        "Mediterranean",
        "Anything!",
      ],
      'storageKey': 'userCuisine',
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
      'text': "How comfortable are you with cooking?",
      'isMultipleChoice': true,
      'options': [
        "Beginner (Simple steps)",
        "Intermediate (Okay)",
        "Confident (Challenge me!)",
      ],
      'storageKey': 'userSkill',
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
    if (_questions.isNotEmpty) {
      _addBotMessage(_questions[_currentQuestionIndex]['text']);
    }
  }

  @override
  void dispose() {
    _typingAnimationController?.dispose();
    _textController.dispose();
    _scrollController.dispose();
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

        if (doc.exists && doc.data()?['lastMealContext'] != null && mounted) {
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
    if (!mounted) return;
    setState(() {
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
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;
    setState(() {
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
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleTextInput(String text) async {
    if (text.trim().isEmpty || !mounted) return;
    if (_currentQuestionIndex < 0 || _currentQuestionIndex >= _questions.length)
      return;

    _addUserMessage(text);
    _textController.clear();

    final currentQuestion = _questions[_currentQuestionIndex];
    final key = currentQuestion['storageKey'] as String;
    _context[key] = text.trim();

    await _saveContextToFirestore();

    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _showTypingIndicator();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      _hideTypingIndicator();
      _addBotMessage(_questions[_currentQuestionIndex]['text']);
      if (_questions[_currentQuestionIndex]['isMultipleChoice'] &&
          _questions[_currentQuestionIndex]['options'] is List<String>) {
        _showOptions(
          _questions[_currentQuestionIndex]['options'] as List<String>,
        );
      }
    } else {
      _addBotMessage("Okay, finding some recipes based on your preferences...");
      await _generateMealSuggestion();
    }
  }

  void _showTypingIndicator() {
    if (!mounted) return;
    setState(() {
      _isTyping = true;
    });
    _scrollToBottom();
  }

  void _hideTypingIndicator() {
    if (!mounted) return;
    setState(() {
      _isTyping = false;
    });
  }

  void _showOptions(List<String>? options) {
    if (options == null || !mounted) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        bool optionsAlreadyShown =
            _messages.isNotEmpty &&
            !_messages.last.isUser &&
            _messages.last.options != null;

        if (!optionsAlreadyShown) {
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
        }
      });
      _scrollToBottom();
    });
  }

  Future<void> _generateMealSuggestion() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    Set<String> likedCuisines = {};
    Set<String> likedMealTypes = {};
    Set<String> likedMoodTags = {};
    Set<String> skippedCuisines = {};
    Set<String> skippedMealTypes = {};
    Set<String> skippedMoodTags = {};
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final savedRecipesSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('savedRecipes')
                .orderBy('savedAt', descending: true)
                .limit(10)
                .get();

        for (var doc in savedRecipesSnapshot.docs) {
          final data = doc.data()['recipeData'] as Map<String, dynamic>?;
          if (data != null) {
            final cuisine = (data['Cuisine'] as String?)?.trim().toLowerCase();
            final mealType =
                (data['Meal_Type'] as String?)?.trim().toLowerCase();
            final moodTags = _splitTags(data['Mood_Tags']);

            if (cuisine != null && cuisine.isNotEmpty)
              likedCuisines.add(cuisine);
            if (mealType != null && mealType.isNotEmpty)
              likedMealTypes.add(mealType);
            likedMoodTags.addAll(moodTags);
          }
        }

        final skippedRecipesSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('skippedRecipes')
                .orderBy('skippedAt', descending: true)
                .limit(20)
                .get();

        for (var doc in skippedRecipesSnapshot.docs) {
          final data = doc.data();
          final cuisine = (data['cuisine'] as String?)?.trim().toLowerCase();
          final mealType = (data['mealType'] as String?)?.trim().toLowerCase();

          if (cuisine != null && cuisine.isNotEmpty)
            skippedCuisines.add(cuisine);
          if (mealType != null && mealType.isNotEmpty)
            skippedMealTypes.add(mealType);
        }
      } catch (e) {
        debugPrint("Error fetching recipe history: $e");
      }
    }

    try {
      final recipesCollection = FirebaseFirestore.instance.collection(
        "recipes2",
      );
      final querySnapshot = await recipesCollection.get();

      final allRecipes =
          querySnapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) {
                  return null;
                }
                final recipeData = Map<String, dynamic>.from(data);
                recipeData['id'] = doc.id;
                return recipeData;
              })
              .where((item) => item != null)
              .cast<Map<String, dynamic>>()
              .toList();

      if (allRecipes.isEmpty) {
        if (mounted) {
          _addBotMessage("No recipes available right now...");
          setState(() => _isLoading = false);
        }
        return;
      }

      final scored =
          allRecipes.map<Map<String, dynamic>>((recipe) {
            return {
              'data': recipe,
              'score': calculateRecipeScore(
                recipe,
                _context,
                likedCuisines,
                likedMealTypes,
                likedMoodTags,
                skippedCuisines,
                skippedMealTypes,
                skippedMoodTags,
              ),
            };
          }).toList();

      final String allergy =
          _context['allergies']?.trim().toLowerCase() ?? 'no';
      final filtered =
          scored.where((entry) {
            if (allergy.isNotEmpty && allergy != 'no') {
              final Map<String, dynamic> data = entry['data'];
              final String allergenField =
                  (data['Allergens'] ?? '').toString().toLowerCase();
              return !allergenField.contains(allergy);
            }
            return true;
          }).toList();

      if (!mounted) return;

      if (filtered.isEmpty) {
        _addBotMessage(
          "Couldn't find recipes matching all preferences/allergies...",
        );
        setState(() => _isLoading = false);
        return;
      }

      filtered.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );
      final topRecipes =
          filtered
              .take(5)
              .map((e) => e['data'] as Map<String, dynamic>)
              .toList();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => RecipeSwipesScreen(
                recipes: topRecipes,
                scannedImage: null,
                onSaveForLater: (recipe) => _saveRecipeToFirestore(recipe),
                onViewRecipe: (recipe) => _showRecipeDetails(context, recipe),
                onSkipRecipe: (recipe) => _logSkippedRecipe(recipe),
              ),
        ),
      );
    } catch (e) {
      debugPrint("Error generating meal suggestion: $e");
      if (!mounted) return;
      _addBotMessage("Oops! Something went wrong finding recipes...");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching/processing recipes: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Set<String> _splitTags(dynamic tagValue) {
    if (tagValue == null || tagValue is! String || tagValue.isEmpty) {
      return <String>{};
    }
    return tagValue
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();
  }

  Future<void> _saveRecipeToFirestore(Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final recipeId = recipe['id'] as String?;
      if (user != null && recipeId != null && mounted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savedRecipes')
            .doc(recipeId)
            .set({
              'recipeId': recipeId,
              'savedAt': FieldValue.serverTimestamp(),
              'recipeData': recipe,
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Saved ${recipe['Recipe Name'] ?? 'Recipe'} for later!",
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else if (recipeId == null) {
        debugPrint("Error saving recipe: Recipe ID is null.");
      }
    } catch (e) {
      debugPrint("Error saving recipe: $e");
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

  Future<void> _logSkippedRecipe(Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final recipeId = recipe['id'] as String?;
      if (user != null && recipeId != null && mounted) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('skippedRecipes')
            .doc(recipeId)
            .set({
              'recipeId': recipeId,
              'skippedAt': FieldValue.serverTimestamp(),
              'cuisine': recipe['Cuisine'],
              'mealType': recipe['Meal_Type'],
              'mainIngredient': recipe['Main_Ingredients'],
              'moodTags': recipe['Mood_Tags'],
            });
        debugPrint("Logged skip for recipe: $recipeId");
      } else if (recipeId == null) {
        debugPrint("Error logging skipped recipe: Recipe ID is null.");
      }
    } catch (e) {
      debugPrint("Error logging skipped recipe: $e");
    }
  }

  void _showRecipeDetails(BuildContext context, Map<String, dynamic> recipe) {
    if (!mounted) return;
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
    final scaffoldBackgroundColor =
        isDarkMode ? Colors.grey[900] : Colors.grey[100];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
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
                style: TextStyle(color: isDarkMode ? darkTextColor : textColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Meal Buddy 🍽️'),
        backgroundColor: primaryGreen,
        elevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (_currentQuestionIndex > 0)
            TextButton(
              onPressed: () {
                if (!mounted || _currentQuestionIndex <= 0) return;
                setState(() {
                  _currentQuestionIndex--;
                  final previousQuestionKey =
                      _questions[_currentQuestionIndex]['storageKey'];
                  _context.remove(previousQuestionKey);

                  if (_messages.isNotEmpty && _messages.last.isUser)
                    _messages.removeLast();
                  while (_messages.isNotEmpty && !_messages.last.isUser) {
                    _messages.removeLast();
                  }

                  _addBotMessage(_questions[_currentQuestionIndex]['text']);
                  if (_questions[_currentQuestionIndex]['isMultipleChoice'] &&
                      _questions[_currentQuestionIndex]['options']
                          is List<String>) {
                    _showOptions(
                      _questions[_currentQuestionIndex]['options']
                          as List<String>,
                    );
                  }
                  _textController.clear();
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
            value: (_currentQuestionIndex / (_questions.length - 1)).clamp(
              0.0,
              1.0,
            ),
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _typingIndicator();
                }
                if (index < _messages.length) {
                  return _messages[index];
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -1),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(child: _buildTextComposer()),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_currentQuestionIndex >= _questions.length ||
        _currentQuestionIndex < 0) {
      return const SizedBox.shrink();
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final bool isMultipleChoice = currentQuestion['isMultipleChoice'] ?? false;
    final options = currentQuestion['options'];

    final bool hasStringOptions = isMultipleChoice && options is List<String>;

    if (hasStringOptions) {
      return _buildOptionsSelector(options);
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.mic, color: primaryGreen),
              tooltip: "Speech-to-text (coming soon)",
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
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _handleTextInput(value),
                  decoration: InputDecoration(
                    hintText: "Type your answer...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : secondaryTextColor,
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? lightTextColor : textColor,
                  ),
                  keyboardType:
                      (currentQuestion['storageKey'] == 'age' ||
                              currentQuestion['storageKey'] == 'weight' ||
                              currentQuestion['storageKey'] == 'height')
                          ? TextInputType.number
                          : TextInputType.text,
                  inputFormatters:
                      (currentQuestion['storageKey'] == 'age' ||
                              currentQuestion['storageKey'] == 'weight' ||
                              currentQuestion['storageKey'] == 'height')
                          ? <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ]
                          : null,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: primaryGreen),
              tooltip: "Send",
              onPressed: () => _handleTextInput(_textController.text),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildOptionsSelector(List<String> options) {
    final chipTheme = Theme.of(context).chipTheme;
    final chipBackgroundColor = chipTheme.backgroundColor ?? Colors.grey[300]!;
    final chipSelectedColor = chipTheme.selectedColor ?? primaryGreen;

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
              backgroundColor: chipBackgroundColor,
              selectedColor: chipSelectedColor,
              labelStyle: chipTheme.labelStyle,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDarkMode ? darkBotBubbleColor : botBubbleColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryGreen.withOpacity(0.2),
            radius: 16,
            child: Icon(
              Icons.support_agent_outlined,
              size: 16,
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_typingAnimationController != null)
                  _TypingDot(delay: 0, controller: _typingAnimationController!),
                const SizedBox(width: 4),
                if (_typingAnimationController != null)
                  _TypingDot(
                    delay: 200,
                    controller: _typingAnimationController!,
                  ),
                const SizedBox(width: 4),
                if (_typingAnimationController != null)
                  _TypingDot(
                    delay: 400,
                    controller: _typingAnimationController!,
                  ),
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
    return FadeTransition(
      opacity: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final dy =
              -5 * (0.5 * (1 + math.sin(controller.value * 2 * math.pi)));
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _MealChatbotScreenState.primaryGreen,
            shape: BoxShape.circle,
          ),
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

    final bubbleColor =
        isUser
            ? _MealChatbotScreenState.lightGreen
            : isDarkMode
            ? _MealChatbotScreenState.darkBotBubbleColor
            : _MealChatbotScreenState.botBubbleColor;
    final textColor =
        isUser
            ? _MealChatbotScreenState.textColor
            : isDarkMode
            ? _MealChatbotScreenState.darkTextColor
            : _MealChatbotScreenState.textColor;

    if (animationController == null) {
      return _buildMessageContent(context, bubbleColor, textColor, isDarkMode);
    }

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController!,
        curve: Curves.easeOut,
      ),
      axisAlignment: isUser ? 1.0 : -1.0,
      child: _buildMessageContent(context, bubbleColor, textColor, isDarkMode),
    );
  }

  Widget _buildMessageContent(
    BuildContext context,
    Color bubbleColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 20),
              child: CircleAvatar(
                backgroundColor: _MealChatbotScreenState.primaryGreen
                    .withOpacity(0.2),
                radius: 16,
                child: Icon(
                  Icons.support_agent_outlined,
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
                    topLeft: Radius.circular(isUser ? 16 : 4),
                    topRight: Radius.circular(isUser ? 4 : 16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                  elevation: 1.5,
                  shadowColor: Colors.black.withOpacity(0.1),
                  color: bubbleColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4, right: 4),
                  child: Text(
                    _formatTime(DateTime.now()),
                    style: TextStyle(
                      color: _MealChatbotScreenState.secondaryTextColor,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (options != null && !isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      alignment: WrapAlignment.start,
                      children:
                          options!.map((option) {
                            return Chip(
                              label: Text(option),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              backgroundColor:
                                  isDarkMode ? Colors.grey[700] : Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              labelStyle: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : _MealChatbotScreenState.textColor,
                                fontSize: 13,
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
                  Icons.edit_note,
                  size: 18,
                  color: _MealChatbotScreenState.secondaryTextColor.withOpacity(
                    0.7,
                  ),
                ),
                tooltip: "Edit (Not implemented)",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Edit functionality not implemented yet."),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
