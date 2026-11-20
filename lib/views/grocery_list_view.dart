import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ingredient.dart';
import '../state/meal_pack_provider.dart';
import '../utils/app_tokens.dart';
import '../utils/botanical_marks.dart';

class GroceryListView extends StatelessWidget {
  const GroceryListView({super.key});

  void _shareGroceryList(BuildContext context, Map<String, List<Ingredient>> aisleGroups) {
    final sb = StringBuffer();
    sb.writeln('WEEKLY GROCERY LIST');
    sb.writeln('---------------------------');

    int totalItems = 0;
    aisleGroups.forEach((aisle, items) {
      if (items.isNotEmpty) {
        sb.writeln('\n$aisle:');
        for (final item in items) {
          totalItems++;
          final checked = item.isChecked ? '[x]' : '[ ]';
          final qty = item.quantity > 0
              ? '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit}'.trim()
              : '';
          sb.writeln(qty.isNotEmpty ? '$checked ${item.name} ($qty)' : '$checked ${item.name}');
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

  IconData _aisleIcon(String aisleName) {
    switch (aisleName) {
      case 'Fresh Produce':
        return Icons.eco_outlined;
      case 'Meat & Protein':
        return Icons.restaurant_outlined;
      case 'Dairy & Chilled':
        return Icons.egg_outlined;
      case 'Grains & Noodles':
        return Icons.grain_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTokens.primary(isDark);
    final sageInk = AppTokens.sageInk(isDark);
    final textPrimary = AppTokens.textPrimary(isDark);
    final textSecondary = AppTokens.textSecondary(isDark);
    final textMuted = AppTokens.textMuted(isDark);
    final border = AppTokens.border(isDark);
    final surface = AppTokens.surface(isDark);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.spaceLg,
        title: Text(
          'Groceries',
          style: AppTokens.display(fontSize: 21, color: textPrimary),
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
                    icon: const Icon(Icons.restart_alt_rounded, size: 21),
                    onPressed: checkedItems > 0 ? () => provider.uncheckAllIngredients() : null,
                    tooltip: 'Uncheck All',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    onPressed: hasItems ? () => _shareGroceryList(context, aisleGroups) : null,
                    tooltip: 'Share Grocery List',
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: AppTokens.spaceSm),
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
                      'No active grocery list',
                      style: AppTokens.display(fontSize: 22, color: textPrimary),
                    ),
                    const SizedBox(height: AppTokens.spaceSm),
                    Text(
                      'Curate a weekly menu in the Planner to combine every ingredient by aisle automatically.',
                      textAlign: TextAlign.center,
                      style: AppTokens.sansBody(fontSize: 13.5, color: textSecondary),
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
              // Calm Oat-Linen Progress Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.spaceLg,
                    AppTokens.spaceSm,
                    AppTokens.spaceLg,
                    AppTokens.spaceMd,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.spaceMd + 2),
                    decoration: BoxDecoration(
                      color: AppTokens.surfaceWarm(isDark),
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(color: AppTokens.sandBorder(isDark), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MARKET LIST',
                                    style: AppTokens.kicker(fontSize: 9.5, color: sageInk),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activePack.title,
                                    style: AppTokens.serifItalic(
                                      fontSize: 19,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceSm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                border: Border.all(color: border),
                              ),
                              child: Text(
                                '$checkedItems / $totalItems',
                                style: AppTokens.numeral(
                                  fontSize: 11.5,
                                  color: sageInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spaceMd),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          child: LinearProgressIndicator(
                            value: totalItems > 0 ? checkedItems / totalItems : 0.0,
                            minHeight: 4,
                            backgroundColor: border,
                            valueColor: AlwaysStoppedAnimation<Color>(primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Porcelain Aisle Sheets
              ...aisleGroups.entries.where((e) => e.value.isNotEmpty).map((entry) {
                final aisleName = entry.key;
                final items = entry.value;
                final isFresh = aisleName == 'Fresh Produce';

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.spaceLg,
                      0,
                      AppTokens.spaceLg,
                      AppTokens.spaceMd,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(color: border, width: 1.0),
                        boxShadow: AppTokens.paperShadow(isDark),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.spaceMd + 2,
                        AppTokens.spaceMd,
                        AppTokens.spaceMd + 2,
                        AppTokens.spaceSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _aisleIcon(aisleName),
                                size: 17,
                                color: isFresh ? sageInk : textSecondary,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  aisleName.toUpperCase(),
                                  style: AppTokens.kicker(
                                    fontSize: 10.5,
                                    color: isFresh ? sageInk : textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${items.length} items',
                                style: AppTokens.numeral(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(height: 1, color: border),
                          for (int i = 0; i < items.length; i++) ...[
                            Builder(
                              builder: (context) {
                                final ing = items[i];
                                final isChecked = ing.isChecked;
                                final isInPantry = provider.pantryItems.any(
                                  (p) => ing.name.toLowerCase().contains(p.toLowerCase()),
                                );
                                final qtyStr = ing.quantity > 0
                                    ? '${ing.quantity.toStringAsFixed(ing.quantity.truncateToDouble() == ing.quantity ? 0 : 1)} ${ing.unit}'
                                    : '';

                                return InkWell(
                                  onTap: () => provider.toggleConsolidatedIngredient(
                                    ing.name,
                                    !isChecked,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
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
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  ing.name,
                                                  style: AppTokens.sansBody(
                                                    fontSize: 14,
                                                    fontWeight: isChecked
                                                        ? FontWeight.w400
                                                        : FontWeight.w500,
                                                    color: isChecked ? textMuted : textPrimary,
                                                  ).copyWith(
                                                    decoration: isChecked
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              if (isInPantry) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTokens.primaryContainer(isDark),
                                                    borderRadius: BorderRadius.circular(
                                                      AppTokens.radiusPill,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'IN PANTRY',
                                                    style: AppTokens.kicker(
                                                      fontSize: 8.5,
                                                      letterSpacing: 0.8,
                                                      color: sageInk,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (qtyStr.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Text(
                                            qtyStr,
                                            style: AppTokens.numeral(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                              color: isChecked ? textMuted : sageInk,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (i < items.length - 1)
                              Divider(height: 1, color: border.withValues(alpha: 0.7)),
                          ],
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
