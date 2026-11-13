import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ingredient.dart';
import '../models/meal_pack.dart';
import '../models/recipe.dart';
import '../models/generate_options.dart';
import '../utils/season_helper.dart';

class LlmService {
  static final LlmService instance = LlmService._init();
  LlmService._init();

  Future<MealPack> generateMealPackSkeleton(SeasonalContext ctx, List<String> pantryItems, GenerateOptions options) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      throw Exception('GEMINI_API_KEY not configured. Please add your key to the .env file.');
    }

    final ingredientSchema = Schema.object(
      properties: {
        'name': Schema.string(),
        'quantity': Schema.number(),
        'unit': Schema.string(),
        'type': Schema.string(),
      },
      requiredProperties: ['name', 'quantity', 'unit', 'type'],
    );

    final recipeSkeletonSchema = Schema.object(
      properties: {
        'title': Schema.string(),
        'description': Schema.string(),
        'cook_time_minutes': Schema.integer(),
        'category': Schema.string(),
        'budget_tier': Schema.string(),
      },
      requiredProperties: ['title', 'description', 'cook_time_minutes', 'category', 'budget_tier'],
    );

    final skeletonSchema = Schema.object(
      properties: {
        'title': Schema.string(),
        'recipes': Schema.array(items: recipeSkeletonSchema),
        'shared_fresh_ingredients': Schema.array(items: ingredientSchema),
        'store_cupboard_staples': Schema.array(items: ingredientSchema),
      },
      requiredProperties: ['title', 'recipes', 'shared_fresh_ingredients', 'store_cupboard_staples'],
    );

    final model = GenerativeModel(
      model: dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash', 
      apiKey: apiKey, 
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: skeletonSchema,
      ),
    );
    
    final pItems = pantryItems.isEmpty ? 'None specified' : pantryItems.join(', ');
    final cDir = options.customDirection.trim().isNotEmpty == true 
        ? '- Custom Request/Theme: "${options.customDirection.trim()}". Ensure at least 1-2 recipes directly reflect this.' 
        : '';

    String budgetInstruction = 'Everyday balanced value (moderate cost, family-pleasing whole foods).';
    if (options.budgetTier == 'budget') {
      budgetInstruction = 'LOW BUDGET / END-OF-MONTH SAVER: Ultra cost-effective recipes. Prioritize budget-friendly pantry staples, eggs, lentils, chickpeas, black/kidney beans, minced beef/chicken thighs, potatoes, pasta, rice, cabbage, and seasonal root veggies. Maximize deep flavor with spices and smart pan sauces while keeping grocery cost minimal.';
    } else if (options.budgetTier == 'gourmet') {
      budgetInstruction = 'ELEVATED / GOURMET: Special weekend feel. Incorporate premium proteins (e.g. salmon fillets, tender beef cuts, fresh herbs, specialty cheeses, wine reductions, artisanal toppings).';
    }

    final prompt = '''You are a master executive chef and meal prep planner. Generate a weekly "Meal Pack" with exactly 6 hearty, delicious, and complete DINNER recipes.

CRITICAL MEAL REQUIREMENTS:
1. COMPLETE DINNERS ONLY: Every single recipe MUST be a full, satisfying main dinner meal (NEVER a side dish, snack, salad garnish, or single roasted vegetable).
2. COMPLETE MEAL ANATOMY: Each dish must contain:
   - Centerpiece / Protein Anchor (e.g. seasoned chicken thighs/breasts, beef mince, pork chops, white fish/salmon, crispy spiced tofu, rich lentil curry, halloumi, beans/eggs).
   - Satiating Carb/Starch Base (e.g. jasmine/basmati rice, noodles, roasted baby potatoes, pasta with pan sauce, couscous, warm tortillas, crusty bread).
   - Seasoned Vegetable/Fresh Element (e.g. roasted broccoli, garlicky greens, braised peppers, crisp cucumber herb salad).
   - Cohesive Sauce / Flavor Profile (e.g. honey-garlic glaze, lemon-herb butter, chimichurri, creamy tomato reduction, peanut-lime sauce).
3. DIETARY BALANCE: ${options.dietaryBalance}.
4. BUDGET TIER: $budgetInstruction
5. INGREDIENT REUSE: ${options.overlap}. Reuse 3-5 versatile fresh items (e.g. spinach, carrots, lemons, garlic, fresh herbs) across recipes to reduce waste, while ensuring every dish has a completely unique cuisine identity (e.g. Italian, Mediterranean, Mexican, Thai/Asian, South African comfort).
6. PANTRY ITEMS ON HAND: $pItems. Seamlessly integrate these where appropriate.
$cDir
7. REGIONAL CONTEXT: Johannesburg, South Africa. Metric units only (g, kg, ml). Season: ${ctx.seasonName}, ${ctx.monthName}. Seasonal Produce: ${ctx.produceKeywords.join(', ')}.
8. Portions: ${options.servings} servings per meal.
9. To keep shopping lists clean, set quantity to 1 and unit to "item" for shared/staple skeleton items. JSON ONLY matching schema.''';

    late GenerateContentResponse res;
    int attempts = 0, delay = 5;
    while (true) {
      try {
        res = await model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 120));
        break;
      } catch (e) {
        final err = e.toString().toLowerCase();
        if (++attempts > 4) {
          if (err.contains('timeout')) throw Exception('Generation timed out. The connection was slow. Please try again.');
          if (['429', 'resource_exhausted', 'rate limit', 'quota'].any(err.contains)) throw Exception('API quota exceeded. Please wait a moment before generating another meal pack.');
          rethrow;
        }
        if (err.contains('timeout') || ['429', '503', 'resource_exhausted', 'unavailable', 'busy', 'rate limit', 'quota'].any(err.contains)) {
          await Future.delayed(Duration(seconds: delay));
          delay *= 2;
        } else {
          rethrow;
        }
      }
    }

    if (res.text?.isEmpty ?? true) throw Exception('Received empty response from AI model.');
    
    final Map<String, dynamic> data = await compute(_decodeJson, res.text!);
    
    List<Ingredient> parseIngredients(String key, String type) => 
        (data[key] as List? ?? []).map((i) => Ingredient(
          name: i['name'] ?? '',
          quantity: (i['quantity'] as num?)?.toDouble() ?? 1.0,
          unit: i['unit'] ?? 'item',
          type: type,
        )).toList();
    
    final budgetLabel = options.budgetTier == 'budget' 
        ? 'Budget Saver' 
        : (options.budgetTier == 'gourmet' ? 'Gourmet' : 'Everyday Value');

    return MealPack(
      createdAt: DateTime.now(),
      season: ctx.seasonName,
      month: ctx.monthName,
      title: data['title'] ?? 'Weekly Meal Pack',
      recipes: (data['recipes'] as List? ?? []).map((r) => Recipe(
        title: r['title'] ?? 'Delicious Dinner',
        description: r['description'] ?? '',
        cookTimeMinutes: (r['cook_time_minutes'] as num?)?.toInt() ?? 30,
        servings: options.servings,
        category: r['category'] ?? 'Main Dinner',
        budgetTier: r['budget_tier'] ?? budgetLabel,
        instructions: [],
        recipeSpecificIngredients: [],
      )).toList(),
      sharedFreshIngredients: parseIngredients('shared_fresh_ingredients', 'shared_fresh'),
      storeCupboardStaples: parseIngredients('store_cupboard_staples', 'staple'),
    );
  }

  Future<Recipe> generateRecipeDetails(Recipe skeleton, MealPack contextPack) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) throw Exception('GEMINI_API_KEY not configured in .env.');

    final ingredientSchema = Schema.object(
      properties: {
        'name': Schema.string(),
        'quantity': Schema.number(),
        'unit': Schema.string(),
        'type': Schema.string(),
      },
      requiredProperties: ['name', 'quantity', 'unit', 'type'],
    );

    final detailsSchema = Schema.object(
      properties: {
        'instructions': Schema.array(items: Schema.string()),
        'ingredients': Schema.array(items: ingredientSchema),
        'chef_tip': Schema.string(),
        'cook_time_minutes': Schema.integer(),
      },
      requiredProperties: ['instructions', 'ingredients', 'chef_tip'],
    );

    final model = GenerativeModel(
      model: dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash', 
      apiKey: apiKey, 
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: detailsSchema,
      ),
    );

    final prompt = '''You are an expert chef writing a complete, foolproof recipe for home cooking.
Recipe: "${skeleton.title}"
Description: "${skeleton.description}"
Category: ${skeleton.category}
Budget Tier: ${skeleton.budgetTier}
Servings: ${skeleton.servings} portions
Season: ${contextPack.season}

Write:
1. 4-6 concise, numbered, step-by-step instructions. Focus on culinary techniques (proper browning/searing, deglazing pan fond, balancing acid and seasoning, resting).
2. COMPLETE list of all ingredients needed for ${skeleton.servings} servings with precise metric units (g, ml, tbsp, tsp, cloves). Include the protein, carb/starch base, vegetables, aromatics, and cooking fat.
3. One high-value "Chef's Pro Tip" (a practical culinary secret that elevates this specific dish from ordinary to restaurant-quality).

Rules:
1. "type" for all ingredients must be "recipe_specific".
2. Metric units ONLY (g, kg, ml, tbsp, tsp, whole).
3. Do not omit the protein or carb base—ensure this is a complete, satisfying dinner.
4. Exclude only basic tap water, salt, and black pepper.
5. JSON ONLY matching schema.''';

    late GenerateContentResponse res;
    int attempts = 0, delay = 3;
    while (true) {
      try {
        res = await model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 45));
        break;
      } catch (e) {
        final err = e.toString().toLowerCase();
        if (++attempts > 3) rethrow;
        if (err.contains('timeout') || ['429', '503', 'resource_exhausted', 'unavailable', 'busy', 'rate limit', 'quota'].any(err.contains)) {
          await Future.delayed(Duration(seconds: delay));
          delay *= 2;
        } else {
          rethrow;
        }
      }
    }

    if (res.text?.isEmpty ?? true) throw Exception('Received empty recipe details from AI.');
    
    final Map<String, dynamic> data = await compute(_decodeJson, res.text!);
    
    return skeleton.copyWith(
      instructions: (data['instructions'] as List? ?? []).map((e) => e.toString()).toList(),
      chefTip: data['chef_tip'] as String? ?? '',
      cookTimeMinutes: (data['cook_time_minutes'] as num?)?.toInt() ?? skeleton.cookTimeMinutes,
      recipeSpecificIngredients: (data['ingredients'] as List? ?? []).map((i) => Ingredient(
        name: i['name'] ?? '',
        quantity: (i['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: i['unit'] ?? 'item',
        type: 'recipe_specific',
      )).toList(),
    );
  }
}

Map<String, dynamic> _decodeJson(String source) {
  return jsonDecode(source) as Map<String, dynamic>;
}

