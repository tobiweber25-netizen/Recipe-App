import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/generate_options.dart';
import '../models/meal_pack.dart';
import '../models/recipe.dart';
import '../services/app_update_manager.dart';
import '../services/meal_pack_generator.dart';
import '../state/meal_pack_provider.dart';
import '../utils/app_tokens.dart';
import '../utils/botanical_marks.dart';
import '../utils/season_helper.dart';
import 'meal_pack_view.dart';
import 'update_dialog.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _customDirectionController = TextEditingController();
  final AppUpdateManager _updateManager = AppUpdateManager();

  late final SeasonalContext _seasonalContext;
  AppUpdateInfo? _availableUpdate;
  bool _hasPromptedUpdate = false;

  // Collapsed by default so the weekly menu takes center stage immediately
  bool _isPreferencesExpanded = false;
  String _cuisineFocus = 'korean_asian';
  String _dietaryBalance = '3 vegetarian, 3 mixed protein';
  String _overlap = 'Smart ingredient reuse (share 2-3 fresh items)';
  String _budgetTier = 'standard';
  int _servings = 2;

  static const List<Map<String, String>> _cuisineOptions = [
    {'id': 'korean_asian', 'title': 'Korean & Pan-Asian'},
    {'id': 'claypot_ferments', 'title': 'Donabe, Claypot & Ferments'},
    {'id': 'mediterranean_european', 'title': 'Mediterranean & European'},
    {'id': 'latin_american', 'title': 'Latin & Mexican'},
    {'id': 'south_asian', 'title': 'South Asian & Indian'},
    {'id': 'middle_eastern', 'title': 'Middle Eastern & Levantine'},
    {'id': 'balanced', 'title': 'World Tour (All Cuisines)'},
    {'id': 'south_african', 'title': 'South African Heritage'},
    {'id': 'adventurous_bold', 'title': 'Adventurous & Bold'},
    {'id': 'gourmet_dining', 'title': "Chef's Tasting Table"},
    {'id': 'quick', 'title': 'Fast Weeknight'},
  ];

  @override
  void initState() {
    super.initState();
    _seasonalContext = SeasonHelper.getSeasonalContext(DateTime.now());
    _checkUpdateInBackground();
  }

  @override
  void dispose() {
    _customDirectionController.dispose();
    _updateManager.dispose();
    super.dispose();
  }

  Future<void> _checkUpdateInBackground() async {
    try {
      final info = await _updateManager.checkForUpdate();
      if (!info.hasUpdate) {
        await _updateManager.cleanupCachedApks();
        return;
      }
      if (!mounted) return;
      setState(() => _availableUpdate = info);
      if (!_hasPromptedUpdate && info.apkDownloadUrl != null) {
        _hasPromptedUpdate = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            UpdateDialog.show(context, initialInfo: info);
          }
        });
      }
    } catch (_) {
      // Silent background check: ignore offline or transient errors
    }
  }

  String _formatSeasonGreeting(String seasonName) {
    final shortSeason = seasonName.replaceFirst('South African ', '').trim();
    return '$shortSeason in Johannesburg';
  }

  String _titleCase(String input) {
    return input
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _cuisineLabel(String id) {
    final match = _cuisineOptions.firstWhere(
      (opt) => opt['id'] == id,
      orElse: () => {'title': id},
    );
    return match['title'] ?? id;
  }

  String _budgetLabel(String id) {
    switch (id) {
      case 'budget':
        return 'Budget Saver';
      case 'gourmet':
        return 'Gourmet';
      default:
        return 'Balanced';
    }
  }

  void _toggleHarvestKeyword(String keyword) {
    final current = _customDirectionController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final idx = current.indexWhere((item) => item.toLowerCase() == keyword.toLowerCase());
    if (idx != -1) {
      current.removeAt(idx);
    } else {
      current.add(keyword);
    }
    setState(() {
      _customDirectionController.text = current.join(', ');
    });
  }

  bool _isHarvestSelected(String keyword) {
    return _customDirectionController.text
        .toLowerCase()
        .contains(keyword.toLowerCase());
  }

  List<String> _extractSharedProduce(MealPack pack) {
    if (pack.sharedFreshIngredients.isNotEmpty) {
      return pack.sharedFreshIngredients
          .map((i) => i.name.trim())
          .where((n) => n.isNotEmpty)
          .take(5)
          .toList();
    }
    final counts = <String, int>{};
    final displayNames = <String, String>{};
    for (final recipe in pack.recipes) {
      final seenInRecipe = <String>{};
      for (final ing in recipe.recipeSpecificIngredients) {
        if (ing.aisle != 'Fresh Produce') continue;
        final key = ing.name.toLowerCase().trim();
        if (key.isEmpty || seenInRecipe.contains(key)) continue;
        seenInRecipe.add(key);
        counts[key] = (counts[key] ?? 0) + 1;
        displayNames[key] = ing.name.trim();
      }
    }
    final shared = counts.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return shared.take(5).map((e) => displayNames[e.key]!).toList();
  }

  InputDecoration _fieldDecoration(bool isDark, {String? hintText, Widget? suffixIcon}) {
    final border = AppTokens.border(isDark);
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTokens.sansBody(fontSize: 13, color: AppTokens.textMuted(isDark)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        borderSide: BorderSide(color: AppTokens.primary(isDark), width: 1.4),
      ),
      filled: true,
      fillColor: AppTokens.surfaceMuted(isDark),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSeasonalHeader(BuildContext context, bool isDark) {
    final ctx = _seasonalContext;
    final primary = AppTokens.primary(isDark);
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOHANNESBURG  ·  ${ctx.monthName.toUpperCase()}',
                    style: AppTokens.kicker(
                      fontSize: 10.5,
                      color: AppTokens.sageInk(isDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatSeasonGreeting(ctx.seasonName),
                    style: AppTokens.display(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      height: 1.12,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: BotanicalSprig(
                size: 46,
                color: primary.withValues(alpha: isDark ? 0.85 : 0.72),
                strokeWidth: 1.25,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceSm + 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ctx.produceKeywords.take(5).map((item) {
              final selected = _isHarvestSelected(item);
              return Padding(
                padding: const EdgeInsets.only(right: AppTokens.spaceSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  onTap: () => _toggleHarvestKeyword(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTokens.primaryContainer(isDark)
                          : AppTokens.surfaceWarm(isDark),
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: selected
                            ? primary.withValues(alpha: 0.65)
                            : AppTokens.border(isDark),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      _titleCase(item),
                      style: AppTokens.sansBody(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? AppTokens.sageInk(isDark) : textSecondary,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPantryRibbon(BuildContext context, MealPackProvider provider, bool isDark) {
    final items = provider.pantryItems;
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      onTap: () => setState(() => _isPreferencesExpanded = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: 12),
        decoration: BoxDecoration(
          color: AppTokens.surfaceWarm(isDark),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: AppTokens.sandBorder(isDark), width: 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PANTRY & FERMENTS ON HAND',
                    style: AppTokens.kicker(
                      fontSize: 9.5,
                      color: AppTokens.sandInk(isDark),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items.isEmpty
                        ? 'Add staples like kimchi, miso, or rice'
                        : items.map(_titleCase).join('  ·  '),
                    style: items.isEmpty
                        ? AppTokens.sansBody(fontSize: 12.5, color: textSecondary)
                        : AppTokens.display(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: textPrimary,
                            height: 1.3,
                            letterSpacing: -0.1,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm),
            TextButton(
              onPressed: () => _showAddPantryDialog(context, provider),
              style: TextButton.styleFrom(
                foregroundColor: AppTokens.sageInk(isDark),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: Text(
                '+ Add',
                style: AppTokens.sansBody(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.sageInk(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineFocusSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUISINE FOCUS',
          style: AppTokens.kicker(fontSize: 10, color: AppTokens.textSecondary(isDark)),
        ),
        const SizedBox(height: AppTokens.spaceSm),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _cuisineFocus,
          dropdownColor: AppTokens.surface(isDark),
          decoration: _fieldDecoration(isDark),
          items: _cuisineOptions.map((opt) {
            return DropdownMenuItem(
              value: opt['id'],
              child: Text(
                opt['title']!,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.sansBody(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.textPrimary(isDark),
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
        backgroundColor: AppTokens.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: AppTokens.border(isDark), width: 1.0),
        ),
        title: Text(
          'Add Pantry Staple',
          style: AppTokens.display(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: AppTokens.textPrimary(isDark),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTokens.sansBody(fontSize: 14, color: AppTokens.textPrimary(isDark)),
          decoration: _fieldDecoration(
            isDark,
            hintText: 'e.g. doenjang, sourdough, black vinegar',
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
            child: Text(
              'Cancel',
              style: AppTokens.sansBody(color: AppTokens.textSecondary(isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addPantryItem(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
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
      'rice',
    ];

    final primary = AppTokens.primary(isDark);
    final sageInk = AppTokens.sageInk(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'KITCHEN PANTRY & FERMENTS',
                style: AppTokens.kicker(fontSize: 10, color: AppTokens.textSecondary(isDark)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddPantryDialog(context, provider),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Custom', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: sageInk,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceXs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: quickStaples.map((staple) {
              final inPantry = provider.pantryItems.contains(staple);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: inPantry,
                  showCheckmark: false,
                  label: Text(
                    staple,
                    style: AppTokens.sansBody(
                      fontSize: 12,
                      fontWeight: inPantry ? FontWeight.w600 : FontWeight.w400,
                      color: inPantry ? sageInk : AppTokens.textSecondary(isDark),
                    ),
                  ),
                  selectedColor: AppTokens.primaryContainer(isDark),
                  backgroundColor: AppTokens.surfaceMuted(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    side: BorderSide(
                      color: inPantry ? primary : AppTokens.border(isDark),
                      width: 1.0,
                    ),
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
        if (provider.pantryItems.isEmpty)
          Text(
            'Tap staples above or add custom items to prioritize dishes using what you already have.',
            style: AppTokens.sansBody(fontSize: 12, color: AppTokens.textMuted(isDark)),
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
                    color: AppTokens.textPrimary(isDark),
                  ),
                ),
                backgroundColor: AppTokens.surfaceWarm(isDark),
                deleteIconColor: AppTokens.textSecondary(isDark),
                onDeleted: () => provider.deletePantryItem(item),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  side: BorderSide(color: AppTokens.border(isDark), width: 1.0),
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBudgetTierSelector(bool isDark) {
    final options = [
      {'id': 'budget', 'title': 'Budget Saver', 'hint': 'Everyday'},
      {'id': 'standard', 'title': 'Balanced', 'hint': 'Standard'},
      {'id': 'gourmet', 'title': 'Gourmet', 'hint': 'Elevated'},
    ];

    final primary = AppTokens.primary(isDark);
    final onPrimary = AppTokens.onPrimary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BUDGET WINDOW',
              style: AppTokens.kicker(fontSize: 10, color: AppTokens.textSecondary(isDark)),
            ),
            if (_budgetTier == 'budget')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTokens.sandTint(isDark),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(color: AppTokens.sandBorder(isDark)),
                ),
                child: Text(
                  'END-OF-MONTH',
                  style: AppTokens.kicker(
                    fontSize: 9,
                    color: AppTokens.sandInk(isDark),
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
                onTap: () => setState(() => _budgetTier = opt['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : AppTokens.surfaceMuted(isDark),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                      color: isSelected ? primary : AppTokens.border(isDark),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opt['title']!,
                        style: AppTokens.sansBody(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? onPrimary : AppTokens.textPrimary(isDark),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt['hint']!,
                        style: AppTokens.sansBody(
                          fontSize: 10.5,
                          color: isSelected
                              ? onPrimary.withValues(alpha: 0.8)
                              : AppTokens.textMuted(isDark),
                          height: 1.1,
                        ),
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

  Widget _buildServingsSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PORTIONS PER MEAL',
          style: AppTokens.kicker(fontSize: 10, color: AppTokens.textSecondary(isDark)),
        ),
        const SizedBox(height: AppTokens.spaceSm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 2,
                label: Text('2 Servings'),
                icon: Icon(Icons.people_outline, size: 16),
              ),
              ButtonSegment(
                value: 4,
                label: Text('4 Servings'),
                icon: Icon(Icons.groups_outlined, size: 16),
              ),
            ],
            selected: {_servings},
            onSelectionChanged: (newSelection) {
              setState(() => _servings = newSelection.first);
            },
          ),
        ),
      ],
    );
  }

  void _showPackHistorySheet(BuildContext context, MealPackProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer<MealPackProvider>(
          builder: (context, prov, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final packs = prov.savedMealPacks;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Past Weekly Menus',
                          style: AppTokens.display(
                            fontSize: 21,
                            color: AppTokens.textPrimary(isDark),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceXs),
                    Text(
                      'Switch back to an earlier menu or remove packs you no longer need.',
                      style: AppTokens.sansBody(
                        fontSize: 13,
                        color: AppTokens.textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMd),
                    if (packs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXl),
                        child: Center(
                          child: Text(
                            'No previous meal packs yet.',
                            style: AppTokens.sansBody(color: AppTokens.textSecondary(isDark)),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: packs.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppTokens.border(isDark),
                          ),
                          itemBuilder: (context, index) {
                            final pack = packs[index];
                            final isActive = prov.activeMealPack?.id == pack.id;
                            final dateStr = '${pack.createdAt.day}/${pack.createdAt.month}/${pack.createdAt.year}';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pack.title,
                                      style: AppTokens.display(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTokens.textPrimary(isDark),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTokens.primaryContainer(isDark),
                                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: AppTokens.kicker(
                                          fontSize: 9,
                                          color: AppTokens.sageInk(isDark),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${pack.season} · $dateStr · ${pack.recipes.length} dinners',
                                style: AppTokens.sansBody(
                                  fontSize: 12,
                                  color: AppTokens.textSecondary(isDark),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      child: const Text('Use', style: TextStyle(fontSize: 12)),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 19),
                                    color: AppTokens.error(isDark),
                                    tooltip: 'Delete Pack',
                                    onPressed: () {
                                      if (pack.id != null) {
                                        prov.deleteMealPack(pack.id!);
                                      }
                                    },
                                  ),
                                ],
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
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Swap This Dinner',
                      style: AppTokens.display(
                        fontSize: 20,
                        color: AppTokens.textPrimary(isDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Choose a replacement for "${recipe.title}":',
                  style: AppTokens.sansBody(
                    fontSize: 13,
                    color: AppTokens.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMd),
                if (alternatives.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceLg),
                    child: Center(
                      child: Text(
                        'No alternative recipes found.',
                        style: AppTokens.sansBody(color: AppTokens.textSecondary(isDark)),
                      ),
                    ),
                  )
                else
                  ...alternatives.map((alt) {
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          title: Text(
                            alt.title,
                            style: AppTokens.display(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w500,
                              color: AppTokens.textPrimary(isDark),
                            ),
                          ),
                          subtitle: Text(
                            '${alt.cookTimeMinutes} min  ·  ${alt.cuisine}  ·  ${alt.budgetTier}',
                            style: AppTokens.sansBody(
                              fontSize: 12,
                              color: AppTokens.textSecondary(isDark),
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
                        Divider(height: 1, color: AppTokens.border(isDark)),
                      ],
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditorialMenuItem(
    BuildContext context,
    Recipe recipe,
    int index,
    MealPackProvider provider,
    bool isDark,
  ) {
    final isSaved = provider.isRecipeSaved(recipe);
    final indexLabel = (index + 1).toString().padLeft(2, '0');
    final sageInk = AppTokens.sageInk(isDark);
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MealPackView(recipe: recipe)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMd + 2,
          vertical: AppTokens.spaceMd + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  indexLabel,
                  style: AppTokens.serifItalic(
                    fontSize: 18,
                    color: AppTokens.textMuted(isDark),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.category.isNotEmpty ? recipe.category : recipe.cuisine,
                          style: AppTokens.kicker(
                            fontSize: 10,
                            color: sageInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSm),
                      InkResponse(
                        radius: 20,
                        onTap: () => provider.toggleSaveRecipe(recipe),
                        child: Icon(
                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 20,
                          color: isSaved ? AppTokens.primary(isDark) : AppTokens.textMuted(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recipe.title,
                    style: AppTokens.display(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      height: 1.24,
                      letterSpacing: -0.3,
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _metaTag(
                        label: '${recipe.cookTimeMinutes} min',
                        bg: AppTokens.surfaceMuted(isDark),
                        fg: textSecondary,
                        isNumeral: true,
                      ),
                      _metaTag(
                        label: recipe.budgetTier,
                        bg: AppTokens.surfaceWarm(isDark),
                        fg: AppTokens.sandInk(isDark),
                      ),
                      if (recipe.isAdventurous)
                        _metaTag(
                          label: 'Adventurous',
                          bg: AppTokens.primaryContainer(isDark),
                          fg: sageInk,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppTokens.spaceSm,
                    runSpacing: AppTokens.spaceXs,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showSwapMealDialog(context, recipe, provider),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                        label: const Text('Swap Dish'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: textSecondary,
                          side: BorderSide(color: AppTokens.border(isDark)),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          textStyle: AppTokens.sansBody(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Recipe',
                            style: AppTokens.sansBody(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: sageInk,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: sageInk),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaTag({
    required String label,
    required Color bg,
    required Color fg,
    bool isNumeral = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Text(
        label,
        style: isNumeral
            ? AppTokens.numeral(fontSize: 11, fontWeight: FontWeight.w500, color: fg)
            : AppTokens.sansBody(fontSize: 11, fontWeight: FontWeight.w500, color: fg, height: 1.1),
      ),
    );
  }

  Widget _buildRecipesList(BuildContext context, MealPackProvider provider, bool isDark) {
    final activePack = provider.activeMealPack;

    if (activePack == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTokens.surface(isDark),
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(color: AppTokens.border(isDark), width: 1.0),
          boxShadow: AppTokens.paperShadow(isDark),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLg, vertical: AppTokens.spaceXl),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppTokens.surfaceWarm(isDark),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: BotanicalSprig(size: 38, color: AppTokens.primary(isDark)),
              ),
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(
              'Your weekly table awaits',
              style: AppTokens.display(
                fontSize: 21,
                color: AppTokens.textPrimary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              'Tap "Curate 6 Dinners" above to assemble a seasonal menu with smart fresh-ingredient overlap.',
              textAlign: TextAlign.center,
              style: AppTokens.sansBody(
                fontSize: 13.5,
                color: AppTokens.textSecondary(isDark),
              ),
            ),
          ],
        ),
      );
    }

    final sharedProduce = _extractSharedProduce(activePack);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Shared Fresh Ingredients highlight strip
        if (sharedProduce.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd, vertical: 10),
            margin: const EdgeInsets.only(bottom: AppTokens.spaceMd),
            decoration: BoxDecoration(
              color: AppTokens.primaryContainer(isDark),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: AppTokens.primary(isDark).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 15,
                  color: AppTokens.sageInk(isDark),
                ),
                const SizedBox(width: AppTokens.spaceSm),
                Expanded(
                  child: Text(
                    'Shared fresh produce: ${sharedProduce.join(' · ')}',
                    style: AppTokens.sansBody(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.sageInk(isDark),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Unified Porcelain Editorial Menu Sheet
        Container(
          decoration: BoxDecoration(
            color: AppTokens.surface(isDark),
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: AppTokens.border(isDark), width: 1.0),
            boxShadow: AppTokens.paperShadow(isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Menu Sheet Masthead
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceMd + 2,
                  AppTokens.spaceMd + 2,
                  AppTokens.spaceMd + 2,
                  AppTokens.spaceMd,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceWarm(isDark).withValues(alpha: 0.55),
                  border: Border(
                    bottom: BorderSide(color: AppTokens.border(isDark), width: 1.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${activePack.season.toUpperCase()}  ·  ${activePack.recipes.length} DINNERS',
                      style: AppTokens.kicker(
                        fontSize: 9.5,
                        color: AppTokens.sageInk(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activePack.title,
                      style: AppTokens.serifItalic(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),

              // Numbered Menu Rows separated by fine hairlines
              for (int i = 0; i < activePack.recipes.length; i++) ...[
                _buildEditorialMenuItem(context, activePack.recipes[i], i, provider, isDark),
                if (i < activePack.recipes.length - 1)
                  Divider(
                    height: 1,
                    indent: AppTokens.spaceMd + 2,
                    endIndent: AppTokens.spaceMd + 2,
                    color: AppTokens.border(isDark),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generatePack(
    BuildContext context,
    MealPackProvider provider, {
    required bool useAiStudio,
  }) async {
    final options = GenerateOptions(
      dietaryBalance: _dietaryBalance,
      overlap: _overlap,
      budgetTier: _budgetTier,
      servings: _servings,
      customDirection: _customDirectionController.text,
      cuisineFocus: _cuisineFocus,
    );

    if (useAiStudio) {
      await provider.generateNewMealPack(options);
    } else {
      await provider.generateInstantMealPack(options);
    }

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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);
    final primary = AppTokens.primary(isDark);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.spaceLg,
        title: Text(
          'Weekly Recipes',
          style: AppTokens.display(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 21),
            onPressed: () => _showPackHistorySheet(context, context.read<MealPackProvider>()),
            tooltip: 'Past Weekly Menus',
          ),
          PopupMenuButton<String>(
            color: AppTokens.surface(isDark),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              side: BorderSide(color: AppTokens.border(isDark)),
            ),
            tooltip: 'Kitchen Options',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.more_horiz_rounded, size: 22),
                if (_availableUpdate?.hasUpdate == true)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onSelected: (value) {
              if (value == 'theme') {
                context.read<MealPackProvider>().toggleThemeMode(currentlyDark: isDark);
              } else if (value == 'updates') {
                UpdateDialog.show(context, autoCheck: true);
              } else if (value == 'reload') {
                context.read<MealPackProvider>().loadSavedMealPacks();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                      size: 18,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isDark ? 'Daylight Mode' : 'Evening Mode',
                      style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'updates',
                child: Row(
                  children: [
                    Icon(Icons.system_update_rounded, size: 18, color: textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      _availableUpdate?.hasUpdate == true ? 'Update Available' : 'Check for Updates',
                      style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      'Reload Saved Packs',
                      style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.spaceSm),
        ],
      ),
      body: Consumer<MealPackProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.savedMealPacks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5, color: primary),
                  const SizedBox(height: AppTokens.spaceMd),
                  Text(
                    'Setting the table...',
                    style: AppTokens.serifItalic(fontSize: 16, color: textSecondary),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                color: primary,
                backgroundColor: AppTokens.surface(isDark),
                onRefresh: () => provider.loadSavedMealPacks(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Seasonal Morning Greeting & Interactive Harvest Chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceLg,
                          AppTokens.spaceSm,
                          AppTokens.spaceLg,
                          AppTokens.spaceMd,
                        ),
                        child: _buildSeasonalHeader(context, isDark),
                      ),
                    ),

                    // Calm Pantry Ribbon
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceLg,
                          0,
                          AppTokens.spaceLg,
                          AppTokens.spaceMd,
                        ),
                        child: _buildPantryRibbon(context, provider, isDark),
                      ),
                    ),

                    // Primary Curate Action Row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceLg,
                          0,
                          AppTokens.spaceLg,
                          AppTokens.spaceMd,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.restaurant_menu_rounded, size: 17),
                                label: const Text('Curate 6 Dinners'),
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _generatePack(context, provider, useAiStudio: false),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceSm),
                            Tooltip(
                              message: 'Custom AI Curated Pack',
                              child: OutlinedButton(
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _generatePack(context, provider, useAiStudio: true),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppTokens.surface(isDark),
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                ),
                                child: Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                  color: AppTokens.sageInk(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Compact Preferences Brief Drawer (collapsed by default)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceLg,
                          0,
                          AppTokens.spaceLg,
                          AppTokens.spaceLg,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTokens.surface(isDark),
                            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                            border: Border.all(color: AppTokens.border(isDark), width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                                onTap: () {
                                  setState(() => _isPreferencesExpanded = !_isPreferencesExpanded);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.spaceMd,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 18,
                                        color: AppTokens.sageInk(isDark),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Meal & Budget Preferences',
                                              style: AppTokens.sansBody(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                                height: 1.2,
                                              ),
                                            ),
                                            if (!_isPreferencesExpanded) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                '$_servings Servings · ${_budgetLabel(_budgetTier)} · ${_cuisineLabel(_cuisineFocus)}',
                                                style: AppTokens.sansBody(
                                                  fontSize: 11.5,
                                                  color: textSecondary,
                                                  height: 1.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        _isPreferencesExpanded
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isPreferencesExpanded)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppTokens.spaceMd,
                                    0,
                                    AppTokens.spaceMd,
                                    AppTokens.spaceMd,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Divider(height: 1, color: AppTokens.border(isDark)),
                                      const SizedBox(height: AppTokens.spaceMd),
                                      _buildCuisineFocusSelector(isDark),
                                      const SizedBox(height: AppTokens.spaceMd),
                                      _buildBudgetTierSelector(isDark),
                                      const SizedBox(height: AppTokens.spaceMd),
                                      _buildServingsSelector(isDark),
                                      const SizedBox(height: AppTokens.spaceMd),

                                      Text(
                                        'DIETARY BALANCE',
                                        style: AppTokens.kicker(fontSize: 10, color: textSecondary),
                                      ),
                                      const SizedBox(height: AppTokens.spaceSm),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _dietaryBalance,
                                        dropdownColor: AppTokens.surface(isDark),
                                        decoration: _fieldDecoration(isDark),
                                        items: [
                                          DropdownMenuItem(
                                            value: '3 vegetarian, 3 mixed protein',
                                            child: Text('Balanced (3 Veg, 3 Protein)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Mostly vegetarian (5 veg, 1 mixed protein)',
                                            child: Text('Mostly Vegetarian (5 Veg, 1 Meat)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'All vegetarian',
                                            child: Text('All Vegetarian (6 Dinners)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Mostly meat (1 veg, 5 mixed protein)',
                                            child: Text('Mostly Meat & Protein (1 Veg, 5 Meat)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'All meat and protein (6 protein-focused meals)',
                                            child: Text('All Meat & Protein (6 Dinners)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'High protein fitness meals (lean chicken, beef, fish, eggs, tofu)',
                                            child: Text('High Protein (Fitness Focus)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'No dietary restrictions',
                                            child: Text('Any / Surprise Me', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setState(() => _dietaryBalance = val);
                                        },
                                      ),
                                      const SizedBox(height: AppTokens.spaceMd),

                                      Text(
                                        'INGREDIENT SHARING',
                                        style: AppTokens.kicker(fontSize: 10, color: textSecondary),
                                      ),
                                      const SizedBox(height: AppTokens.spaceSm),
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: _overlap,
                                        dropdownColor: AppTokens.surface(isDark),
                                        decoration: _fieldDecoration(isDark),
                                        items: [
                                          DropdownMenuItem(
                                            value: 'Smart ingredient reuse (share 2-3 fresh items)',
                                            child: Text('Smart Sharing (Low Waste & Variety)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: '>=80% overlap in fresh ingredients',
                                            child: Text('High Overlap (Batch Cooking)', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'No overlap required, maximum recipe variety',
                                            child: Text('Maximum Variety', overflow: TextOverflow.ellipsis, style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary)),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) setState(() => _overlap = val);
                                        },
                                      ),
                                      const SizedBox(height: AppTokens.spaceMd),

                                      Text(
                                        'CRAVING OR STYLE NOTE',
                                        style: AppTokens.kicker(fontSize: 10, color: textSecondary),
                                      ),
                                      const SizedBox(height: AppTokens.spaceSm),
                                      TextField(
                                        controller: _customDirectionController,
                                        maxLines: 1,
                                        style: AppTokens.sansBody(fontSize: 13.5, color: textPrimary),
                                        decoration: _fieldDecoration(
                                          isDark,
                                          hintText: 'e.g. Quick 20-min meals, cozy stews, sheet pan',
                                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                            valueListenable: _customDirectionController,
                                            builder: (context, value, child) {
                                              return value.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.clear, size: 17),
                                                      onPressed: () => setState(() => _customDirectionController.clear()),
                                                    )
                                                  : const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppTokens.spaceMd),
                                      _buildPantrySection(context, provider, isDark),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Active Weekly Menu Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: Text(
                                    'This Week\'s Table',
                                    style: AppTokens.display(
                                      fontSize: 22,
                                      color: textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (provider.activeMealPack != null)
                                  Text(
                                    '${provider.activeMealPack!.recipes.length} DINNERS',
                                    style: AppTokens.kicker(
                                      fontSize: 10,
                                      color: AppTokens.sageInk(isDark),
                                    ),
                                  ),
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
              ),

              // Calm Loading Overlay
              if (provider.isLoading)
                Container(
                  color: AppTokens.bg(isDark).withValues(alpha: 0.78),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(AppTokens.spaceLg),
                      decoration: BoxDecoration(
                        color: AppTokens.surface(isDark),
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(color: AppTokens.border(isDark)),
                        boxShadow: AppTokens.paperShadow(isDark),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceXl,
                        vertical: AppTokens.spaceLg + 4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spaceMd),
                          Text(
                            'Curating your weekly menu',
                            style: AppTokens.serifItalic(
                              fontSize: 17,
                              color: textPrimary,
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
