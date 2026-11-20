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
  static const List<int> _supportedServings = [2, 4, 6];

  bool _isLoadingDetails = false;
  String? _loadError;
  int _currentServings = 2;
  final Set<String> _localCheckedIngredients = {};

  static String _formatQuantity(double quantity, String unit) {
    if (quantity <= 0) return unit.trim();
    final qtyStr = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);
    return unit.trim().isEmpty ? qtyStr : '$qtyStr ${unit.trim()}';
  }

  @override
  void initState() {
    super.initState();
    final initialServings = widget.recipe.servings;
    _currentServings = _supportedServings.contains(initialServings) ? initialServings : 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadDetails();
    });
  }

  Recipe _resolveLatestRecipe(MealPackProvider provider) {
    final targetId = widget.recipe.id;
    if (targetId != null) {
      final activePack = provider.activeMealPack;
      if (activePack != null) {
        final idx = activePack.recipes.indexWhere((r) => r.id == targetId);
        if (idx != -1) return activePack.recipes[idx];
      }
      final savedIdx = provider.savedRecipes.indexWhere((r) => r.id == targetId);
      if (savedIdx != -1) return provider.savedRecipes[savedIdx];
    }
    return widget.recipe;
  }

  Future<void> _checkAndLoadDetails() async {
    final provider = context.read<MealPackProvider>();
    final currentRecipe = _resolveLatestRecipe(provider);

    if (currentRecipe.instructions.isEmpty && provider.activeMealPack != null) {
      setState(() {
        _isLoadingDetails = true;
        _loadError = null;
      });
      try {
        await provider.loadRecipeDetails(currentRecipe);
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadError = e.toString().replaceFirst('Exception: ', '');
          });
        }
      } finally {
        if (mounted) setState(() => _isLoadingDetails = false);
      }
    }
  }

  void _shareRecipe(Recipe recipe) {
    if (recipe.instructions.isEmpty) return;
    final scaleFactor = (recipe.servings > 0) ? (_currentServings / recipe.servings) : 1.0;
    final sb = StringBuffer();
    sb.writeln('${recipe.title}\n');
    if (recipe.description.isNotEmpty) {
      sb.writeln('${recipe.description}\n');
    }
    sb.writeln('Cook Time: ${recipe.cookTimeMinutes} min | Servings: $_currentServings | ${recipe.budgetTier}\n');
    sb.writeln('Ingredients:');
    if (recipe.recipeSpecificIngredients.isEmpty) {
      sb.writeln('- Pantry staples & seasonal fresh produce');
    } else {
      for (final ing in recipe.recipeSpecificIngredients) {
        final formattedQty = _formatQuantity(ing.quantity * scaleFactor, ing.unit);
        sb.writeln(formattedQty.isNotEmpty ? '- ${ing.name}: $formattedQty' : '- ${ing.name}');
      }
    }
    if (recipe.chefTip.isNotEmpty) {
      sb.writeln("\nChef's Note: ${recipe.chefTip}");
    }
    sb.writeln('\nMethod:');
    for (int i = 0; i < recipe.instructions.length; i++) {
      sb.writeln('${i + 1}. ${recipe.instructions[i]}');
    }
    SharePlus.instance.share(
      ShareParams(text: sb.toString(), subject: recipe.title),
    );
  }

  void _openCookingMode(Recipe recipe) {
    final scaleFactor = (recipe.servings > 0) ? (_currentServings / recipe.servings) : 1.0;
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTokens.primary(isDark);
    final sageInk = AppTokens.sageInk(isDark);
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);
    final border = AppTokens.border(isDark);
    final surface = AppTokens.surface(isDark);

    return Consumer<MealPackProvider>(
      builder: (context, provider, child) {
        final recipe = _resolveLatestRecipe(provider);
        final isSaved = provider.isRecipeSaved(recipe);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Recipe',
              style: AppTokens.display(fontSize: 19, color: textPrimary),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? primary : textSecondary,
                ),
                onPressed: () => provider.toggleSaveRecipe(recipe),
                tooltip: isSaved ? 'Unsave Recipe' : 'Save Recipe',
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: () => _shareRecipe(recipe),
                tooltip: 'Share Recipe',
              ),
              const SizedBox(width: AppTokens.spaceXs),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceLg,
              AppTokens.spaceSm,
              AppTokens.spaceLg,
              AppTokens.spaceXxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cookbook Spread Header Sheet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTokens.spaceLg),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    border: Border.all(color: border, width: 1.0),
                    boxShadow: AppTokens.paperShadow(isDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            recipe.category.isNotEmpty ? recipe.category : recipe.cuisine,
                            style: AppTokens.kicker(fontSize: 10.5, color: sageInk),
                          ),
                          Text('·', style: AppTokens.kicker(color: AppTokens.textMuted(isDark))),
                          Text(
                            '${recipe.cookTimeMinutes} mins',
                            style: AppTokens.kicker(fontSize: 10.5, color: textSecondary),
                          ),
                          Text('·', style: AppTokens.kicker(color: AppTokens.textMuted(isDark))),
                          Text(
                            recipe.budgetTier,
                            style: AppTokens.kicker(fontSize: 10.5, color: textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spaceSm + 4),
                      Text(
                        recipe.title,
                        style: AppTokens.serifItalic(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                          height: 1.18,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (recipe.description.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spaceSm + 2),
                        Text(
                          recipe.description,
                          style: AppTokens.sansBody(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (recipe.instructions.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.spaceMd + 2),
                        Divider(height: 1, color: border),
                        const SizedBox(height: AppTokens.spaceMd),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SERVINGS',
                              style: AppTokens.kicker(fontSize: 10.5, color: textSecondary),
                            ),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 2, label: Text('2P')),
                                ButtonSegment(value: 4, label: Text('4P')),
                                ButtonSegment(value: 6, label: Text('6P')),
                              ],
                              selected: {_currentServings},
                              onSelectionChanged: (newSelection) {
                                setState(() => _currentServings = newSelection.first);
                              },
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppTokens.spaceLg),

                if (_isLoadingDetails)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Writing your recipe...',
                            style: AppTokens.serifItalic(fontSize: 18, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (recipe.instructions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 36,
                            color: AppTokens.error(isDark),
                          ),
                          const SizedBox(height: AppTokens.spaceMd),
                          Text(
                            'Could Not Load Recipe Steps',
                            style: AppTokens.display(fontSize: 19, color: textPrimary),
                          ),
                          if (_loadError != null) ...[
                            const SizedBox(height: AppTokens.spaceSm),
                            Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                              style: AppTokens.sansBody(fontSize: 13, color: textSecondary),
                            ),
                          ],
                          const SizedBox(height: AppTokens.spaceMd),
                          ElevatedButton.icon(
                            onPressed: _checkAndLoadDetails,
                            icon: const Icon(Icons.refresh_rounded, size: 17),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Warm Parchment Chef's Note Margin Callout
                  if (recipe.chefTip.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppTokens.sandTint(isDark),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(
                          color: AppTokens.sandBorder(isDark),
                          width: 1.0,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(width: 3.5, color: primary),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTokens.spaceMd + 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "CHEF'S NOTE",
                                      style: AppTokens.kicker(
                                        fontSize: 10,
                                        color: sageInk,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      recipe.chefTip,
                                      style: AppTokens.sansBody(
                                        fontSize: 13.5,
                                        color: AppTokens.sandInk(isDark),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceLg),
                  ],

                  // Ingredients Checklist Sheet
                  Builder(
                    builder: (context) {
                      final scaleFactor = (recipe.servings > 0) ? (_currentServings / recipe.servings) : 1.0;
                      final scaledIngredients = recipe.recipeSpecificIngredients.map((ing) {
                        return ing.copyWith(quantity: ing.quantity * scaleFactor);
                      }).toList();
                      const basicStaples = {
                        'salt', 'pepper', 'black pepper', 'white pepper',
                        'water', 'kosher salt', 'sea salt', 'tap water',
                      };
                      final displayIngredients = scaledIngredients
                          .where((ing) => !basicStaples.contains(ing.name.toLowerCase().trim()))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Ingredients Checklist',
                                style: AppTokens.display(fontSize: 20, color: textPrimary),
                              ),
                              Text(
                                '${displayIngredients.length} items (${_currentServings}P)',
                                style: AppTokens.numeral(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceSm + 4),
                          Container(
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                              border: Border.all(color: border, width: 1.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.spaceMd,
                              vertical: AppTokens.spaceXs,
                            ),
                            child: displayIngredients.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceMd),
                                    child: Text(
                                      'Uses pantry staples and shared seasonal fresh produce.',
                                      style: AppTokens.sansBody(color: textSecondary),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (int i = 0; i < displayIngredients.length; i++) ...[
                                        Builder(
                                          builder: (context) {
                                            final ing = displayIngredients[i];
                                            final localKey = '${ing.name}_${ing.unit}';
                                            final isChecked = ing.id != null
                                                ? ing.isChecked
                                                : _localCheckedIngredients.contains(localKey);
                                            final formattedQty = _formatQuantity(ing.quantity, ing.unit);

                                            return InkWell(
                                              onTap: () {
                                                if (ing.id != null) {
                                                  provider.toggleIngredientChecked(ing, !isChecked);
                                                } else {
                                                  setState(() {
                                                    if (isChecked) {
                                                      _localCheckedIngredients.remove(localKey);
                                                    } else {
                                                      _localCheckedIngredients.add(localKey);
                                                    }
                                                  });
                                                }
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isChecked
                                                          ? Icons.check_circle_rounded
                                                          : Icons.radio_button_unchecked_rounded,
                                                      size: 19,
                                                      color: isChecked
                                                          ? primary
                                                          : (isDark
                                                              ? AppTokens.borderHoverDark
                                                              : AppTokens.borderHoverLight),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        ing.name,
                                                        style: AppTokens.sansBody(
                                                          fontSize: 14,
                                                          fontWeight: isChecked ? FontWeight.w400 : FontWeight.w500,
                                                          color: isChecked
                                                              ? AppTokens.textMuted(isDark)
                                                              : textPrimary,
                                                        ).copyWith(
                                                          decoration: isChecked
                                                              ? TextDecoration.lineThrough
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                    if (formattedQty.isNotEmpty) ...[
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        formattedQty,
                                                        style: AppTokens.numeral(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w500,
                                                          color: isChecked
                                                              ? AppTokens.textMuted(isDark)
                                                              : sageInk,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        if (i < displayIngredients.length - 1)
                                          Divider(height: 1, color: border),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: AppTokens.spaceLg),

                          // Start Cooking Mode CTA
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openCookingMode(recipe),
                              icon: const Icon(Icons.soup_kitchen_outlined, size: 19),
                              label: const Text('Start Cooking Mode'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppTokens.spaceXl),

                  // Editorial Step-by-Step Method Sheet
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Step-by-Step Instructions',
                          style: AppTokens.display(fontSize: 20, color: textPrimary),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openCookingMode(recipe),
                        icon: Icon(Icons.timer_outlined, size: 15, color: sageInk),
                        label: Text(
                          'Cooking View',
                          style: AppTokens.sansBody(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: sageInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceSm),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(color: border, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMd + 2,
                      vertical: AppTokens.spaceSm,
                    ),
                    child: Column(
                      children: [
                        for (int idx = 0; idx < recipe.instructions.length; idx++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceMd),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    (idx + 1).toString().padLeft(2, '0'),
                                    style: AppTokens.serifItalic(
                                      fontSize: 17,
                                      color: sageInk,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceSm + 4),
                                Expanded(
                                  child: Text(
                                    recipe.instructions[idx],
                                    style: AppTokens.sansBody(
                                      fontSize: 14.5,
                                      color: textPrimary,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (idx < recipe.instructions.length - 1)
                            Divider(height: 1, color: border),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
