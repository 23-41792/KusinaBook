import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecipeBookApp());
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'Kusina Book',
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B4513),
              secondary: const Color(0xFFD4A574),
              surface: const Color(0xFFFDF8F0),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.latoTextTheme(const TextTheme(
              displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF5D2E0C), letterSpacing: 2),
              displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF5D2E0C)),
              titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D2E0C)),
              bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF5D2E0C)),
            )).copyWith(
              displayLarge: GoogleFonts.playfairDisplay(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF5D2E0C), letterSpacing: 2),
              displayMedium: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF5D2E0C)),
              titleLarge: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF5D2E0C)),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F0E8),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B4513),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
              displayLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
              displayMedium: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
              titleLarge: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
            ),
          ),
          home: const RecipeBookHome(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class RecipeImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isCircle;

  const RecipeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageContent;
    if (imageUrl == null || imageUrl!.isEmpty) {
      imageContent = Container(
        width: width,
        height: height,
        color: const Color(0xFFD4A574).withOpacity(0.3),
        child: const Icon(Icons.restaurant, color: Color(0xFF8B4513)),
      );
    } else if (imageUrl!.startsWith('http')) {
      imageContent = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => Container(width: width, height: height, color: Colors.grey, child: const Icon(Icons.error)),
      );
    } else if (imageUrl!.startsWith('assets/')) {
      imageContent = Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => Container(width: width, height: height, color: Colors.grey, child: const Icon(Icons.error)),
      );
    } else if (imageUrl!.contains('/') || imageUrl!.contains('\\')) {
      imageContent = Image.file(
        File(imageUrl!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => Container(width: width, height: height, color: Colors.grey, child: const Icon(Icons.error)),
      );
    } else {
      imageContent = Image.asset(
        'assets/recipes/$imageUrl',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => Container(width: width, height: height, color: Colors.grey, child: const Icon(Icons.error)),
      );
    }

    Widget result = isCircle ? ClipOval(child: imageContent) : imageContent;
    
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Hero(tag: imageUrl!, child: result);
    }
    return result;
  }
}

enum Difficulty { easy, medium, hard }

class Recipe {
  final String name;
  final String category;
  final String cookingTime;
  final String prepTime;
  final String servings;
  final List<String> ingredients;
  final List<String> directions;
  final String notes;
  final String trivia;
  final String? imageUrl;
  final Difficulty difficulty;
  final String estimatedCost;
  final String origin;
  bool isFavorite;
  List<bool> ingredientStatus;
  double userRating;
  int viewCount;
  bool isCooked;

  Recipe({
    required this.name,
    required this.category,
    required this.cookingTime,
    required this.prepTime,
    required this.servings,
    required this.ingredients,
    required this.directions,
    required this.notes,
    this.trivia = 'A classic Filipino favorite.',
    this.imageUrl,
    this.difficulty = Difficulty.medium,
    this.estimatedCost = '₱150–₱250',
    this.origin = 'General',
    this.isFavorite = false,
    this.userRating = 0.0,
    this.viewCount = 0,
    this.isCooked = false,
    List<bool>? ingredientStatus,
  }) : ingredientStatus = ingredientStatus ?? List.filled(ingredients.length, false);

  double get availabilityPercentage {
    if (ingredients.isEmpty) return 0;
    int have = ingredientStatus.where((s) => s).length;
    return (have / ingredients.length) * 100;
  }

  int get minutes {
    final lower = cookingTime.toLowerCase();
    final number = double.tryParse(lower.split(' ').first) ?? 0;
    if (lower.contains('hour')) return (number * 60).toInt();
    return number.toInt();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'cookingTime': cookingTime,
    'prepTime': prepTime,
    'servings': servings,
    'ingredients': ingredients,
    'directions': directions,
    'notes': notes,
    'trivia': trivia,
    'imageUrl': imageUrl,
    'difficulty': difficulty.index,
    'estimatedCost': estimatedCost,
    'origin': origin,
    'isFavorite': isFavorite,
    'ingredientStatus': ingredientStatus,
    'userRating': userRating,
    'viewCount': viewCount,
    'isCooked': isCooked,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'],
      category: json['category'],
      cookingTime: json['cookingTime'],
      prepTime: json['prepTime'],
      servings: json['servings'],
      ingredients: List<String>.from(json['ingredients']),
      directions: List<String>.from(json['directions']),
      notes: json['notes'],
      trivia: json['trivia'] ?? 'A classic Filipino favorite.',
      imageUrl: json['imageUrl'],
      difficulty: Difficulty.values[json['difficulty'] ?? 1],
      estimatedCost: json['estimatedCost'] ?? '₱150–₱250',
      origin: json['origin'] ?? json['region'] ?? 'General',
      isFavorite: json['isFavorite'] ?? false,
      userRating: json['userRating']?.toDouble() ?? 0.0,
      viewCount: json['viewCount'] ?? 0,
      isCooked: json['isCooked'] ?? false,
      ingredientStatus: List<bool>.from(json['ingredientStatus'] ?? []),
    );
  }
}

class ShoppingItem {
  final String recipeName;
  final String ingredient;
  bool isChecked;

  ShoppingItem({
    required this.recipeName,
    required this.ingredient,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
    'recipeName': recipeName,
    'ingredient': ingredient,
    'isChecked': isChecked,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    recipeName: json['recipeName'],
    ingredient: json['ingredient'],
    isChecked: json['isChecked'],
  );
}

class FoodTrivia {
  final String title;
  final String fact;
  const FoodTrivia({required this.title, required this.fact});
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  bool isUnlocked;
  Achievement({required this.title, required this.description, required this.icon, this.isUnlocked = false});
}

class GlobalCookingTimer extends ChangeNotifier {
  static final GlobalCookingTimer _instance = GlobalCookingTimer._internal();
  factory GlobalCookingTimer() => _instance;
  GlobalCookingTimer._internal();

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  String _currentRecipeName = '';

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  String get currentRecipeName => _currentRecipeName;

  void start(int minutes, String recipeName) {
    stop();
    _secondsRemaining = minutes * 60;
    _currentRecipeName = recipeName;
    _isRunning = true;
    _resume();
    notifyListeners();
  }

  void _resume() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        stop();
      }
    });
  }

  void toggle() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
    } else {
      _isRunning = true;
      _resume();
    }
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _secondsRemaining = 0;
    _isRunning = false;
    notifyListeners();
  }

  void reset(int minutes) {
    _secondsRemaining = minutes * 60;
    notifyListeners();
  }
}

class RecipeBookHome extends StatefulWidget {
  const RecipeBookHome({super.key});

  @override
  State<RecipeBookHome> createState() => _RecipeBookHomeState();
}

