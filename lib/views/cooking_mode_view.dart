import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../utils/app_tokens.dart';

class CookingModeView extends StatefulWidget {
  final Recipe recipe;
  final List<Ingredient> ingredients;

  const CookingModeView({
    super.key,
    required this.recipe,
    this.ingredients = const [],
  });

  @override
  State<CookingModeView> createState() => _CookingModeViewState();
}

class _CookingModeViewState extends State<CookingModeView> {
  int _currentStepIndex = 0;
  final PageController _pageController = PageController();

  // Timer State
  Timer? _timer;
  int _timerSecondsRemaining = 0;
  int _timerTotalSeconds = 0;
  bool _isTimerRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int minutes) {
    _timer?.cancel();
    final totalSecs = minutes * 60;
    setState(() {
      _timerTotalSeconds = totalSecs;
      _timerSecondsRemaining = totalSecs;
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSecondsRemaining > 0) {
        setState(() {
          _timerSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isTimerRunning = false;
        });
        HapticFeedback.heavyImpact();
        _showTimerCompleteDialog(minutes);
      }
    });
  }

  void _pauseResumeTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else if (_timerSecondsRemaining > 0) {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerSecondsRemaining > 0) {
          setState(() {
            _timerSecondsRemaining--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isTimerRunning = false;
          });
          HapticFeedback.heavyImpact();
          _showTimerCompleteDialog(_timerTotalSeconds ~/ 60);
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerSecondsRemaining = 0;
      _timerTotalSeconds = 0;
    });
  }

  void _addMinuteToTimer() {
    setState(() {
      _timerSecondsRemaining += 60;
      _timerTotalSeconds += 60;
    });
  }

  void _showTimerCompleteDialog(int minutes) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight;
    final textSecondary = isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight;
    final primaryColor = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
    final cardBg = isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight;
    final borderColor = isDark ? AppTokens.borderDark : AppTokens.borderLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              decoration: const BoxDecoration(
                gradient: AppTokens.goldenNectarGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppTokens.spaceSm + 2),
            Text(
              'Timer Finished',
              style: AppTokens.display(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
            ),
          ],
        ),
        content: Text(
          'Your $minutes-minute timer has completed. Check your food on the stove.',
          style: AppTokens.sansBody(fontSize: 13.5, color: textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            ),
            child: Text(
              'ACKNOWLEDGE',
              style: AppTokens.kicker(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _detectAllMinutesInText(String text) {
    final reg = RegExp(r'(\d+)\s*(?:minutes|mins|min)\b', caseSensitive: false);
    final matches = reg.allMatches(text);
    final results = <int>[];
    for (final m in matches) {
      final val = int.tryParse(m.group(1) ?? '');
      if (val != null && !results.contains(val)) {
        results.add(val);
      }
    }
    return results;
  }

  List<Ingredient> _getIngredientsForStep(String stepText) {
    final allIngredients = widget.ingredients.isNotEmpty
        ? widget.ingredients
        : widget.recipe.recipeSpecificIngredients;
    if (allIngredients.isEmpty) return [];

    final lowerStep = stepText.toLowerCase();
    final matched = <Ingredient>[];

    const stopWords = {
      'fresh', 'dried', 'ground', 'sliced', 'chopped', 'diced', 'minced',
      'crushed', 'grated', 'shredded', 'peeled', 'toasted', 'boneless',
      'skinless', 'cooked', 'warm', 'cold', 'large', 'small', 'medium',
      'whole', 'halved', 'pieces', 'thick', 'thin', 'cloves', 'stalks',
      'with', 'from', 'into', 'over', 'optional', 'fillets', 'about'
    };

    for (final ing in allIngredients) {
      final cleanFullName = ing.name.toLowerCase().replaceAll(RegExp(r'\([^)]*\)'), '').trim();

      // 1. Full/base ingredient name match
      if (cleanFullName.length >= 3 && lowerStep.contains(cleanFullName)) {
        matched.add(ing);
        continue;
      }

      // 2. Significant words >= 4 chars
      final words = cleanFullName
          .split(RegExp(r'[^a-zA-Z]+'))
          .where((w) => w.length >= 4 && !stopWords.contains(w));

      bool hasMatch = false;
      for (final w in words) {
        final singular = w.endsWith('s') && w.length > 4 ? w.substring(0, w.length - 1) : w;
        if (lowerStep.contains(w) || (singular.length >= 4 && lowerStep.contains(singular))) {
          hasMatch = true;
          break;
        }
      }
      if (hasMatch) {
        matched.add(ing);
      }
    }
    return matched;
  }

  void _showIngredientsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
    final textPrimary = isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight;
    final textSecondary = isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight;
    final borderColor = isDark ? AppTokens.borderDark : AppTokens.borderLight;
    final modalBg = isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight;

    final allIngredients = widget.ingredients.isNotEmpty
        ? widget.ingredients
        : widget.recipe.recipeSpecificIngredients;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMd + 4,
                vertical: AppTokens.spaceMd,
              ),
              child: Column(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'INGREDIENTS REFERENCE',
                        style: AppTokens.kicker(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceSm + 2,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppTokens.primaryContainerDark : AppTokens.primaryContainerLight,
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Text(
                          '${widget.recipe.servings} Servings',
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
                  Expanded(
                    child: allIngredients.isEmpty
                        ? Center(
                            child: Text(
                              'No ingredient list recorded.',
                              style: AppTokens.sansBody(fontSize: 13, color: textSecondary),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: allIngredients.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                            itemBuilder: (context, idx) {
                              final ing = allIngredients[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.spaceSm + 4),
                                    Expanded(
                                      child: Text(
                                        ing.name,
                                        style: AppTokens.sansBody(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${ing.quantity > 0 ? (ing.quantity % 1 == 0 ? ing.quantity.toInt().toString() : ing.quantity.toString()) : ''} ${ing.unit}',
                                      style: AppTokens.numeral(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _finishCooking() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTokens.primaryDark : AppTokens.primaryLight;
    final textPrimary = isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight;
    final textSecondary = isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight;
    final cardBg = isDark ? AppTokens.surfaceDark : AppTokens.surfaceLight;
    final borderColor = isDark ? AppTokens.borderDark : AppTokens.borderLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        title: Text(
          'Dinner is Served',
          style: AppTokens.display(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        content: Text(
          'Great work cooking "${widget.recipe.title}". Bon appétit!',
          style: AppTokens.sansBody(fontSize: 13.5, color: textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            ),
            child: Text(
              'FINISH',
              style: AppTokens.kicker(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
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

    final instructions = widget.recipe.instructions;
    final totalSteps = instructions.length;

    if (totalSteps == 0) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.recipe.title)),
        body: Center(
          child: Text(
            'No culinary instructions available.',
            style: AppTokens.sansBody(fontSize: 14, color: textSecondary),
          ),
        ),
      );
    }

    final currentInstruction = instructions[_currentStepIndex];
    final allDetectedMins = _detectAllMinutesInText(currentInstruction);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe.title,
          style: AppTokens.display(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Ingredients Sheet',
            onPressed: () => _showIngredientsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Step Progress with Sunburst Styling
            LinearProgressIndicator(
              value: (totalSteps > 0) ? (_currentStepIndex + 1) / totalSteps : 0.0,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 4,
            ),

            // Step Header Sub-bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMd,
                vertical: AppTokens.spaceSm + 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      'STEP ${_currentStepIndex + 1} OF $totalSteps',
                      style: AppTokens.kicker(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showIngredientsSheet(context),
                    icon: Icon(Icons.menu_book_rounded, size: 16, color: primaryColor),
                    label: Text(
                      'Ingredients',
                      style: AppTokens.display(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Step Card PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalSteps,
                onPageChanged: (idx) {
                  setState(() => _currentStepIndex = idx);
                },
                itemBuilder: (context, index) {
                  final text = instructions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMd,
                      vertical: AppTokens.spaceXs,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(color: borderColor, width: 1.0),
                        boxShadow: AppTokens.cardShadow,
                      ),
                      padding: const EdgeInsets.all(AppTokens.spaceLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  gradient: AppTokens.sunburstGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: AppTokens.sunGlowShadow,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: AppTokens.numeral(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSm + 2),
                              Text(
                                'Action Step',
                                style: AppTokens.kicker(
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceLg),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: AppTokens.display(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w500,
                                      height: 1.45,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final stepIngredients = _getIngredientsForStep(text);
                                      if (stepIngredients.isEmpty) return const SizedBox.shrink();

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: AppTokens.spaceMd),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: stepIngredients.map((ing) {
                                              final qtyStr = ing.quantity > 0
                                                  ? (ing.quantity % 1 == 0
                                                      ? ing.quantity.toInt().toString()
                                                      : ing.quantity.toString())
                                                  : '';
                                              final label = qtyStr.isNotEmpty
                                                  ? '• ${ing.name}: $qtyStr ${ing.unit}'
                                                  : '• ${ing.name}';

                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppTokens.primaryContainerDark
                                                      : AppTokens.primaryContainerLight,
                                                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                                  border: Border.all(
                                                    color: isDark ? AppTokens.borderDark : AppTokens.borderLight,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: AppTokens.sansBody(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Active Kitchen Timer Banner (if running or set)
            if (_timerSecondsRemaining > 0 || _isTimerRunning) ...[
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceMd,
                  vertical: AppTokens.spaceXs + 2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceMd,
                  vertical: AppTokens.spaceSm + 2,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTokens.accentSunTintDark : AppTokens.accentSunTintLight,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  border: Border.all(
                    color: AppTokens.accentSun.withValues(alpha: isDark ? 0.35 : 0.4),
                    width: 1.0,
                  ),
                  boxShadow: AppTokens.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTokens.spaceSm),
                          decoration: const BoxDecoration(
                            gradient: AppTokens.goldenNectarGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceSm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACTIVE KITCHEN TIMER',
                                style: AppTokens.kicker(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTokens.accentSunDark : AppTokens.accentSun,
                                ),
                              ),
                              Text(
                                '${(_timerSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_timerSecondsRemaining % 60).toString().padLeft(2, '0')}',
                                style: AppTokens.numeral(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isTimerRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            color: AppTokens.accentSun,
                            size: 30,
                          ),
                          onPressed: _pauseResumeTimer,
                        ),
                        IconButton(
                          icon: Icon(Icons.add_alarm_rounded, color: textSecondary, size: 20),
                          tooltip: '+1 min',
                          onPressed: _addMinuteToTimer,
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                          tooltip: 'Cancel Timer',
                          onPressed: _resetTimer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Quick Add:',
                          style: AppTokens.kicker(
                            fontSize: 9.5,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ...[1, 3, 5, 10].map((extra) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                            onTap: () {
                              setState(() {
                                _timerSecondsRemaining += extra * 60;
                                _timerTotalSeconds += extra * 60;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTokens.accentSunDark : AppTokens.accentSun).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              ),
                              child: Text(
                                '+$extra m',
                                style: AppTokens.numeral(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTokens.accentSunDark : AppTokens.accentSun,
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (allDetectedMins.isNotEmpty) ...[
              // Quick Detected Timer Button(s)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceMd,
                  vertical: AppTokens.spaceXs,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: allDetectedMins.map((m) {
                    return OutlinedButton.icon(
                      onPressed: () => _startTimer(m),
                      icon: const Icon(Icons.alarm_rounded, size: 18, color: AppTokens.accentSun),
                      label: Text(
                        'Start $m min Timer',
                        style: AppTokens.display(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTokens.accentSunDark : AppTokens.accentSun,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTokens.accentSun.withValues(alpha: isDark ? 0.4 : 0.6),
                          width: 1.0,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppTokens.spaceSm + 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMd,
                vertical: AppTokens.spaceSm + 4,
              ),
              child: Row(
                children: [
                  if (_currentStepIndex > 0) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(
                        'BACK',
                        style: AppTokens.kicker(
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMd,
                          vertical: AppTokens.spaceSm + 4,
                        ),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSm + 2),
                  ],
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTokens.sunburstGradient,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        boxShadow: AppTokens.sunGlowShadow,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_currentStepIndex < totalSteps - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishCooking();
                          }
                        },
                        icon: Icon(
                          _currentStepIndex < totalSteps - 1 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _currentStepIndex < totalSteps - 1 ? 'Next Step' : 'Finish Cooking',
                          style: AppTokens.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm + 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
