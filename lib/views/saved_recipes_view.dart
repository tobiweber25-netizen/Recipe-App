import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../state/meal_pack_provider.dart';
import '../utils/app_tokens.dart';
import '../utils/botanical_marks.dart';
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
      return 'Saved Today · $dateStr';
    } else if (diffDays == 1) {
      return 'Saved Yesterday · $dateStr';
    } else if (diffDays > 1 && diffDays < 7) {
      return 'Saved This Week · $dateStr';
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
    final primary = AppTokens.primary(isDark);
    final sageInk = AppTokens.sageInk(isDark);
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);
    final border = AppTokens.border(isDark);
    final surface = AppTokens.surface(isDark);
    final mutedBg = AppTokens.surfaceMuted(isDark);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.spaceLg,
        title: Text(
          'Saved Recipes',
          style: AppTokens.display(fontSize: 21, color: textPrimary),
        ),
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
                      decoration: BoxDecoration(
                        color: AppTokens.surfaceWarm(isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: BotanicalSprig(size: 40, color: primary),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMd),
                    Text(
                      'No Saved Recipes Yet',
                      style: AppTokens.display(fontSize: 22, color: textPrimary),
                    ),
                    const SizedBox(height: AppTokens.spaceSm),
                    Text(
                      'Bookmark dishes from your weekly menu or library to keep your personal cookbook here.',
                      textAlign: TextAlign.center,
                      style: AppTokens.sansBody(fontSize: 13.5, color: textSecondary),
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
                r.cuisine.toLowerCase().contains(q) ||
                r.budgetTier.toLowerCase().contains(q) ||
                r.recipeSpecificIngredients.any((i) => i.name.toLowerCase().contains(q));
          }).toList();

          final grouped = _groupRecipes(filtered);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceLg,
                    AppTokens.spaceSm,
                    AppTokens.spaceLg,
                    AppTokens.spaceSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: AppTokens.sansBody(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search saved recipes by title or ingredient...',
                          hintStyle: AppTokens.sansBody(
                            fontSize: 13.5,
                            color: AppTokens.textMuted(isDark),
                          ),
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
                      ),
                      const SizedBox(height: AppTokens.spaceMd),
                      Text(
                        '${filtered.length} SAVED DISH${filtered.length == 1 ? '' : 'ES'}',
                        style: AppTokens.kicker(fontSize: 10, color: textSecondary),
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
                        style: AppTokens.sansBody(fontSize: 13.5, color: textSecondary),
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
                      // Editorial Hairline Group Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.spaceLg,
                            AppTokens.spaceMd,
                            AppTokens.spaceLg,
                            AppTokens.spaceSm,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      groupTitle,
                                      style: AppTokens.kicker(
                                        fontSize: 10.5,
                                        color: sageInk,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${recipes.length} dish${recipes.length == 1 ? '' : 'es'}',
                                    style: AppTokens.numeral(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppTokens.textMuted(isDark),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Divider(height: 1, color: border),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLg),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final recipe = recipes[index];
                              final timeStr = _formatItemTime(recipe.savedAt);

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
                                          children: [
                                            Expanded(
                                              child: Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    (recipe.category.isNotEmpty ? recipe.category : 'Main Dinner').toUpperCase(),
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
                                                  Text('·', style: AppTokens.kicker(color: AppTokens.textMuted(isDark))),
                                                  Text(
                                                    recipe.budgetTier,
                                                    style: AppTokens.sansBody(
                                                      fontSize: 11,
                                                      color: textSecondary,
                                                      height: 1.1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            InkResponse(
                                              radius: 20,
                                              onTap: () => provider.toggleSaveRecipe(recipe),
                                              child: Icon(Icons.bookmark_rounded, color: primary, size: 20),
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (timeStr.isNotEmpty)
                                              Text(
                                                'Saved at $timeStr',
                                                style: AppTokens.sansBody(
                                                  fontSize: 11.5,
                                                  color: AppTokens.textMuted(isDark),
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
                                              icon: Icon(
                                                Icons.soup_kitchen_outlined,
                                                size: 15,
                                                color: sageInk,
                                              ),
                                              label: Text(
                                                'Cook Now',
                                                style: AppTokens.sansBody(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: sageInk,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: AppTokens.primaryContainer(isDark),
                                                side: BorderSide(color: primary.withValues(alpha: 0.35)),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 13,
                                                  vertical: 7,
                                                ),
                                                visualDensity: VisualDensity.compact,
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
