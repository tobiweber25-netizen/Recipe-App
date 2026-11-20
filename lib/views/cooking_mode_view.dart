import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../utils/app_tokens.dart';
import '../utils/botanical_marks.dart';

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

  static String _formatQuantity(double quantity) {
    if (quantity <= 0) return '';
    if (quantity == quantity.roundToDouble()) return quantity.toInt().toString();
    return quantity.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
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
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerSecondsRemaining > 0) {
        setState(() => _timerSecondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _isTimerRunning = false);
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
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_timerSecondsRemaining > 0) {
          setState(() => _timerSecondsRemaining--);
        } else {
          timer.cancel();
          setState(() => _isTimerRunning = false);
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

  void _addMinutesToTimer(int extraMinutes) {
    setState(() {
      _timerSecondsRemaining += extraMinutes * 60;
      _timerTotalSeconds += extraMinutes * 60;
    });
  }

  void _showTimerCompleteDialog(int minutes) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: AppTokens.border(isDark), width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceSm),
              decoration: BoxDecoration(
                color: AppTokens.primaryContainer(isDark),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alarm_on_rounded,
                color: AppTokens.sageInk(isDark),
                size: 20,
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm + 4),
            Text(
              'Timer Finished',
              style: AppTokens.display(
                fontSize: 20,
                color: AppTokens.textPrimary(isDark),
              ),
            ),
          ],
        ),
        content: Text(
          'Your $minutes-minute timer is complete. Check your dish on the stove.',
          style: AppTokens.sansBody(
            fontSize: 13.5,
            color: AppTokens.textSecondary(isDark),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  List<int> _detectAllMinutesInText(String text) {
    final reg = RegExp(r'(\d+)\s*(?:minutes|minute|mins|min)\b', caseSensitive: false);
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
      'with', 'from', 'into', 'over', 'optional', 'fillets', 'about',
    };

    for (final ing in allIngredients) {
      final cleanFullName = ing.name.toLowerCase().replaceAll(RegExp(r'\([^)]*\)'), '').trim();

      if (cleanFullName.length >= 3 && lowerStep.contains(cleanFullName)) {
        matched.add(ing);
        continue;
      }

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
      if (hasMatch) matched.add(ing);
    }
    return matched;
  }

  void _showIngredientsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allIngredients = widget.ingredients.isNotEmpty
        ? widget.ingredients
        : widget.recipe.recipeSpecificIngredients;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface(isDark),
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
                horizontal: AppTokens.spaceLg,
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
                        'Ingredients',
                        style: AppTokens.display(
                          fontSize: 21,
                          color: AppTokens.textPrimary(isDark),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTokens.primaryContainer(isDark),
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Text(
                          '${widget.recipe.servings} Servings',
                          style: AppTokens.numeral(
                            fontSize: 11.5,
                            color: AppTokens.sageInk(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMd),
                  Expanded(
                    child: allIngredients.isEmpty
                        ? Center(
                            child: Text(
                              'No ingredient list recorded.',
                              style: AppTokens.sansBody(
                                fontSize: 13.5,
                                color: AppTokens.textSecondary(isDark),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: allIngredients.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: AppTokens.border(isDark),
                            ),
                            itemBuilder: (context, idx) {
                              final ing = allIngredients[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppTokens.primary(isDark),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ing.name,
                                        style: AppTokens.sansBody(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppTokens.textPrimary(isDark),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_formatQuantity(ing.quantity)} ${ing.unit}'.trim(),
                                      style: AppTokens.numeral(
                                        fontSize: 13,
                                        color: AppTokens.sageInk(isDark),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTokens.surface(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: AppTokens.border(isDark), width: 1.0),
        ),
        title: Text(
          'Dinner is Served',
          style: AppTokens.serifItalic(
            fontSize: 22,
            color: AppTokens.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Well cooked — enjoy "${widget.recipe.title}".',
          style: AppTokens.sansBody(
            fontSize: 13.5,
            color: AppTokens.textSecondary(isDark),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
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

    final instructions = widget.recipe.instructions;
    final totalSteps = instructions.length;

    if (totalSteps == 0) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.recipe.title)),
        body: Center(
          child: Text(
            'No cooking instructions available.',
            style: AppTokens.sansBody(fontSize: 14, color: textSecondary),
          ),
        ),
      );
    }

    final currentInstruction = instructions[_currentStepIndex];
    final allDetectedMins = _detectAllMinutesInText(currentInstruction);
    final timerProgress = (_timerTotalSeconds > 0)
        ? (_timerSecondsRemaining / _timerTotalSeconds)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe.title,
          style: AppTokens.display(fontSize: 18, color: textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, size: 21),
            tooltip: 'Ingredients Sheet',
            onPressed: () => _showIngredientsSheet(context),
          ),
          const SizedBox(width: AppTokens.spaceXs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Whisper-thin eucalyptus progress line
            LinearProgressIndicator(
              value: (_currentStepIndex + 1) / totalSteps,
              backgroundColor: border,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 3,
            ),

            // Quiet Step Sub-bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceLg,
                AppTokens.spaceMd,
                AppTokens.spaceLg,
                AppTokens.spaceSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STEP ${_currentStepIndex + 1} OF $totalSteps',
                    style: AppTokens.kicker(
                      fontSize: 11,
                      color: sageInk,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showIngredientsSheet(context),
                    icon: Icon(Icons.menu_book_outlined, size: 16, color: sageInk),
                    label: Text(
                      'Ingredients',
                      style: AppTokens.sansBody(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sageInk,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),

            // Glare-Free Porcelain Step Card
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalSteps,
                onPageChanged: (idx) => setState(() => _currentStepIndex = idx),
                itemBuilder: (context, index) {
                  final text = instructions[index];
                  final stepNumber = (index + 1).toString().padLeft(2, '0');
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceLg,
                      vertical: AppTokens.spaceXs,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(color: border, width: 1.0),
                        boxShadow: AppTokens.paperShadow(isDark),
                      ),
                      padding: const EdgeInsets.all(AppTokens.spaceLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                stepNumber,
                                style: AppTokens.serifItalic(
                                  fontSize: 28,
                                  color: sageInk,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Action Step',
                                style: AppTokens.kicker(
                                  fontSize: 10.5,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceMd),
                          Divider(height: 1, color: border),
                          const SizedBox(height: AppTokens.spaceLg),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: AppTokens.sansBody(
                                      fontSize: 19.5,
                                      fontWeight: FontWeight.w400,
                                      height: 1.55,
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
                                          const SizedBox(height: AppTokens.spaceLg),
                                          Text(
                                            'FOR THIS STEP',
                                            style: AppTokens.kicker(
                                              fontSize: 9.5,
                                              color: AppTokens.textMuted(isDark),
                                            ),
                                          ),
                                          const SizedBox(height: AppTokens.spaceSm),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: stepIngredients.map((ing) {
                                              final qtyStr = _formatQuantity(ing.quantity);
                                              final label = qtyStr.isNotEmpty
                                                  ? '${ing.name} · $qtyStr ${ing.unit}'.trim()
                                                  : ing.name;

                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 11,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTokens.surfaceWarm(isDark),
                                                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                                  border: Border.all(
                                                    color: AppTokens.sandBorder(isDark),
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  label,
                                                  style: AppTokens.sansBody(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTokens.sandInk(isDark),
                                                    height: 1.1,
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

            // Calm Sculpted Countertop Timer Strip
            if (_timerSecondsRemaining > 0 || _isTimerRunning) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AppTokens.spaceLg,
                  AppTokens.spaceSm,
                  AppTokens.spaceLg,
                  AppTokens.spaceXs,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceMd,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceWarm(isDark),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  border: Border.all(color: AppTokens.sandBorder(isDark), width: 1.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        TimerProgressRing(
                          progress: timerProgress,
                          trackColor: border,
                          progressColor: primary,
                          size: 46,
                          strokeWidth: 3.0,
                          child: Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: sageInk,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KITCHEN TIMER',
                                style: AppTokens.kicker(fontSize: 9.5, color: sageInk),
                              ),
                              Text(
                                '${(_timerSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_timerSecondsRemaining % 60).toString().padLeft(2, '0')}',
                                style: AppTokens.numeral(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isTimerRunning
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            color: primary,
                            size: 32,
                          ),
                          onPressed: _pauseResumeTimer,
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: textSecondary, size: 19),
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
                          'Extend:',
                          style: AppTokens.sansBody(fontSize: 11, color: textSecondary),
                        ),
                        const SizedBox(width: 6),
                        ...[1, 3, 5].map((extra) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                onTap: () => _addMinutesToTimer(extra),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                    border: Border.all(color: border),
                                  ),
                                  child: Text(
                                    '+$extra m',
                                    style: AppTokens.numeral(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sageInk,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceLg,
                  AppTokens.spaceSm,
                  AppTokens.spaceLg,
                  AppTokens.spaceXs,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: allDetectedMins.map((m) {
                    return OutlinedButton.icon(
                      onPressed: () => _startTimer(m),
                      icon: Icon(Icons.timer_outlined, size: 17, color: sageInk),
                      label: Text(
                        'Start $m min Timer',
                        style: AppTokens.sansBody(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sageInk,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTokens.primaryContainer(isDark),
                        side: BorderSide(color: primary.withValues(alpha: 0.35)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceLg,
                AppTokens.spaceSm + 4,
                AppTokens.spaceLg,
                AppTokens.spaceMd,
              ),
              child: Row(
                children: [
                  if (_currentStepIndex > 0) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: surface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMd,
                          vertical: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSm + 2),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_currentStepIndex < totalSteps - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishCooking();
                        }
                      },
                      icon: Icon(
                        _currentStepIndex < totalSteps - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _currentStepIndex < totalSteps - 1 ? 'Next Step' : 'Finish Cooking',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
