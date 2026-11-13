import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ingredient.dart';
import '../state/meal_pack_provider.dart';
import '../utils/app_tokens.dart';

class GroceryListView extends StatelessWidget {
  const GroceryListView({super.key});

  void _shareGroceryList(BuildContext context, Map<String, List<Ingredient>> aisleGroups) {
    final sb = StringBuffer();
    sb.writeln('🛒 MARKET PROVISION LIST');
    sb.writeln('---------------------------');

    int totalItems = 0;
    aisleGroups.forEach((aisle, items) {
      if (items.isNotEmpty) {
        sb.writeln('\n$aisle:');
        for (final item in items) {
          totalItems++;
          final checked = item.isChecked ? '[x]' : '[ ]';
          final qty = item.quantity > 0
              ? '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}'
              : '';
          sb.writeln('$checked ${item.name} ($qty)');
        }
      }
    });

    sb.writeln('\nTotal items: $totalItems');

    SharePlus.instance.share(
      ShareParams(
        text: sb.toString(),
        subject: 'Weekly Grocery Shopping List',
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GROCERY BASKET',
          style: AppTokens.kicker(
            fontSize: 13,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          Consumer<MealPackProvider>(
            builder: (context, provider, child) {
              final aisleGroups = provider.getConsolidatedGroceryList();
              final hasItems = aisleGroups.values.any((list) => list.isNotEmpty);
              final checkedItems = aisleGroups.values.fold<int>(
                0,
                (sum, list) => sum + list.where((i) => i.isChecked).length,
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded),
                    onPressed: checkedItems > 0 ? () => provider.uncheckAllIngredients() : null,
                    tooltip: 'Clear Checked',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: hasItems ? () => _shareGroceryList(context, aisleGroups) : null,
                    tooltip: 'Share via WhatsApp / Notes',
                  ),
                ],
              );
            },
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
        ],
      ),
      body: Consumer<MealPackProvider>(
        builder: (context, provider, child) {
          final activePack = provider.activeMealPack;
          if (activePack == null) {
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
                        Icons.shopping_basket_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceMd),
                    Text(
                      'No Active Grocery Basket',
                      style: AppTokens.display(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceSm),
                    Text(
                      'Generate a 6-dinner meal pack in the Planner to automatically aggregate your consolidated market list with zero food waste.',
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

          final aisleGroups = provider.getConsolidatedGroceryList();
          final totalItems = aisleGroups.values.fold<int>(0, (sum, list) => sum + list.length);
          final checkedItems = aisleGroups.values.fold<int>(
            0,
            (sum, list) => sum + list.where((i) => i.isChecked).length,
          );

          return CustomScrollView(
            slivers: [
              // Summary Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceMd,
                    AppTokens.spaceSm,
                    AppTokens.spaceMd,
                    AppTokens.spaceSm,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMd),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(color: borderColor, width: 1.0),
                      boxShadow: AppTokens.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MARKET CHECKLIST',
                                    style: AppTokens.kicker(
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: AppTokens.spaceXs),
                                  Text(
                                    activePack.title,
                                    style: AppTokens.display(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.spaceSm + 4,
                                vertical: AppTokens.spaceXs + 1,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              ),
                              child: Text(
                                '$checkedItems / $totalItems done',
                                style: AppTokens.numeral(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spaceSm + 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          child: LinearProgressIndicator(
                            value: totalItems > 0 ? checkedItems / totalItems : 0.0,
                            minHeight: 6,
                            backgroundColor: mutedBg,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Aisle Categories
              ...aisleGroups.entries.where((e) => e.value.isNotEmpty).map((entry) {
                final aisleName = entry.key;
                final items = entry.value;

                IconData aisleIcon;
                Color aisleAccent;
                switch (aisleName) {
                  case 'Fresh Produce':
                    aisleIcon = Icons.eco_rounded;
                    aisleAccent = isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight;
                    break;
                  case 'Meat & Protein':
                    aisleIcon = Icons.restaurant_rounded;
                    aisleAccent = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
                    break;
                  case 'Dairy & Chilled':
                    aisleIcon = Icons.egg_rounded;
                    aisleAccent = isDark ? AppTokens.accentSunDark : AppTokens.accentSun;
                    break;
                  case 'Grains & Noodles':
                    aisleIcon = Icons.grain_rounded;
                    aisleAccent = isDark ? AppTokens.accentSkyDark : AppTokens.accentSkyLight;
                    break;
                  default:
                    aisleIcon = Icons.inventory_2_rounded;
                    aisleAccent = textSecondary;
                    break;
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMd,
                      vertical: AppTokens.spaceXs + 2,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: AppTokens.cardShadow,
                      ),
                      padding: const EdgeInsets.all(AppTokens.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: aisleAccent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(aisleIcon, size: 16, color: aisleAccent),
                              ),
                              const SizedBox(width: AppTokens.spaceSm + 2),
                              Expanded(
                                child: Text(
                                  aisleName.toUpperCase(),
                                  style: AppTokens.kicker(
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
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
                                  '${items.length} items',
                                  style: AppTokens.numeral(
                                    fontSize: 10.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceSm + 2),
                          Divider(height: 1, color: borderColor),
                          const SizedBox(height: AppTokens.spaceXs),
                          ...items.map((ing) {
                            final isChecked = ing.isChecked;
                            final isInPantry = provider.pantryItems.any(
                              (p) => ing.name.toLowerCase().contains(p),
                            );
                            final qtyStr = ing.quantity > 0
                                ? '${ing.quantity.toStringAsFixed(ing.quantity.truncateToDouble() == ing.quantity ? 0 : 1)} ${ing.unit}'
                                : '';

                            return InkWell(
                              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                              onTap: () {
                                provider.toggleConsolidatedIngredient(ing.name, !isChecked);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppTokens.spaceSm,
                                  horizontal: AppTokens.spaceXs,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                      size: 19,
                                      color: isChecked ? aisleAccent : borderColor,
                                    ),
                                    const SizedBox(width: AppTokens.spaceSm + 4),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              ing.name,
                                              style: AppTokens.sansBody(
                                                fontSize: 13.5,
                                                fontWeight: isChecked ? FontWeight.w400 : FontWeight.w500,
                                                color: isChecked
                                                    ? textSecondary.withValues(alpha: 0.5)
                                                    : textPrimary,
                                              ).copyWith(
                                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                          ),
                                          if (isInPantry) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isDark ? AppTokens.accentMintDark : AppTokens.accentMintLight).withValues(alpha: 0.18),
                                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                              ),
                                              child: Text(
                                                'IN PANTRY',
                                                style: AppTokens.kicker(
                                                  fontSize: 9,
                                                  letterSpacing: 0.8,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppTokens.accentMintDark : const Color(0xFF065F46),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      qtyStr,
                                      style: AppTokens.numeral(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isChecked
                                            ? textSecondary.withValues(alpha: 0.4)
                                            : primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
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
