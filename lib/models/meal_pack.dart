import 'recipe.dart';
import 'ingredient.dart';

class MealPack {
  final int? id;
  final DateTime createdAt;
  final String season;
  final String month;
  final String title;
  final List<Recipe> recipes;
  final List<Ingredient> sharedFreshIngredients;
  final List<Ingredient> storeCupboardStaples;

  MealPack({
    this.id,
    required this.createdAt,
    required this.season,
    required this.month,
    required this.title,
    required this.recipes,
    required this.sharedFreshIngredients,
    required this.storeCupboardStaples,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'created_at': createdAt.toIso8601String(),
      'season': season,
      'month': month,
      'title': title,
    };
  }

  factory MealPack.fromMap({
    required Map<String, dynamic> map,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
  }) {
    return MealPack(
      id: map['id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      season: map['season'] as String,
      month: map['month'] as String,
      title: map['title'] as String? ?? 'Weekly Meal Pack',
      recipes: recipes,
      sharedFreshIngredients: ingredients
          .where((ing) => ing.recipeId == null && ing.type == 'shared_fresh')
          .toList(),
      storeCupboardStaples: ingredients
          .where((ing) => ing.recipeId == null && ing.type == 'staple')
          .toList(),
    );
  }

  MealPack copyWith({
    int? id,
    DateTime? createdAt,
    String? season,
    String? month,
    String? title,
    List<Recipe>? recipes,
    List<Ingredient>? sharedFreshIngredients,
    List<Ingredient>? storeCupboardStaples,
  }) {
    return MealPack(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      season: season ?? this.season,
      month: month ?? this.month,
      title: title ?? this.title,
      recipes: recipes ?? this.recipes,
      sharedFreshIngredients: sharedFreshIngredients ?? this.sharedFreshIngredients,
      storeCupboardStaples: storeCupboardStaples ?? this.storeCupboardStaples,
    );
  }
}
