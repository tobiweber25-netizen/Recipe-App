import 'package:flutter/material.dart';
import 'dart:math';
class SeasonalContext {
  final String seasonName;
  final String monthName;
  final List<String> produceKeywords;
  final String description;
  final List<Color> gradientColors;

  SeasonalContext({
    required this.seasonName,
    required this.monthName,
    required this.produceKeywords,
    required this.description,
    required this.gradientColors,
  });
}

class SeasonHelper {
  static const String defaultLocation = "Johannesburg, South Africa";
  static const String defaultUnits = "Metric (g, kg, ml, °C)";

  static const List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  static SeasonalContext getSeasonalContext(DateTime date) {
    final month = date.month;
    final monthName = _months[month - 1];
    final random = Random();

    List<String> produce = [];
    String baseDesc = "";
    List<Color> colors = [];
    String seasonName = "";

    if (month == 6 || month == 7 || month == 8) {
      // Winter
      seasonName = "South African Winter";
      produce = ["root vegetables", "brassicas", "squashes", "citrus fruits", "avocados", "spinach", "kale", "cabbage", "cauliflower"];
      baseDesc = "Focus on rich, warming winter dishes using locally sourced produce.";
      colors = [const Color(0xFF1B365D), const Color(0xFFE07A5F)];
    } else if (month == 9 || month == 10 || month == 11) {
      // Spring
      seasonName = "South African Spring";
      produce = ["asparagus", "artichokes", "green peas", "baby potatoes", "strawberries", "spring onions", "pineapples", "spinach", "apricots"];
      baseDesc = "Emphasize light, fresh spring recipes featuring crisp, new-season produce.";
      colors = [const Color(0xFF70E000), const Color(0xFF38B000)];
    } else if (month == 12 || month == 1 || month == 2) {
      // Summer
      seasonName = "South African Summer";
      produce = ["tomatoes", "sweetcorn", "cucumbers", "bell peppers", "zucchini", "peaches", "mangoes", "watermelon", "eggplants"];
      baseDesc = "Emphasize colorful, refreshing summer recipes utilizing juicy, hydration-filled produce.";
      colors = [const Color(0xFFF77F00), const Color(0xFFD62828)];
    } else {
      // Autumn
      seasonName = "South African Autumn";
      produce = ["apples", "pears", "figs", "pomegranates", "sweet potatoes", "eggplants", "wild mushrooms", "leeks", "butternut"];
      baseDesc = "Bias towards comforting autumn produce featuring earthy, sweet seasonal harvests.";
      colors = [const Color(0xFFB07D62), const Color(0xFF9C6644)];
    }

    // Shuffle and pick 4-5 items for variety
    produce.shuffle(random);
    final selectedProduce = produce.take(random.nextInt(2) + 4).toList();

    return SeasonalContext(
      seasonName: seasonName,
      monthName: monthName,
      produceKeywords: selectedProduce,
      description: "$baseDesc Highlight: ${selectedProduce.join(', ')}.",
      gradientColors: colors,
    );
  }
}