class _RecipeBookHomeState extends State<RecipeBookHome> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Recipe> _recipes = [];
  List<Recipe> _favorites = [];
  final List<ShoppingItem> _shoppingList = [];
  final List<Recipe> _recentlyViewed = [];
  List<Achievement> _achievements = [];
  final Set<String> _deletedRecipeNames = {};
  final List<Recipe> _trash = [];

  bool _showBookCover = true;
  bool _showTableOfContents = false;
  bool _showQuiz = false;
  bool _showWhatCanICook = false;
  bool _showAchievements = false;
  bool _showRecentlyViewed = false;
  bool _showTrash = false;
  bool _isGridView = false;

  String _selectedCategory = '';
  List<Recipe> _categoryRecipes = [];

  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _searchResults = [];
  bool _isSearching = false;

  final Map<String, IconData> _categoryIcons = {
    'Almusal': Icons.breakfast_dining,
    'Tanghalian': Icons.lunch_dining,
    'Hapunan': Icons.dinner_dining,
    'Panghimagas': Icons.cake,
    'Merienda': Icons.fastfood,
  };

  @override
  void initState() {
    super.initState();
    // Use post frame callback to allow the app to render the first frame (splash/cover) immediately
    Future.microtask(() async {
      _initializeRecipes();
      _initializeAchievements();
      _updateFavorites();
      await _loadStoredData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final List<String>? deleted = prefs.getStringList('deleted_recipes');
      if (deleted != null) {
        setState(() {
          _deletedRecipeNames.addAll(deleted);
          _recipes.removeWhere((r) => _deletedRecipeNames.contains(r.name));
        });
      }

      final String? shoppingJson = prefs.getString('shopping_list');
      if (shoppingJson != null) {
        final List<dynamic> decoded = jsonDecode(shoppingJson);
        setState(() {
          _shoppingList.clear();
          _shoppingList.addAll(decoded.map((item) => ShoppingItem.fromJson(item)).toList());
        });
      }

      final String? recipesJson = prefs.getString('all_recipes');
      if (recipesJson != null) {
        final List<dynamic> decoded = jsonDecode(recipesJson);
        final List<Recipe> storedRecipes = decoded.map((item) => Recipe.fromJson(item)).toList();

        setState(() {
          // Optimized merging: Use a map for O(1) lookups instead of O(N) indexWhere
          final Map<String, Recipe> recipeMap = {for (var r in _recipes) r.name: r};

          for (var stored in storedRecipes) {
            if (_deletedRecipeNames.contains(stored.name)) continue;

            final existing = recipeMap[stored.name];
            if (existing != null) {
              existing.isFavorite = stored.isFavorite;
              existing.ingredientStatus = stored.ingredientStatus;
              existing.isCooked = stored.isCooked;
              existing.userRating = stored.userRating;
              existing.viewCount = stored.viewCount;
            } else {
              _recipes.add(stored);
            }
          }
          _updateFavorites();
        });
      }

      final String? trashJson = prefs.getString('trash_recipes');
      if (trashJson != null) {
        final List<dynamic> decoded = jsonDecode(trashJson);
        setState(() {
          _trash.clear();
          _trash.addAll(decoded.map((item) => Recipe.fromJson(item)).toList());
        });
      }
    } catch (e) {
      debugPrint('Error loading stored data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final shoppingJson = jsonEncode(_shoppingList.map((i) => i.toJson()).toList());
      await prefs.setString('shopping_list', shoppingJson);

      final recipesJson = jsonEncode(_recipes.map((r) => r.toJson()).toList());
      await prefs.setString('all_recipes', recipesJson);

      await prefs.setStringList('deleted_recipes', _deletedRecipeNames.toList());

      final trashJson = jsonEncode(_trash.map((r) => r.toJson()).toList());
      await prefs.setString('trash_recipes', trashJson);
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  void _initializeAchievements() {
    _achievements = [
      Achievement(title: 'First Recipe Viewed', description: 'Open your first recipe page', icon: Icons.visibility),
      Achievement(title: 'Favorite Collector', description: 'Save 3 recipes to your favorites', icon: Icons.favorite),
      Achievement(title: 'Cooked 5 Recipes', description: 'Mark 5 recipes as cooked', icon: Icons.restaurant),
      Achievement(title: 'Shopping Master', description: 'Add items to your shopping list', icon: Icons.shopping_cart),
      Achievement(title: 'Quiz Master', description: 'Complete the recipe quiz', icon: Icons.psychology),
      Achievement(title: 'Recipe Creator', description: 'Add your own recipe entry', icon: Icons.edit_note),
    ];
  }

  void _checkAchievements() {
    setState(() {
      if (_recipes.any((r) => r.viewCount > 0)) _achievements[0].isUnlocked = true;
      if (_favorites.length >= 3) _achievements[1].isUnlocked = true;
      if (_recipes.where((r) => r.isCooked).length >= 5) _achievements[2].isUnlocked = true;
      if (_shoppingList.isNotEmpty) _achievements[3].isUnlocked = true;
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isSearching = true;
        _searchResults = _recipes.where((r) {
          bool nameMatch = r.name.toLowerCase().contains(query);
          bool catMatch = r.category.toLowerCase().contains(query);
          bool ingredientMatch = r.ingredients.any((i) => i.toLowerCase().contains(query));
          return nameMatch || catMatch || ingredientMatch;
        }).toList();
      });
    }
  }

  void _initializeRecipes() {
    _recipes = [
      Recipe(
        name: 'Tapsilog',
        category: 'Almusal',
        cookingTime: '30 min',
        prepTime: '15 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱150–₱200',
        origin: 'Luzon',
        imageUrl: 'assets/almusal/tapsilog.png',
        ingredients: [
          '1 kg beef sirloin, thinly sliced',
          '1/2 cup soy sauce',
          '1/4 cup calamansi juice',
          '6 cloves garlic, minced',
          '1 tsp black pepper',
          '4 cups garlic rice',
          '4 fried eggs',
          '1/4 cup vinegar',
        ],
        directions: [
          'Marinate beef in soy sauce, calamansi, garlic, and pepper for 30 mins.',
          'Fry beef in hot oil until crispy.',
          'Serve with garlic rice and fried egg.',
          'Serve with vinegar dip.',
        ],
        notes: 'Marinating overnight makes the beef more flavorful.',
        trivia: 'Tapsilog is a portmanteau of Tapa, Sinangag (fried rice), and Itlog (egg).',
      ),
      Recipe(
        name: 'Longsilog',
        category: 'Almusal',
        cookingTime: '25 min',
        prepTime: '10 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱120–₱180',
        origin: 'Luzon',
        imageUrl: 'assets/almusal/longsilog.png',
        ingredients: [
          '1 kg longganisa',
          '4 cups garlic rice',
          '4 fried eggs',
          '2 tomatoes',
          '1 onion',
          'Vinegar for dipping',
        ],
        directions: [
          'Prick longganisa with a fork.',
          'Cook with water until water evaporates.',
          'Fry until browned.',
          'Serve with garlic rice and fried egg.',
        ],
        notes: 'Longganisa comes in sweet and garlicky varieties.',
        trivia: 'Filipino longganisa is influenced by Spanish longaniza but has distinct local spices.',
      ),
      Recipe(
        name: 'Champorado',
        category: 'Almusal',
        cookingTime: '30 min',
        prepTime: '5 min',
        servings: '6',
        difficulty: Difficulty.easy,
        estimatedCost: '₱100–₱150',
        origin: 'Luzon',
        imageUrl: 'assets/almusal/champorado.png',
        ingredients: [
          '1 cup sticky rice',
          '1/2 cup cocoa powder',
          '1 cup sugar',
          '4 cups water',
          '1 can evaporated milk',
          'Dried fish (tuyo)',
        ],
        directions: [
          'Cook sticky rice with water.',
          'Add cocoa powder and sugar.',
          'Cook until thick.',
          'Serve with evaporated milk and tuyo.',
        ],
        notes: 'Sweet chocolate rice porridge eaten with tuyo.',
        trivia: 'Champorado was derived from the Mexican chocolate-based drink Champurrado.',
      ),
      Recipe(
        name: 'Chicken Adobo',
        category: 'Tanghalian',
        cookingTime: '45 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱200–₱300',
        origin: 'Luzon',
        imageUrl: 'assets/tanghalian/chicken adobo.png',
        ingredients: [
          '1 kg chicken',
          '1/2 cup soy sauce',
          '1/2 cup vinegar',
          '8 cloves garlic',
          '3 bay leaves',
          '1 tsp peppercorns',
          '2 tbsp oil',
          '1 cup water',
        ],
        directions: [
          'Marinate chicken for 30 mins.',
          'Brown chicken in oil.',
          'Add marinade and water.',
          'Simmer until tender.',
          'Reduce sauce.',
        ],
        notes: 'The longer it marinates, the more flavorful.',
        trivia: 'Adobo is not just a dish, but a cooking process of marinating in vinegar.',
      ),
      Recipe(
        name: 'Sinigang na Baboy',
        category: 'Tanghalian',
        cookingTime: '50 min',
        prepTime: '20 min',
        servings: '8',
        difficulty: Difficulty.medium,
        estimatedCost: '₱250–₱400',
        origin: 'Luzon',
        imageUrl: 'assets/tanghalian/sinigang na baboy.png',
        ingredients: [
          '1 kg pork belly',
          '1 onion',
          '2 tomatoes',
          '1 pack sinigang mix',
          '2 cups kangkong',
          '1 cup sitaw',
          '2 radishes',
        ],
        directions: [
          'Boil pork with onion and tomatoes.',
          'Add sinigang mix.',
          'Add vegetables.',
          'Season with salt.',
        ],
        notes: 'A sour soup known for its tangy flavor.',
        trivia: 'Traditional Sinigang uses natural souring agents like tamarind, guava, or calamansi.',
      ),
      Recipe(
        name: 'Kare-Kare',
        category: 'Tanghalian',
        cookingTime: '1.5 hours',
        prepTime: '30 min',
        servings: '8',
        difficulty: Difficulty.hard,
        estimatedCost: '₱400–₱600',
        origin: 'Luzon',
        imageUrl: 'assets/tanghalian/kare kare.png',
        ingredients: [
          '1 kg oxtail',
          '1/2 kg beef tripe',
          '1 onion',
          '4 cloves garlic',
          '1 cup peanut butter',
          '1/2 cup ground peanuts',
          '1 bundle sitaw',
          '1 eggplant',
          'Bagoong',
        ],
        directions: [
          'Boil oxtail and tripe until tender.',
          'Sauté garlic and onion.',
          'Add meat and broth.',
          'Add peanut butter and ground peanuts.',
          'Add vegetables.',
          'Serve with bagoong.',
        ],
        notes: 'Rich peanut-based stew served with bagoong.',
        trivia: 'The orange color of Kare-Kare comes from atsuete (annatto) seeds.',
      ),
      Recipe(
        name: 'Lechon Kawali',
        category: 'Hapunan',
        cookingTime: '60 min',
        prepTime: '20 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱300–₱450',
        origin: 'Luzon',
        imageUrl: 'assets/hapunan/lechon kawali.png',
        ingredients: [
          '1.5 kg pork belly',
          '2 tbsp salt',
          '1 tsp pepper',
          '4 cloves garlic',
          '2 bay leaves',
          'Oil for frying',
        ],
        directions: [
          'Boil pork until tender.',
          'Pat dry completely.',
          'Deep fry until crispy.',
          'Serve with lechon sauce.',
        ],
        notes: 'Key to crispy lechon is drying thoroughly.',
        trivia: '"Kawali" refers to the traditional Filipino wok used for deep frying.',
      ),
      Recipe(
        name: 'Pork Menudo',
        category: 'Hapunan',
        cookingTime: '45 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱200–₱300',
        origin: 'Luzon',
        imageUrl: 'assets/hapunan/pork menudo.png',
        ingredients: [
          '1 kg pork',
          '1/4 cup soy sauce',
          '1 onion',
          '4 cloves garlic',
          '2 tomatoes',
          '1 cup tomato sauce',
          '1/2 cup potatoes',
          '1/2 cup carrots',
          '1/4 cup liver spread',
        ],
        directions: [
          'Marinate pork in soy sauce.',
          'Sauté garlic, onion, and tomatoes.',
          'Add pork and brown.',
          'Add tomato sauce.',
          'Add vegetables.',
          'Add liver spread.',
        ],
        notes: 'Hearty tomato-based stew with liver spread.',
        trivia: 'Liver spread is the secret ingredient that gives Menudo its rich, thick sauce.',
      ),
      Recipe(
        name: 'Beef Bulalo',
        category: 'Hapunan',
        cookingTime: '120 min',
        prepTime: '15 min',
        servings: '8',
        difficulty: Difficulty.hard,
        estimatedCost: '₱500–₱800',
        origin: 'Batangas',
        imageUrl: 'assets/hapunan/beef bulalo.png',
        ingredients: [
          '1.5 kg beef shanks',
          '1 onion',
          '4 cloves garlic',
          '4 potatoes',
          '2 corn',
          '1/2 cabbage',
          '1 bunch pechay',
        ],
        directions: [
          'Boil beef shanks until tender.',
          'Add potatoes and corn.',
          'Add cabbage and pechay.',
          'Season with salt.',
        ],
        notes: 'Comforting beef bone marrow soup.',
        trivia: 'Batangas is famous for producing the best beef shanks for Bulalo.',
      ),
      Recipe(
        name: 'Laing',
        category: 'Tanghalian',
        cookingTime: '40 min',
        prepTime: '15 min',
        servings: '4',
        difficulty: Difficulty.medium,
        estimatedCost: '₱150–₱250',
        origin: 'Bicol',
        imageUrl: 'assets/tanghalian/laing.png',
        ingredients: [
          'Dried gabi leaves',
          'Coconut milk',
          'Shrimp paste',
          'Chili peppers',
          'Pork bits',
        ],
        directions: [
          'Simmer pork and shrimp paste in coconut milk.',
          'Add gabi leaves. Do not stir immediately.',
          'Cook until leaves are soft and sauce is thick.',
          'Add chilies for heat.',
        ],
        notes: 'A spicy coconut-based dish from Bicol.',
        trivia: 'The secret to good Laing is not stirring the taro leaves while they simmer.',
      ),
      Recipe(
        name: 'Leche Flan',
        category: 'Panghimagas',
        cookingTime: '45 min',
        prepTime: '15 min',
        servings: '8',
        difficulty: Difficulty.medium,
        estimatedCost: '₱150–₱200',
        origin: 'General',
        imageUrl: 'assets/panghimagas/leche plan.png',
        ingredients: [
          '10 egg yolks',
          '1 can condensed milk',
          '1 can evaporated milk',
          '1 cup sugar',
          '1 tsp vanilla',
          'Caramel: 1/2 cup sugar',
        ],
        directions: [
          'Make caramel.',
          'Pour into mold.',
          'Mix egg yolks, milks, and vanilla.',
          'Strain and pour over caramel.',
          'Steam for 30-35 mins.',
        ],
        notes: 'Rich creamy caramel custard.',
        trivia: 'Traditional Filipino Leche Flan uses only egg yolks for a richer texture.',
      ),
      Recipe(
        name: 'Halo-Halo',
        category: 'Panghimagas',
        cookingTime: '10 min',
        prepTime: '20 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱200–₱300',
        origin: 'General',
        imageUrl: 'assets/panghimagas/halo halo.png',
        ingredients: [
          'Crushed ice',
          'Sweetened beans',
          'Macapuno',
          'Nata de coco',
          'Kaong',
          'Leche flan',
          'Ube halaya',
          'Bananas',
          'Jackfruit',
          'Evaporated milk',
          'Ube ice cream',
        ],
        directions: [
          'Add crushed ice to glass.',
          'Add beans, macapuno, nata, kaong.',
          'Add leche flan and ube halaya.',
          'Add bananas and jackfruit.',
          'Top with more ice.',
          'Pour milk and top with ice cream.',
        ],
        notes: '"Mix-mix" dessert with endless variations.',
        trivia: 'Halo-Halo was inspired by the Japanese dessert "Kakigori."',
      ),
      Recipe(
        name: 'Bibingka',
        category: 'Panghimagas',
        cookingTime: '30 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱150–₱250',
        origin: 'General',
        imageUrl: 'assets/panghimagas/bibingka.png',
        ingredients: [
          '1 cup rice flour',
          '1 cup sugar',
          '1 cup coconut milk',
          '1/2 cup water',
          '3 eggs',
          '1 tsp baking powder',
          '1/2 tsp salt',
          'Grated coconut',
          'Salted egg slices',
        ],
        directions: [
          'Mix dry ingredients.',
          'Add wet ingredients.',
          'Pour into greased pan.',
          'Top with coconut and salted egg.',
          'Bake for 25-30 mins.',
        ],
        notes: 'Traditional rice cake for Christmas.',
        trivia: 'Bibingka is traditionally baked in clay pots lined with banana leaves.',
      ),
      Recipe(
        name: 'Lumpiang Shanghai',
        category: 'Merienda',
        cookingTime: '20 min',
        prepTime: '25 min',
        servings: '8',
        difficulty: Difficulty.easy,
        estimatedCost: '₱200–₱300',
        origin: 'General',
        imageUrl: 'assets/merienda/lumpiang sanghai.png',
        ingredients: [
          '1 kg ground pork',
          '1 carrot',
          '1 onion',
          '4 cloves garlic',
          '1/4 cup soy sauce',
          'Lumpia wrappers',
          '1 egg',
          'Oil for frying',
        ],
        directions: [
          'Mix all ingredients.',
          'Place filling on wrapper.',
          'Roll tightly and seal with egg.',
          'Deep fry until golden.',
        ],
        notes: 'Crispy Filipino spring rolls.',
        trivia: 'Lumpiang Shanghai is often the most popular dish at any Filipino party.',
      ),
      Recipe(
        name: 'Palabok',
        category: 'Merienda',
        cookingTime: '35 min',
        prepTime: '20 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱300–₱450',
        origin: 'General',
        imageUrl: 'assets/merienda/palabok.png',
        ingredients: [
          '500g rice noodles',
          '1/2 kg shrimp',
          '1 cup ground pork',
          '1 onion',
          '4 cloves garlic',
          '1/4 cup fish sauce',
          '1 cup shrimp broth',
          '1/4 cup annatto water',
          'Hard-boiled eggs',
          'Crushed chicharon',
        ],
        directions: [
          'Cook noodles.',
          'Sauté garlic and onion.',
          'Add pork and shrimp.',
          'Add fish sauce and broth.',
          'Pour over noodles.',
          'Top with eggs and chicharon.',
        ],
        notes: 'Classic noodle dish with rich shrimp sauce.',
        trivia: 'The orange sauce of Palabok is traditionally made using shrimp heads for flavor.',
      ),
      Recipe(
        name: 'Banana Cue',
        category: 'Merienda',
        cookingTime: '15 min',
        prepTime: '10 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱50–₱100',
        origin: 'General',
        imageUrl: 'assets/merienda/banana cue.png',
        ingredients: [
          '8 saba bananas',
          '1 cup brown sugar',
          'Oil for frying',
          'Bamboo skewers',
        ],
        directions: [
          'Fry bananas in oil.',
          'Add sugar and let it caramelize onto bananas.',
          'Skew bananas.',
        ],
        notes: 'Popular street food snack.',
        trivia: 'The "Cue" in Banana Cue refers to the stick, similar to "Barbecue."',
      ),
      Recipe(
        name: 'Lugaw',
        category: 'Almusal',
        cookingTime: '40 min',
        prepTime: '10 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱50–₱100',
        origin: 'Luzon',
        imageUrl: 'assets/almusal/lugaw.png',
        ingredients: [
          '1 cup rice',
          '6 cups water',
          '1 tbsp ginger, minced',
          '1 onion, chopped',
          '4 cloves garlic, minced',
          '2 tbsp fish sauce',
          '1 tsp salt',
          'Green onions for garnish',
        ],
        directions: [
          'Sauté garlic, onion, and ginger in a large pot.',
          'Add the rice and stir for 2 minutes.',
          'Pour in the water and bring to a boil.',
          'Lower the heat and simmer until rice is soft and thick.',
          'Stir occasionally to prevent sticking at the bottom.',
          'Season with fish sauce and salt.',
          'Garnish with chopped green onions before serving.',
        ],
        notes: 'Using chicken broth instead of water adds more depth to the flavor.',
        trivia: 'Lugaw is the ultimate Filipino comfort food, often served when someone is feeling unwell.',
      ),
      Recipe(
        name: 'Arroz Caldo',
        category: 'Almusal',
        cookingTime: '45 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱150–₱250',
        origin: 'Luzon',
        imageUrl: 'assets/almusal/arroz caldo.png',
        ingredients: [
          '500g chicken, cut into pieces',
          '1.5 cups glutinous rice',
          '2 tbsp ginger, julienned',
          '1 head garlic, toasted',
          '1 onion, chopped',
          '2 tbsp fish sauce',
          '8 cups water',
          '2 hard-boiled eggs',
        ],
        directions: [
          'Sauté ginger, onion, and chicken in a pot until chicken is browned.',
          'Add the glutinous rice and stir well.',
          'Pour in water and bring to a boil.',
          'Simmer until the rice is cooked and the mixture thickens.',
          'Add fish sauce and black pepper to taste.',
          'Top with hard-boiled eggs and toasted garlic.',
          'Serve hot with calamansi on the side.',
        ],
        notes: 'Squeeze fresh calamansi over the bowl to cut through the richness.',
        trivia: 'Despite its Spanish name, Arroz Caldo is a local adaptation of Chinese congee.',
      ),
      Recipe(
        name: 'Tocilog',
        category: 'Almusal',
        cookingTime: '20 min',
        prepTime: '10 min',
        servings: '2',
        difficulty: Difficulty.easy,
        estimatedCost: '₱100–₱150',
        origin: 'Pampanga',
        imageUrl: 'assets/almusal/tocilog.png',
        ingredients: [
          '250g pork tocino',
          '2 cups garlic rice',
          '2 fried eggs',
          '1/4 cup water',
          '1 tbsp oil',
          'Sliced tomatoes',
        ],
        directions: [
          'Place tocino in a pan with water.',
          'Simmer until water evaporates.',
          'Add oil and fry tocino until caramelized.',
          'Prepare the fried eggs sunny side up.',
          'Place garlic rice on a plate.',
          'Add the fried tocino and eggs.',
          'Serve with sliced tomatoes on the side.',
        ],
        notes: 'Don’t overcook the tocino or it will become tough and bitter.',
        trivia: 'Tocino comes from the Spanish word for bacon or cured meat.',
      ),
      Recipe(
        name: 'Bangsilog',
        category: 'Almusal',
        cookingTime: '25 min',
        prepTime: '15 min',
        servings: '2',
        difficulty: Difficulty.easy,
        estimatedCost: '₱150–₱250',
        origin: 'Luzon',
        imageUrl: 'assets/almusal/bangsilog.png',
        ingredients: [
          '1 medium boneless bangus, marinated',
          '2 cups garlic fried rice',
          '2 eggs',
          'Oil for frying',
          'Vinegar with garlic for dipping',
        ],
        directions: [
          'Heat oil in a frying pan.',
          'Fry the bangus skin-side down until crispy.',
          'Flip and fry the other side until golden brown.',
          'Fry the eggs to your preference.',
          'Assemble the bangus, rice, and eggs on a plate.',
          'Serve immediately with vinegar dip.',
        ],
        notes: 'Pat the fish dry before frying to prevent oil splatters.',
        trivia: 'Bangus or Milkfish is the national fish of the Philippines.',
      ),
      Recipe(
        name: 'Tortang Talong',
        category: 'Almusal',
        cookingTime: '20 min',
        prepTime: '10 min',
        servings: '2',
        difficulty: Difficulty.easy,
        estimatedCost: '₱50–₱100',
        origin: 'General',
        imageUrl: 'assets/almusal/tortang talong.png',
        ingredients: [
          '2 long eggplants',
          '2 eggs, beaten',
          '1/2 tsp salt',
          '1/4 tsp pepper',
          '2 tbsp oil',
        ],
        directions: [
          'Grill eggplants until the skin is charred.',
          'Peel off the skin while keeping the stem attached.',
          'Flatten the eggplant flesh with a fork.',
          'Season beaten eggs with salt and pepper.',
          'Dip the flattened eggplant into the egg mixture.',
          'Heat oil and fry the eggplant until golden brown.',
          'Pour remaining egg over the eggplant while frying.',
          'Flip carefully to cook both sides.',
        ],
        notes: 'Prick the eggplant with a fork before grilling to prevent it from bursting.',
        trivia: 'Tortang Talong was once ranked as the best-rated egg dish in the world by TasteAtlas.',
      ),
      Recipe(
        name: 'Daingsilog',
        category: 'Almusal',
        cookingTime: '15 min',
        prepTime: '5 min',
        servings: '2',
        difficulty: Difficulty.easy,
        estimatedCost: '₱50–₱100',
        origin: 'Visayas',
        imageUrl: 'assets/almusal/daingsilog.png',
        ingredients: [
          '4 pieces dried fish (daing)',
          '2 cups garlic rice',
          '2 eggs',
          'Oil for frying',
          'Tomato and onion salad',
        ],
        directions: [
          'Fry the dried fish in hot oil until crispy.',
          'Fry the eggs sunny side up.',
          'Prepare the garlic rice in the same pan.',
          'Mix chopped tomatoes and onions for the side salad.',
          'Arrange the fish, eggs, and rice on a plate.',
          'Serve hot with a side of vinegar.',
        ],
        notes: 'Open the windows while frying dried fish to allow the strong aroma to escape.',
        trivia: 'Daing refers to the process of preserving fish through sun-drying and salting.',
      ),
      Recipe(
        name: 'Corned Beef Silog',
        category: 'Almusal',
        cookingTime: '15 min',
        prepTime: '5 min',
        servings: '2',
        difficulty: Difficulty.easy,
        estimatedCost: '₱100–₱150',
        origin: 'General',
        imageUrl: 'assets/almusal/corned beef silog.png',
        ingredients: [
          '1 can corned beef',
          '1 potato, diced',
          '1 onion, sliced',
          '2 cups garlic rice',
          '2 fried eggs',
        ],
        directions: [
          'Fry diced potatoes until golden and set aside.',
          'Sauté onions in a pan until soft.',
          'Add the corned beef and cook for 5 minutes.',
          'Mix in the fried potatoes.',
          'Serve alongside garlic rice and fried eggs.',
          'Garnish with a little toasted garlic.',
        ],
        notes: 'Adding a bit of water to the corned beef makes it "soupy" which some prefer.',
        trivia: 'Canned corned beef became a staple in the Philippines during the American colonial period.',
      ),
      Recipe(
        name: 'Bicol Express',
        category: 'Tanghalian',
        cookingTime: '40 min',
        prepTime: '20 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱250–₱400',
        origin: 'Bicol',
        imageUrl: 'assets/tanghalian/bicol express.png',
        ingredients: [
          '1 kg pork belly, diced',
          '3 cups coconut milk',
          '1 cup coconut cream',
          '1/2 cup shrimp paste (bagoong)',
          '2 cups chili peppers, sliced',
          '4 cloves garlic, minced',
          '1 onion, chopped',
          '1 tbsp ginger, julienned',
        ],
        directions: [
          'Sauté garlic, onion, and ginger in a pan.',
          'Add the pork belly and cook until browned.',
          'Stir in the shrimp paste and cook for 2 minutes.',
          'Pour in the coconut milk and bring to a simmer.',
          'Add the chili peppers and simmer until the pork is tender.',
          'Pour in the coconut cream for extra richness.',
          'Cook until the sauce is thick and oily.',
        ],
        notes: 'Soak the chilies in salt water to reduce their heat if you want a milder version.',
        trivia: 'This dish was named after the passenger train service from Manila to Bicol.',
      ),
      Recipe(
        name: 'Pinakbet Tagalog',
        category: 'Tanghalian',
        cookingTime: '30 min',
        prepTime: '20 min',
        servings: '6',
        difficulty: Difficulty.easy,
        estimatedCost: '₱150–₱250',
        origin: 'Luzon',
        imageUrl: 'assets/tanghalian/pinakbet.png',
        ingredients: [
          '200g pork belly, sliced',
          '1 piece squash, cubed',
          '1 bunch string beans (sitaw)',
          '1 piece eggplant, sliced',
          '1 piece bitter gourd (ampalaya)',
          '3 tbsp shrimp paste',
          '2 tomatoes, chopped',
          '1 cup water',
        ],
        directions: [
          'Sauté pork until the fat is rendered and browned.',
          'Add onion and tomatoes; cook until soft.',
          'Stir in the shrimp paste and cook for 1 minute.',
          'Add the squash and pour in water.',
          'Simmer until the squash is slightly tender.',
          'Add the string beans, eggplant, and bitter gourd.',
          'Cover and cook until all vegetables are tender.',
          'Do not over-stir to avoid the ampalaya’s bitterness from spreading.',
        ],
        notes: 'The squash should be soft enough to slightly thicken the sauce.',
        trivia: 'The word "pinakbet" is derived from the Ilocano word "pinakebbet," meaning shriveled.',
      ),
      Recipe(
        name: 'Ginisang Munggo',
        category: 'Tanghalian',
        cookingTime: '45 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.easy,
        estimatedCost: '₱100–₱150',
        origin: 'General',
        imageUrl: 'assets/tanghalian/ginisang munggo.png',
        ingredients: [
          '1 cup dried mung beans',
          '100g pork, sliced',
          '50g smoked fish (tinapa), flaked',
          '1 bunch spinach or ampalaya leaves',
          '1 tomato, chopped',
          '3 cloves garlic, minced',
          '1 tbsp fish sauce',
        ],
        directions: [
          'Boil the mung beans in water until soft and bursting.',
          'In a separate pan, sauté garlic, onion, and pork.',
          'Add the flaked tinapa and tomatoes.',
          'Pour the boiled mung beans (with water) into the pan.',
          'Season with fish sauce and simmer for 10 minutes.',
          'Add the spinach or ampalaya leaves.',
          'Cook for another 2 minutes until leaves are wilted.',
        ],
        notes: 'Mashing some of the beans makes the soup creamier.',
        trivia: 'Filipinos traditionally serve Ginisang Munggo on Fridays.',
      ),
      Recipe(
        name: 'Tinolang Manok',
        category: 'Tanghalian',
        cookingTime: '50 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱200–₱300',
        origin: 'Luzon',
        imageUrl: 'assets/tanghalian/tinolang manok.png',
        ingredients: [
          '1 kg chicken, cut up',
          '1 piece green papaya, wedged',
          '1 bunch chili leaves',
          '2 tbsp ginger, sliced',
          '1 onion, chopped',
          '2 tbsp fish sauce',
          '6 cups water',
        ],
        directions: [
          'Sauté ginger and onion until fragrant.',
          'Add the chicken and cook until the outer layer turns brown.',
          'Add the fish sauce and stir.',
          'Pour in water and bring to a boil.',
          'Lower heat and simmer until chicken is tender.',
          'Add the green papaya and cook until soft.',
          'Stir in the chili leaves and turn off the heat.',
        ],
        notes: 'Use a lot of ginger for a more warming and medicinal broth.',
        trivia: 'Tinola was mentioned in Jose Rizal’s famous novel, Noli Me Tangere.',
      ),
      Recipe(
        name: 'Pork Dinuguan',
        category: 'Tanghalian',
        cookingTime: '60 min',
        prepTime: '20 min',
        servings: '8',
        difficulty: Difficulty.hard,
        estimatedCost: '₱250–₱400',
        origin: 'General',
        imageUrl: 'assets/tanghalian/pork dinuguan.png',
        ingredients: [
          '1 kg pork belly and entrails',
          '2 cups pork blood',
          '1 cup vinegar',
          '4 pieces long green peppers',
          '1 tbsp sugar',
          '4 cloves garlic, minced',
          '1 onion, chopped',
        ],
        directions: [
          'Sauté garlic and onion until aromatic.',
          'Add the pork and cook until slightly browned.',
          'Add the vinegar and simmer without stirring.',
          'Pour in the pork blood while stirring continuously.',
          'Add the green peppers and sugar.',
          'Simmer until the sauce thickens and pork is tender.',
          'Season with salt and pepper to taste.',
        ],
        notes: 'Stirring the blood continuously prevents it from curdling.',
        trivia: 'This dish is often called "chocolate meat" to make it more appealing to children.',
      ),
      Recipe(
        name: 'Sinigang na Hipon',
        category: 'Tanghalian',
        cookingTime: '25 min',
        prepTime: '15 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱300–₱450',
        origin: 'General',
        imageUrl: 'assets/tanghalian/sinigang na hipon.png',
        ingredients: [
          '500g large shrimp',
          '1 pack sinigang mix',
          '1 bunch radish, sliced',
          '1 bunch string beans',
          '2 pieces tomatoes, wedged',
          '1 piece onion, chopped',
          '2 pieces long green pepper',
          '1 bunch kangkong',
        ],
        directions: [
          'Boil water with onion and tomatoes.',
          'Add the radish and string beans.',
          'Stir in the sinigang mix.',
          'Add the shrimp and green peppers.',
          'Simmer for 3 minutes until shrimp turn orange.',
          'Add the kangkong leaves.',
          'Turn off the heat and let the residual heat cook the leaves.',
        ],
        notes: 'Do not overcook the shrimp or they will become rubbery.',
        trivia: 'Sinigang is often considered the most representative dish of Filipino cuisine.',
      ),
      Recipe(
        name: 'Beef Kaldereta',
        category: 'Hapunan',
        cookingTime: '1.5 hours',
        prepTime: '20 min',
        servings: '8',
        difficulty: Difficulty.hard,
        estimatedCost: '₱500–₱800',
        origin: 'Luzon',
        imageUrl: 'assets/hapunan/beef kaldereta.png',
        ingredients: [
          '1 kg beef brisket, cubed',
          '1/2 cup liver spread',
          '1 cup tomato sauce',
          '1/2 cup cheese, grated',
          '2 potatoes, cubed',
          '2 carrots, cubed',
          '1 red bell pepper, sliced',
          '1/2 cup olives (optional)',
        ],
        directions: [
          'Sauté garlic and onion in a large pot.',
          'Add beef and cook until browned.',
          'Pour in tomato sauce and water; simmer until beef is tender.',
          'Add the liver spread and stir well.',
          'Put in the potatoes and carrots.',
          'Add the cheese and bell peppers.',
          'Simmer until the sauce is thick and oily.',
        ],
        notes: 'Using a pressure cooker reduces the beef cooking time to 30 minutes.',
        trivia: 'The name Kaldereta comes from the Spanish word "caldera," meaning cauldron.',
      ),
      Recipe(
        name: 'Chicken Inasal',
        category: 'Hapunan',
        cookingTime: '30 min',
        prepTime: '4 hours',
        servings: '4',
        difficulty: Difficulty.medium,
        estimatedCost: '₱250–₱400',
        origin: 'Iloilo',
        imageUrl: 'assets/hapunan/chicken inasal.png',
        ingredients: [
          '1 kg chicken quarters',
          '1/2 cup vinegar',
          '1/4 cup calamansi juice',
          '1/4 cup ginger, minced',
          '1/4 cup garlic, minced',
          '2 tbsp lemongrass, chopped',
          '1/4 cup achiote oil',
        ],
        directions: [
          'Marinate chicken in vinegar, calamansi, ginger, garlic, and lemongrass for at least 4 hours.',
          'Prepare the charcoal grill.',
          'Baste the chicken with achiote oil while grilling.',
          'Grill until the skin is charred and the meat is cooked through.',
          'Make sure to turn the chicken frequently to avoid burning.',
          'Serve with hot rice and sinamak (spiced vinegar).',
        ],
        notes: 'The achiote oil is what gives Inasal its signature orange color.',
        trivia: 'Bacolod City is world-famous for its "Manokan Country" dedicated to Inasal.',
      ),
      Recipe(
        name: 'Pork Humba',
        category: 'Hapunan',
        cookingTime: '1 hour',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱300–₱450',
        origin: 'Visayas',
        imageUrl: 'assets/hapunan/pork humba.png',
        ingredients: [
          '1 kg pork belly, sliced',
          '1/2 cup soy sauce',
          '1/4 cup vinegar',
          '1/2 cup pineapple juice',
          '1/2 cup brown sugar',
          '1/4 cup salted black beans',
          '1/2 cup dried banana blossoms',
          '2 pieces star anise',
        ],
        directions: [
          'Sauté garlic and onion in a pot.',
          'Add pork and cook until fat is rendered.',
          'Pour in soy sauce, vinegar, and pineapple juice.',
          'Add brown sugar, black beans, and star anise.',
          'Simmer until the pork is very tender.',
          'Add the banana blossoms and cook for another 5 minutes.',
          'Cook until the sauce is reduced and becomes a thick syrup.',
        ],
        notes: 'Banana blossoms add a unique chewy texture and floral aroma.',
        trivia: 'Humba is often described as the Southern version of Adobo but sweeter.',
      ),
      Recipe(
        name: 'Sinampalukang Manok',
        category: 'Hapunan',
        cookingTime: '50 min',
        prepTime: '20 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱200–₱300',
        origin: 'Luzon',
        imageUrl: 'assets/hapunan/sinampalukang manok.png',
        ingredients: [
          '1 kg chicken, cut up',
          '2 cups young tamarind leaves',
          '1/2 cup tamarind fruit pulp',
          '1 piece ginger, sliced',
          '1 piece onion, chopped',
          '2 tbsp fish sauce',
          '6 cups water',
        ],
        directions: [
          'Sauté ginger, onion, and chicken until browned.',
          'Add the fish sauce and stir.',
          'Pour in water and bring to a boil.',
          'Add the tamarind pulp to achieve the desired sourness.',
          'Simmer until the chicken is tender.',
          'Add the young tamarind leaves and green chilies.',
          'Simmer for 2 minutes and serve hot.',
        ],
        notes: 'Fresh young tamarind leaves are essential for the most authentic taste.',
        trivia: 'Sinampalukan differs from Sinigang because the chicken is sautéed with ginger first.',
      ),
      Recipe(
        name: 'Beef Mechado',
        category: 'Hapunan',
        cookingTime: '1 hour 20 min',
        prepTime: '20 min',
        servings: '6',
        difficulty: Difficulty.medium,
        estimatedCost: '₱400–₱600',
        origin: 'Luzon',
        imageUrl: 'assets/hapunan/beef menudo.png',
        ingredients: [
          '1 kg beef chuck, cubed',
          '100g pork fat, sliced into strips',
          '1 cup tomato sauce',
          '2 pieces potatoes, cubed',
          '1 piece onion, chopped',
          '1/4 cup soy sauce',
          '1/4 cup calamansi juice',
          '1 cup beef broth',
        ],
        directions: [
          'Insert a strip of pork fat into the center of each beef cube.',
          'Marinate beef in soy sauce and calamansi juice for 30 minutes.',
          'Brown the beef in a hot pot and set aside.',
          'Sauté onions, then add the beef back into the pot.',
          'Pour in tomato sauce and beef broth.',
          'Simmer until beef is tender.',
          'Add the potatoes and cook until soft.',
        ],
        notes: 'Larding the beef with pork fat ensures it stays moist during long simmering.',
        trivia: 'The term "Mechado" comes from the Spanish word "mecha," which means wick.',
      ),
      Recipe(
        name: 'Crispy Pata',
        category: 'Hapunan',
        cookingTime: '2 hours',
        prepTime: '30 min',
        servings: '6',
        difficulty: Difficulty.hard,
        estimatedCost: '₱600–₱900',
        origin: 'General',
        imageUrl: 'assets/hapunan/crispy pata.png',
        ingredients: [
          '1 whole pork leg (pata)',
          '1/4 cup salt',
          '1 tbsp black peppercorns',
          '4 pieces bay leaves',
          'Oil for deep frying',
          'Vinegar, soy sauce, and chilies for dip',
        ],
        directions: [
          'Boil the pork leg with salt, pepper, and bay leaves until tender.',
          'Drain and let it cool completely.',
          'Prick the skin with a fork and rub with more salt.',
          'Refrigerate overnight for better results.',
          'Heat a large amount of oil in a deep pot.',
          'Deep fry the leg until the skin is golden and blistered.',
          'Serve with a spicy soy-vinegar dip.',
        ],
        notes: 'Freezing the meat before frying makes the skin extra crispy.',
        trivia: 'Crispy Pata was created by Rodolfo Ongpauco in a restaurant in Caloocan City.',
      ),
      Recipe(
        name: 'Bistek Tagalog',
        category: 'Hapunan',
        cookingTime: '30 min',
        prepTime: '20 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱300–₱450',
        origin: 'Luzon',
        imageUrl: 'assets/hapunan/bistek tagalog.png',
        ingredients: [
          '500g beef sirloin, thinly sliced',
          '1/4 cup soy sauce',
          '1/4 cup calamansi juice',
          '2 large onions, sliced into rings',
          '3 cloves garlic, minced',
          '1/2 tsp black pepper',
          '2 tbsp oil',
        ],
        directions: [
          'Marinate beef in soy sauce, calamansi, and pepper for at least 30 mins.',
          'Sauté half of the onion rings until translucent and set aside.',
          'In the same pan, fry the beef slices until browned.',
          'Pour in the marinade and a bit of water.',
          'Simmer for 10 minutes until the beef is tender.',
          'Top with the sautéed and fresh onion rings.',
          'Serve immediately with warm rice.',
        ],
        notes: 'Do not overcook the beef or it will become tough; high heat for a short time is best.',
        trivia: 'Bistek is a corruption of the English words "beef steak."',
      ),
      Recipe(
        name: 'Buko Pandan',
        category: 'Panghimagas',
        cookingTime: '15 min',
        prepTime: '30 min',
        servings: '10',
        difficulty: Difficulty.easy,
        estimatedCost: '₱150–₱250',
        origin: 'General',
        imageUrl: 'assets/panghimagas/buko pandan.png',
        ingredients: [
          '2 cups young coconut (buko), shredded',
          '1 box green jelly (gulaman) powder',
          '1 can condensed milk',
          '1 jar all-purpose cream',
          '1 tsp pandan extract',
          '1/2 cup sago (tapioca pearls)',
        ],
        directions: [
          'Prepare the green jelly according to package instructions with pandan extract.',
          'Once set, cut the jelly into small cubes.',
          'In a large bowl, combine shredded coconut, jelly, and cooked sago.',
          'Stir in the condensed milk and all-purpose cream.',
          'Mix well until everything is evenly coated.',
          'Chill in the refrigerator for at least 4 hours.',
          'Serve cold.',
        ],
        notes: 'Whipping the cream before adding it makes the dessert lighter and fluffier.',
        trivia: 'Pandan leaves are known as the "vanilla of the East" for their sweet aroma.',
      ),
      Recipe(
        name: 'Cassava Cake',
        category: 'Panghimagas',
        cookingTime: '1 hour',
        prepTime: '20 min',
        servings: '12',
        difficulty: Difficulty.medium,
        estimatedCost: '₱200–₱300',
        origin: 'General',
        imageUrl: 'assets/panghimagas/cassava cake.png',
        ingredients: [
          '1 kg grated cassava',
          '2 cans coconut milk',
          '1 can condensed milk',
          '2 eggs',
          '1/4 cup butter, melted',
          'Topping: 1/2 can condensed milk and grated cheese',
        ],
        directions: [
          'Preheat oven to 375°F (190°C).',
          'Mix grated cassava, coconut milk, condensed milk, eggs, and butter.',
          'Pour the mixture into a greased baking pan.',
          'Bake for 45 minutes or until the top is set.',
          'Pour the topping mixture (condensed milk) and sprinkle with cheese.',
          'Bake for another 15 minutes until the top is golden brown.',
          'Let it cool completely before slicing.',
        ],
        notes: 'Squeeze out the juice from the grated cassava to avoid a bitter taste.',
        trivia: 'Cassava is one of the most drought-tolerant crops in the world.',
      ),
      Recipe(
        name: 'Maja Blanca',
        category: 'Panghimagas',
        cookingTime: '30 min',
        prepTime: '10 min',
        servings: '12',
        difficulty: Difficulty.easy,
        estimatedCost: '₱150–₱250',
        origin: 'General',
        imageUrl: 'assets/panghimagas/maja blanca.png',
        ingredients: [
          '4 cups coconut milk',
          '1 can condensed milk',
          '1 can whole kernel corn',
          '1 cup cornstarch',
          '1 cup sugar',
          '1/2 cup water',
          'Topping: Toasted coconut (latik)',
        ],
        directions: [
          'Mix coconut milk, condensed milk, sugar, and corn in a large pot.',
          'Bring to a boil then lower the heat.',
          'Dissolve cornstarch in water and pour into the pot.',
          'Stir continuously until the mixture thickens significantly.',
          'Pour into a serving tray and smooth the surface.',
          'Let it cool and set in the refrigerator.',
          'Top with toasted coconut before serving.',
        ],
        notes: 'Stirring constantly is key to getting a smooth, lump-free consistency.',
        trivia: 'Maja Blanca is a Filipino adaptation of the Spanish blancmange.',
      ),
      Recipe(
        name: 'Ube Halaya',
        category: 'Panghimagas',
        cookingTime: '1 hour',
        prepTime: '30 min',
        servings: '8',
        difficulty: Difficulty.medium,
        estimatedCost: '₱250–₱400',
        origin: 'General',
        imageUrl: 'assets/panghimagas/ube halaya.png',
        ingredients: [
          '1 kg purple yam (ube), boiled and grated',
          '1 can condensed milk',
          '1 can evaporated milk',
          '1/2 cup butter',
          '1 tsp vanilla extract',
        ],
        directions: [
          'Melt butter in a wide non-stick pan.',
          'Add the grated ube, condensed milk, and evaporated milk.',
          'Cook over low heat, stirring constantly for 45-60 minutes.',
          'Add the vanilla extract once the mixture thickens.',
          'Continue stirring until it becomes very thick and sticky.',
          'Transfer to a greased container and smooth the top.',
          'Let it cool before serving.',
        ],
        notes: 'The ube is ready when it starts to pull away from the sides of the pan.',
        trivia: 'Ube Halaya is a staple in Filipino festivities, especially during Christmas.',
      ),
      Recipe(
        name: 'Puto Cheese',
        category: 'Panghimagas',
        cookingTime: '15 min',
        prepTime: '15 min',
        servings: '24',
        difficulty: Difficulty.easy,
        estimatedCost: '₱100–₱150',
        origin: 'General',
        imageUrl: 'assets/panghimagas/puto.png',
        ingredients: [
          '2 cups rice flour',
          '1 cup sugar',
          '1.5 tbsp baking powder',
          '1.5 cups water',
          '1/2 cup evaporated milk',
          'Cheese slices for topping',
        ],
        directions: [
          'Sift the rice flour, sugar, and baking powder together.',
          'Mix in water and milk until the batter is smooth.',
          'Pour the batter into puto molds until 3/4 full.',
          'Steam for 10 minutes over medium heat.',
          'Place a slice of cheese on top of each puto.',
          'Steam for another 2 minutes until cheese is melted.',
          'Let it cool slightly before removing from the molds.',
        ],
        notes: 'Wrap the steamer lid with a cloth to prevent water from dripping onto the puto.',
        trivia: 'Puto is traditionally made from slightly fermented rice dough called galapong.',
      ),
      Recipe(
        name: 'Kutsinta',
        category: 'Panghimagas',
        cookingTime: '45 min',
        prepTime: '10 min',
        servings: '20',
        difficulty: Difficulty.medium,
        estimatedCost: '₱50–₱100',
        origin: 'General',
        imageUrl: 'assets/panghimagas/kutsinta.png',
        ingredients: [
          '1.5 cups rice flour',
          '1/2 cup all-purpose flour',
          '1 cup brown sugar',
          '2 cups water',
          '1 tsp lye water',
          'Grated coconut for topping',
        ],
        directions: [
          'Combine rice flour, all-purpose flour, and brown sugar in a bowl.',
          'Gradually add water and stir until no lumps remain.',
          'Add the lye water and mix well.',
          'Strain the mixture to ensure it is smooth.',
          'Pour into small molds and steam for 30-40 minutes.',
          'Let it cool completely before unmolding.',
          'Serve with plenty of fresh grated coconut.',
        ],
        notes: 'Lye water is what gives Kutsinta its characteristic jelly-like texture.',
        trivia: 'Kutsinta is almost always served alongside Puto during snack time.',
      ),
      Recipe(
        name: 'Sapin-Sapin',
        category: 'Panghimagas',
        cookingTime: '1 hour',
        prepTime: '30 min',
        servings: '12',
        difficulty: Difficulty.hard,
        estimatedCost: '₱250–₱400',
        origin: 'Luzon',
        imageUrl: 'assets/panghimagas/sapin sapin.png',
        ingredients: [
          '1.5 cups glutinous rice flour',
          '1 cup sugar',
          '2 cups coconut milk',
          '1/2 cup ube jam',
          '1/2 cup jackfruit, pureed',
          'Yellow and purple food coloring',
          'Toasted coconut (latik) for garnish',
        ],
        directions: [
          'Mix glutinous rice flour, sugar, and coconut milk until smooth.',
          'Divide the mixture into three equal parts.',
          'Add ube jam and purple coloring to the first part.',
          'Add jackfruit puree and yellow coloring to the second part.',
          'Keep the third part white.',
          'Steam the purple layer for 15 minutes.',
          'Pour the yellow layer over it and steam for another 15 minutes.',
          'Add the final white layer and steam for 20 minutes.',
          'Let it cool and top with latik.',
        ],
        notes: 'Brush the bottom of the pan with coconut oil to prevent sticking.',
        trivia: 'The name Sapin-Sapin literally means "layers" in Tagalog.',
      ),
      Recipe(
        name: 'Turon',
        category: 'Merienda',
        cookingTime: '20 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.easy,
        estimatedCost: '₱50–₱100',
        origin: 'General',
        imageUrl: 'assets/merienda/turon.png',
        ingredients: [
          '6 saba bananas, halved lengthwise',
          '12 lumpia wrappers',
          '1/2 cup brown sugar',
          '1/2 cup jackfruit strips (optional)',
          'Oil for frying',
        ],
        directions: [
          'Roll each banana half in brown sugar.',
          'Place a sugared banana and a few jackfruit strips on a wrapper.',
          'Fold the sides and roll tightly.',
          'Heat oil in a pan and add a tablespoon of sugar.',
          'Fry the rolls until the wrapper is golden brown.',
          'The sugar in the oil will stick to the wrapper as it fries.',
          'Drain on a wire rack to keep it crispy.',
        ],
        notes: 'Avoid using paper towels to drain turon as the sugar will stick to them.',
        trivia: 'Turon is often considered the most popular afternoon street snack in Manila.',
      ),
      Recipe(
        name: 'Ginataan Bilo-Bilo',
        category: 'Merienda',
        cookingTime: '40 min',
        prepTime: '20 min',
        servings: '8',
        difficulty: Difficulty.medium,
        estimatedCost: '₱200–₱300',
        origin: 'Luzon',
        imageUrl: 'assets/merienda/ginataan bilobilo.png',
        ingredients: [
          '2 cups glutinous rice flour',
          '1 cup water',
          '4 cups coconut milk',
          '1 cup sugar',
          '1 cup sweet potato, cubed',
          '1 cup taro, cubed',
          '1 cup jackfruit strips',
          '1/2 cup sago pearls',
        ],
        directions: [
          'Mix rice flour and water to form small balls (bilo-bilo).',
          'Bring coconut milk and sugar to a boil.',
          'Add the sweet potato and taro; cook until almost soft.',
          'Drop the rice balls into the simmering mixture.',
          'Once the balls float, they are cooked.',
          'Stir in the sago and jackfruit.',
          'Simmer for 5 minutes until the sauce is slightly thick.',
        ],
        notes: 'Adding more sweet potato naturally thickens and sweetens the coconut milk.',
        trivia: 'Bilo-bilo refers to the sound the sticky rice balls make as they boil.',
      ),
      Recipe(
        name: 'Kwek-Kwek',
        category: 'Merienda',
        cookingTime: '15 min',
        prepTime: '15 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱50–₱100',
        origin: 'General',
        imageUrl: 'assets/merienda/kwek kwek.png',
        ingredients: [
          '12 quail eggs, hard-boiled and peeled',
          '1 cup flour',
          '1/2 cup cornstarch',
          '1/2 cup water',
          '1 tsp annatto powder',
          'Oil for deep frying',
        ],
        directions: [
          'Mix flour, cornstarch, water, and annatto powder into a smooth batter.',
          'Dredge boiled quail eggs in dry flour.',
          'Dip the eggs into the orange batter until fully coated.',
          'Heat oil to 350°F (175°C).',
          'Carefully drop the coated eggs into the oil.',
          'Fry until the batter is crispy (about 2 minutes).',
          'Serve with a spiced vinegar dip.',
        ],
        notes: 'The dry flour coating helps the batter stick better to the eggs.',
        trivia: 'The name Kwek-Kwek is an onomatopoeic word imitating the sound of a bird.',
      ),
      Recipe(
        name: 'Maruya',
        category: 'Merienda',
        cookingTime: '20 min',
        prepTime: '10 min',
        servings: '4',
        difficulty: Difficulty.easy,
        estimatedCost: '₱50–₱100',
        origin: 'General',
        imageUrl: 'assets/merienda/maruya.png',
        ingredients: [
          '4 saba bananas, mashed or sliced',
          '1 cup flour',
          '1/2 cup milk',
          '1 egg',
          '1 tsp baking powder',
          '1/4 cup sugar for dusting',
          'Oil for frying',
        ],
        directions: [
          'Combine flour, baking powder, egg, and milk to make a batter.',
          'Stir in the mashed bananas until well mixed.',
          'Heat oil in a pan.',
          'Scoop a portion of the mixture and fry until golden brown.',
          'Flip to cook the other side.',
          'Drain on paper towels.',
          'Dust with sugar while still warm.',
        ],
        notes: 'Use overripe bananas for a sweeter and softer fritter.',
        trivia: 'Maruya is a staple snack often sold by roadside vendors near schools.',
      ),
      Recipe(
        name: 'Puto Bumbong',
        category: 'Merienda',
        cookingTime: '10 min',
        prepTime: '12 hours',
        servings: '6',
        difficulty: Difficulty.hard,
        estimatedCost: '₱150–₱250',
        origin: 'Luzon',
        imageUrl: 'assets/merienda/puto bumbong.png',
        ingredients: [
          '2 cups purple glutinous rice (pirurutong)',
          '1/2 cup glutinous rice',
          'Water for soaking',
          'Butter or margarine',
          'Grated coconut',
          'Muscovado sugar',
        ],
        directions: [
          'Soak both types of rice in water overnight.',
          'Grind the soaked rice until smooth and drain well.',
          'Fill bamboo tubes (bumbong) with the rice mixture.',
          'Steam the tubes vertically for about 5 minutes.',
          'Push out the purple rice cakes from the tubes.',
          'Spread with butter and top with grated coconut.',
          'Sprinkle generously with muscovado sugar.',
        ],
        notes: 'Using authentic pirurutong rice gives the best color and flavor.',
        trivia: 'Puto Bumbong is traditionally associated with the Simbang Gabi Christmas masses.',
      ),
      Recipe(
        name: 'Sotanghon Guisado',
        category: 'Merienda',
        cookingTime: '30 min',
        prepTime: '15 min',
        servings: '6',
        difficulty: Difficulty.easy,
        estimatedCost: '₱150–₱250',
        origin: 'General',
        imageUrl: 'assets/merienda/sotanghon guisado.png',
        ingredients: [
          '250g glass noodles (sotanghon)',
          '100g chicken, shredded',
          '1/2 cup carrots, julienned',
          '1/2 cup cabbage, shredded',
          '2 tbsp achiote oil',
          '3 cups chicken broth',
          '2 tbsp fish sauce',
        ],
        directions: [
          'Soak sotanghon in water for 10 minutes then drain.',
          'Sauté garlic and onion in achiote oil.',
          'Add chicken and cook for 5 minutes.',
          'Pour in chicken broth and bring to a boil.',
          'Add the noodles and cook until they absorb the liquid.',
          'Stir in the carrots and cabbage.',
          'Season with fish sauce and black pepper.',
        ],
        notes: 'Achiote oil gives the noodles a beautiful golden-orange tint.',
        trivia: 'Sotanghon noodles are also known as cellophane or glass noodles.',
      ),
      Recipe(
        name: 'Lumpiang Sariwa',
        category: 'Merienda',
        cookingTime: '30 min',
        prepTime: '30 min',
        servings: '6',
        difficulty: Difficulty.hard,
        estimatedCost: '₱200–₱300',
        origin: 'Luzon',
        imageUrl: 'assets/merienda/lumpiang sariwa.png',
        ingredients: [
          'Fresh lumpia wrappers',
          'Lettuce leaves',
          '1 cup heart of palm (ubod), julienned',
          '1/2 cup carrots, julienned',
          '1/2 cup peanuts, crushed',
          'Sweet brown sauce (soy, sugar, starch)',
          'Minced garlic for garnish',
        ],
        directions: [
          'Sauté ubod and carrots until tender.',
          'Lay a wrapper flat and place a lettuce leaf on top.',
          'Add a few spoons of the vegetable filling.',
          'Roll the wrapper securely.',
          'Prepare the sweet sauce by thickening soy sauce and sugar with starch.',
          'Pour the sauce over the roll.',
          'Garnish with crushed peanuts and minced garlic.',
        ],
        notes: 'Using fresh ubod (heart of palm) is superior to using bamboo shoots.',
        trivia: 'Unlike the fried version, this "fresh" lumpia uses a soft crepelike wrapper.',
      ),
    ];
    _updateFavorites();
  }

  void _updateFavorites() {
    setState(() {
      _favorites = _recipes.where((recipe) => recipe.isFavorite).toList();
    });
    _checkAchievements();
  }

  void _toggleFavorite(Recipe recipe) {
    setState(() {
      recipe.isFavorite = !recipe.isFavorite;
      _updateFavorites();
    });
    _saveData();
  }

  void _addToShoppingList(Recipe recipe) {
    int addedCount = 0;
    setState(() {
      for (int i = 0; i < recipe.ingredients.length; i++) {
        if (recipe.ingredientStatus[i]) continue;
        var ingredient = recipe.ingredients[i];
        bool exists = _shoppingList.any((item) => item.recipeName == recipe.name && item.ingredient == ingredient);
        if (!exists) {
          _shoppingList.add(ShoppingItem(recipeName: recipe.name, ingredient: ingredient));
          addedCount++;
        }
      }
    });
    _checkAchievements();
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(addedCount > 0 ? 'Added $addedCount missing items from ${recipe.name}' : 'No new missing ingredients to add for ${recipe.name}'),
        backgroundColor: const Color(0xFF8B4513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearShoppingList() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Shopping List', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove all items from your shopping list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CLEAR ALL', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _shoppingList.clear());
      _saveData();
    }
  }

  void _toggleShoppingItem(int index) {
    setState(() {
      final item = _shoppingList[index];
      item.isChecked = !item.isChecked;
      final recipe = _recipes.firstWhere((r) => r.name == item.recipeName, orElse: () => _recipes[0]);
      int ingredientIndex = recipe.ingredients.indexOf(item.ingredient);
      if (ingredientIndex != -1) recipe.ingredientStatus[ingredientIndex] = item.isChecked;
    });
    _saveData();
  }

  void _removeShoppingItem(int index) {
    setState(() => _shoppingList.removeAt(index));
    _saveData();
  }

  void _removeRecipeFromShoppingList(String recipeName) {
    setState(() => _shoppingList.removeWhere((item) => item.recipeName == recipeName));
    _saveData();
  }

  void _restoreRecipe(Recipe recipe) {
    setState(() {
      _deletedRecipeNames.remove(recipe.name);
      _trash.removeWhere((r) => r.name == recipe.name);
      if (!_recipes.any((r) => r.name == recipe.name)) {
        _recipes.add(recipe);
      }
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restored ${recipe.name}')));
  }

  void _permanentlyDeleteRecipe(Recipe recipe) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete "${recipe.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE PERMANENTLY', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _trash.removeWhere((r) => r.name == recipe.name));
      _saveData();
    }
  }

  void _deleteRecipe(Recipe recipe) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${recipe.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _trash.add(recipe);
        _deletedRecipeNames.add(recipe.name);
        _recipes.removeWhere((r) => r.name == recipe.name);
        _favorites.removeWhere((r) => r.name == recipe.name);
        _recentlyViewed.removeWhere((r) => r.name == recipe.name);
        _shoppingList.removeWhere((item) => item.recipeName == recipe.name);
      });
      _saveData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted ${recipe.name}')));
    }
  }

  void _openCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _categoryRecipes = _recipes.where((r) => r.category == category).toList();
      _showBookCover = false;
      _showTableOfContents = false;
      _showQuiz = false;
      _showWhatCanICook = false;
      _showRecentlyViewed = false;
      _showAchievements = false;
      _showTrash = false;
    });
  }

  void _syncShoppingListWithRecipe(Recipe recipe) {
    setState(() {
      for (int i = 0; i < recipe.ingredients.length; i++) {
        String ingredient = recipe.ingredients[i];
        bool status = recipe.ingredientStatus[i];
        for (var item in _shoppingList) {
          if (item.recipeName == recipe.name && item.ingredient == ingredient) {
            item.isChecked = status;
          }
        }
      }
    });
    _saveData();
  }

  void _trackView(Recipe recipe) {
    setState(() {
      recipe.viewCount++;
      _recentlyViewed.removeWhere((r) => r.name == recipe.name);
      _recentlyViewed.insert(0, recipe);
      if (_recentlyViewed.length > 10) _recentlyViewed.removeLast();
    });
    _checkAchievements();
    _saveData();
  }

  void _surpriseMe() {
    if (_recipes.isEmpty) return;
    final randomRecipe = _recipes[Random().nextInt(_recipes.length)];
    _trackView(randomRecipe);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipe: randomRecipe,
          onToggleFavorite: _toggleFavorite,
          onAddToShoppingList: _addToShoppingList,
          onSyncShoppingList: _syncShoppingListWithRecipe,
          allRecipes: _recipes,
          onCooked: (r) { setState(() => r.isCooked = true); _checkAchievements(); _saveData(); },
        ),
      ),
    );
  }

  void _openQuiz() { setState(() { _showQuiz = true; _showBookCover = false; _showTableOfContents = false; _showWhatCanICook = false; _showAchievements = false; _showRecentlyViewed = false; _showTrash = false; }); }
  void _openWhatCanICook() { setState(() { _showWhatCanICook = true; _showBookCover = false; _showTableOfContents = false; _showQuiz = false; _showAchievements = false; _showRecentlyViewed = false; _showTrash = false; }); }
  void _openRecentlyViewed() { setState(() { _showRecentlyViewed = true; _showBookCover = false; _showTableOfContents = false; _showQuiz = false; _showWhatCanICook = false; _showAchievements = false; _showTrash = false; }); }
  void _openTrash() { setState(() { _showTrash = true; _showBookCover = false; _showTableOfContents = false; _showQuiz = false; _showWhatCanICook = false; _showAchievements = false; _showRecentlyViewed = false; }); }
  void _openAchievements() { setState(() { _showAchievements = true; _showBookCover = false; _showTableOfContents = false; _showQuiz = false; _showWhatCanICook = false; _showRecentlyViewed = false; _showTrash = false; }); }

  void _addNewRecipe(Recipe recipe) {
    setState(() {
      _deletedRecipeNames.remove(recipe.name);
      _recipes.add(recipe);
      _achievements[5].isUnlocked = true;
    });
    _saveData();
  }

  void _showTableOfContentsView() { 
    setState(() { 
      _showTableOfContents = true; 
      _showBookCover = false; 
      _showQuiz = false; 
      _showWhatCanICook = false; 
      _showAchievements = false; 
      _showRecentlyViewed = false; 
      _showTrash = false; 
      _isSearching = false;
      _searchController.clear();
    }); 
  }
  
  void _goBackToBookCover() { 
    setState(() { 
      _showBookCover = true; 
      _showTableOfContents = false; 
      _showQuiz = false; 
      _showWhatCanICook = false; 
      _showAchievements = false; 
      _showRecentlyViewed = false; 
      _showTrash = false; 
      _selectedCategory = ''; 
      _isSearching = false;
      _searchController.clear();
    }); 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: _selectedIndex == 0 && _showBookCover,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) { setState(() => _selectedIndex = 0); return; }
        if (_showQuiz || _showWhatCanICook || _showAchievements || _showRecentlyViewed || _showTrash || _selectedCategory.isNotEmpty) {
          _showTableOfContentsView();
        } else if (_showTableOfContents) {
          _goBackToBookCover();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        appBar: _selectedIndex == 0 && !_showBookCover ? AppBar(
          backgroundColor: const Color(0xFF8B4513),
          elevation: 0,
          title: Text(
            _showTableOfContents ? 'CONTENTS' : (_showQuiz ? 'QUIZ' : (_showWhatCanICook ? 'WHAT CAN I COOK?' : (_showAchievements ? 'ACHIEVEMENTS' : (_showRecentlyViewed ? 'RECENT' : (_showTrash ? 'TRASH' : _selectedCategory.toUpperCase()))))),
            style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, color: Colors.white, letterSpacing: 1),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_selectedCategory.isNotEmpty || _isSearching)
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
                onPressed: () => setState(() => _isGridView = !_isGridView),
                tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
              ),
            if (_showTableOfContents) IconButton(icon: const Icon(Icons.casino, color: Colors.white), onPressed: _surpriseMe, tooltip: 'Surprise Me!'),
          ],
        ) : null,
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeScreen(),
            _buildFavoritesScreen(),
            _buildShoppingListScreen(),
          ],
        ),
        bottomNavigationBar: _selectedIndex == 0 && _showBookCover ? null : Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: const Color(0xFF8B4513),
            unselectedItemColor: Colors.grey.shade400,
            showUnselectedLabels: true,
            selectedLabelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: GoogleFonts.lato(fontSize: 12),
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_outlined),
                activeIcon: Icon(Icons.restaurant),
                label: 'Kitchen',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Market',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFDF8F0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            const SizedBox(height: 12),
            _buildDrawerSectionHeader('NAVIGATION'),
            _buildDrawerItem(Icons.home, 'Home', () { _goBackToBookCover(); Navigator.pop(context); setState(() => _selectedIndex = 0); }),
            _buildDrawerItem(Icons.favorite, 'Favorites', () { Navigator.pop(context); setState(() => _selectedIndex = 1); }),
            _buildDrawerItem(Icons.shopping_cart, 'Shopping List', () { Navigator.pop(context); setState(() => _selectedIndex = 2); }),
            _buildDrawerItem(Icons.restaurant_menu, 'Categories', () { _showTableOfContentsView(); Navigator.pop(context); setState(() => _selectedIndex = 0); }),
            
            const Divider(height: 32, indent: 20, endIndent: 20),
            _buildDrawerSectionHeader('PREFERENCES'),
            ListTile(
              leading: Icon(
                themeNotifier.value == ThemeMode.light ? Icons.dark_mode : Icons.light_mode, 
                color: const Color(0xFF8B4513)
              ),
              title: Text(
                themeNotifier.value == ThemeMode.light ? 'Dark Mode' : 'Light Mode', 
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: isDark ? Colors.white : const Color(0xFF5D2E0C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                themeNotifier.value = themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            ),
            
            const Divider(height: 32, indent: 20, endIndent: 20),
            _buildDrawerSectionHeader('TOOLS & STATS'),
            _buildDrawerItem(Icons.restaurant, 'What Can I Cook?', () { _openWhatCanICook(); Navigator.pop(context); }),
            _buildDrawerItem(Icons.history, 'Recently Viewed', () { _openRecentlyViewed(); Navigator.pop(context); }),
            _buildDrawerItem(Icons.delete, 'Trash bin', () { _openTrash(); Navigator.pop(context); }),
            _buildDrawerItem(Icons.emoji_events, 'Achievements', () { _openAchievements(); Navigator.pop(context); }),
            _buildDrawerItem(Icons.lightbulb, 'Recipe Quiz', () { _openQuiz(); Navigator.pop(context); }),
            
            const Divider(height: 32, indent: 20, endIndent: 20),
            _buildDrawerItem(Icons.add_circle, 'Add New Recipe', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddRecipeScreen(onAdd: _addNewRecipe)));
            }, color: const Color(0xFF27AE60)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 16, bottom: 8),
      child: Text(
        title, 
        style: GoogleFonts.lato(
          fontSize: 11, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white38 : Colors.grey.shade500, 
          letterSpacing: 2.0
        )
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF8B4513),
        image: DecorationImage(
          image: const AssetImage('assets/icon/logo.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            'KUSINA BOOK',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'The Heart of Filipino Kitchen',
            style: GoogleFonts.lato(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFF8B4513)),
        title: Text(
          title, 
          style: GoogleFonts.lato(
            color: isDark ? Colors.white : const Color(0xFF5D2E0C),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, 
          end: Alignment.bottomCenter, 
          colors: isDark 
            ? [const Color(0xFF1E1E1E), const Color(0xFF121212)] 
            : [const Color(0xFFF5F0E8), const Color(0xFFE8E0D5)]
        )
      ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 500, // Limit width on tablets
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), 
                spreadRadius: 5, 
                blurRadius: 30, 
                offset: const Offset(0, 10)
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showBookCover 
                  ? _buildBookCoverPage(key: const ValueKey('cover')) 
                  : _buildActivePage(key: const ValueKey('content')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePage({Key? key}) {
    Widget content;
    String type;
    if (_showQuiz) {
      content = _buildQuizPage();
      type = 'quiz';
    } else if (_showWhatCanICook) {
      content = _buildWhatCanICookPage();
      type = 'whatcanicook';
    } else if (_showRecentlyViewed) {
      content = _buildRecentlyViewedPage();
      type = 'recent';
    } else if (_showAchievements) {
      content = _buildAchievementsPage();
      type = 'achievements';
    } else if (_showTrash) {
      content = _buildTrashPage();
      type = 'trash';
    } else if (_showTableOfContents || _isSearching) {
      content = _buildTableOfContentsPage();
      type = 'toc';
    } else {
      content = _buildCategoryPage();
      type = 'category_$_selectedCategory';
    }
    
    // Standard transition for pages inside the book
    return AnimatedSwitcher(
      key: key,
      duration: const Duration(milliseconds: 300),
      child: SizedBox(key: ValueKey(type), child: content),
    );
  }

  Widget _buildBookCoverPage({Key? key}) {
    return Stack(
      key: key,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, 
              end: Alignment.bottomRight, 
              colors: [Color(0xFF8B4513), Color(0xFF6B3410), Color(0xFF4A2508)]
            )
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white12, size: 24), 
                                  Icon(Icons.auto_awesome, color: Colors.white12, size: 24)
                                ]
                              ),
                              const Spacer(),
                              
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    )
                                  ],
                                  border: Border.all(color: const Color(0xFFD4A574).withOpacity(0.6), width: 3),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icon/logo.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'KUSINA',
                                style: GoogleFonts.lato(
                                  color: const Color(0xFFD4A574),
                                  fontSize: 18,
                                  letterSpacing: 10,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                'BOOK',
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  height: 1,
                                  shadows: [
                                    const Shadow(color: Colors.black45, offset: Offset(2, 6), blurRadius: 12)
                                  ]
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(width: 60, height: 2.5, color: const Color(0xFFD4A574)),
                              const SizedBox(height: 16),
                              Text(
                                'Authentic Filipino Flavors',
                                style: GoogleFonts.lato(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              
                              const Spacer(),
                              
                              ElevatedButton(
                                onPressed: _showTableOfContentsView, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, 
                                  foregroundColor: const Color(0xFF8B4513),
                                  minimumSize: const Size(220, 64),
                                  elevation: 12,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                ), 
                                child: Text(
                                  'OPEN THE KITCHEN', 
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 24),

                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white12, size: 24), 
                                  Icon(Icons.auto_awesome, color: Colors.white12, size: 24)
                                ]
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
            ),
          ),
        ),
        _buildBookSpine(),
      ],
    );
  }

  Widget _buildBookSpine() {
    return Positioned(
      left: 0, top: 0, bottom: 0,
      child: Container(
        width: 45,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.1), Colors.white.withOpacity(0.05), Colors.transparent])),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(8, (i) => Container(margin: const EdgeInsets.symmetric(vertical: 20), width: 2, height: 15, color: Colors.white.withOpacity(0.1)))),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (_) => _onSearchChanged(),
        onSubmitted: (_) => _onSearchChanged(),
        decoration: InputDecoration(
          hintText: 'Search recipe, category, ingredient...',
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear), 
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged();
                }) 
            : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true, 
          fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        ),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildTableOfContentsPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF5D2E0C);
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFDF8F0),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 10),
          Expanded(
            child: _isSearching 
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
                      child: Text(
                        'SEARCH RESULTS', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
                      )
                    ),
                    Expanded(child: _searchResults.isEmpty 
                      ? _buildEmptyState(Icons.search_off, 'No recipes found') 
                      : _buildRecipeListBody(_searchResults)),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'CATEGORIES', 
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: textColor.withOpacity(0.7))
                    ),
                    const Divider(),
                    ..._categoryIcons.keys.map((cat) => _buildMenuTile(cat, () => _openCategory(cat))),
                  ],
                ),
          ),
          _buildBookFooter(_isSearching ? 'SEARCH RESULTS' : 'CONTENTS', () {
            if (_isSearching) {
              setState(() { _isSearching = false; _searchController.clear(); });
            } else {
              _goBackToBookCover();
            }
          }, null),
        ],
      ),
    );
  }

  Widget _buildMenuTile(String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = _categoryIcons[title] ?? Icons.restaurant;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF8B4513), size: 24),
          ),
          title: Text(
            title, 
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold, 
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF5D2E0C)
            )
          ),
          onTap: onTap,
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : const Color(0xFFD4A574)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }


  Widget _buildRecipeList(String title, List<Recipe> recipes, VoidCallback onBack) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
          child: Text(
            title, 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF5D2E0C)
            )
          )
        ),
        Expanded(child: _buildRecipeListBody(recipes)),
        _buildBookFooter(title, onBack, null),
      ],
    );
  }

  Widget _buildRecipeListBody(List<Recipe> recipes) {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, i) => _buildRecipeGridItem(recipes[i]),
      );
    }
    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, i) {
        final r = recipes[i];
        return ListTile(
          leading: SizedBox(width: 50, height: 50, child: RecipeImage(imageUrl: r.imageUrl, isCircle: true)),
          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${r.difficulty.name} • ${r.cookingTime}'),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20), onPressed: () => _deleteRecipe(r)),
          onTap: () {
            _trackView(r);
            Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(
              recipe: r,
              onToggleFavorite: _toggleFavorite,
              onAddToShoppingList: _addToShoppingList,
              onSyncShoppingList: _syncShoppingListWithRecipe,
              allRecipes: _recipes,
              onCooked: (rec) { setState(() => rec.isCooked = true); _checkAchievements(); _saveData(); },
            )));
          },
        );
      },
    );
  }

  Widget _buildRecipeGridItem(Recipe r) {
    return InkWell(
      onTap: () {
        _trackView(r);
        Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(
          recipe: r,
          onToggleFavorite: _toggleFavorite,
          onAddToShoppingList: _addToShoppingList,
          onSyncShoppingList: _syncShoppingListWithRecipe,
          allRecipes: _recipes,
          onCooked: (rec) { setState(() => rec.isCooked = true); _checkAchievements(); _saveData(); },
        )));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RecipeImage(imageUrl: r.imageUrl),
              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.name,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white70, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              r.cookingTime,
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A574).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r.difficulty.name.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(r),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      r.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: r.isFavorite ? Colors.red : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPage() => _buildRecipeList(_selectedCategory, _categoryRecipes, _showTableOfContentsView);

  Widget _buildWhatCanICookPage() {
    List<Recipe> ready = _recipes.where((r) => r.availabilityPercentage == 100).toList();
    List<Recipe> almost = _recipes.where((r) => r.availabilityPercentage >= 50 && r.availabilityPercentage < 100).toList();
    return Column(
      children: [
        Expanded(child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('✅ READY TO COOK', Colors.green),
            ...ready.map((r) => _buildInventoryTile(r, '100% ingredients available', Colors.green)),
            const SizedBox(height: 24),
            _buildSectionHeader('🟡 ALMOST READY', Colors.orange),
            ...almost.map((r) => _buildInventoryTile(r, '${r.availabilityPercentage.toStringAsFixed(0)}% available', Colors.orange)),
          ],
        )),
        _buildBookFooter('INVENTORY', _showTableOfContentsView, null),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2, fontSize: 13)),
    );
  }

  Widget _buildInventoryTile(Recipe r, String sub, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: ListTile(
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          _trackView(r);
          Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(
            recipe: r,
            onToggleFavorite: _toggleFavorite,
            onAddToShoppingList: _addToShoppingList,
            onSyncShoppingList: _syncShoppingListWithRecipe,
            allRecipes: _recipes,
            onCooked: (rec) { setState(() => rec.isCooked = true); _checkAchievements(); _saveData(); },
          )));
        },
      ),
    );
  }

  Widget _buildRecentlyViewedPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), 
          child: Text(
            'RECENTLY VIEWED', 
            style: GoogleFonts.playfairDisplay(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF5D2E0C),
            ),
          ),
        ),
        Expanded(
          child: _recentlyViewed.isEmpty 
            ? _buildEmptyState(Icons.history, 'Your culinary journey starts here')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recentlyViewed.length,
                itemBuilder: (context, i) => _buildRecipeCard(_recentlyViewed[i]),
              ),
        ),
        _buildBookFooter('RECENT', _showTableOfContentsView, null),
      ],
    );
  }

  Widget _buildTrashPage() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(20), child: const Text('TRASH BIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Expanded(child: _trash.isEmpty ? _buildEmptyState(Icons.delete_outline, 'Trash is empty') : ListView.builder(
          itemCount: _trash.length,
          itemBuilder: (context, i) {
            final r = _trash[i];
            return ListTile(
              leading: SizedBox(width: 50, height: 50, child: RecipeImage(imageUrl: r.imageUrl, isCircle: true)),
              title: Text(r.name),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.restore, color: Colors.green), onPressed: () => _restoreRecipe(r)),
                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _permanentlyDeleteRecipe(r)),
              ]),
            );
          },
        )),
        _buildBookFooter('ARCHIVE', _showTableOfContentsView, null),
      ],
    );
  }

  Widget _buildAchievementsPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _achievements.length,
          itemBuilder: (context, i) {
            final a = _achievements[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: a.isUnlocked ? const Color(0xFF8B4513).withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon, color: a.isUnlocked ? Colors.amber : Colors.grey.withOpacity(0.1)),
                ),
                title: Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: a.isUnlocked ? null : TextDecoration.lineThrough, color: a.isUnlocked ? null : Colors.grey)),
                subtitle: Text(a.description, style: TextStyle(fontSize: 12, color: a.isUnlocked ? null : Colors.grey)),
                trailing: a.isUnlocked ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
              ),
            );
          },
        )),
        _buildBookFooter('BADGES', _showTableOfContentsView, null),
      ],
    );
  }

  Widget _buildFavoritesScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513), 
        elevation: 0, 
        centerTitle: true, 
        title: const Text('❤️ Favorites', style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: Colors.white),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: _favorites.isEmpty 
          ? _buildEmptyState(Icons.favorite_border, 'No favorites yet') 
          : (_isGridView ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: _favorites.length,
              itemBuilder: (context, i) => _buildRecipeGridItem(_favorites[i]),
            ) : ListView.builder(
              padding: const EdgeInsets.all(16), 
              itemCount: _favorites.length, 
              itemBuilder: (context, i) => _buildRecipeCard(_favorites[i]),
            )),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white24 : const Color(0xFF8B4513).withOpacity(0.1);
    final iconColor = isDark ? Colors.white38 : const Color(0xFFD4A574).withOpacity(0.1);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 80, color: iconColor),
          ),
          const SizedBox(height: 24), 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              msg, 
              textAlign: TextAlign.center, 
              style: GoogleFonts.playfairDisplay(
                fontSize: 22, 
                color: isDark ? Colors.white54 : const Color(0xFF8B4513).withOpacity(0.1), 
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RecipeImage(imageUrl: r.imageUrl),
            ),
          ),
          title: Text(
            r.name,
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF5D2E0C),
            ),
          ),
          subtitle: Text(
            '${r.category} • ${r.cookingTime}',
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 22),
            onPressed: () => _deleteRecipe(r),
          ),
          onTap: () {
            _trackView(r);
            Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(
              recipe: r,
              onToggleFavorite: _toggleFavorite,
              onAddToShoppingList: _addToShoppingList,
              onSyncShoppingList: _syncShoppingListWithRecipe,
              allRecipes: _recipes,
              onCooked: (rec) { setState(() => rec.isCooked = true); _checkAchievements(); _saveData(); },
            )));
          },
        ),
      ),
    );
  }

  Widget _buildShoppingListScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Map<String, List<ShoppingItem>> grouped = {};
    for (var item in _shoppingList) { grouped.putIfAbsent(item.recipeName, () => []).add(item); }
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F0E8),
      appBar: AppBar(backgroundColor: const Color(0xFF8B4513), title: const Text('🛒 Shopping List', style: TextStyle(color: Colors.white)), actions: [if (_shoppingList.isNotEmpty) IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.white), onPressed: _clearShoppingList)]),
      body: _shoppingList.isEmpty ? _buildEmptyState(Icons.shopping_cart_outlined, 'Shopping list is empty') : ListView(padding: const EdgeInsets.all(16), children: grouped.keys.map((name) => _buildShoppingGroup(name, grouped[name]!)).toList()),
    );
  }

  Widget _buildShoppingGroup(String name, List<ShoppingItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ListTile(
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B4513), letterSpacing: 0.5)),
              trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => _removeRecipeFromShoppingList(name)),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          ...items.map((item) {
            int index = _shoppingList.indexOf(item);
            return ListTile(
              dense: true,
              leading: Checkbox(
                value: item.isChecked, 
                activeColor: const Color(0xFF8B4513), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) => _toggleShoppingItem(index)
              ),
              title: Text(item.ingredient, style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null, color: item.isChecked ? Colors.grey : (isDark ? Colors.white : const Color(0xFF5D2E0C)))),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => _removeShoppingItem(index)),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBookFooter(String label, VoidCallback onBack, String? rightText) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          TextButton.icon(onPressed: onBack, icon: const Icon(Icons.keyboard_arrow_left), label: const Text('BACK')),
          Expanded(child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey), textAlign: TextAlign.center)),
          const SizedBox(width: 70),
        ],
      ),
    );
  }

  Widget _buildQuizPage() => RecipeQuizView(onBack: _showTableOfContentsView, onComplete: () { _achievements[4].isUnlocked = true; _checkAchievements(); });
}

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onToggleFavorite;
  final Function(Recipe) onAddToShoppingList;
  final Function(Recipe) onSyncShoppingList;
  final List<Recipe> allRecipes;
  final Function(Recipe) onCooked;

  const RecipeDetailScreen({super.key, required this.recipe, required this.onToggleFavorite, required this.onAddToShoppingList, required this.onSyncShoppingList, required this.allRecipes, required this.onCooked});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    int initialIdx = widget.allRecipes.indexOf(widget.recipe);
    _pageController = PageController(initialPage: initialIdx);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.allRecipes.length,
      itemBuilder: (context, index) {
        final recipe = widget.allRecipes[index];
        return RecipeDetailView(
          recipe: recipe,
          onToggleFavorite: widget.onToggleFavorite,
          onAddToShoppingList: widget.onAddToShoppingList,
          onSyncShoppingList: widget.onSyncShoppingList,
          onCooked: widget.onCooked,
          allRecipes: widget.allRecipes,
          currentIndex: index,
          onNext: index < widget.allRecipes.length - 1 ? () {
            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          } : null,
          onPrev: index > 0 ? () {
            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          } : null,
        );
      },
    );
  }
}

