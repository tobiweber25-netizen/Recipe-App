import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe.dart';
import '../state/meal_pack_provider.dart';
import '../utils/app_tokens.dart';
import 'cooking_mode_view.dart';

class MealPackView extends StatefulWidget {
  final Recipe recipe;

  const MealPackView({super.key, required this.recipe});

  @override
  State<MealPackView> createState() => _MealPackViewState();
}

class _MealPackViewState extends State<MealPackView> {
  bool _isLoadingDetails = false;
  int _currentServings = 2;

  @override
  void initState() {
    super.initState();
    _currentServings = widget.recipe.servings > 0 ? widget.recipe.servings : 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadDetails();
    });
  }

  void _checkAndLoadDetails() async {
    final provider = context.read<MealPackProvider>();
    final activePack = provider.activeMealPack;
    if (activePack == null) return;

    Recipe currentRecipe = widget.recipe;
    final index = activePack.recipes.indexWhere((r) => r.id == widget.recipe.id);
    if (index != -1) currentRecipe = activePack.recipes[index];

    if (currentRecipe.instructions.isEmpty) {
      setState(() => _isLoadingDetails = true);
      try {
        await provider.loadRecipeDetails(currentRecipe);
      } finally {
        if (mounted) setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<MealPackProvider>(
      builder: (context, provider, child) {
        // Find latest recipe version
        Recipe recipe = widget.recipe;
        final activePack = provider.activeMealPack;
        if (activePack != null) {
          final found = activePack.recipes.firstWhere((r) => r.id == widget.recipe.id, orElse: () => widget.recipe);
          recipe = found;
        }

        final isSaved = provider.savedRecipes.any((r) =>
            r.id == recipe.id ||
            (r.title == recipe.title && r.mealPackId == recipe.mealPackId));

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Recipe Details',
              style: AppTokens.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: isSaved
                      ? (isDark ? AppTokens.primaryDark : AppTokens.primaryLight)
                      : (isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight),
                ),
                onPressed: () {
                  provider.toggleSaveRecipe(recipe);
                },
                tooltip: isSaved ? 'Unsave Recipe' : 'Save Recipe',
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  if (recipe.instructions.isEmpty) return;
                  final sb = StringBuffer();
                  sb.writeln('🍳 Recipe: ${recipe.title}\n');
                  if (recipe.description.isNotEmpty) {
                    sb.writeln('${recipe.description}\n');
                  }
                  sb.writeln('⏱ Cook Time: ${recipe.cookTimeMinutes} min | 🍽 Servings: ${recipe.servings} | Tier: ${recipe.budgetTier}\n');
                  sb.writeln('🛒 Ingredients:');
                  if (recipe.recipeSpecificIngredients.isEmpty) {
                    sb.writeln('- Pantry staples & seasonal fresh produce');
                  } else {
                    for (var ing in recipe.recipeSpecificIngredients) {
                      sb.writeln('• ${ing.name}: ${ing.quantity.toStringAsFixed(0)} ${ing.unit}');
                    }
                  }
                  if (recipe.chefTip.isNotEmpty) {
                    sb.writeln('\n💡 Chef Tip: ${recipe.chefTip}');
                  }
                  sb.writeln('\n📋 Step-by-Step Instructions:');
                  for (int i = 0; i < recipe.instructions.length; i++) {
                    sb.writeln('${i + 1}. ${recipe.instructions[i]}');
                  }
                  SharePlus.instance.share(
                    ShareParams(
                      text: sb.toString(),
                      subject: recipe.title,
                    ),
                  );
                },
                tooltip: 'Share Recipe',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe Title & Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTokens.spaceLg),
                  decoration: BoxDecoration(
                    color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    border: Border.all(
                      color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                      width: 1.0,
                    ),
                    boxShadow: AppTokens.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kicker Meta Row
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: AppTokens.spaceXs + 2,
                              runSpacing: AppTokens.spaceXs,
                              children: [
                                Text(
                                  recipe.category.isNotEmpty ? recipe.category : recipe.cuisine,
                                  style: AppTokens.kicker(
                                    fontSize: 10.5,
                                    color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                  ),
                                ),
                                Text('•', style: AppTokens.kicker(color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withValues(alpha: 0.5))),
                                Text(
                                  '${recipe.cookTimeMinutes} mins',
                                  style: AppTokens.kicker(
                                    fontSize: 10.5,
                                    color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                  ),
                                ),
                                Text('•', style: AppTokens.kicker(color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withValues(alpha: 0.5))),
                                Text(
                                  recipe.budgetTier,
                                  style: AppTokens.kicker(
                                    fontSize: 10.5,
                                    color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            ),
                            child: Text(
                              '$_currentServings PORTIONS',
                              style: AppTokens.kicker(
                                fontSize: 9.5,
                                color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spaceSm + 4),

                      // Title
                      Text(
                        recipe.title,
                        style: AppTokens.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                          height: 1.25,
                        ),
                      ),
                      if (recipe.description.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spaceSm),
                        Text(
                          recipe.description,
                          style: AppTokens.sansBody(
                            fontSize: 14,
                            color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppTokens.spaceLg),

                if (_isLoadingDetails || recipe.instructions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.0,
                              color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Writing Chef Recipe...',
                            style: AppTokens.display(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Chef's Golden Tip Box
                  if (recipe.chefTip.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTokens.spaceMd),
                      decoration: BoxDecoration(
                        color: isDark ? AppTokens.accentSunTintDark : AppTokens.accentSunTintLight,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(
                          color: AppTokens.accentSun.withValues(alpha: isDark ? 0.35 : 0.4),
                          width: 1.0,
                        ),
                        boxShadow: AppTokens.cardShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTokens.spaceSm),
                            decoration: const BoxDecoration(
                              gradient: AppTokens.goldenNectarGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSm + 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Chef's Golden Tip",
                                  style: AppTokens.kicker(
                                    fontSize: 11,
                                    color: isDark ? AppTokens.accentSunDark : const Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recipe.chefTip,
                                  style: AppTokens.sansBody(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppTokens.textPrimaryDark : const Color(0xFF78350F),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceLg),
                  ],

                  // Servings Scaler
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(
                        color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                        width: 1.0,
                      ),
                      boxShadow: AppTokens.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt_outlined,
                              size: 20,
                              color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                            ),
                            const SizedBox(width: AppTokens.spaceSm),
                            Text(
                              'Servings',
                              style: AppTokens.display(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 2, label: Text('2P')),
                            ButtonSegment(value: 4, label: Text('4P')),
                            ButtonSegment(value: 6, label: Text('6P')),
                          ],
                          selected: {_currentServings},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _currentServings = newSelection.first;
                            });
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceLg),

                  // Ingredients Section
                  Builder(
                    builder: (context) {
                      final double scaleFactor = (recipe.servings > 0) ? (_currentServings / recipe.servings) : 1.0;
                      final scaledIngredients = recipe.recipeSpecificIngredients.map((ing) {
                        return ing.copyWith(quantity: ing.quantity * scaleFactor);
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ingredients Checklist',
                                style: AppTokens.display(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                                ),
                              ),
                              Text(
                                '${scaledIngredients.length} items (${_currentServings}P)',
                                style: AppTokens.kicker(
                                  fontSize: 10.5,
                                  color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMd),
                          scaledIngredients.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
                                  child: Text(
                                    'All ingredients provided via pantry staples and seasonal fresh produce.',
                                    style: AppTokens.sansBody(
                                      color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: AppTokens.spaceSm,
                                  runSpacing: AppTokens.spaceSm,
                                  children: scaledIngredients
                                      .where((ing) {
                                        final name = ing.name.toLowerCase().trim();
                                        const basic = ['salt', 'pepper', 'black pepper', 'white pepper', 'water', 'kosher salt', 'sea salt', 'tap water'];
                                        return !basic.contains(name);
                                      })
                                      .map((ing) {
                                    final isChecked = ing.isChecked;
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                      onTap: () {
                                        provider.toggleIngredientChecked(ing, !isChecked);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? (isDark ? AppTokens.accentMintTintDark : AppTokens.accentMintTintLight)
                                              : (isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight),
                                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                          border: Border.all(
                                            color: isChecked
                                                ? (isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight)
                                                : (isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                            width: 1.0,
                                          ),
                                          boxShadow: AppTokens.cardShadow,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                              size: 16,
                                              color: isChecked
                                                  ? (isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight)
                                                  : (isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${ing.name} ',
                                              style: AppTokens.sansBody(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isChecked
                                                    ? (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight)
                                                    : (isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight),
                                              ).copyWith(
                                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            Text(
                                              '(${ing.quantity > 0 ? (ing.quantity == ing.quantity.roundToDouble() ? ing.quantity.toStringAsFixed(0) : ing.quantity.toStringAsFixed(1)) : ''} ${ing.unit})',
                                              style: AppTokens.numeral(
                                                fontSize: 11.5,
                                                color: isChecked
                                                    ? (isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight)
                                                    : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                          const SizedBox(height: AppTokens.spaceLg),

                          // Start Cooking Mode Primary Action Banner
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppTokens.sunburstGradient,
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              boxShadow: AppTokens.sunGlowShadow,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CookingModeView(
                                      recipe: recipe.copyWith(servings: _currentServings),
                                      ingredients: scaledIngredients,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.soup_kitchen_rounded, size: 20),
                              label: const Text('Start Cooking Mode'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusPill)),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppTokens.spaceXl),

                  // Instructions Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Step-by-Step Instructions',
                          style: AppTokens.display(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final double scaleFactor = (recipe.servings > 0) ? (_currentServings / recipe.servings) : 1.0;
                          final scaledIngredients = recipe.recipeSpecificIngredients.map((ing) {
                            return ing.copyWith(quantity: ing.quantity * scaleFactor);
                          }).toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CookingModeView(
                                recipe: recipe.copyWith(servings: _currentServings),
                                ingredients: scaledIngredients,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                        ),
                        label: Text(
                          'Cooking View',
                          style: AppTokens.kicker(
                            fontSize: 11,
                            color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMd),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recipe.instructions.length,
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTokens.spaceMd),
                        child: Container(
                          padding: const EdgeInsets.all(AppTokens.spaceMd),
                          decoration: BoxDecoration(
                            color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                            border: Border.all(
                              color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                              width: 1.0,
                            ),
                            boxShadow: AppTokens.cardShadow,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  (idx + 1).toString().padLeft(2, '0'),
                                  style: AppTokens.numeral(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceMd),
                              Expanded(
                                child: Text(
                                  recipe.instructions[idx],
                                  style: AppTokens.sansBody(
                                    fontSize: 14.5,
                                    color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTokens.spaceXxl),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
