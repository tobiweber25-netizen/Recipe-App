import 'dart:math';
import '../data/curated_recipe_library.dart';
import '../models/ingredient.dart';
import '../models/meal_pack.dart';
import '../models/recipe.dart';
import '../models/generate_options.dart';
import '../utils/season_helper.dart';

class MealPackGenerator {
  static final MealPackGenerator instance = MealPackGenerator._init();
  MealPackGenerator._init();

  final List<String> _recentHistory = [];
  static const int maxRecentHistory = 36;

  void recordRecentRecipes(List<String> titles) {
    for (final t in titles) {
      _recentHistory.removeWhere((item) => item.toLowerCase() == t.toLowerCase());
      _recentHistory.add(t);
    }
    while (_recentHistory.length > maxRecentHistory) {
      _recentHistory.removeAt(0);
    }
  }

  void clearRecentHistory() {
    _recentHistory.clear();
  }

  static bool _isVegetarian(Recipe recipe) {
    const meatKeywords = [
      'chicken', 'beef', 'pork', 'lamb', 'mutton', 'hake', 'fish', 'salmon',
      'trout', 'clam', 'squid', 'shrimp', 'prawn', 'bacon', 'sausage'
    ];
    for (final ing in recipe.recipeSpecificIngredients) {
      final name = ing.name.toLowerCase();
      if (meatKeywords.any((k) => name.contains(k))) return false;
    }
    return true;
  }

  static String _detectPrimaryProtein(Recipe r) {
    final text = '${r.title}${r.recipeSpecificIngredients.map((i) => i.name).join(' ')}'.toLowerCase();
    if (text.contains('chicken') || text.contains('duck') || text.contains('poultry')) return 'poultry';
    if (text.contains('beef') || text.contains('steak') || text.contains('short rib') || text.contains('brisket') || text.contains('shank')) return 'beef';
    if (text.contains('pork') || text.contains('bacon') || text.contains('chashu') || text.contains('chorizo') || text.contains('chouriço') || text.contains('sausage')) return 'pork';
    if (text.contains('lamb') || text.contains('mutton')) return 'lamb';
    if (text.contains('fish') || text.contains('salmon') || text.contains('hake') || text.contains('cod') || text.contains('prawn') || text.contains('shrimp') || text.contains('clam') || text.contains('mussel') || text.contains('squid') || text.contains('calamari')) return 'seafood';
    if (text.contains('tofu') || text.contains('tempeh')) return 'tofu';
    if (text.contains('lentil') || text.contains('chickpea') || text.contains('bean') || text.contains('dal')) return 'legume';
    if (text.contains('paneer') || text.contains('halloumi') || text.contains('feta') || text.contains('egg')) return 'dairy_egg';
    return 'vegetable';
  }

  static String _detectStarchBase(Recipe r) {
    final text = '${r.title}${r.recipeSpecificIngredients.map((i) => i.name).join(' ')}'.toLowerCase();
    if (text.contains('noodle') || text.contains('ramen') || text.contains('spaghetti') || text.contains('pasta') || text.contains('rigatoni') || text.contains('bucatini') || text.contains('orzo') || text.contains('ditalini') || text.contains('vermicelli') || text.contains('dangmyeon')) return 'noodle_pasta';
    if (text.contains('potato') || text.contains('sweet potato') || text.contains('yuca') || text.contains('yam')) return 'potato_root';
    if (text.contains('bread') || text.contains('roti') || text.contains('naan') || text.contains('pita') || text.contains('tortilla') || text.contains('tostada') || text.contains('arepa') || text.contains('baguette') || text.contains('bun') || text.contains('dumpling') || text.contains('dombolo')) return 'bread_dough';
    if (text.contains('rice') || text.contains('risotto') || text.contains('arborio') || text.contains('bomba') || text.contains('biryani') || text.contains('paella') || text.contains('jollof')) return 'rice';
    return 'other';
  }

