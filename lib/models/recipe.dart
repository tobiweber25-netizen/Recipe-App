import 'ingredient.dart';

class Recipe {
  final int? id;
  final int? mealPackId;
  final String title;
  final String description;
  final bool isSaved;
  final DateTime? savedAt;
  final int cookTimeMinutes;
  final int servings;
  final String category;
  final String cuisine;
  final bool isAdventurous;
  final String budgetTier;
  final String chefTip;
  final List<String> instructions;
  final List<Ingredient> recipeSpecificIngredients;

  Recipe({
    this.id,
    this.mealPackId,
    required this.title,
    this.description = '',
    this.isSaved = false,
    this.savedAt,
    this.cookTimeMinutes = 25,
    this.servings = 2,
    this.category = 'Main Dish',
    String? cuisine,
    this.isAdventurous = false,
    this.budgetTier = 'Standard',
    this.chefTip = '',
    required this.instructions,
    required this.recipeSpecificIngredients,
  }) : cuisine = cuisine ?? category;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meal_pack_id': mealPackId,
      'title': title,
      'description': description,
      'is_saved': isSaved ? 1 : 0,
      'saved_at': savedAt?.toIso8601String(),
      'cook_time_minutes': cookTimeMinutes,
      'servings': servings,
      'category': category,
      'budget_tier': budgetTier,
      'chef_tip': chefTip,
      'instructions': instructions.join('\n'),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map, List<Ingredient> ingredients) {
    final recipeId = map['id'] as int?;
    return Recipe(
      id: recipeId,
      mealPackId: map['meal_pack_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isSaved: (map['is_saved'] as int? ?? 0) == 1,
      savedAt: map['saved_at'] != null ? DateTime.tryParse(map['saved_at'] as String) : null,
      cookTimeMinutes: (map['cook_time_minutes'] as num?)?.toInt() ?? 25,
      servings: (map['servings'] as num?)?.toInt() ?? 2,
      category: map['category'] as String? ?? 'Main Dish',
      cuisine: map['cuisine'] as String? ?? (map['category'] as String? ?? 'Main Dish'),
      isAdventurous: (map['is_adventurous'] as int? ?? 0) == 1,
      budgetTier: map['budget_tier'] as String? ?? 'Standard',
      chefTip: map['chef_tip'] as String? ?? '',
      instructions: (map['instructions'] as String? ?? '')
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList(),
      recipeSpecificIngredients: ingredients
          .where((ing) => ing.recipeId == recipeId)
          .toList(),
    );
  }

  Recipe copyWith({
    int? id,
    int? mealPackId,
    String? title,
    String? description,
    bool? isSaved,
    DateTime? savedAt,
    bool clearSavedAt = false,
    int? cookTimeMinutes,
    int? servings,
    String? category,
    String? cuisine,
    bool? isAdventurous,
    String? budgetTier,
    String? chefTip,
    List<String>? instructions,
    List<Ingredient>? recipeSpecificIngredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      mealPackId: mealPackId ?? this.mealPackId,
      title: title ?? this.title,
      description: description ?? this.description,
      isSaved: isSaved ?? this.isSaved,
      savedAt: clearSavedAt ? null : (savedAt ?? this.savedAt),
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      isAdventurous: isAdventurous ?? this.isAdventurous,
      budgetTier: budgetTier ?? this.budgetTier,
      chefTip: chefTip ?? this.chefTip,
      instructions: instructions ?? this.instructions,
      recipeSpecificIngredients: recipeSpecificIngredients ?? this.recipeSpecificIngredients,
    );
  }
}

