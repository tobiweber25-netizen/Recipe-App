import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/curated_recipe_library.dart';
import '../models/recipe.dart';
import '../services/meal_pack_generator.dart';
import '../state/meal_pack_provider.dart';
import '../utils/app_tokens.dart';
import 'meal_pack_view.dart';

class RecipeLibraryView extends StatefulWidget {
  const RecipeLibraryView({super.key});

  @override
  State<RecipeLibraryView> createState() => _RecipeLibraryViewState();
}

class _RecipeLibraryViewState extends State<RecipeLibraryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Italian',
    'Latin American',
    'Indian',
    'French',
    'Mediterranean',
    'Middle Eastern',
    'Korean',
    'Pan-Asian',
    'South African',
    'Americas & Caribbean',
    'Budget Saver',
    'Balanced',
    'Gourmet',
    'Adventurous',
    'Under 25m',
    'Vegetarian',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isVeg(Recipe r) => MealPackGenerator.isVegetarian(r);

  List<Recipe> _getFilteredRecipes() {
    return CuratedRecipeLibrary.recipes.where((r) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = r.title.toLowerCase().contains(q);
        final matchesDesc = r.description.toLowerCase().contains(q);
        final matchesIng = r.recipeSpecificIngredients.any((i) => i.name.toLowerCase().contains(q));
        final matchesCuisine = r.cuisine.toLowerCase().contains(q);

        if (!matchesTitle && !matchesDesc && !matchesIng && !matchesCuisine) {
          return false;
        }
      }

      switch (_selectedFilter) {
        case 'Italian':
          return r.cuisine == 'Italian';
        case 'Latin American':
          return r.cuisine == 'Mexican' || r.cuisine == 'Latin American';
        case 'Indian':
          return r.cuisine == 'Indian';
        case 'French':
          return r.cuisine == 'French' || r.cuisine == 'European';
        case 'Mediterranean':
          return r.cuisine == 'Mediterranean' || r.cuisine == 'Greek' || r.cuisine == 'Spanish';
        case 'Middle Eastern':
          return r.cuisine == 'Middle Eastern' || r.cuisine == 'Moroccan' || r.cuisine == 'Egyptian' || r.cuisine == 'African';
        case 'Korean':
          return r.cuisine == 'Korean';
        case 'Pan-Asian':
          return r.cuisine == 'Pan-Asian' || r.cuisine == 'Korean' || r.cuisine == 'Thai' || r.cuisine == 'Chinese' || r.cuisine == 'Japanese' || r.cuisine == 'Vietnamese';
        case 'South African':
          return r.cuisine == 'South African';
        case 'Americas & Caribbean':
          return r.cuisine == 'American' || r.cuisine == 'Caribbean';
        case 'Budget Saver':
          return r.budgetTier == 'Budget Saver';
        case 'Balanced':
          return r.budgetTier == 'Balanced' || r.budgetTier == 'Standard' || r.budgetTier == 'Everyday Value';
        case 'Gourmet':
          return r.budgetTier == 'Gourmet';
        case 'Adventurous':
          return r.isAdventurous;
        case 'Under 25m':
          return r.cookTimeMinutes <= 25;
        case 'Vegetarian':
          return _isVeg(r);
        case 'All':
        default:
          return true;
      }
    }).toList();
  }

  void _showAddToPackDialog(BuildContext context, Recipe recipe, MealPackProvider provider) {
    final activePack = provider.activeMealPack;
    if (activePack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active meal pack. Curate a weekly menu in Planner first.')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sageInk = AppTokens.sageInk(isDark);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceLg,
              AppTokens.spaceMd,
              AppTokens.spaceLg,
              AppTokens.spaceLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTokens.border(isDark),
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                Text(
                  'Swap Into This Week',
                  style: AppTokens.display(fontSize: 20, color: AppTokens.textPrimary(isDark)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a dinner to replace with "${recipe.title}":',
                  style: AppTokens.sansBody(fontSize: 13, color: AppTokens.textSecondary(isDark)),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activePack.recipes.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppTokens.border(isDark)),
                    itemBuilder: (c, idx) {
                      final currentR = activePack.recipes[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        leading: Text(
                          (idx + 1).toString().padLeft(2, '0'),
                          style: AppTokens.serifItalic(fontSize: 17, color: sageInk),
                        ),
                        title: Text(
                          currentR.title,
                          style: AppTokens.display(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.textPrimary(isDark),
                          ),
                        ),
                        subtitle: Text(
                          '${currentR.cookTimeMinutes} min  ·  ${currentR.cuisine}',
                          style: AppTokens.sansBody(
                            fontSize: 12,
                            color: AppTokens.textSecondary(isDark),
                          ),
                        ),
                        trailing: Icon(Icons.swap_horiz_rounded, color: sageInk, size: 20),
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (currentR.id != null) {
                            await provider.swapRecipeInActivePack(currentR.id!, recipe);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Replaced "${currentR.title}" with "${recipe.title}"')),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTokens.primary(isDark);
    final onPrimary = AppTokens.onPrimary(isDark);
    final sageInk = AppTokens.sageInk(isDark);
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);
    final border = AppTokens.border(isDark);
    final surface = AppTokens.surface(isDark);
    final mutedBg = AppTokens.surfaceMuted(isDark);
    final filtered = _getFilteredRecipes();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.spaceLg,
        title: Text(
          'Recipe Library',
          style: AppTokens.display(fontSize: 21, color: textPrimary),
        ),
      ),
      body: Consumer<MealPackProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              // Calm Dove-Grey Search Field
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceLg,
                    AppTokens.spaceSm,
                    AppTokens.spaceLg,
                    AppTokens.spaceSm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTokens.sansBody(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search dishes, gochujang, chicken, garlic...',
                      hintStyle: AppTokens.sansBody(fontSize: 13.5, color: AppTokens.textMuted(isDark)),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 17, color: textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceMd,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: BorderSide(color: primary, width: 1.4),
                      ),
                      filled: true,
                      fillColor: mutedBg,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),

              // Zero-Emoji Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceLg,
                    vertical: AppTokens.spaceXs,
                  ),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTokens.spaceSm),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: AppTokens.sansBody(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? onPrimary : textSecondary,
                              height: 1.1,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primary,
                          backgroundColor: surface,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            side: BorderSide(
                              color: isSelected ? primary : border,
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Dish Count Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceLg,
                    AppTokens.spaceMd,
                    AppTokens.spaceLg,
                    AppTokens.spaceSm,
                  ),
                  child: Text(
                    '${filtered.length} CURATED DISHES',
                    style: AppTokens.kicker(fontSize: 10, color: textSecondary),
                  ),
                ),
              ),

              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceXxl),
                    child: Center(
                      child: Text(
                        'No dishes match your search.',
                        style: AppTokens.sansBody(fontSize: 14, color: textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final recipe = filtered[idx];
                        final isSaved = provider.isRecipeSaved(recipe);
                        final isGourmet = recipe.budgetTier == 'Gourmet';

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTokens.spaceMd),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                            border: Border.all(color: border, width: 1.0),
                            boxShadow: AppTokens.paperShadow(isDark),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MealPackView(recipe: recipe)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppTokens.spaceMd + 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              recipe.cuisine.toUpperCase(),
                                              style: AppTokens.kicker(fontSize: 10, color: sageInk),
                                            ),
                                            Text('·', style: AppTokens.kicker(color: AppTokens.textMuted(isDark))),
                                            Text(
                                              '${recipe.cookTimeMinutes} min',
                                              style: AppTokens.numeral(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: textSecondary,
                                              ),
                                            ),
                                            if (recipe.isAdventurous) ...[
                                              Text('·', style: AppTokens.kicker(color: AppTokens.textMuted(isDark))),
                                              Text(
                                                'ADVENTUROUS',
                                                style: AppTokens.kicker(
                                                  fontSize: 9.5,
                                                  color: AppTokens.sandInk(isDark),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      InkResponse(
                                        radius: 20,
                                        onTap: () => provider.toggleSaveRecipe(recipe),
                                        child: Icon(
                                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                          color: isSaved ? primary : AppTokens.textMuted(isDark),
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    recipe.title,
                                    style: AppTokens.display(
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                      height: 1.24,
                                    ),
                                  ),
                                  if (recipe.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      recipe.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTokens.sansBody(
                                        fontSize: 13,
                                        color: textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isGourmet
                                              ? AppTokens.sandTint(isDark)
                                              : mutedBg,
                                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                        ),
                                        child: Text(
                                          '${recipe.budgetTier} · ${recipe.recipeSpecificIngredients.length} items',
                                          style: AppTokens.sansBody(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isGourmet
                                                ? AppTokens.sandInk(isDark)
                                                : textSecondary,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _showAddToPackDialog(context, recipe, provider),
                                            icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                                            label: const Text('Swap to Pack'),
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              foregroundColor: textSecondary,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              textStyle: AppTokens.sansBody(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 16, color: sageInk),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTokens.spaceXxl),
              ),
            ],
          );
        },
      ),
    );
  }
}