  MealPack generateInstantMealPack({
    required SeasonalContext seasonContext,
    required List<String> pantryItems,
    required GenerateOptions options,
    List<String> excludedRecipeTitles = const [],
  }) {
    final allRecipes = List<Recipe>.from(CuratedRecipeLibrary.recipes);
    final random = Random();

    // 1. Determine dietary split targets
    int targetVeg = 0;
    int targetMeat = 0;

    final diet = options.dietaryBalance.toLowerCase();
    if (diet.contains('all vegetarian')) {
      targetVeg = 6;
      targetMeat = 0;
    } else if (diet.contains('all meat')) {
      targetVeg = 0;
      targetMeat = 6;
    } else if (diet.contains('mostly vegetarian')) {
      targetVeg = 5;
      targetMeat = 1;
    } else if (diet.contains('mostly meat')) {
      targetVeg = 1;
      targetMeat = 5;
    } else {
      // Default: balanced 3 veg, 3 meat
      targetVeg = 3;
      targetMeat = 3;
    }

    // 2. Score candidates based on cuisine focus, budget, adventurous, and pantry items
    double scoreRecipe(Recipe r) {
      double score = 10.0;

      // Anti-repeat penalty: heavy penalty for excluded or recently generated recipes
      if (excludedRecipeTitles.any((t) => t.toLowerCase() == r.title.toLowerCase())) {
        score -= 500.0;
      }
      final recentIdx = _recentHistory.indexWhere((t) => t.toLowerCase() == r.title.toLowerCase());
      if (recentIdx != -1) {
        final recencyFactor = (_recentHistory.length - recentIdx) / _recentHistory.length;
        score -= 300.0 + (recencyFactor * 200.0);
      }

      // Cuisine Focus Scoring
      switch (options.cuisineFocus) {
        case 'claypot_ferments':
          final lowerTitleDesc = '${r.title}${r.description}'.toLowerCase();
          final ingText = r.recipeSpecificIngredients.map((i) => i.name.toLowerCase()).join(' ');
          if (lowerTitleDesc.contains('donabe') || lowerTitleDesc.contains('claypot') || lowerTitleDesc.contains('jjigae') || lowerTitleDesc.contains('stew') || lowerTitleDesc.contains('braised')) score += 20.0;
          if (ingText.contains('kimchi') || ingText.contains('miso') || ingText.contains('doenjang') || ingText.contains('gochujang') || ingText.contains('sauerkraut') || ingText.contains('yogurt') || ingText.contains('yoghurt') || ingText.contains('pickled') || ingText.contains('preserved')) score += 25.0;
          break;
        case 'korean_asian':
          if (r.cuisine == 'Korean') score += 35.0;
          if (r.cuisine == 'Pan-Asian' ||
              r.cuisine == 'Thai' ||
              r.cuisine == 'Chinese' ||
              r.cuisine == 'Japanese' ||
              r.cuisine == 'Vietnamese' ||
              r.cuisine == 'Malaysian' ||
              r.cuisine == 'Indonesian' ||
              r.cuisine == 'Filipino' ||
              r.cuisine == 'Cantonese' ||
              r.cuisine == 'Sichuan') {
            score += 20.0;
          }
          break;
        case 'adventurous_bold':
          if (r.isAdventurous) score += 30.0;
          if (r.cuisine == 'Korean' ||
              r.cuisine == 'Pan-Asian' ||
              r.cuisine == 'Sichuan' ||
              r.cuisine == 'Nigerian' ||
              r.cuisine == 'Peruvian') {
            score += 10.0;
          }
          break;
        case 'mediterranean_european':
          if (r.cuisine == 'Italian' ||
              r.cuisine == 'Spanish' ||
              r.cuisine == 'Mediterranean' ||
              r.cuisine == 'Greek') {
            score += 35.0;
          }
          if (r.cuisine == 'French' ||
              r.cuisine == 'European' ||
              r.cuisine == 'Portuguese' ||
              r.cuisine == 'Polish' ||
              r.cuisine == 'Ukrainian' ||
              r.cuisine == 'Russian') {
            score += 20.0;
          }
          break;
        case 'latin_american':
          if (r.cuisine == 'Mexican' ||
              r.cuisine == 'Latin American' ||
              r.cuisine == 'Peruvian' ||
              r.cuisine == 'Venezuelan' ||
              r.cuisine == 'Colombian' ||
              r.cuisine == 'Argentine') {
            score += 45.0;
          }
          break;
        case 'south_asian':
          if (r.cuisine == 'Indian' || r.cuisine == 'South Asian') score += 30.0;
          break;
        case 'middle_eastern':
          if (r.cuisine == 'Middle Eastern' ||
              r.cuisine == 'Turkish' ||
              r.cuisine == 'Lebanese' ||
              r.cuisine == 'Persian') {
            score += 30.0;
          }
          if (r.cuisine == 'Moroccan' ||
              r.cuisine == 'African' ||
              r.cuisine == 'Mediterranean') {
            score += 15.0;
          }
          break;
        case 'gourmet_dining':
          if (r.budgetTier == 'Gourmet') score += 35.0;
          if (r.isAdventurous) score += 15.0;
          break;
        case 'south_african':
          if (r.cuisine == 'South African') score += 30.0;
          break;
        case 'quick':
          if (r.cookTimeMinutes <= 20) {
            score += 25.0;
          } else if (r.cookTimeMinutes <= 25) {
            score += 15.0;
          }
          break;
        case 'balanced':
        default:
          score += 5.0;
          break;
      }

      // Custom Direction Matching
      if (options.customDirection.trim().isNotEmpty) {
        final keywords = options.customDirection
            .toLowerCase()
            .split(RegExp(r'[^a-zA-Z0-9]+'))
            .where((w) => w.length > 2);
        final searchableText = '${r.title} ${r.description} ${r.cuisine} ${r.recipeSpecificIngredients.map((i) => i.name).join(' ')}'.toLowerCase();
        for (final kw in keywords) {
          if (searchableText.contains(kw)) {
            score += 18.0;
          }
        }
      }

      // Budget Tier Matching
      if (options.budgetTier == 'budget') {
        if (r.budgetTier == 'Budget Saver') score += 15.0;
        if (r.budgetTier == 'Gourmet') score -= 10.0;
      } else if (options.budgetTier == 'gourmet') {
        if (r.budgetTier == 'Gourmet') score += 20.0;
        if (r.budgetTier == 'Balanced') score += 10.0;
      }

      // Pantry Items Match
      if (pantryItems.isNotEmpty) {
        for (final pItem in pantryItems) {
          final cleanP = pItem.toLowerCase().trim();
          if (r.recipeSpecificIngredients.any((ing) => ing.name.toLowerCase().contains(cleanP))) {
            score += 8.0;
          }
        }
      }

      // Seasonal Keywords Match
      for (final seasonalProd in seasonContext.produceKeywords) {
        final cleanS = seasonalProd.toLowerCase().trim();
        if (r.recipeSpecificIngredients.any((ing) => ing.name.toLowerCase().contains(cleanS))) {
          score += 6.0;
        }
      }

      // Significant stochastic jitter for randomized fresh variety across generations
      score += random.nextDouble() * 25.0;

      return score;
    }

    final scoredRecipes = allRecipes.map((r) => MapEntry(r, scoreRecipe(r))).toList();
    scoredRecipes.sort((a, b) => b.value.compareTo(a.value));

    // 3. Select balanced recipes matching dietary balance, rotation, and overlap
    final List<Recipe> selected = [];
    final vegCandidates = scoredRecipes.where((e) => _isVegetarian(e.key)).map((e) => e.key).toList();
    final meatCandidates = scoredRecipes.where((e) => !_isVegetarian(e.key)).map((e) => e.key).toList();
    final Set<String> pickedCuisines = {};
    final Map<String, int> proteinCounts = {};
    final Map<String, int> starchCounts = {};
    final Set<String> activeFreshProduce = {};
    final Map<String, double> recipeScoreMap = {for (var e in scoredRecipes) e.key.title: e.value};

    void addSelected(Recipe r) {
      selected.add(r);
      pickedCuisines.add(r.cuisine);
      final p = _detectPrimaryProtein(r);
      final s = _detectStarchBase(r);
      proteinCounts[p] = (proteinCounts[p] ?? 0) + 1;
      starchCounts[s] = (starchCounts[s] ?? 0) + 1;
      for (final ing in r.recipeSpecificIngredients) {
        if (ing.aisle == 'Fresh Produce') {
          activeFreshProduce.add(ing.name.toLowerCase().trim());
        }
      }
    }

    bool sharesFreshProduce(Recipe r) {
      if (activeFreshProduce.isEmpty) return false;
      return r.recipeSpecificIngredients.any(
        (ing) => ing.aisle == 'Fresh Produce' && activeFreshProduce.contains(ing.name.toLowerCase().trim()),
      );
    }

    List<Recipe> sortWithProduceBoost(List<Recipe> candidates) {
      final shouldBoost = options.overlap.contains('80%') || options.overlap.contains('Smart');
      if (!shouldBoost || activeFreshProduce.isEmpty) {
        return candidates;
      }
      final list = List<Recipe>.from(candidates);
      list.sort((a, b) {
        final aScore = (recipeScoreMap[a.title] ?? 0.0) + (sharesFreshProduce(a) ? 15.0 : 0.0);
        final bScore = (recipeScoreMap[b.title] ?? 0.0) + (sharesFreshProduce(b) ? 15.0 : 0.0);
        return bScore.compareTo(aScore);
      });
      return list;
    }

    // Pick target vegetarian: pass 1 ensures diverse cuisines, protein & starch rotation
    int vegPicked = 0;
    for (final r in sortWithProduceBoost(vegCandidates)) {
      if (vegPicked >= targetVeg) break;
      if (!selected.contains(r)) {
        if (options.cuisineFocus == 'balanced' && pickedCuisines.contains(r.cuisine)) {
          continue;
        }
        if ((proteinCounts[_detectPrimaryProtein(r)] ?? 0) >= 2) {
          continue;
        }
        if ((starchCounts[_detectStarchBase(r)] ?? 0) >= 3) {
          continue;
        }
        addSelected(r);
        vegPicked++;
      }
    }
    // Pass 2: fill remaining veg if rotation/diverse pass left slots open
    for (final r in vegCandidates) {
      if (vegPicked >= targetVeg) break;
      if (!selected.contains(r)) {
        addSelected(r);
        vegPicked++;
      }
    }

    // Pick target meat: pass 1 ensures diverse cuisines, protein & starch rotation
    int meatPicked = 0;
    for (final r in sortWithProduceBoost(meatCandidates)) {
      if (meatPicked >= targetMeat) break;
      if (!selected.contains(r)) {
        if (options.cuisineFocus == 'balanced' && pickedCuisines.contains(r.cuisine)) {
          continue;
        }
        if ((proteinCounts[_detectPrimaryProtein(r)] ?? 0) >= 2) {
          continue;
        }
        if ((starchCounts[_detectStarchBase(r)] ?? 0) >= 3) {
          continue;
        }
        addSelected(r);
        meatPicked++;
      }
    }
    // Pass 2: fill remaining meat if rotation/diverse pass left slots open
    for (final r in meatCandidates) {
      if (meatPicked >= targetMeat) break;
      if (!selected.contains(r)) {
        addSelected(r);
        meatPicked++;
      }
    }

    // Fill any remainder up to 6 from top scored
    for (final entry in scoredRecipes) {
      if (selected.length >= 6) break;
      if (!selected.contains(entry.key)) {
        addSelected(entry.key);
      }
    }

    // Scale recipes to requested servings
    final scaledRecipes = selected.take(6).map((r) {
      final baseServings = r.servings;
      final targetServings = options.servings;
      final scale = targetServings / baseServings;

      final scaledIngredients = r.recipeSpecificIngredients.map((ing) {
        return ing.copyWith(
          quantity: (ing.quantity * scale).roundToDouble(),
        );
      }).toList();

      return r.copyWith(
        servings: targetServings,
        recipeSpecificIngredients: scaledIngredients,
      );
    }).toList();

    // Record chosen recipes in recency memory
    recordRecentRecipes(scaledRecipes.map((r) => r.title).toList());

    // 4. Calculate smart ingredient overlap & staples
    final Map<String, List<Ingredient>> produceCounts = {};
    final Map<String, List<Ingredient>> stapleCounts = {};

    for (final r in scaledRecipes) {
      for (final ing in r.recipeSpecificIngredients) {
        final aisle = ing.aisle;
        final cleanName = ing.name.toLowerCase().trim();

        if (aisle == 'Fresh Produce') {
          produceCounts.putIfAbsent(cleanName, () => []).add(ing);
        } else if (aisle == 'Pantry & Spices') {
          stapleCounts.putIfAbsent(cleanName, () => []).add(ing);
        }
      }
    }

    final List<Ingredient> sharedFresh = [];
    produceCounts.forEach((name, list) {
      if (list.length >= 2) {
        double totalQty = list.fold(0.0, (sum, i) => sum + i.quantity);
        sharedFresh.add(Ingredient(
          name: list.first.name,
          quantity: totalQty,
          unit: list.first.unit,
          type: 'shared_fresh',
        ));
      }
    });

    final List<Ingredient> staples = [];
    stapleCounts.forEach((name, list) {
      if (list.length >= 2) {
        double totalQty = list.fold(0.0, (sum, i) => sum + i.quantity);
        staples.add(Ingredient(
          name: list.first.name,
          quantity: totalQty,
          unit: list.first.unit,
          type: 'staple',
        ));
      }
    });

    String packTitle;
    switch (options.cuisineFocus) {
      case 'claypot_ferments':
        packTitle = 'Donabe, Claypot & Ferments Pack';
        break;
      case 'korean_asian':
        packTitle = 'Seoul & Asian Kitchen Meal Pack';
        break;
      case 'adventurous_bold':
        packTitle = 'Adventurous Regional Chef Pack';
        break;
      case 'mediterranean_european':
        packTitle = 'Tuscan & Mediterranean Feast Pack';
        break;
      case 'latin_american':
        packTitle = 'Oaxaca & Latin Kitchen Pack';
        break;
      case 'south_asian':
        packTitle = 'Spice Route & Curry Pack';
        break;
      case 'middle_eastern':
        packTitle = 'Levantine & Mezze Dinner Pack';
        break;
      case 'gourmet_dining':
        packTitle = 'Chef\'s Table Tasting Pack';
        break;
      case 'south_african':
        packTitle = 'Mzansi Heritage Meal Pack';
        break;
      case 'quick':
        packTitle = 'Fast 25-Min Weeknight Pack';
        break;
      default:
        packTitle = 'Weekly ${seasonContext.monthName} Dinner Pack';
        break;
    }

    return MealPack(
      createdAt: DateTime.now(),
      season: seasonContext.seasonName,
      month: seasonContext.monthName,
      title: packTitle,
      recipes: scaledRecipes,
      sharedFreshIngredients: sharedFresh,
      storeCupboardStaples: staples,
    );
  }

