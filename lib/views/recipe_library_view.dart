import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/curated_recipe_library.dart';
import '../models/recipe.dart';
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

  final List<String> _filters = [
    'All',
    '🇮🇹 Italian',
    '🇲🇽 Latin American',
    '🇮🇳 Indian',
    '🇫🇷 French',
    '🫒 Mediterranean',
    '🇱🇧 Middle Eastern',
    '🇰🇷 Korean',
    '🥢 Pan-Asian',
    '🇿🇦 South African',
    '🇺🇸 Americas & Caribbean',
    '🪙 Budget Saver',
    '⚖️ Balanced',
    '👑 Gourmet',
    '🔥 Adventurous',
    '⏱ Under 25m',
    '🥗 Vegetarian',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isVeg(Recipe r) {
    const meat = [
      'chicken', 'beef', 'pork', 'lamb', 'mutton', 'hake', 'fish', 'salmon',
      'trout', 'clam', 'squid', 'shrimp', 'prawn', 'bacon', 'sausage',
      'duck', 'veal', 'shank', 'mussel', 'calamari', 'cod', 'halibut', 'scallop'
    ];
    for (final ing in r.recipeSpecificIngredients) {
      final n = ing.name.toLowerCase();
      if (meat.any((k) => n.contains(k))) return false;
    }
    return true;
  }

  List<Recipe> _getFilteredRecipes() {
    return CuratedRecipeLibrary.recipes.where((r) {
      // 1. Search Query Filter
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

      // 2. Chip Filter
      switch (_selectedFilter) {
        case '🇮🇹 Italian':
          return r.cuisine == 'Italian';
        case '🇲🇽 Latin American':
          return r.cuisine == 'Mexican' || r.cuisine == 'Latin American';
        case '🇮🇳 Indian':
          return r.cuisine == 'Indian';
        case '🇫🇷 French':
          return r.cuisine == 'French' || r.cuisine == 'European';
        case '🫒 Mediterranean':
          return r.cuisine == 'Mediterranean' || r.cuisine == 'Greek' || r.cuisine == 'Spanish';
        case '🇱🇧 Middle Eastern':
          return r.cuisine == 'Middle Eastern' || r.cuisine == 'Moroccan' || r.cuisine == 'Egyptian' || r.cuisine == 'African';
        case '🇰🇷 Korean':
          return r.cuisine == 'Korean';
        case '🥢 Pan-Asian':
          return r.cuisine == 'Pan-Asian' || r.cuisine == 'Korean' || r.cuisine == 'Thai' || r.cuisine == 'Chinese' || r.cuisine == 'Japanese' || r.cuisine == 'Vietnamese';
        case '🇿🇦 South African':
          return r.cuisine == 'South African';
        case '🇺🇸 Americas & Caribbean':
          return r.cuisine == 'American' || r.cuisine == 'Caribbean';
        case '🪙 Budget Saver':
          return r.budgetTier == 'Budget Saver';
        case '⚖️ Balanced':
          return r.budgetTier == 'Balanced' || r.budgetTier == 'Standard' || r.budgetTier == 'Everyday Value';
        case '👑 Gourmet':
          return r.budgetTier == 'Gourmet';
        case '🔥 Adventurous':
          return r.isAdventurous;
        case '⏱ Under 25m':
          return r.cookTimeMinutes <= 25;
        case '🥗 Vegetarian':
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
        const SnackBar(content: Text('No active meal pack. Generate a pack in Planner first.')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
    final textPrimary = isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight;
    final textSecondary = isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight;
    final borderColor = isDark ? AppTokens.borderDark : AppTokens.borderLight;
    final modalBg = isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMd + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                Text(
                  'SWAP INTO ACTIVE PACK',
                  style: AppTokens.kicker(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceXs),
                Text(
                  'Choose which dinner to replace with "${recipe.title}":',
                  style: AppTokens.sansBody(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: activePack.recipes.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                    itemBuilder: (c, idx) {
                      final currentR = activePack.recipes[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceXs,
                          vertical: AppTokens.spaceXs,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${idx + 1}',
                            style: AppTokens.numeral(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        title: Text(
                          currentR.title,
                          style: AppTokens.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${currentR.cookTimeMinutes} min • ${currentR.cuisine}',
                          style: AppTokens.sansBody(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        trailing: Icon(Icons.swap_horiz_rounded, color: primaryColor, size: 20),
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
    final primaryColor = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
    final textPrimary = isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight;
    final textSecondary = isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight;
    final borderColor = isDark ? AppTokens.borderDark : AppTokens.borderLight;
    final cardBg = isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight;
    final mutedBg = isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight;
    final filtered = _getFilteredRecipes();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RECIPE ARCHIVE',
          style: AppTokens.kicker(
            fontSize: 13,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<MealPackProvider>().themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () {
              context.read<MealPackProvider>().toggleThemeMode();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Consumer<MealPackProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceMd,
                    AppTokens.spaceSm,
                    AppTokens.spaceMd,
                    AppTokens.spaceSm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search dishes, gochujang, chicken, garlic...',
                      hintStyle: AppTokens.sansBody(fontSize: 13, color: textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16, color: textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceMd,
                        vertical: AppTokens.spaceSm + 2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                      filled: true,
                      fillColor: mutedBg,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMd,
                    vertical: AppTokens.spaceXs,
                  ),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTokens.spaceSm),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: AppTokens.sansBody(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          checkmarkColor: Colors.white,
                          backgroundColor: cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            side: BorderSide(
                              color: isSelected ? primaryColor : borderColor,
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.spaceSm + 2,
                            vertical: 3,
                          ),
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Header Count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceMd,
                    AppTokens.spaceMd,
                    AppTokens.spaceMd,
                    AppTokens.spaceXs,
                  ),
                  child: Text(
                    '${filtered.length} CURATED DISHES',
                    style: AppTokens.kicker(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),

              // Recipe Cards Grid/List
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceXxl),
                    child: Center(
                      child: Text(
                        'No dishes match your culinary filters.',
                        style: AppTokens.sansBody(fontSize: 14, color: textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMd,
                    vertical: AppTokens.spaceXs,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final recipe = filtered[idx];
                        final isSaved = provider.savedRecipes.any((r) => r.title == recipe.title);

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTokens.spaceMd),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                            border: Border.all(color: borderColor, width: 1.0),
                            boxShadow: AppTokens.cardShadow,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MealPackView(recipe: recipe),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppTokens.spaceMd),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badges Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: AppTokens.spaceXs + 2,
                                          runSpacing: AppTokens.spaceXs + 2,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppTokens.spaceSm,
                                                vertical: AppTokens.spaceXs,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                              ),
                                              child: Text(
                                                recipe.cuisine.toUpperCase(),
                                                style: AppTokens.kicker(
                                                  fontSize: 10,
                                                  letterSpacing: 1.1,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                            if (recipe.isAdventurous)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppTokens.spaceSm,
                                                  vertical: AppTokens.spaceXs,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTokens.accentSun.withValues(alpha: isDark ? 0.25 : 0.15),
                                                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                                ),
                                                child: Text(
                                                  '🔥 ADVENTUROUS',
                                                  style: AppTokens.kicker(
                                                    fontSize: 10,
                                                    letterSpacing: 1.1,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppTokens.accentSunDark : AppTokens.accentSun,
                                                  ),
                                                ),
                                              ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppTokens.spaceSm,
                                                vertical: AppTokens.spaceXs,
                                              ),
                                              decoration: BoxDecoration(
                                                color: mutedBg,
                                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.timer_outlined, size: 12, color: textSecondary),
                                                  const SizedBox(width: AppTokens.spaceXs),
                                                  Text(
                                                    '${recipe.cookTimeMinutes} min',
                                                    style: AppTokens.numeral(
                                                      fontSize: 11,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppTokens.spaceSm,
                                                vertical: AppTokens.spaceXs,
                                              ),
                                              decoration: BoxDecoration(
                                                color: recipe.budgetTier == 'Gourmet'
                                                    ? AppTokens.accentSun.withValues(alpha: isDark ? 0.25 : 0.15)
                                                    : recipe.budgetTier == 'Budget Saver'
                                                        ? (isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight)
                                                        : mutedBg,
                                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                              ),
                                              child: Text(
                                                recipe.budgetTier == 'Gourmet'
                                                    ? '👑 ${recipe.budgetTier} (\$\$\$)'
                                                    : recipe.budgetTier == 'Budget Saver'
                                                        ? '🍋 ${recipe.budgetTier} (\$)'
                                                        : '🥗 ${recipe.budgetTier} (\$\$)',
                                                style: AppTokens.sansBody(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: recipe.budgetTier == 'Gourmet'
                                                      ? (isDark ? AppTokens.accentSunDark : AppTokens.accentSun)
                                                      : recipe.budgetTier == 'Budget Saver'
                                                          ? primaryColor
                                                          : textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                          color: isSaved ? primaryColor : (isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight),
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          provider.toggleSaveRecipe(recipe);
                                        },
                                        tooltip: 'Save Recipe',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTokens.spaceSm + 2),

                                  // Recipe Title
                                  Text(
                                    recipe.title,
                                    style: AppTokens.display(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  if (recipe.description.isNotEmpty) ...[
                                    const SizedBox(height: AppTokens.spaceXs),
                                    Text(
                                      recipe.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTokens.sansBody(
                                        fontSize: 13,
                                        color: textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: AppTokens.spaceMd),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${recipe.recipeSpecificIngredients.length} ingredients',
                                        style: AppTokens.sansBody(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => _showAddToPackDialog(context, recipe, provider),
                                            icon: const Icon(Icons.swap_horiz, size: 14),
                                            label: Text(
                                              'Swap to Pack',
                                              style: AppTokens.sansBody(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppTokens.spaceSm + 2,
                                                vertical: AppTokens.spaceXs,
                                              ),
                                              side: BorderSide(color: borderColor),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppTokens.spaceSm),
                                          Text(
                                            'VIEW',
                                            style: AppTokens.kicker(
                                              fontSize: 11,
                                              letterSpacing: 1.1,
                                              fontWeight: FontWeight.w700,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
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
