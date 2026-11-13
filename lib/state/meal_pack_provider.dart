import 'package:flutter/material.dart';
import '../models/meal_pack.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../services/db_helper.dart';
import '../services/llm_service.dart';
import '../services/meal_pack_generator.dart';
import '../models/generate_options.dart';
import '../utils/season_helper.dart';

class MealPackProvider extends ChangeNotifier {
  final DbHelper _dbHelper = DbHelper.instance;
  final LlmService _llmService = LlmService.instance;
  final MealPackGenerator _generator = MealPackGenerator.instance;

  List<MealPack> _savedMealPacks = [];
  List<Recipe> _savedRecipes = [];
  List<String> _pantryItems = [];
  MealPack? _activeMealPack;
  bool _isLoading = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;

  List<MealPack> get savedMealPacks => _savedMealPacks;
  List<Recipe> get savedRecipes => _savedRecipes;
  List<String> get pantryItems => _pantryItems;
  MealPack? get activeMealPack => _activeMealPack;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadSavedMealPacks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _savedMealPacks = await _dbHelper.getAllMealPacks();
      _savedRecipes = await _dbHelper.getSavedRecipes();
      _pantryItems = await _dbHelper.getPantryItems();
      if (_activeMealPack == null && _savedMealPacks.isNotEmpty) {
        _activeMealPack = _savedMealPacks.first;
      }
      if (_savedMealPacks.isNotEmpty) {
        final recentTitles = _savedMealPacks.take(4).expand((p) => p.recipes.map((r) => r.title)).toList();
        _generator.recordRecentRecipes(recentTitles);
      }
    } catch (e) {
      _errorMessage = 'Failed to load saved data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateInstantMealPack(GenerateOptions options) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final seasonContext = SeasonHelper.getSeasonalContext(now);

      // Collect titles from current active pack and saved packs to prevent repeats
      final excluded = <String>{};
      if (_activeMealPack != null) {
        excluded.addAll(_activeMealPack!.recipes.map((r) => r.title));
      }
      for (final p in _savedMealPacks.take(3)) {
        excluded.addAll(p.recipes.map((r) => r.title));
      }

      final newPack = _generator.generateInstantMealPack(
        seasonContext: seasonContext,
        pantryItems: _pantryItems,
        options: options,
        excludedRecipeTitles: excluded.toList(),
      );

      final savedPack = await _dbHelper.insertMealPack(newPack);
      _savedMealPacks.insert(0, savedPack);
      _activeMealPack = savedPack;
    } catch (e) {
      _errorMessage = 'Instant generation failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> swapRecipeInActivePack(int oldRecipeId, Recipe newRecipe) async {
    if (_activeMealPack?.id == null) return;

    try {
      final savedNewRecipe = await _dbHelper.replaceRecipe(
        oldRecipeId,
        _activeMealPack!.id!,
        newRecipe,
      );

      final index = _activeMealPack!.recipes.indexWhere((r) => r.id == oldRecipeId);
      if (index != -1) {
        final newRecipes = List<Recipe>.from(_activeMealPack!.recipes);
        newRecipes[index] = savedNewRecipe;
        _activeMealPack = _activeMealPack!.copyWith(recipes: newRecipes);

        final packIdx = _savedMealPacks.indexWhere((p) => p.id == _activeMealPack!.id);
        if (packIdx != -1) {
          _savedMealPacks[packIdx] = _activeMealPack!;
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to swap recipe: $e';
      notifyListeners();
    }
  }

  Map<String, List<Ingredient>> getConsolidatedGroceryList() {
    if (_activeMealPack == null) return {};

    final Map<String, List<Ingredient>> aisleGroups = {
      'Fresh Produce': [],
      'Meat & Protein': [],
      'Dairy & Chilled': [],
      'Grains & Noodles': [],
      'Pantry & Spices': [],
    };

    final Map<String, Ingredient> consolidatedMap = {};

    for (final recipe in _activeMealPack!.recipes) {
      for (final ing in recipe.recipeSpecificIngredients) {
        final key = '${ing.name.toLowerCase().trim()}_${ing.unit.toLowerCase().trim()}';
        if (consolidatedMap.containsKey(key)) {
          final existing = consolidatedMap[key]!;
          consolidatedMap[key] = existing.copyWith(
            quantity: existing.quantity + ing.quantity,
            isChecked: existing.isChecked && ing.isChecked,
          );
        } else {
          consolidatedMap[key] = ing;
        }
      }
    }

    if (consolidatedMap.isEmpty) {
      for (final ing in _activeMealPack!.sharedFreshIngredients) {
        final key = '${ing.name.toLowerCase().trim()}_${ing.unit.toLowerCase().trim()}';
        consolidatedMap[key] = ing;
      }
      for (final ing in _activeMealPack!.storeCupboardStaples) {
        final key = '${ing.name.toLowerCase().trim()}_${ing.unit.toLowerCase().trim()}';
        consolidatedMap[key] = ing;
      }
    }

    for (final ing in consolidatedMap.values) {
      final aisle = ing.aisle;
      if (aisleGroups.containsKey(aisle)) {
        aisleGroups[aisle]!.add(ing);
      } else {
        aisleGroups['Pantry & Spices']!.add(ing);
      }
    }

    for (final list in aisleGroups.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    return aisleGroups;
  }

  Future<void> toggleConsolidatedIngredient(String ingredientName, bool isChecked) async {
    if (_activeMealPack == null) return;
    final cleanName = ingredientName.toLowerCase().trim();

    try {
      for (final recipe in _activeMealPack!.recipes) {
        for (final ing in recipe.recipeSpecificIngredients) {
          if (ing.name.toLowerCase().trim() == cleanName && ing.id != null) {
            await _dbHelper.updateIngredientChecked(ing.id!, isChecked);
            ing.isChecked = isChecked;
          }
        }
      }

      for (final ing in _activeMealPack!.sharedFreshIngredients) {
        if (ing.name.toLowerCase().trim() == cleanName && ing.id != null) {
          await _dbHelper.updateIngredientChecked(ing.id!, isChecked);
          ing.isChecked = isChecked;
        }
      }

      for (final ing in _activeMealPack!.storeCupboardStaples) {
        if (ing.name.toLowerCase().trim() == cleanName && ing.id != null) {
          await _dbHelper.updateIngredientChecked(ing.id!, isChecked);
          ing.isChecked = isChecked;
        }
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update grocery item: $e';
      notifyListeners();
    }
  }

  Future<void> generateNewMealPack(GenerateOptions options) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final seasonContext = SeasonHelper.getSeasonalContext(now);
      
      final newPack = await _llmService.generateMealPackSkeleton(
        seasonContext,
        _pantryItems,
        options,
      );
      final savedPack = await _dbHelper.insertMealPack(newPack);
      
      _savedMealPacks.insert(0, savedPack);
      _activeMealPack = savedPack;
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.startsWith('Exception: ')) {
        errMsg = errMsg.substring('Exception: '.length);
      }
      if (errMsg.contains('AI cooking assistant')) {
        _errorMessage = errMsg;
      } else {
        _errorMessage = 'Generation failed: $errMsg';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecipeDetails(Recipe recipe) async {
    if (_activeMealPack == null) return;
    try {
      final updatedRecipe = await _llmService.generateRecipeDetails(recipe, _activeMealPack!);
      await _dbHelper.updateRecipeDetails(updatedRecipe);
      
      // Update local state
      final recipeIndex = _activeMealPack!.recipes.indexWhere((r) => r.id == recipe.id);
      if (recipeIndex != -1) {
        final newRecipes = List<Recipe>.from(_activeMealPack!.recipes);
        newRecipes[recipeIndex] = updatedRecipe;
        _activeMealPack = _activeMealPack!.copyWith(recipes: newRecipes);
        
        // Also update saved packs reference if needed
        final packIndex = _savedMealPacks.indexWhere((p) => p.id == _activeMealPack!.id);
        if (packIndex != -1) {
          _savedMealPacks[packIndex] = _activeMealPack!;
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load recipe details: $e';
      notifyListeners();
      rethrow;
    }
  }

  void setActiveMealPack(MealPack mealPack) {
    _activeMealPack = mealPack;
    notifyListeners();
  }

  Future<void> deleteMealPack(int id) async {
    try {
      await _dbHelper.deleteMealPack(id);
      _savedMealPacks.removeWhere((mp) => mp.id == id);
      if (_activeMealPack?.id == id) {
        _activeMealPack = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete meal pack: $e';
      notifyListeners();
    }
  }

  Future<void> toggleIngredientChecked(Ingredient ingredient, bool isChecked) async {
    if (ingredient.id == null) return;

    try {
      await _dbHelper.updateIngredientChecked(ingredient.id!, isChecked);

      if (_activeMealPack != null) {
        final sharedIndex = _activeMealPack!.sharedFreshIngredients
            .indexWhere((ing) => ing.id == ingredient.id);
        if (sharedIndex != -1) {
          _activeMealPack!.sharedFreshIngredients[sharedIndex].isChecked = isChecked;
        }

        final stapleIndex = _activeMealPack!.storeCupboardStaples
            .indexWhere((ing) => ing.id == ingredient.id);
        if (stapleIndex != -1) {
          _activeMealPack!.storeCupboardStaples[stapleIndex].isChecked = isChecked;
        }

        for (var recipe in _activeMealPack!.recipes) {
          final specificIndex = recipe.recipeSpecificIngredients
              .indexWhere((ing) => ing.id == ingredient.id);
          if (specificIndex != -1) {
            recipe.recipeSpecificIngredients[specificIndex].isChecked = isChecked;
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update ingredient status: $e';
      notifyListeners();
    }
  }

  Future<void> uncheckAllIngredients() async {
    if (_activeMealPack?.id == null) return;
    try {
      await _dbHelper.uncheckAllIngredients(_activeMealPack!.id!);
      for (var ing in _activeMealPack!.sharedFreshIngredients) {
        ing.isChecked = false;
      }
      for (var ing in _activeMealPack!.storeCupboardStaples) {
        ing.isChecked = false;
      }
      for (var recipe in _activeMealPack!.recipes) {
        for (var ing in recipe.recipeSpecificIngredients) {
          ing.isChecked = false;
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to reset ingredient list: $e';
      notifyListeners();
    }
  }

  Future<void> toggleSaveRecipe(Recipe recipe) async {
    if (recipe.id == null) return;
    final newSaveState = !recipe.isSaved;
    try {
      await _dbHelper.updateRecipeSavedState(recipe.id!, newSaveState);

      if (_activeMealPack != null) {
        for (int i = 0; i < _activeMealPack!.recipes.length; i++) {
          if (_activeMealPack!.recipes[i].id == recipe.id) {
            _activeMealPack!.recipes[i] = _activeMealPack!.recipes[i].copyWith(
              isSaved: newSaveState,
              savedAt: newSaveState ? DateTime.now() : null,
              clearSavedAt: !newSaveState,
            );
          }
        }
      }

      for (var pack in _savedMealPacks) {
        for (int i = 0; i < pack.recipes.length; i++) {
          if (pack.recipes[i].id == recipe.id) {
            pack.recipes[i] = pack.recipes[i].copyWith(
              isSaved: newSaveState,
              savedAt: newSaveState ? DateTime.now() : null,
              clearSavedAt: !newSaveState,
            );
          }
        }
      }

      _savedRecipes = await _dbHelper.getSavedRecipes();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update recipe bookmark state: $e';
      notifyListeners();
    }
  }

  void setSavedRecipes(List<Recipe> recipes) {
    _savedRecipes = List.from(recipes);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> addPantryItem(String name) async {
    final cleanName = name.trim().toLowerCase();
    if (cleanName.isEmpty || _pantryItems.contains(cleanName)) return;

    try {
      await _dbHelper.addPantryItem(cleanName);
      _pantryItems.add(cleanName);
      _pantryItems.sort();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add pantry item: $e';
      notifyListeners();
    }
  }

  Future<void> deletePantryItem(String name) async {
    final cleanName = name.trim().toLowerCase();
    try {
      await _dbHelper.deletePantryItem(cleanName);
      _pantryItems.remove(cleanName);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete pantry item: $e';
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleThemeMode() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
