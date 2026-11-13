import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../state/meal_pack_provider.dart';
import '../utils/app_tokens.dart';
import 'cooking_mode_view.dart';
import 'meal_pack_view.dart';

class SavedRecipesView extends StatefulWidget {
  const SavedRecipesView({super.key});

  @override
  State<SavedRecipesView> createState() => _SavedRecipesViewState();
}

class _SavedRecipesViewState extends State<SavedRecipesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateGroup(DateTime? date) {
    if (date == null) return 'Saved Recipes';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(itemDate).inDays;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    if (diffDays == 0) {
      return 'Saved Today • $dateStr';
    } else if (diffDays == 1) {
      return 'Saved Yesterday • $dateStr';
    } else if (diffDays < 7) {
      return 'Saved This Week • $dateStr';
    } else {
      return 'Batch from $dateStr';
    }
  }

  String _formatItemTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Map<String, List<Recipe>> _groupRecipes(List<Recipe> recipes) {
    final Map<String, List<Recipe>> groups = {};
    for (final r in recipes) {
      final key = _formatDateGroup(r.savedAt);
      groups.putIfAbsent(key, () => []).add(r);
    }
    return groups;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SAVED RECIPES',
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
          if (provider.savedRecipes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spaceXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        gradient: AppTokens.sunburstGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTokens.sunGlowShadow,
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMd),
                    Text(
                      'No Saved Recipes Yet',
                      style: AppTokens.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceSm),
                    Text(
                      'Bookmark dishes from your weekly dinner packs to curate your personal cookbook of tried-and-tested favorites.',
                      textAlign: TextAlign.center,
                      style: AppTokens.sansBody(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = provider.savedRecipes.where((r) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return r.title.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q) ||
                r.category.toLowerCase().contains(q) ||
                r.budgetTier.toLowerCase().contains(q);
          }).toList();

          final grouped = _groupRecipes(filtered);

          return CustomScrollView(
            slivers: [
              // Search & Count Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceMd,
                    AppTokens.spaceSm,
                    AppTokens.spaceMd,
                    AppTokens.spaceSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                        style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search saved recipes by title, ingredients...',
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
                      ),
                      const SizedBox(height: AppTokens.spaceSm + 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceXs),
                        child: Text(
                          '${filtered.length} SAVED DISHES ACROSS ${grouped.keys.length} SESSION${grouped.keys.length == 1 ? '' : 'S'}',
                          style: AppTokens.kicker(
                            fontSize: 10.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceXxl),
                      child: Text(
                        'No dishes matching "$_searchQuery"',
                        style: AppTokens.sansBody(fontSize: 13, color: textSecondary),
                      ),
                    ),
                  ),
                )
              else
                ...grouped.entries.map((entry) {
                  final groupTitle = entry.key;
                  final recipes = entry.value;

                  return SliverMainAxisGroup(
                    slivers: [
                      // Date Group Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.spaceMd,
                            AppTokens.spaceMd,
                            AppTokens.spaceMd,
                            AppTokens.spaceSm,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.spaceSm + 4,
                              vertical: AppTokens.spaceSm,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                              border: Border.all(color: borderColor, width: 1.0),
                              boxShadow: AppTokens.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTokens.spaceXs),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceSm + 2),
                                Expanded(
                                  child: Text(
                                    groupTitle,
                                    style: AppTokens.kicker(
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.spaceSm + 2,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mutedBg,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                  ),
                                  child: Text(
                                    '${recipes.length} dish${recipes.length == 1 ? '' : 'es'}',
                                    style: AppTokens.numeral(
                                      fontSize: 10.5,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Group Recipe Cards
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final recipe = recipes[index];
                              final timeStr = _formatItemTime(recipe.savedAt);

                              return Container(
                                margin: const EdgeInsets.only(bottom: AppTokens.spaceSm + 4),
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
                                      MaterialPageRoute(builder: (context) => MealPackView(recipe: recipe)),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
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
                                                      (recipe.category.isNotEmpty ? recipe.category : 'Main Dinner').toUpperCase(),
                                                      style: AppTokens.kicker(
                                                        fontSize: 10,
                                                        letterSpacing: 1.1,
                                                        fontWeight: FontWeight.w700,
                                                        color: primaryColor,
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
                                                      color: mutedBg,
                                                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                                    ),
                                                    child: Text(
                                                      recipe.budgetTier,
                                                      style: AppTokens.sansBody(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: AppTokens.spaceSm),
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: Icon(Icons.bookmark_rounded, color: primaryColor, size: 22),
                                              onPressed: () {
                                                provider.toggleSaveRecipe(recipe);
                                              },
                                              tooltip: 'Unsave Recipe',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppTokens.spaceSm + 2),
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
                                            if (timeStr.isNotEmpty)
                                              Text(
                                                'Saved at $timeStr',
                                                style: AppTokens.sansBody(
                                                  fontSize: 11,
                                                  color: textSecondary.withValues(alpha: 0.6),
                                                ),
                                              )
                                            else
                                              const SizedBox.shrink(),
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => CookingModeView(
                                                      recipe: recipe,
                                                      ingredients: recipe.recipeSpecificIngredients,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.soup_kitchen_rounded, size: 15),
                                              label: Text(
                                                'Cook Now',
                                                style: AppTokens.sansBody(fontSize: 11.5, fontWeight: FontWeight.w700),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppTokens.spaceSm + 6,
                                                  vertical: AppTokens.spaceXs + 2,
                                                ),
                                                visualDensity: VisualDensity.compact,
                                                side: BorderSide(color: borderColor, width: 1.0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: recipes.length,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
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
