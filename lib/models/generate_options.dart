class GenerateOptions {
  final String dietaryBalance;
  final String overlap;
  final String budgetTier; // 'budget', 'standard', 'gourmet'
  final int servings;
  final String customDirection;

  final String cuisineFocus; // 'korean_asian', 'adventurous_bold', 'balanced', 'south_african', 'quick'

  const GenerateOptions({
    this.dietaryBalance = '3 vegetarian, 3 mixed protein',
    this.overlap = 'Smart ingredient reuse (share 2-3 fresh items)',
    this.budgetTier = 'standard',
    this.servings = 2,
    this.customDirection = '',
    this.cuisineFocus = 'korean_asian',
  });

  GenerateOptions copyWith({
    String? dietaryBalance,
    String? overlap,
    String? budgetTier,
    int? servings,
    String? customDirection,
    String? cuisineFocus,
  }) {
    return GenerateOptions(
      dietaryBalance: dietaryBalance ?? this.dietaryBalance,
      overlap: overlap ?? this.overlap,
      budgetTier: budgetTier ?? this.budgetTier,
      servings: servings ?? this.servings,
      customDirection: customDirection ?? this.customDirection,
      cuisineFocus: cuisineFocus ?? this.cuisineFocus,
    );
  }
}

