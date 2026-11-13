import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:seasonal_prep_cook/main.dart';
import 'package:seasonal_prep_cook/data/curated_recipe_library.dart';
import 'package:seasonal_prep_cook/models/generate_options.dart';
import 'package:seasonal_prep_cook/models/ingredient.dart';
import 'package:seasonal_prep_cook/models/meal_pack.dart';
import 'package:seasonal_prep_cook/models/recipe.dart';
import 'package:seasonal_prep_cook/services/meal_pack_generator.dart';
import 'package:seasonal_prep_cook/state/meal_pack_provider.dart';
import 'package:seasonal_prep_cook/utils/season_helper.dart';
import 'package:seasonal_prep_cook/views/cooking_mode_view.dart';
import 'package:seasonal_prep_cook/views/dashboard_view.dart';
import 'package:seasonal_prep_cook/views/main_layout.dart';
import 'package:seasonal_prep_cook/views/meal_pack_view.dart';
import 'package:seasonal_prep_cook/views/saved_recipes_view.dart';

void main() {
  group('GenerateOptions Unit Tests', () {
    test('default options include standard budget and 2 servings', () {
      const options = GenerateOptions();
      expect(options.budgetTier, 'standard');
      expect(options.servings, 2);
      expect(options.dietaryBalance, '3 vegetarian, 3 mixed protein');
      expect(options.overlap, contains('Smart'));
    });

    test('copyWith updates budgetTier and servings correctly', () {
      const options = GenerateOptions();
      final updated = options.copyWith(
        budgetTier: 'budget',
        servings: 4,
        dietaryBalance: 'All vegetarian',
      );
      expect(updated.budgetTier, 'budget');
      expect(updated.servings, 4);
      expect(updated.dietaryBalance, 'All vegetarian');
      expect(updated.overlap, options.overlap);
    });
  });

  group('Recipe Model Unit Tests', () {
    test('serializes and deserializes new recipe attributes', () {
      final recipe = Recipe(
        id: 42,
        mealPackId: 1,
        title: 'Honey-Soy Glazed Chicken Thighs with Jasmine Rice',
        description: 'Crispy skin chicken over fragrant rice and steamed bok choy.',
        cookTimeMinutes: 25,
        servings: 2,
        category: 'Skillet Dinner',
        budgetTier: 'Budget Saver',
        chefTip: 'Pat the chicken dry before searing for maximum crispness.',
        instructions: ['Heat skillet over medium-high', 'Sear chicken skin-side down for 6 mins'],
        recipeSpecificIngredients: [
          Ingredient(name: 'Chicken Thighs', quantity: 400, unit: 'g', type: 'recipe_specific', recipeId: 42),
          Ingredient(name: 'Jasmine Rice', quantity: 150, unit: 'g', type: 'recipe_specific', recipeId: 42),
        ],
      );

      final map = recipe.toMap();
      expect(map['id'], 42);
      expect(map['title'], contains('Honey-Soy'));
      expect(map['cook_time_minutes'], 25);
      expect(map['servings'], 2);
      expect(map['category'], 'Skillet Dinner');
      expect(map['budget_tier'], 'Budget Saver');
      expect(map['chef_tip'], contains('Pat the chicken dry'));

      final reconstructed = Recipe.fromMap(map, recipe.recipeSpecificIngredients);
      expect(reconstructed.id, 42);
      expect(reconstructed.title, recipe.title);
      expect(reconstructed.cookTimeMinutes, 25);
      expect(reconstructed.servings, 2);
      expect(reconstructed.category, 'Skillet Dinner');
      expect(reconstructed.budgetTier, 'Budget Saver');
      expect(reconstructed.chefTip, recipe.chefTip);
      expect(reconstructed.instructions.length, 2);
      expect(reconstructed.recipeSpecificIngredients.length, 2);
    });
  });

  group('SeasonHelper Unit Tests', () {
    test('produces correct winter context without literal \$baseDesc', () {
      final winterDate = DateTime(2026, 7, 15); // July = Winter in SA
      final ctx = SeasonHelper.getSeasonalContext(winterDate);
      expect(ctx.seasonName, 'South African Winter');
      expect(ctx.monthName, 'July');
      expect(ctx.description, isNot(contains(r'$baseDesc')));
      expect(ctx.description, contains('Focus on rich, warming winter dishes'));
      expect(ctx.produceKeywords.isNotEmpty, true);
    });

    test('produces correct summer context', () {
      final summerDate = DateTime(2026, 1, 10); // January = Summer in SA
      final ctx = SeasonHelper.getSeasonalContext(summerDate);
      expect(ctx.seasonName, 'South African Summer');
      expect(ctx.monthName, 'January');
      expect(ctx.description, contains('Emphasize colorful, refreshing summer recipes'));
    });
  });

  group('Widget Tests', () {
    testWidgets('DashboardView renders with Meal & Budget Preferences and Generate button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => MealPackProvider(),
            ),
          ],
          child: const WeeklyRecipesApp(),
        ),
      );

      expect(find.byType(DashboardView), findsOneWidget);
      expect(find.text('⚡ INSTANT GENERATE (6 MEALS)'), findsOneWidget);
      expect(find.text('Meal & Budget Preferences'), findsOneWidget);
      expect(find.text('Budget Saver'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Gourmet'), findsOneWidget);
    });

    testWidgets('MealPackView renders recipe details, chef tip, and badges', (WidgetTester tester) async {
      final testRecipe = Recipe(
        id: 1,
        mealPackId: 1,
        title: 'Creamy Tuscan Garlic Chicken Pasta',
        description: 'Tender seared chicken in a velvety sun-dried tomato and spinach garlic cream sauce with penne.',
        cookTimeMinutes: 20,
        servings: 2,
        category: 'Pasta Dinner',
        budgetTier: 'Everyday Value',
        chefTip: 'Reserve 1/2 cup of starchy pasta water to emulsify the sauce to restaurant silkiness.',
        instructions: [
          'Boil penne in salted water until al dente.',
          'Sear seasoned chicken breast slices until golden brown.',
          'Add garlic, sun-dried tomatoes, and cream to skillet.',
          'Toss pasta with sauce and spinach until wilted.',
        ],
        recipeSpecificIngredients: [
          Ingredient(name: 'Chicken Breast', quantity: 300, unit: 'g', type: 'recipe_specific', recipeId: 1),
          Ingredient(name: 'Penne Pasta', quantity: 200, unit: 'g', type: 'recipe_specific', recipeId: 1),
          Ingredient(name: 'Heavy Cream', quantity: 150, unit: 'ml', type: 'recipe_specific', recipeId: 1),
        ],
      );

      final dummyPack = MealPack(
        id: 1,
        createdAt: DateTime.now(),
        season: 'South African Winter',
        month: 'August',
        title: 'Winter Comfort Pack',
        recipes: [testRecipe],
        sharedFreshIngredients: [],
        storeCupboardStaples: [],
      );

      final provider = MealPackProvider();
      provider.setActiveMealPack(dummyPack);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: MealPackView(recipe: testRecipe),
          ),
        ),
      );

      expect(find.text('Creamy Tuscan Garlic Chicken Pasta'), findsOneWidget);
      expect(find.text("Chef's Golden Tip"), findsOneWidget);
      expect(find.text(testRecipe.chefTip), findsOneWidget);
      expect(find.text('Pasta Dinner'), findsOneWidget);
      expect(find.text('20 mins'), findsOneWidget);
      expect(find.text('Everyday Value'), findsOneWidget);
      expect(find.text('Chicken Breast '), findsOneWidget);
      expect(find.text('Start Cooking Mode'), findsOneWidget);
      expect(find.text('Step-by-Step Instructions'), findsOneWidget);
      expect(find.text('Boil penne in salted water until al dente.'), findsOneWidget);
    });

    testWidgets('SavedRecipesView renders empty state and search bar correctly', (WidgetTester tester) async {
      final provider = MealPackProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: const MaterialApp(
            home: SavedRecipesView(),
          ),
        ),
      );

      expect(find.text('No Saved Recipes Yet'), findsOneWidget);
    });

    testWidgets('SavedRecipesView renders date group headers and recipe cards with Cook Now', (WidgetTester tester) async {
      final savedRecipe = Recipe(
        id: 10,
        title: 'Crispy Lemon Thyme Chicken Thighs',
        description: 'Golden skin chicken with roasted potatoes and pan drippings.',
        isSaved: true,
        savedAt: DateTime.now(),
        cookTimeMinutes: 30,
        servings: 2,
        category: 'Poultry Dinner',
        budgetTier: 'Everyday Value',
        chefTip: 'Pat skin completely dry before seasoning.',
        instructions: ['Sear chicken', 'Roast at 200C', 'Rest and carve'],
        recipeSpecificIngredients: [],
      );

      final provider = MealPackProvider();
      provider.setSavedRecipes([savedRecipe]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: const MaterialApp(
            home: SavedRecipesView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SAVED RECIPES'), findsOneWidget);
      expect(find.text('Crispy Lemon Thyme Chicken Thighs'), findsOneWidget);
      expect(find.textContaining('Saved Today'), findsOneWidget);
      expect(find.text('Cook Now'), findsOneWidget);
    });

    testWidgets('DashboardView and RecipeCard render on narrow screen without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 2400); // Narrow mobile device test
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final longBadgeRecipe = Recipe(
        id: 99,
        mealPackId: 1,
        title: 'Creamy Lemon-Herb Butter Salmon Fillet with Roasted Veggies',
        description: 'Pan-seared salmon with a bright lemon-herb compound butter over seasonal greens.',
        cookTimeMinutes: 35,
        servings: 2,
        category: 'One-Pan Skillet Seafood Dinner',
        budgetTier: 'Budget Saver (End-of-Month Friendly)',
        chefTip: 'Sear salmon skin-side down on high heat without moving it for 5 minutes.',
        instructions: ['Heat skillet', 'Cook salmon', 'Serve hot'],
        recipeSpecificIngredients: [],
      );

      final dummyPack = MealPack(
        id: 1,
        createdAt: DateTime.now(),
        season: 'South African Winter',
        month: 'August',
        title: 'Winter Warmers',
        recipes: [longBadgeRecipe],
        sharedFreshIngredients: [],
        storeCupboardStaples: [],
      );

      final provider = MealPackProvider();
      provider.setActiveMealPack(dummyPack);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: const MaterialApp(
            home: DashboardView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Creamy Lemon-Herb Butter Salmon Fillet with Roasted Veggies'), findsOneWidget);
      expect(find.text('One-Pan Skillet Seafood Dinner'), findsOneWidget);
      expect(find.text('Budget Saver (End-of-Month Friendly)'), findsOneWidget);
      expect(find.text('35 min'), findsOneWidget);
    });

    testWidgets('MainLayout renders 4 bottom navigation destinations (Planner, Library, Groceries, Saved)', (WidgetTester tester) async {
      final provider = MealPackProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: const MaterialApp(
            home: MainLayout(),
          ),
        ),
      );

      expect(find.text('Planner'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('CookingModeView renders step action, detects timer, and navigates steps', (WidgetTester tester) async {
      final testRecipe = Recipe(
        id: 1,
        title: 'Pan-Seared Salmon with Garlic Herb Butter',
        cookTimeMinutes: 20,
        servings: 2,
        category: 'Seafood Dinner',
        budgetTier: 'Everyday Value',
        chefTip: 'Sear skin-side down for 5 minutes without touching.',
        instructions: [
          'Heat olive oil in a skillet over medium-high heat until shimmering.',
          'Place salmon fillets skin-side down and sear for 5 minutes until crispy.',
          'Flip and baste with garlic butter for 3 minutes until cooked through.',
        ],
        recipeSpecificIngredients: [
          Ingredient(name: 'Salmon Fillets', quantity: 2, unit: 'fillets', type: 'recipe_specific', recipeId: 1),
          Ingredient(name: 'Garlic Butter', quantity: 30, unit: 'g', type: 'recipe_specific', recipeId: 1),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CookingModeView(recipe: testRecipe),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pan-Seared Salmon with Garlic Herb Butter'), findsOneWidget);
      expect(find.text('STEP 1 OF 3'), findsOneWidget);
      expect(find.text('Action Step'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
      expect(find.text('Ingredients'), findsOneWidget);

      // Tap Next Step
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Step 2 has "sear for 5 minutes" -> detects timer
      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      expect(find.text('Start 5 min Timer'), findsOneWidget);
    });
  });

  group('CuratedRecipeLibrary Unit Tests', () {
    test('contains comprehensive catalog with Korean, Asian, and Adventurous dishes', () {
      final recipes = CuratedRecipeLibrary.recipes;
      expect(recipes.length, greaterThanOrEqualTo(150));

      final korean = recipes.where((r) => r.cuisine.toLowerCase().contains('korean')).toList();
      expect(korean.length, greaterThanOrEqualTo(10));
      expect(korean.any((r) => r.title.contains('Jjimdak')), isTrue);
      expect(korean.any((r) => r.title.contains('Galbijjim')), isTrue);
      expect(korean.any((r) => r.title.contains('Dakdoritang')), isTrue);
      expect(korean.any((r) => r.title.contains('Jeyuk Bokkeum')), isTrue);
      expect(korean.any((r) => r.title.contains('Sundubu')), isTrue);

      final adventurous = recipes.where((r) => r.isAdventurous).toList();
      expect(adventurous.length, greaterThanOrEqualTo(8));
      expect(adventurous.any((r) => r.title.contains('ChongQing')), isTrue);
      expect(adventurous.any((r) => r.title.contains('Lu Rou Fan')), isTrue);
      expect(adventurous.any((r) => r.title.contains('Denningvleis')), isTrue);

      for (final r in recipes) {
        expect(r.title.isNotEmpty, isTrue);
        expect(r.instructions.isNotEmpty, isTrue);
        expect(r.chefTip.isNotEmpty, isTrue);
        expect(r.recipeSpecificIngredients.isNotEmpty, isTrue);
        expect(r.cookTimeMinutes, greaterThan(0));
        expect(r.servings, greaterThan(0));
      }
    });

    test('features broad global cuisine diversity across multiple continents', () {
      final recipes = CuratedRecipeLibrary.recipes;

      final italian = recipes.where((r) => r.cuisine == 'Italian').toList();
      expect(italian.length, greaterThanOrEqualTo(5));
      expect(italian.any((r) => r.title.contains('Carbonara')), isTrue);
      expect(italian.any((r) => r.title.contains('Fagioli')), isTrue);

      final latin = recipes.where((r) => r.cuisine == 'Mexican' || r.cuisine == 'Latin American' || r.cuisine == 'Peruvian' || r.cuisine == 'Argentine').toList();
      expect(latin.length, greaterThanOrEqualTo(6));
      expect(latin.any((r) => r.title.contains('Birria')), isTrue);
      expect(latin.any((r) => r.title.contains('Lomo Saltado')), isTrue);

      final indian = recipes.where((r) => r.cuisine == 'Indian' || r.cuisine == 'South Asian').toList();
      expect(indian.length, greaterThanOrEqualTo(5));
      expect(indian.any((r) => r.title.contains('Butter Chicken')), isTrue);
      expect(indian.any((r) => r.title.contains('Dal Tadka')), isTrue);

      final french = recipes.where((r) => r.cuisine == 'French').toList();
      expect(french.length, greaterThanOrEqualTo(5));
      expect(french.any((r) => r.title.contains('Bourguignon')), isTrue);

      final middleEastern = recipes.where((r) => r.cuisine == 'Middle Eastern' || r.cuisine == 'Turkish' || r.cuisine == 'Lebanese').toList();
      expect(middleEastern.length, greaterThanOrEqualTo(5));
      expect(middleEastern.any((r) => r.title.contains('Shawarma')), isTrue);
      expect(middleEastern.any((r) => r.title.contains('Mujadara')), isTrue);

      final mediterranean = recipes.where((r) => r.cuisine == 'Mediterranean' || r.cuisine == 'Spanish' || r.cuisine == 'Greek').toList();
      expect(mediterranean.length, greaterThanOrEqualTo(5));
      expect(mediterranean.any((r) => r.title.contains('Paella')), isTrue);
    });

    test('features substantial price difference and variability across all 3 budget tiers', () {
      final recipes = CuratedRecipeLibrary.recipes;

      final budgetSaver = recipes.where((r) => r.budgetTier == 'Budget Saver').toList();
      final balanced = recipes.where((r) => r.budgetTier == 'Balanced' || r.budgetTier == 'Standard' || r.budgetTier == 'Everyday Value').toList();
      final gourmet = recipes.where((r) => r.budgetTier == 'Gourmet').toList();

      expect(budgetSaver.length, greaterThanOrEqualTo(30));
      expect(balanced.length, greaterThanOrEqualTo(35));
      expect(gourmet.length, greaterThanOrEqualTo(20));

      // Each tier should span multiple distinct cuisines
      final budgetCuisines = budgetSaver.map((r) => r.cuisine).toSet();
      final gourmetCuisines = gourmet.map((r) => r.cuisine).toSet();
      expect(budgetCuisines.length, greaterThanOrEqualTo(6));
      expect(gourmetCuisines.length, greaterThanOrEqualTo(5));
    });
  });

  group('MealPackGenerator Unit Tests', () {
    test('generates 3 consecutive meal packs with zero repeat recipes and high cuisine diversity', () {
      MealPackGenerator.instance.clearRecentHistory();
      final titlesSeen = <String>{};

      for (int i = 0; i < 3; i++) {
        final pack = MealPackGenerator.instance.generateInstantMealPack(
          seasonContext: SeasonHelper.getSeasonalContext(DateTime.now()),
          pantryItems: [],
          options: const GenerateOptions(cuisineFocus: 'balanced'),
        );

        expect(pack.recipes.length, 6);
        for (final r in pack.recipes) {
          expect(titlesSeen.contains(r.title), isFalse, reason: 'Recipe "${r.title}" repeated in generation $i');
          titlesSeen.add(r.title);
        }

        final packCuisines = pack.recipes.map((r) => r.cuisine).toSet();
        expect(packCuisines.length, greaterThanOrEqualTo(4));
      }

      expect(titlesSeen.length, 18);
    });
    test('generates instant 6-meal pack with korean_asian focus', () {
      const options = GenerateOptions(
        cuisineFocus: 'korean_asian',
        dietaryBalance: '3 vegetarian, 3 mixed protein',
        budgetTier: 'standard',
        servings: 2,
      );

      final pack = MealPackGenerator.instance.generateInstantMealPack(
        seasonContext: SeasonHelper.getSeasonalContext(DateTime.now()),
        pantryItems: ['rice', 'soy sauce'],
        options: options,
      );
      expect(pack.recipes.length, 6);
      expect(pack.sharedFreshIngredients.isNotEmpty, isTrue);
      expect(pack.storeCupboardStaples.isNotEmpty, isTrue);

      final asianCount = pack.recipes.where((r) =>
        r.cuisine.toLowerCase().contains('korean') ||
        r.cuisine.toLowerCase().contains('asian') ||
        r.cuisine.toLowerCase().contains('thai') ||
        r.cuisine.toLowerCase().contains('japanese') ||
        r.cuisine.toLowerCase().contains('chinese') ||
        r.cuisine.toLowerCase().contains('vietnamese')
      ).length;
      expect(asianCount, greaterThanOrEqualTo(4));
    });

    test('generates instant meal pack honoring all vegetarian balance', () {
      const options = GenerateOptions(
        cuisineFocus: 'balanced',
        dietaryBalance: 'All vegetarian',
        budgetTier: 'budget',
        servings: 4,
      );

      final pack = MealPackGenerator.instance.generateInstantMealPack(
        seasonContext: SeasonHelper.getSeasonalContext(DateTime.now()),
        pantryItems: [],
        options: options,
      );
      expect(pack.recipes.length, 6);
      const meatKeywords = [
        'chicken', 'beef', 'pork', 'lamb', 'mutton', 'hake', 'fish', 'salmon',
        'trout', 'clam', 'squid', 'shrimp', 'prawn', 'bacon', 'sausage'
      ];
      for (final r in pack.recipes) {
        final hasMeat = r.recipeSpecificIngredients.any((ing) =>
          meatKeywords.any((m) => ing.name.toLowerCase().contains(m))
        );
        expect(hasMeat, isFalse, reason: '${r.title} should not contain meat');
      }
    });

    test('findAlternativeRecipes returns valid replacements excluding current recipe', () {
      final baseRecipe = CuratedRecipeLibrary.recipes.first.copyWith(id: 999);
      final pack = MealPackGenerator.instance.generateInstantMealPack(
        seasonContext: SeasonHelper.getSeasonalContext(DateTime.now()),
        pantryItems: [],
        options: const GenerateOptions(cuisineFocus: 'korean_asian'),
      );
      final alternatives = MealPackGenerator.instance.findAlternativeRecipes(
        baseRecipe,
        pack,
        const GenerateOptions(cuisineFocus: 'korean_asian'),
      );

      expect(alternatives.isNotEmpty, isTrue);
      expect(alternatives.any((r) => r.id == baseRecipe.id), isFalse);
      expect(alternatives.any((r) => r.title == baseRecipe.title), isFalse);
    });

    test('generates instant meal pack with mediterranean_european focus', () {
      const options = GenerateOptions(
        cuisineFocus: 'mediterranean_european',
        dietaryBalance: '3 vegetarian, 3 mixed protein',
        budgetTier: 'standard',
        servings: 2,
      );

      final pack = MealPackGenerator.instance.generateInstantMealPack(
        seasonContext: SeasonHelper.getSeasonalContext(DateTime.now()),
        pantryItems: ['olive oil', 'garlic'],
        options: options,
      );

      expect(pack.recipes.length, 6);
      expect(pack.title, 'Tuscan & Mediterranean Feast Pack');

      final medCount = pack.recipes.where((r) =>
        r.cuisine == 'Italian' ||
        r.cuisine == 'Spanish' ||
        r.cuisine == 'Mediterranean' ||
        r.cuisine == 'Greek' ||
        r.cuisine == 'French' ||
        r.cuisine == 'European'
      ).length;
      expect(medCount, greaterThanOrEqualTo(4));
    });

    test('generates instant meal pack with latin_american focus', () {
      const options = GenerateOptions(
        cuisineFocus: 'latin_american',
        dietaryBalance: '3 vegetarian, 3 mixed protein',
        budgetTier: 'standard',
        servings: 2,
      );

      final pack = MealPackGenerator.instance.generateInstantMealPack(
        seasonContext: SeasonHelper.getSeasonalContext(DateTime.now()),
        pantryItems: ['tortillas', 'black beans'],
        options: options,
      );

      expect(pack.recipes.length, 6);
      expect(pack.title, 'Oaxaca & Latin Kitchen Pack');

      final latinCount = pack.recipes.where((r) =>
        r.cuisine == 'Mexican' || r.cuisine == 'Latin American'
      ).length;
      expect(latinCount, greaterThanOrEqualTo(4));
    });
  });

  group('Ingredient Aisle Categorization and Scaling Tests', () {
    test('classifies ingredients into correct supermarket aisles', () {
      final produce = Ingredient(name: 'Scallions (Green Onions)', quantity: 4, unit: 'stalks', type: 'shared_fresh');
      final meat = Ingredient(name: 'Boneless Chicken Thighs', quantity: 500, unit: 'g', type: 'recipe_specific');
      final dairy = Ingredient(name: 'Heavy Cream', quantity: 150, unit: 'ml', type: 'recipe_specific');
      final grain = Ingredient(name: 'Dangmyeon Sweet Potato Glass Noodles', quantity: 150, unit: 'g', type: 'recipe_specific');
      final pantry = Ingredient(name: 'Korean Gochujang Chili Paste', quantity: 2, unit: 'tbsp', type: 'staple');

      expect(produce.aisle, 'Fresh Produce');
      expect(meat.aisle, 'Meat & Protein');
      expect(dairy.aisle, 'Dairy & Chilled');
      expect(grain.aisle, 'Grains & Noodles');
      expect(pantry.aisle, 'Pantry & Spices');
    });

    test('scales ingredient quantities correctly for servings changes', () {
      final original = Ingredient(name: 'Short Ribs', quantity: 600, unit: 'g', type: 'recipe_specific');
      const baseServings = 2;
      const targetServings = 4;
      const scaleFactor = targetServings / baseServings;

      final scaled = original.copyWith(quantity: original.quantity * scaleFactor);
      expect(scaled.quantity, 1200.0);
      expect(scaled.unit, 'g');
    });
  });
}