class RecipeDetailView extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onToggleFavorite;
  final Function(Recipe) onAddToShoppingList;
  final Function(Recipe) onSyncShoppingList;
  final Function(Recipe) onCooked;
  final List<Recipe> allRecipes;
  final int currentIndex;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const RecipeDetailView({
    super.key,
    required this.recipe,
    required this.onToggleFavorite,
    required this.onAddToShoppingList,
    required this.onSyncShoppingList,
    required this.onCooked,
    required this.allRecipes,
    required this.currentIndex,
    this.onNext,
    this.onPrev,
  });

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
  bool _showIngredients = true;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFDF8F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300, pinned: true, backgroundColor: const Color(0xFF8B4513),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.name,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  RecipeImage(imageUrl: recipe.imageUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddRecipeScreen(
                    recipeToEdit: recipe,
                    onAdd: (updatedRecipe) {
                      setState(() {
                        // In a real app we'd update the source list, but for now we just refresh UI
                      });
                    },
                  )));
                },
              ),
              IconButton(icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.white), onPressed: () { widget.onToggleFavorite(recipe); setState(() {}); })
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Rating: ', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF5D2E0C).withOpacity(0.7), fontWeight: FontWeight.bold)),
                      ...List.generate(5, (i) => GestureDetector(
                        onTap: () => setState(() => recipe.userRating = i + 1.0),
                        child: Icon(i < recipe.userRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 24),
                      )),
                      Text(' (${recipe.userRating.toStringAsFixed(1)})', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF5D2E0C).withOpacity(0.7))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _buildTopChip(Icons.timer, recipe.cookingTime, 'Cook Time'),
                    const SizedBox(width: 12),
                    _buildTopChip(Icons.bar_chart, recipe.difficulty.name, 'Difficulty'),
                    const SizedBox(width: 12),
                    _buildTopChip(Icons.restaurant, recipe.servings, 'Servings'),
                    const SizedBox(width: 12),
                    _buildTopChip(Icons.location_on, recipe.origin, 'Origin'),
                  ]),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD4A574).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('KITCHEN TRIVIA', style: TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(recipe.trivia, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF5D2E0C).withOpacity(0.8), fontSize: 13, height: 1.4, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CookingTimerWidget(initialMinutes: recipe.minutes, recipeName: recipe.name),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabButton('Ingredients', _showIngredients, () => setState(() => _showIngredients = true))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTabButton('Instructions', !_showIngredients, () => setState(() => _showIngredients = false))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _showIngredients ? _buildIngredientsList(recipe) : _buildInstructionsList(recipe),
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4513), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    onPressed: () { widget.onCooked(recipe); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Cooked!'))); },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('MARK AS COOKED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    if (widget.onPrev != null) TextButton.icon(onPressed: widget.onPrev, icon: const Icon(Icons.arrow_back_ios, size: 16), label: const Text('PREVIOUS')),
                    if (widget.onNext != null) TextButton.icon(onPressed: widget.onNext, label: const Text('NEXT'), icon: const Icon(Icons.arrow_forward_ios, size: 16)),
                  ]),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopChip(IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8B4513), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lato(
              color: isDark ? Colors.white : const Color(0xFF5D2E0C),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              color: isDark ? Colors.white54 : const Color(0xFF5D2E0C).withOpacity(0.6),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B4513) : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD4A574).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF5D2E0C)), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildIngredientsList(Recipe recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('RECIPE INGREDIENTS', style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF5D2E0C).withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
          TextButton.icon(onPressed: () => widget.onAddToShoppingList(recipe), icon: const Icon(Icons.add_shopping_cart, size: 16, color: Color(0xFF8B4513)), label: const Text('ADD TO LIST', style: TextStyle(fontSize: 11, color: Color(0xFF8B4513)))),
        ]),
        const SizedBox(height: 8),
        ...recipe.ingredients.asMap().entries.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: CheckboxListTile(
              value: recipe.ingredientStatus[e.key],
              title: Text(e.value, style: TextStyle(color: recipe.ingredientStatus[e.key] ? (isDark ? Colors.white38 : Colors.grey) : (isDark ? Colors.white : const Color(0xFF5D2E0C)), fontSize: 14, decoration: recipe.ingredientStatus[e.key] ? TextDecoration.lineThrough : null)),
              onChanged: (v) { setState(() => recipe.ingredientStatus[e.key] = v!); widget.onSyncShoppingList(recipe); },
              activeColor: const Color(0xFF8B4513),
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInstructionsList(Recipe recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COOKING STEPS', style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF5D2E0C).withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ...recipe.directions.asMap().entries.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(color: Color(0xFF8B4513), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step ${e.key + 1}', style: const TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(e.value, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF5D2E0C), fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class CookingTimerWidget extends StatefulWidget {
  final int initialMinutes;
  final String recipeName;
  const CookingTimerWidget({super.key, required this.initialMinutes, required this.recipeName});
  @override
  State<CookingTimerWidget> createState() => _CookingTimerWidgetState();
}

class _CookingTimerWidgetState extends State<CookingTimerWidget> {
  final TextEditingController _minController = TextEditingController();
  @override
  void initState() { super.initState(); _minController.text = widget.initialMinutes.toString(); }
  @override
  void didUpdateWidget(CookingTimerWidget oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.initialMinutes != widget.initialMinutes) { _minController.text = widget.initialMinutes.toString(); } }

  @override
  Widget build(BuildContext context) {
    final timer = GlobalCookingTimer();
    return AnimatedBuilder(
      animation: timer,
      builder: (context, _) {
        int min = timer.secondsRemaining ~/ 60;
        int sec = timer.secondsRemaining % 60;
        double progress = timer.isRunning || timer.secondsRemaining > 0 ? (timer.secondsRemaining / (widget.initialMinutes * 60)) : 0;
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
                : [Colors.white, const Color(0xFFFDF8F0)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60, height: 60,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark ? Colors.white12 : const Color(0xFFD4A574).withOpacity(0.1),
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                      Icon(Icons.timer_outlined, color: isDark ? Colors.white : const Color(0xFF8B4513), size: 24),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COOKING TIMER',
                        style: GoogleFonts.lato(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        timer.isRunning || timer.secondsRemaining > 0 
                          ? '$min:${sec.toString().padLeft(2, '0')}' 
                          : '${widget.initialMinutes}:00', 
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFF8B4513),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (timer.isRunning || timer.secondsRemaining > 0)
                    _timerCircleButton(Icons.refresh, timer.stop, isDark ? Colors.white12 : Colors.grey.shade200, iconColor: isDark ? Colors.white70 : Colors.grey.shade600)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(width: 12),
                  _timerCircleButton(
                    timer.isRunning ? Icons.pause : Icons.play_arrow,
                    () {
                      if (timer.isRunning || timer.secondsRemaining > 0) {
                        timer.toggle();
                      } else {
                        timer.start(widget.initialMinutes, widget.recipeName);
                      }
                    },
                    const Color(0xFF8B4513),
                    iconColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timerCircleButton(IconData icon, VoidCallback onTap, Color color, {Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
      ),
    );
  }
}

class RecipeQuizView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onComplete;
  const RecipeQuizView({super.key, required this.onBack, required this.onComplete});
  @override
  State<RecipeQuizView> createState() => _RecipeQuizViewState();
}

class _RecipeQuizViewState extends State<RecipeQuizView> {
  int _currIdx = 0, _score = 0;
  bool _finished = false, _started = false, _isAnswered = false;
  int? _selectedIdx;

  final List<String> _trivias = [
    "Adobo refers to the cooking process of marinating in vinegar and soy sauce.",
    "Sinigang is known for its sour broth, traditionally using tamarind as a souring agent.",
    "The name 'Halo-halo' literally translates to 'mix-mix' in English.",
    "Bulalo is a famous beef marrow soup originating from the province of Batangas.",
    "Laing is a creamy and spicy dish made from dried gabi (taro) leaves and coconut milk.",
    "Tapsilog is a breakfast combo of Tapa (dried beef), Sinangag (fried rice), and Itlog (egg).",
    "Pancit noodles are traditionally served during birthdays to symbolize 'long life'.",
    "Binakol is a unique chicken soup traditionally cooked inside a bamboo tube.",
    "The distinct orange color of Kare-Kare comes from Atchuete (Annatto) seeds.",
    "San Fernando, Pampanga is widely recognized as the 'Culinary Capital of the Philippines'.",
    "Dinuguan is a savory stew whose primary ingredient is pork blood.",
    "Isaw is a popular Filipino street food made from grilled chicken or pork intestines.",
    "Biko is a sweet rice cake made primarily from sticky rice (malagkit) and coconut milk.",
    "Guimaras province is world-famous for producing the sweetest mangoes in the country.",
    "Bicol Express gets its signature spicy kick from Siling Labuyo (small chili peppers).",
    "Cebu-style Lechon is often stuffed with lemongrass and local spices for extra flavor."
  ];
  final List<QuizQuestion> _questions = const [
    QuizQuestion(question: "What does 'Halo-Halo' mean?", options: ['Mix-Mix', 'Sweet', 'Cold', 'Many'], correctAnswerIndex: 0),
    QuizQuestion(question: "Which region is famous for Bulalo?", options: ['Bicol', 'Batangas', 'Ilocos', 'Cebu'], correctAnswerIndex: 1),
    QuizQuestion(question: "Main ingredient of Laing?", options: ['Cabbage', 'Gabi Leaves', 'Spinach', 'Kangkong'], correctAnswerIndex: 1),
    QuizQuestion(question: "What is the main souring agent in traditional Sinigang?", options: ['Lemon', 'Vinegar', 'Tamarind', 'Mango'], correctAnswerIndex: 2),
    QuizQuestion(question: "'Tapsilog' is Tapa, Sinangag, and what?", options: ['Tinapa', 'Itlog', 'Iced Tea', 'Talong'], correctAnswerIndex: 1),
    QuizQuestion(question: "Which Filipino dish is traditionally cooked in a bamboo tube?", options: ['Puto', 'Binakol', 'Lechon', 'Adobo'], correctAnswerIndex: 1),
    QuizQuestion(question: "What gives Kare-Kare its distinct orange color?", options: ['Carrots', 'Atchuete (Annatto)', 'Pumpkin', 'Turmeric'], correctAnswerIndex: 1),
    QuizQuestion(question: "Which city is known as the 'Culinary Capital of the Philippines'?", options: ['Cebu City', 'Davao City', 'San Fernando, Pampanga', 'Manila'], correctAnswerIndex: 2),
    QuizQuestion(question: "What is the main ingredient of Dinuguan?", options: ['Pork Blood', 'Soy Sauce', 'Black Beans', 'Chocolate'], correctAnswerIndex: 0),
    QuizQuestion(question: "Which of these is a popular Filipino street food made of grilled chicken/pork intestines?", options: ['Kwek-kwek', 'Isaw', 'Betamax', 'Adidas'], correctAnswerIndex: 1),
    QuizQuestion(question: "What is the primary ingredient of the dessert 'Biko'?", options: ['Sticky Rice', 'Cassava', 'Corn', 'Flour'], correctAnswerIndex: 0),
    QuizQuestion(question: "Which province is famous for its sweet Mangoes?", options: ['Guimaras', 'Batangas', 'Laguna', 'Quezon'], correctAnswerIndex: 0),
    QuizQuestion(question: "In Bicol Express, what is the primary source of heat?", options: ['Ginger', 'Black Pepper', 'Siling Labuyo (Chili)', 'Wasabi'], correctAnswerIndex: 2),
    QuizQuestion(question: "What is 'Lechon' usually stuffed with in Cebu?", options: ['Rice', 'Lemongrass and Spices', 'Potatoes', 'Bread'], correctAnswerIndex: 1),
    QuizQuestion(question: "Which noodle dish is traditionally served during birthdays for 'long life'?", options: ['Lomi', 'Pancit', 'Sotanghon', 'Mami'], correctAnswerIndex: 1),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_started) return _buildTriviaScreen();
    if (_finished) return _buildResultScreen();
    final q = _questions[_currIdx];
    return Padding(
      padding: const EdgeInsets.all(16.0), 
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currIdx + 1) / _questions.length, 
                    minHeight: 8,
                    backgroundColor: Colors.brown.withOpacity(0.1), 
                    color: const Color(0xFF8B4513),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currIdx + 1}/${_questions.length}',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: const Color(0xFF8B4513), fontSize: 13),
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            q.question, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF5D2E0C),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: q.options.length, 
              itemBuilder: (context, index) {
                final isDarkQuiz = Theme.of(context).brightness == Brightness.dark;
                Color btnColor = isDarkQuiz ? const Color(0xFF2A2A2A) : Colors.white;
                Color txtColor = isDarkQuiz ? Colors.white : const Color(0xFF8B4513);
                
                if (_isAnswered) { 
                  if (index == q.correctAnswerIndex) { 
                    btnColor = Colors.green; txtColor = Colors.white; 
                  } else if (index == _selectedIdx) { 
                    btnColor = Colors.red; txtColor = Colors.white; 
                  } 
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16), 
                  child: AnimatedScale(
                    scale: _selectedIdx == index ? 0.98 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: SizedBox(
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isAnswered ? null : () async { 
                          setState(() { 
                            _selectedIdx = index; 
                            _isAnswered = true; 
                            if (index == q.correctAnswerIndex) _score++; 
                          }); 
                          
                          await Future.delayed(const Duration(milliseconds: 600));
                          
                          if (!mounted) return;

                          if (_currIdx < _questions.length - 1) { 
                            setState(() { 
                              _currIdx++; 
                              _isAnswered = false; 
                              _selectedIdx = null; 
                            }); 
                          } else { 
                            setState(() => _finished = true); 
                            widget.onComplete(); 
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor, 
                          foregroundColor: txtColor, 
                          disabledBackgroundColor: btnColor, 
                          disabledForegroundColor: txtColor, 
                          elevation: _isAnswered ? 0 : 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _isAnswered && (index == q.correctAnswerIndex || index == _selectedIdx) 
                                ? Colors.transparent 
                                : (isDarkQuiz ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.1))
                            ),
                          )
                        ),
                        child: Text(
                          q.options[index], 
                          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriviaScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lightbulb_outline, size: 40, color: Colors.amber),
        ), 
        const SizedBox(height: 12),
        Text(
          'KITCHEN TRIVIA',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: const Color(0xFF8B4513),
          ),
        ), 
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Master these culinary facts to ace the quiz!',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
            children: _trivias.map((t) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD4A574)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t, style: GoogleFonts.lato(fontSize: 13, height: 1.4))),
                  ],
                ),
              ),
            )).toList()
          )
        ), 
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            onPressed: () => setState(() => _started = true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513), 
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              elevation: 4,
              shadowColor: Colors.brown.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('START THE CHALLENGE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5))
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            const Icon(Icons.emoji_events_outlined, size: 100, color: Colors.amber), 
            const SizedBox(height: 20),
            const Text('QUIZ COMPLETE!', style: TextStyle(fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.w300)),
            Text('$_score / ${_questions.length}', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Color(0xFF8B4513))), 
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: widget.onBack, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513), 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('BACK TO MENU', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))
            )
          ]
        ),
      )
    );
  }
}

