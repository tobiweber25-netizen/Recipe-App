import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/meal_pack_provider.dart';
import '../models/generate_options.dart';
import 'meal_pack_view.dart';
import '../models/recipe.dart';
import '../utils/season_helper.dart';
import '../services/meal_pack_generator.dart';
import '../utils/app_tokens.dart';
import 'update_dialog.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _customDirectionController = TextEditingController();
  
  bool _isPreferencesExpanded = true;
  String _cuisineFocus = 'korean_asian';
  String _dietaryBalance = '3 vegetarian, 3 mixed protein';
  String _overlap = 'Smart ingredient reuse (share 2-3 fresh items)';
  String _budgetTier = 'standard'; // 'budget', 'standard', 'gourmet'
  int _servings = 2;

  Widget _buildSeasonalHeader(BuildContext context, ThemeData theme, bool isDark) {
    final ctx = SeasonHelper.getSeasonalContext(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: AppTokens.spaceSm + 4),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
          width: 1.0,
        ),
        boxShadow: AppTokens.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceSm),
            decoration: const BoxDecoration(
              gradient: AppTokens.mintGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppTokens.spaceSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ctx.seasonName.toUpperCase()} • ${ctx.monthName.toUpperCase()}',
                  style: AppTokens.kicker(
                    fontSize: 10.5,
                    color: isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fresh Harvest: ${ctx.produceKeywords.take(4).join(', ')}',
                  style: AppTokens.sansBody(
                    fontSize: 12.5,
                    color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customDirectionController.dispose();
    super.dispose();
  }

  Widget _buildCuisineFocusSelector(ThemeData theme, bool isDark) {
    final options = [
      {'id': 'korean_asian', 'title': '🇰🇷 Korean & Pan-Asian'},
      {'id': 'claypot_ferments', 'title': '🍲 Donabe, Claypot & Ferments'},
      {'id': 'mediterranean_european', 'title': '🫒 Mediterranean & European'},
      {'id': 'latin_american', 'title': '🌮 Latin & Mexican'},
      {'id': 'south_asian', 'title': '🍛 South Asian & Indian'},
      {'id': 'middle_eastern', 'title': '🧆 Middle Eastern & Levantine'},
      {'id': 'balanced', 'title': '🌍 World Tour (All Cuisines)'},
      {'id': 'south_african', 'title': '🇿🇦 SA Heritage'},
      {'id': 'adventurous_bold', 'title': '🔥 Adventurous & Bold'},
      {'id': 'gourmet_dining', 'title': '👑 Chef\'s Tasting Table'},
      {'id': 'quick', 'title': '⚡ Fast Weeknight'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisine & Adventure Focus',
          style: AppTokens.kicker(
            fontSize: 11,
            color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTokens.spaceSm),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _cuisineFocus,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              borderSide: BorderSide(color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight, width: 1.5),
            ),
            filled: true,
            fillColor: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
          ),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt['id'] as String,
              child: Text(
                opt['title'] as String,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.sansBody(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _cuisineFocus = val);
          },
        ),
      ],
    );
  }

  void _showAddPantryDialog(BuildContext context, MealPackProvider provider) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight, width: 1.0),
        ),
        title: Text(
          'Add Pantry / Ferment Staple',
          style: AppTokens.display(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. doenjang, sourdough, black vinegar',
            hintStyle: AppTokens.sansBody(
              fontSize: 13,
              color: isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
            ),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              provider.addPantryItem(val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addPantryItem(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPantrySection(BuildContext context, MealPackProvider provider, bool isDark) {
    const quickStaples = [
      'kimchi',
      'gochujang',
      'miso',
      'sauerkraut',
      'pickled jalapeños',
      'eggs',
      'coconut milk',
      'tofu',
      'spinach',
      'rice'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Kitchen Pantry & Ferments on Hand',
                style: AppTokens.kicker(
                  fontSize: 11,
                  color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppTokens.spaceXs),
            TextButton.icon(
              onPressed: () => _showAddPantryDialog(context, provider),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('+ Add Item', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceXs),

        // Quick-Add Staples Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: quickStaples.map((staple) {
              final inPantry = provider.pantryItems.contains(staple);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: inPantry,
                  label: Text(
                    staple,
                    style: AppTokens.sansBody(
                      fontSize: 12,
                      fontWeight: inPantry ? FontWeight.w600 : FontWeight.w400,
                      color: inPantry
                          ? (isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight)
                          : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                    ),
                  ),
                  selectedColor: (isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight).withValues(alpha: 0.25),
                  backgroundColor: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
                  side: BorderSide(
                    color: inPantry
                        ? (isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight)
                        : (isDark ? AppTokens.borderDark : AppTokens.borderLight),
                    width: 1.0,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (selected) {
                    if (selected) {
                      provider.addPantryItem(staple);
                    } else {
                      provider.deletePantryItem(staple);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppTokens.spaceSm),

        // Current Pantry Items
        if (provider.pantryItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No pantry items recorded. Tap quick staples above or add custom items to boost recipes that use what you have.',
              style: AppTokens.sansBody(
                fontSize: 12,
                color: isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight,
              ),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: provider.pantryItems.map((item) {
              return InputChip(
                label: Text(
                  item,
                  style: AppTokens.sansBody(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                  ),
                ),
                backgroundColor: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
                deleteIconColor: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                onDeleted: () => provider.deletePantryItem(item),
                side: BorderSide(
                  color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                  width: 1.0,
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showPackHistorySheet(BuildContext context, MealPackProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) {
        return Consumer<MealPackProvider>(
          builder: (context, prov, child) {
            final modalTheme = Theme.of(context);
            final isDark = modalTheme.brightness == Brightness.dark;
            final packs = prov.savedMealPacks;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.all(AppTokens.spaceMd),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTokens.spaceSm - 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_rounded,
                                color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceSm + 2),
                            Text(
                              'Meal Pack History',
                              style: AppTokens.display(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceSm),
                    Text(
                      'Switch between previously generated weekly menus or remove old packs:',
                      style: AppTokens.sansBody(
                        fontSize: 12.5,
                        color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMd),
                    if (packs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXl),
                        child: Center(
                          child: Text(
                            'No saved meal packs in history.',
                            style: AppTokens.sansBody(
                              color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                            ),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: packs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceSm),
                          itemBuilder: (context, index) {
                            final pack = packs[index];
                            final isActive = prov.activeMealPack?.id == pack.id;
                            final dateStr = '${pack.createdAt.day}/${pack.createdAt.month}/${pack.createdAt.year}';

                            return Container(
                              decoration: BoxDecoration(
                                color: isActive
                                    ? (isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight)
                                    : (isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight),
                                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(
                                  color: isActive
                                      ? (isDark ? AppTokens.primaryDark : AppTokens.primaryLight)
                                      : (isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                  width: isActive ? 1.5 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pack.title,
                                        style: AppTokens.display(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${pack.season} • ${pack.month} • Created $dateStr • ${pack.recipes.length} Dinners',
                                  style: AppTokens.sansBody(
                                    fontSize: 11.5,
                                    color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isActive)
                                      FilledButton.tonal(
                                        onPressed: () {
                                          prov.setActiveMealPack(pack);
                                          Navigator.pop(ctx);
                                        },
                                        style: FilledButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                        child: const Text('Select', style: TextStyle(fontSize: 12)),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      color: isDark ? AppTokens.accentSunDark : const Color(0xFFDC2626),
                                      tooltip: 'Delete Pack',
                                      onPressed: () {
                                        if (pack.id != null) {
                                          prov.deleteMealPack(pack.id!);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
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
      },
    );
  }

  void _showSwapMealDialog(BuildContext context, Recipe recipe, MealPackProvider provider) {
    final activePack = provider.activeMealPack;
    if (activePack == null) return;

    final options = GenerateOptions(
      dietaryBalance: _dietaryBalance,
      overlap: _overlap,
      budgetTier: _budgetTier,
      servings: _servings,
      customDirection: _customDirectionController.text,
      cuisineFocus: _cuisineFocus,
    );

    final alternatives = MealPackGenerator.instance.findAlternativeRecipes(recipe, activePack, options);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) {
        final modalTheme = Theme.of(ctx);
        final isDark = modalTheme.brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Swap This Meal',
                      style: AppTokens.display(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Replacing "${recipe.title}" with a matching chef recipe:',
                  style: AppTokens.sansBody(
                    fontSize: 12.5,
                    color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSm + 4),
                if (alternatives.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceLg),
                    child: Center(
                      child: Text(
                        'No alternative recipes found.',
                        style: AppTokens.sansBody(
                          color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                        ),
                      ),
                    ),
                  )
                else
                  ...alternatives.map((alt) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTokens.spaceSm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        side: BorderSide(
                          color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                          width: 1.0,
                        ),
                      ),
                      elevation: 0,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(AppTokens.spaceSm),
                          decoration: BoxDecoration(
                            color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          alt.title,
                          style: AppTokens.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                          ),
                        ),
                        subtitle: Text(
                          '${alt.cookTimeMinutes} min • ${alt.cuisine} • ${alt.budgetTier}',
                          style: AppTokens.sansBody(
                            fontSize: 12,
                            color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                          ),
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            if (recipe.id != null) {
                              await provider.swapRecipeInActivePack(recipe.id!, alt);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Swapped to "${alt.title}"')),
                                );
                              }
                            }
                          },
                          child: const Text('Select', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetTierSelector(ThemeData theme, bool isDark) {
    final options = [
      {'id': 'budget', 'title': 'Budget Saver', 'icon': '🍋'},
      {'id': 'standard', 'title': 'Balanced', 'icon': '🥗'},
      {'id': 'gourmet', 'title': 'Gourmet', 'icon': '✨'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Window',
              style: AppTokens.kicker(
                fontSize: 11,
                color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
              ),
            ),
            if (_budgetTier == 'budget')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTokens.accentSun.withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                child: Text(
                  'End-of-Month Mode',
                  style: AppTokens.kicker(
                    fontSize: 9.5,
                    color: isDark ? AppTokens.accentSunDark : AppTokens.accentSun,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceSm),
        Row(
          children: options.map((opt) {
            final isSelected = _budgetTier == opt['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _budgetTier = opt['id'] as String);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTokens.sunburstGradient : null,
                    color: isSelected
                        ? null
                        : (isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? AppTokens.borderDark : AppTokens.borderLight),
                      width: 1.0,
                    ),
                    boxShadow: isSelected ? AppTokens.sunGlowShadow : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opt['icon'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opt['title'] as String,
                        style: AppTokens.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServingsSelector(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portions per Meal',
          style: AppTokens.kicker(
            fontSize: 11,
            color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTokens.spaceSm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 2,
                label: Text('2 Servings (Couple)'),
                icon: Icon(Icons.people_outline, size: 16),
              ),
              ButtonSegment(
                value: 4,
                label: Text('4 Servings (Family)'),
                icon: Icon(Icons.groups_outlined, size: 16),
              ),
            ],
            selected: {_servings},
            onSelectionChanged: (newSelection) {
              setState(() {
                _servings = newSelection.first;
              });
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.comfortable,
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, MealPackProvider provider, bool isDark) {
    final isSaved = provider.savedRecipes.any((r) => r.id == recipe.id || (r.title == recipe.title && r.mealPackId == recipe.mealPackId));

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
          width: 1.0,
        ),
        boxShadow: AppTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
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
                // Top Meta Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        recipe.category.isNotEmpty ? recipe.category : recipe.cuisine,
                        style: AppTokens.kicker(
                          fontSize: 11,
                          color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        size: 22,
                        color: isSaved
                            ? (isDark ? AppTokens.primaryDark : AppTokens.primaryLight)
                            : (isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight),
                      ),
                      onPressed: () {
                        provider.toggleSaveRecipe(recipe);
                      },
                      tooltip: isSaved ? 'Unsave Recipe' : 'Save Recipe',
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceSm),
                
                // Recipe Title (Modern Geometric Headline)
                Text(
                  recipe.title,
                  style: AppTokens.display(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                    height: 1.25,
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
                      color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: AppTokens.spaceSm + 2),

                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      child: Text(
                        recipe.budgetTier,
                        style: AppTokens.kicker(
                          fontSize: 9.5,
                          color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.cookTimeMinutes} min',
                            style: AppTokens.numeral(
                              fontSize: 10.5,
                              color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recipe.isAdventurous)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTokens.accentSun.withValues(alpha: isDark ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Text(
                          '🔥 Adventurous',
                          style: AppTokens.kicker(
                            fontSize: 9.5,
                            color: isDark ? AppTokens.accentSunDark : AppTokens.accentSun,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppTokens.spaceMd),
                
                // Bottom Action Bar (Responsive Wrap)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppTokens.spaceSm,
                  runSpacing: AppTokens.spaceXs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showSwapMealDialog(context, recipe, provider),
                      icon: const Icon(Icons.swap_horiz, size: 14),
                      label: const Text('Swap Dish'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                        side: BorderSide(
                          color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                          width: 1.0,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: AppTokens.kicker(fontSize: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusPill)),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Recipe',
                          style: AppTokens.sansBody(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipesList(BuildContext context, MealPackProvider provider, bool isDark) {
    final activePack = provider.activeMealPack;
    
    if (activePack == null) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(
            color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
            width: 1.0,
          ),
          boxShadow: AppTokens.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLg, vertical: AppTokens.spaceXl),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMd),
              decoration: BoxDecoration(
                color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: 32,
                color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
              ),
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(
              'Weekly Dinners Ready To Curate',
              style: AppTokens.display(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              'Tap "Generate 6 Dinners" to curate a balanced weekly menu with smart seasonal ingredient sharing.',
              textAlign: TextAlign.center,
              style: AppTokens.sansBody(
                fontSize: 13,
                color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pack Summary Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: 12),
          margin: const EdgeInsets.only(bottom: AppTokens.spaceMd),
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
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceSm),
                decoration: const BoxDecoration(
                  gradient: AppTokens.goldenNectarGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              ),
              const SizedBox(width: AppTokens.spaceSm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activePack.title,
                      style: AppTokens.display(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activePack.season.toUpperCase()} • 6 COMPLETE DINNERS',
                      style: AppTokens.kicker(
                        fontSize: 10,
                        color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        ...activePack.recipes.map((recipe) => _buildRecipeCard(context, recipe, provider, isDark)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weekly Planner',
          style: AppTokens.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.system_update_rounded),
            onPressed: () => UpdateDialog.show(context),
            tooltip: 'Check for Updates',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _showPackHistorySheet(context, context.read<MealPackProvider>()),
            tooltip: 'Meal Pack History',
          ),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MealPackProvider>().loadSavedMealPacks();
            },
            tooltip: 'Reload Packs',
          )
        ],
      ),
      body: Consumer<MealPackProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.savedMealPacks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your kitchen dashboard...',
                    style: AppTokens.sansBody(
                      color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Seasonal Inspiration Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                      child: _buildSeasonalHeader(context, theme, isDark),
                    ),
                  ),

                  // Generation Action Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: AppTokens.spaceSm),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTokens.sunburstGradient,
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                boxShadow: AppTokens.sunGlowShadow,
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.bolt, size: 18),
                                label: const Text('⚡ INSTANT GENERATE (6 MEALS)'),
                                onPressed: provider.isLoading
                                    ? null
                                    : () async {
                                        await provider.generateInstantMealPack(
                                          GenerateOptions(
                                            dietaryBalance: _dietaryBalance,
                                            overlap: _overlap,
                                            budgetTier: _budgetTier,
                                            servings: _servings,
                                            customDirection: _customDirectionController.text,
                                            cuisineFocus: _cuisineFocus,
                                          ),
                                        );
                                        if (!context.mounted) return;
                                        if (provider.errorMessage != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(provider.errorMessage!),
                                              backgroundColor: Theme.of(context).colorScheme.error,
                                            ),
                                          );
                                          provider.clearError();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSm),
                          Tooltip(
                            message: 'AI Studio Prompt Customizer',
                            child: OutlinedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      await provider.generateNewMealPack(
                                        GenerateOptions(
                                          dietaryBalance: _dietaryBalance,
                                          overlap: _overlap,
                                          budgetTier: _budgetTier,
                                          servings: _servings,
                                          customDirection: _customDirectionController.text,
                                          cuisineFocus: _cuisineFocus,
                                        ),
                                      );
                                      if (!context.mounted) return;
                                      if (provider.errorMessage != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(provider.errorMessage!),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                        );
                                        provider.clearError();
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                                  width: 1.0,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome_outlined,
                                size: 18,
                                color: isDark ? AppTokens.accentSunDark : AppTokens.accentSun,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Meal Pack Preferences Accordion
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: AppTokens.spaceXs),
                      child: Container(
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
                            InkWell(
                              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                              onTap: () {
                                setState(() {
                                  _isPreferencesExpanded = !_isPreferencesExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppTokens.spaceSm - 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.spaceSm + 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Meal & Budget Preferences',
                                            style: AppTokens.display(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                                            ),
                                          ),
                                          if (!_isPreferencesExpanded)
                                            Text(
                                              '$_servings Servings • ${_budgetTier.toUpperCase()} • ${_cuisineFocus.replaceAll('_', ' ').toUpperCase()}',
                                              style: AppTokens.kicker(
                                                fontSize: 10,
                                                color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _isPreferencesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isPreferencesExpanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(AppTokens.spaceMd, 0, AppTokens.spaceMd, AppTokens.spaceMd),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Cuisine & Adventure Focus
                                    _buildCuisineFocusSelector(theme, isDark),
                                    const SizedBox(height: AppTokens.spaceMd),

                                    // 2. Budget Tier Selector
                                    _buildBudgetTierSelector(theme, isDark),
                                    const SizedBox(height: AppTokens.spaceMd),

                                    // 3. Servings Selector
                                    _buildServingsSelector(theme, isDark),
                                    const SizedBox(height: AppTokens.spaceMd),
                                    
                                    // 4. Dietary Balance Dropdown
                                    Text(
                                      'Dietary Balance',
                                      style: AppTokens.kicker(
                                        fontSize: 11,
                                        color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.spaceSm),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _dietaryBalance,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight, width: 1.5),
                                        ),
                                        filled: true,
                                        fillColor: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: '3 vegetarian, 3 mixed protein',
                                          child: Text('Balanced (3 Veg, 3 Protein/Meat)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Mostly vegetarian (5 veg, 1 mixed protein)',
                                          child: Text('Mostly Vegetarian (5 Veg, 1 Meat)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'All vegetarian',
                                          child: Text('All Vegetarian (6 Veg Dinners)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Mostly meat (1 veg, 5 mixed protein)',
                                          child: Text('Mostly Meat/Protein (1 Veg, 5 Meat)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'All meat and protein (6 protein-focused meals)',
                                          child: Text('All Meat & Protein (6 Dinners)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'High protein fitness meals (lean chicken, beef, fish, eggs, tofu)',
                                          child: Text('High Protein (Fitness Focus)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'No dietary restrictions',
                                          child: Text('Any / Surprise Me', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _dietaryBalance = val);
                                      },
                                    ),
                                    const SizedBox(height: AppTokens.spaceMd),

                                    // 5. Ingredient Overlap
                                    Text(
                                      'Ingredient Sharing Strategy',
                                      style: AppTokens.kicker(
                                        fontSize: 11,
                                        color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.spaceSm),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _overlap,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight, width: 1.5),
                                        ),
                                        filled: true,
                                        fillColor: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'Smart ingredient reuse (share 2-3 fresh items)',
                                          child: Text('Smart Sharing (Low Waste & Variety)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: '>=80% overlap in fresh ingredients',
                                          child: Text('High Overlap (Batch Cooking & Strict Budget)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'No overlap required, maximum recipe variety',
                                          child: Text('Maximum Variety (Distinct Cuisine Every Day)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5)),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _overlap = val);
                                      },
                                    ),
                                    
                                    const SizedBox(height: AppTokens.spaceMd),

                                    // 6. Custom Craving / Style Direction
                                    Text(
                                      'Custom Craving / Style Direction',
                                      style: AppTokens.kicker(
                                        fontSize: 11,
                                        color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.spaceSm),
                                    TextField(
                                      controller: _customDirectionController,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Quick 20-minute meals, Mediterranean, cozy stews, sheet pan',
                                        hintStyle: AppTokens.sansBody(
                                          fontSize: 13,
                                          color: isDark ? AppTokens.textMutedDark : AppTokens.textMutedLight,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.borderDark : AppTokens.borderLight),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                          borderSide: BorderSide(color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight, width: 1.5),
                                        ),
                                        filled: true,
                                        fillColor: isDark ? AppTokens.surfaceMutedDark : AppTokens.surfaceMutedLight,
                                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                          valueListenable: _customDirectionController,
                                          builder: (context, value, child) {
                                            return value.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.clear, size: 18),
                                                    onPressed: () => _customDirectionController.clear(),
                                                  )
                                                : const SizedBox.shrink();
                                          },
                                        ),
                                      ),
                                      style: AppTokens.sansBody(
                                        fontSize: 14,
                                        color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.spaceMd),

                                    // 7. Kitchen Pantry & Ferments on Hand
                                    _buildPantrySection(context, provider, isDark),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Active Meal Pack Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: AppTokens.spaceSm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Weekly Tasting Menu',
                                  style: AppTokens.display(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (provider.activeMealPack != null) ...[
                                const SizedBox(width: AppTokens.spaceSm),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                  ),
                                  child: Text(
                                    '${provider.activeMealPack!.recipes.length} Dinners',
                                    style: AppTokens.kicker(
                                      fontSize: 10.5,
                                      color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMd),
                          _buildRecipesList(context, provider, isDark),
                          const SizedBox(height: AppTokens.spaceXxl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Loading Overlay
              if (provider.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(AppTokens.spaceLg),
                      decoration: BoxDecoration(
                        color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        boxShadow: AppTokens.cardShadow,
                      ),
                      padding: const EdgeInsets.all(AppTokens.spaceXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceMd),
                          Text(
                            'Designing Your Weekly Dinners',
                            style: AppTokens.display(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
