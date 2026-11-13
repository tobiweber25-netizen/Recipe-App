class Ingredient {
  final int? id;
  final int? mealPackId;
  final int? recipeId; // Null if it is shared_fresh or staple
  final String name;
  final double quantity;
  final String unit;
  final String type; // 'shared_fresh', 'recipe_specific', 'staple'
  bool isChecked;

  Ingredient({
    this.id,
    this.mealPackId,
    this.recipeId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.type,
    this.isChecked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meal_pack_id': mealPackId,
      'recipe_id': recipeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'type': type,
      'is_checked': isChecked ? 1 : 0,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as int?,
      mealPackId: map['meal_pack_id'] as int?,
      recipeId: map['recipe_id'] as int?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      type: map['type'] as String,
      isChecked: (map['is_checked'] as int? ?? 0) == 1,
    );
  }

  Ingredient copyWith({
    int? id,
    int? mealPackId,
    int? recipeId,
    String? name,
    double? quantity,
    String? unit,
    String? type,
    bool? isChecked,
  }) {
    return Ingredient(
      id: id ?? this.id,
      mealPackId: mealPackId ?? this.mealPackId,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  String get aisle {
    final n = name.toLowerCase();

    // 1. Pantry Staples, Spices & Sauces (explicit staple type or clear condiment/powder/paste/oil)
    if (type == 'staple') return 'Pantry & Spices';
    const pantryKeywords = [
      'paste', 'sauce', 'oil', 'vinegar', 'powder', 'flakes', 'mirin', 'syrup',
      'sugar', 'salt', 'pepper flakes', 'gochujang', 'doenjang', 'dashi',
      'curry paste', 'paprika', 'cumin', 'oregano', 'cinnamon', 'turmeric',
      'peppercorn', 'sesame seeds', 'bouillon', 'stock cube', 'cornstarch',
      'baking', 'yeast', 'honey', 'mayo', 'mayonnaise', 'mustard', 'soy',
      'saffron', 'berbere', 'harissa', 'tahini', 'garam masala', 'wine', 'stock',
      'broth', 'lentil', 'beans', 'chickpea', 'nut', 'almond', 'walnut', 'pine nut',
      'peanut', 'cashew', 'tamarind', 'sumac', 'sofrito', 'barberries', 'zereshk',
      'allspice', 'pimento', 'ancho', 'pasilla', 'sauerkraut'
    ];
    if (pantryKeywords.any((k) => n.contains(k))) return 'Pantry & Spices';

    // 2. Meat, Fish & Protein
    const proteinKeywords = [
      'chicken', 'beef', 'pork', 'bacon', 'belly', 'mince', 'rib', 'short rib',
      'steak', 'lamb', 'mutton', 'fish', 'salmon', 'hake', 'trout', 'clam',
      'squid', 'prawn', 'shrimp', 'tofu', 'egg', 'eggs', 'meat', 'sausage',
      'duck', 'veal', 'shank', 'mussel', 'calamari', 'paneer', 'cod', 'halibut', 'scallop',
      'chashu', 'kielbasa', 'chouriço', 'chorizo', 'catfish', 'tilapia', 'egusi', 'bonito'
    ];
    if (proteinKeywords.any((k) => n.contains(k))) return 'Meat & Protein';

    // 3. Grains, Noodles & Bakery
    const grainKeywords = [
      'rice', 'noodle', 'noodles', 'ramen', 'somyeon', 'vermicelli', 'dangmyeon',
      'glass noodle', 'pasta', 'rigatoni', 'orzo', 'spaghetti', 'wrap', 'tortilla',
      'bread', 'baguette', 'sourdough', 'roti', 'naan', 'dombolo', 'rice cake',
      'tteok', 'bun', 'buns', 'flour', 'polenta', 'couscous', 'ditalini', 'bucatini',
      'arborio', 'bomba', 'penne', 'fettuccine', 'pide', 'simit', 'lavash', 'arepa',
      'biscuit', 'crackers', 'dumpling', 'pierogi', 'pampushky'
    ];
    if (grainKeywords.any((k) => n.contains(k))) return 'Grains & Noodles';

    // 4. Dairy & Refrigerated
    const dairyKeywords = [
      'milk', 'cream', 'butter', 'cheese', 'cheddar', 'parmesan', 'mozzarella',
      'feta', 'halloumi', 'yoghurt', 'yogurt', 'kimchi', 'pecorino', 'gruyère',
      'gruyere', 'burrata', 'ricotta', 'crema', 'ghee', 'sour cream', 'twaróg'
    ];
    if (dairyKeywords.any((k) => n.contains(k))) return 'Dairy & Chilled';

    // 5. Fresh Produce
    const produceKeywords = [
      'onion', 'garlic', 'ginger', 'scallion', 'spring onion', 'shallot', 'spinach',
      'kale', 'cabbage', 'bok choy', 'mushroom', 'shiitake', 'potato', 'sweet potato',
      'carrot', 'zucchini', 'bell pepper', 'chili', 'pepper', 'tomato', 'cucumber',
      'bean sprout', 'daikon', 'radish', 'lime', 'lemon', 'cilantro', 'coriander',
      'mint', 'basil', 'perilla', 'asparagus', 'broccoli', 'cauliflower', 'avocado',
      'apple', 'pear', 'peas', 'corn', 'lettuce', 'herb', 'parsley', 'leek',
      'eggplant', 'aubergine', 'celery', 'tarragon', 'thyme', 'rosemary', 'dill',
      'okra', 'plantain', 'tomatillo', 'prune', 'olive', 'beet', 'beetroot',
      'yuca', 'cassava', 'galangal', 'lemongrass', 'mustard greens', 'curry leaves'
    ];
    if (produceKeywords.any((k) => n.contains(k))) return 'Fresh Produce';

    // 6. Default: Pantry Staples & Sauces
    return 'Pantry & Spices';
  }
}