  List<Recipe> findAlternativeRecipes(Recipe currentRecipe, MealPack currentPack, GenerateOptions options) {
    final existingTitles = currentPack.recipes.map((r) => r.title.toLowerCase()).toSet();
    existingTitles.add(currentRecipe.title.toLowerCase());
    final isVeg = _isVegetarian(currentRecipe);
    final random = Random();

    // Candidates not already in active pack and not current recipe
    final candidates = CuratedRecipeLibrary.recipes.where((r) {
      if (existingTitles.contains(r.title.toLowerCase())) return false;
      return true;
    }).toList();

    // Sort by matching cuisine, dietary, adventurous preference, and recency penalty
    candidates.sort((a, b) {
      double scoreA = 0.0;
      double scoreB = 0.0;

      // Dietary match
      if (_isVegetarian(a) == isVeg) scoreA += 25.0;
      if (_isVegetarian(b) == isVeg) scoreB += 25.0;

      // Cuisine match
      if (a.cuisine == currentRecipe.cuisine) scoreA += 15.0;
      if (b.cuisine == currentRecipe.cuisine) scoreB += 15.0;

      // Adventurous match
      if (a.isAdventurous == currentRecipe.isAdventurous) scoreA += 8.0;
      if (b.isAdventurous == currentRecipe.isAdventurous) scoreB += 8.0;

      // Recency penalty
      if (_recentHistory.any((t) => t.toLowerCase() == a.title.toLowerCase())) scoreA -= 50.0;
      if (_recentHistory.any((t) => t.toLowerCase() == b.title.toLowerCase())) scoreB -= 50.0;

      // Stochastic jitter for fresh alternatives
      scoreA += random.nextDouble() * 10.0;
      scoreB += random.nextDouble() * 10.0;

      return scoreB.compareTo(scoreA);
    });

    return candidates.take(4).map((r) {
      final scale = currentRecipe.servings / r.servings;
      final scaledIngredients = r.recipeSpecificIngredients.map((ing) {
        return ing.copyWith(
          quantity: (ing.quantity * scale).roundToDouble(),
        );
      }).toList();

      return r.copyWith(
        servings: currentRecipe.servings,
        recipeSpecificIngredients: scaledIngredients,
      );
    }).toList();
  }
}