class AddRecipeScreen extends StatefulWidget {
  final Function(Recipe) onAdd;
  final Recipe? recipeToEdit;
  const AddRecipeScreen({super.key, required this.onAdd, this.recipeToEdit});
  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(), _prep = TextEditingController(), _cook = TextEditingController(), _serv = TextEditingController(), _notes = TextEditingController(), _cost = TextEditingController(), _region = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _directionControllers = [];
  Difficulty _difficulty = Difficulty.medium;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      final r = widget.recipeToEdit!;
      _name.text = r.name;
      _prep.text = r.prepTime;
      _cook.text = r.cookingTime;
      _serv.text = r.servings;
      _notes.text = r.notes;
      _cost.text = r.estimatedCost;
      _region.text = r.origin;
      _difficulty = r.difficulty;
      for (var ing in r.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ing));
      }
      for (var dir in r.directions) {
        _directionControllers.add(TextEditingController(text: dir));
      }
    } else {
      _ingredientControllers.add(TextEditingController());
      _directionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var c in _ingredientControllers) { c.dispose(); }
    for (var c in _directionControllers) { c.dispose(); }
    super.dispose();
  }

  void _addIngredient() => setState(() => _ingredientControllers.add(TextEditingController()));
  void _removeIngredient(int index) => setState(() { _ingredientControllers[index].dispose(); _ingredientControllers.removeAt(index); });
  void _addDirection() => setState(() => _directionControllers.add(TextEditingController()));
  void _removeDirection(int index) => setState(() { _directionControllers[index].dispose(); _directionControllers.removeAt(index); });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFDF8F0),
      appBar: AppBar(
        title: Text(widget.recipeToEdit == null ? 'ADD NEW RECIPE' : 'EDIT RECIPE', style: const TextStyle(fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildFormSection('BASIC INFORMATION'),
            _buildTextField(_name, 'Recipe Name', Icons.restaurant, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<Difficulty>(
              initialValue: _difficulty,
              items: Difficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name.toUpperCase(), style: const TextStyle(fontSize: 13)))).toList(), 
              onChanged: (v) => setState(() => _difficulty = v!), 
              decoration: _inputDecoration('Difficulty', Icons.bar_chart),
              dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_prep, 'Prep Time', Icons.timer_outlined)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_cook, 'Cook Time', Icons.timer)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_serv, 'Servings', Icons.people_outline)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_cost, 'Cost', Icons.payments_outlined)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_region, 'Origin', Icons.location_on_outlined),
            const SizedBox(height: 24),
            
            _buildFormSection('INGREDIENTS'),
            ..._ingredientControllers.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: _buildTextField(e.value, 'Ingredient ${e.key + 1}', Icons.shopping_basket_outlined)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red), 
                    onPressed: () => _removeIngredient(e.key)
                  ),
                ],
              ),
            )),
            TextButton.icon(
              onPressed: _addIngredient, 
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B4513)), 
              label: const Text('ADD INGREDIENT', style: TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.bold, fontSize: 12))
            ),
            const SizedBox(height: 24),

            _buildFormSection('DIRECTIONS'),
            ..._directionControllers.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: _buildTextField(e.value, 'Step ${e.key + 1}', Icons.format_list_numbered, maxLines: 2)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red), 
                    onPressed: () => _removeDirection(e.key)
                  ),
                ],
              ),
            )),
            TextButton.icon(
              onPressed: _addDirection, 
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B4513)), 
              label: const Text('ADD STEP', style: TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.bold, fontSize: 12))
            ),
            const SizedBox(height: 24),

            _buildFormSection('NOTES & TRIVIA'),
            _buildTextField(_notes, 'Recipe Notes', Icons.note_outlined, maxLines: 3),
            const SizedBox(height: 24),

            _buildFormSection('RECIPE IMAGE'),
            InkWell(
              onTap: () async { 
                final img = await ImagePicker().pickImage(source: ImageSource.gallery); 
                if (img != null) setState(() => _image = img); 
              },
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.1)),
                ),
                child: _image != null 
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_image!.path), fit: BoxFit.cover))
                  : RecipeImage(imageUrl: widget.recipeToEdit?.imageUrl),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513), 
                foregroundColor: Colors.white, 
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final ingredients = _ingredientControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                  final directions = _directionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                  widget.onAdd(Recipe(
                    name: _name.text,
                    category: widget.recipeToEdit?.category ?? 'Tanghalian',
                    cookingTime: _cook.text,
                    prepTime: _prep.text,
                    servings: _serv.text,
                    notes: _notes.text,
                    difficulty: _difficulty,
                    estimatedCost: _cost.text,
                    origin: _region.text,
                    imageUrl: _image?.path ?? widget.recipeToEdit?.imageUrl,
                    ingredients: ingredients.isEmpty ? ['No ingredients'] : ingredients,
                    directions: directions.isEmpty ? ['No directions'] : directions,
                    trivia: widget.recipeToEdit?.trivia ?? 'A classic Filipino favorite.',
                    isFavorite: widget.recipeToEdit?.isFavorite ?? false,
                    userRating: widget.recipeToEdit?.userRating ?? 0.0,
                    viewCount: widget.recipeToEdit?.viewCount ?? 0,
                    isCooked: widget.recipeToEdit?.isCooked ?? false,
                  ));
                  Navigator.pop(context);
                }
              },
              child: Text(widget.recipeToEdit == null ? 'SAVE RECIPE' : 'UPDATE RECIPE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF8B4513))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label, icon),
      style: const TextStyle(fontSize: 15),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF8B4513).withOpacity(0.7)),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFD4A574).withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B4513))),
      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    );
  }
}
