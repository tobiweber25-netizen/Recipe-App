import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/meal_pack.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  // In-memory fallback database for Web/testing
  final List<MealPack> _webInMemoryPacks = [];
  int _webIdCounter = 1;

  DbHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web. Using in-memory fallback.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('seasonal_prep_cook.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE recipes ADD COLUMN description TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE recipes ADD COLUMN is_saved INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE pantry_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE recipes ADD COLUMN saved_at TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE recipes ADD COLUMN cook_time_minutes INTEGER DEFAULT 25');
      await db.execute('ALTER TABLE recipes ADD COLUMN servings INTEGER DEFAULT 2');
      await db.execute('ALTER TABLE recipes ADD COLUMN category TEXT DEFAULT "Main Dish"');
      await db.execute('ALTER TABLE recipes ADD COLUMN budget_tier TEXT DEFAULT "Standard"');
      await db.execute('ALTER TABLE recipes ADD COLUMN chef_tip TEXT DEFAULT ""');
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meal_packs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        season TEXT NOT NULL,
        month TEXT NOT NULL,
        title TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_pack_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        is_saved INTEGER NOT NULL DEFAULT 0,
        saved_at TEXT,
        cook_time_minutes INTEGER NOT NULL DEFAULT 25,
        servings INTEGER NOT NULL DEFAULT 2,
        category TEXT NOT NULL DEFAULT 'Main Dish',
        budget_tier TEXT NOT NULL DEFAULT 'Standard',
        chef_tip TEXT,
        instructions TEXT NOT NULL,
        FOREIGN KEY (meal_pack_id) REFERENCES meal_packs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_pack_id INTEGER NOT NULL,
        recipe_id INTEGER,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        type TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (meal_pack_id) REFERENCES meal_packs (id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pantry_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<MealPack> insertMealPack(MealPack mealPack) async {
    if (kIsWeb) {
      final mealPackId = _webIdCounter++;
      final List<Recipe> savedRecipes = [];
      int recipeIdCounter = 100;
      int ingredientIdCounter = 1000;

      for (var recipe in mealPack.recipes) {
        final List<Ingredient> savedRecipeSpecificIngredients = [];
        final recipeId = recipeIdCounter++;
        for (var ing in recipe.recipeSpecificIngredients) {
          final ingId = ingredientIdCounter++;
          savedRecipeSpecificIngredients.add(ing.copyWith(
            id: ingId,
            mealPackId: mealPackId,
            recipeId: recipeId,
          ));
        }
        savedRecipes.add(recipe.copyWith(
          id: recipeId,
          mealPackId: mealPackId,
          recipeSpecificIngredients: savedRecipeSpecificIngredients,
        ));
      }

      final List<Ingredient> savedSharedIngredients = [];
      for (var ing in mealPack.sharedFreshIngredients) {
        final ingId = ingredientIdCounter++;
        savedSharedIngredients.add(ing.copyWith(
          id: ingId,
          mealPackId: mealPackId,
        ));
      }

      final List<Ingredient> savedStaples = [];
      for (var ing in mealPack.storeCupboardStaples) {
        final ingId = ingredientIdCounter++;
        savedStaples.add(ing.copyWith(
          id: ingId,
          mealPackId: mealPackId,
        ));
      }

      final result = mealPack.copyWith(
        id: mealPackId,
        recipes: savedRecipes,
        sharedFreshIngredients: savedSharedIngredients,
        storeCupboardStaples: savedStaples,
      );

      _webInMemoryPacks.insert(0, result);
      return result;
    }

    final db = await database;

    
    return await db.transaction((txn) async {
      final mealPackId = await txn.insert('meal_packs', mealPack.toMap());
      
      final recipeBatch = txn.batch();
      for (var recipe in mealPack.recipes) {
        final recipeMap = recipe.toMap();
        recipeMap['meal_pack_id'] = mealPackId;
        recipeBatch.insert('recipes', recipeMap);
      }
      final recipeIds = await recipeBatch.commit();
      
      final ingredientBatch = txn.batch();
      for (int i = 0; i < mealPack.recipes.length; i++) {
        var recipe = mealPack.recipes[i];
        final recipeId = recipeIds[i] as int;
        for (var ing in recipe.recipeSpecificIngredients) {
          final ingMap = ing.toMap();
          ingMap['meal_pack_id'] = mealPackId;
          ingMap['recipe_id'] = recipeId;
          ingredientBatch.insert('ingredients', ingMap);
        }
      }
      for (var ing in mealPack.sharedFreshIngredients) {
        final ingMap = ing.toMap();
        ingMap['meal_pack_id'] = mealPackId;
        ingMap['recipe_id'] = null;
        ingredientBatch.insert('ingredients', ingMap);
      }
      for (var ing in mealPack.storeCupboardStaples) {
        final ingMap = ing.toMap();
        ingMap['meal_pack_id'] = mealPackId;
        ingMap['recipe_id'] = null;
        ingredientBatch.insert('ingredients', ingMap);
      }
      
      final ingredientIds = await ingredientBatch.commit();
      
      int ingredientResultIndex = 0;
      final List<Recipe> savedRecipes = [];
      for (int i = 0; i < mealPack.recipes.length; i++) {
        var recipe = mealPack.recipes[i];
        final recipeId = recipeIds[i] as int;
        
        final List<Ingredient> savedRecipeSpecificIngredients = [];
        for (var ing in recipe.recipeSpecificIngredients) {
          final ingId = ingredientIds[ingredientResultIndex++] as int;
          savedRecipeSpecificIngredients.add(ing.copyWith(id: ingId, mealPackId: mealPackId, recipeId: recipeId));
        }
        savedRecipes.add(recipe.copyWith(id: recipeId, mealPackId: mealPackId, recipeSpecificIngredients: savedRecipeSpecificIngredients));
      }

      final List<Ingredient> savedSharedIngredients = [];
      for (var ing in mealPack.sharedFreshIngredients) {
        final ingId = ingredientIds[ingredientResultIndex++] as int;
        savedSharedIngredients.add(ing.copyWith(id: ingId, mealPackId: mealPackId));
      }

      final List<Ingredient> savedStaples = [];
      for (var ing in mealPack.storeCupboardStaples) {
        final ingId = ingredientIds[ingredientResultIndex++] as int;
        savedStaples.add(ing.copyWith(id: ingId, mealPackId: mealPackId));
      }

      return mealPack.copyWith(
        id: mealPackId,
        recipes: savedRecipes,
        sharedFreshIngredients: savedSharedIngredients,
        storeCupboardStaples: savedStaples,
      );
    });
  }

  Future<void> updateRecipeDetails(Recipe recipe) async {
    if (kIsWeb) {
      // In-memory web update
      for (int i = 0; i < _webInMemoryPacks.length; i++) {
        if (_webInMemoryPacks[i].id == recipe.mealPackId) {
          final pack = _webInMemoryPacks[i];
          final recipeIndex = pack.recipes.indexWhere((r) => r.id == recipe.id);
          if (recipeIndex != -1) {
            final newRecipes = List<Recipe>.from(pack.recipes);
            newRecipes[recipeIndex] = recipe;
            _webInMemoryPacks[i] = pack.copyWith(recipes: newRecipes);
          }
          break;
        }
      }
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'recipes',
        {
          'instructions': recipe.instructions.join('\n'),
          'chef_tip': recipe.chefTip,
          'cook_time_minutes': recipe.cookTimeMinutes,
          'servings': recipe.servings,
        },
        where: 'id = ?',
        whereArgs: [recipe.id],
      );

      final ingredientBatch = txn.batch();
      for (var ing in recipe.recipeSpecificIngredients) {
        final ingMap = ing.toMap();
        ingMap['meal_pack_id'] = recipe.mealPackId;
        ingMap['recipe_id'] = recipe.id;
        ingredientBatch.insert('ingredients', ingMap);
      }
      await ingredientBatch.commit();
    });
  }

  Future<Recipe> replaceRecipe(int oldRecipeId, int mealPackId, Recipe newRecipe) async {
    if (kIsWeb) {
      for (int i = 0; i < _webInMemoryPacks.length; i++) {
        if (_webInMemoryPacks[i].id == mealPackId) {
          final pack = _webInMemoryPacks[i];
          final recipeIndex = pack.recipes.indexWhere((r) => r.id == oldRecipeId);
          if (recipeIndex != -1) {
            final savedRecipe = newRecipe.copyWith(
              id: oldRecipeId,
              mealPackId: mealPackId,
            );
            final newRecipes = List<Recipe>.from(pack.recipes);
            newRecipes[recipeIndex] = savedRecipe;
            _webInMemoryPacks[i] = pack.copyWith(recipes: newRecipes);
            return savedRecipe;
          }
        }
      }
      return newRecipe;
    }

    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete('recipes', where: 'id = ?', whereArgs: [oldRecipeId]);
      
      final recipeMap = newRecipe.toMap();
      recipeMap['meal_pack_id'] = mealPackId;
      final newRecipeId = await txn.insert('recipes', recipeMap);

      final ingredientBatch = txn.batch();
      for (var ing in newRecipe.recipeSpecificIngredients) {
        final ingMap = ing.toMap();
        ingMap['meal_pack_id'] = mealPackId;
        ingMap['recipe_id'] = newRecipeId;
        ingredientBatch.insert('ingredients', ingMap);
      }
      final ingIds = await ingredientBatch.commit();

      final List<Ingredient> savedIngredients = [];
      for (int i = 0; i < newRecipe.recipeSpecificIngredients.length; i++) {
        final ing = newRecipe.recipeSpecificIngredients[i];
        final id = ingIds[i] as int;
        savedIngredients.add(ing.copyWith(
          id: id,
          mealPackId: mealPackId,
          recipeId: newRecipeId,
        ));
      }

      return newRecipe.copyWith(
        id: newRecipeId,
        mealPackId: mealPackId,
        recipeSpecificIngredients: savedIngredients,
      );
    });
  }

  Future<List<MealPack>> getAllMealPacks() async {
    if (kIsWeb) {
      return List.from(_webInMemoryPacks);
    }

    final db = await database;
    final mealPacksMaps = await db.query('meal_packs', orderBy: 'created_at DESC');
    
    final List<MealPack> mealPacks = [];
    
    for (var mpMap in mealPacksMaps) {
      final mealPackId = mpMap['id'] as int;
      
      final ingredientsMaps = await db.query('ingredients', where: 'meal_pack_id = ?', whereArgs: [mealPackId]);
      final List<Ingredient> ingredients = ingredientsMaps.map((m) => Ingredient.fromMap(m)).toList();
      
      final recipesMaps = await db.query('recipes', where: 'meal_pack_id = ?', whereArgs: [mealPackId]);
      final List<Recipe> recipes = recipesMaps.map((m) => Recipe.fromMap(m, ingredients)).toList();
      
      mealPacks.add(MealPack.fromMap(
        map: mpMap,
        recipes: recipes,
        ingredients: ingredients,
      ));
    }
    
    return mealPacks;
  }

  Future<int> updateIngredientChecked(int ingredientId, bool isChecked) async {
    if (kIsWeb) {
      for (var pack in _webInMemoryPacks) {
        for (var ing in pack.sharedFreshIngredients) {
          if (ing.id == ingredientId) {
            ing.isChecked = isChecked;
            return 1;
          }
        }
        for (var ing in pack.storeCupboardStaples) {
          if (ing.id == ingredientId) {
            ing.isChecked = isChecked;
            return 1;
          }
        }
        for (var recipe in pack.recipes) {
          for (var ing in recipe.recipeSpecificIngredients) {
            if (ing.id == ingredientId) {
              ing.isChecked = isChecked;
              return 1;
            }
          }
        }
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'ingredients',
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [ingredientId],
    );
  }

  Future<int> uncheckAllIngredients(int mealPackId) async {
    if (kIsWeb) {
      for (var pack in _webInMemoryPacks) {
        if (pack.id == mealPackId) {
          for (var ing in pack.sharedFreshIngredients) {
            ing.isChecked = false;
          }
          for (var ing in pack.storeCupboardStaples) {
            ing.isChecked = false;
          }
          for (var recipe in pack.recipes) {
            for (var ing in recipe.recipeSpecificIngredients) {
              ing.isChecked = false;
            }
          }
          return 1;
        }
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'ingredients',
      {'is_checked': 0},
      where: 'meal_pack_id = ?',
      whereArgs: [mealPackId],
    );
  }

  Future<int> deleteMealPack(int id) async {
    if (kIsWeb) {
      _webInMemoryPacks.removeWhere((pack) => pack.id == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      'meal_packs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateRecipeSavedState(int recipeId, bool isSaved) async {
    final now = DateTime.now();
    if (kIsWeb) {
      for (var pack in _webInMemoryPacks) {
        for (int i = 0; i < pack.recipes.length; i++) {
          if (pack.recipes[i].id == recipeId) {
            pack.recipes[i] = pack.recipes[i].copyWith(
              isSaved: isSaved,
              savedAt: isSaved ? now : null,
              clearSavedAt: !isSaved,
            );
            return 1;
          }
        }
      }
      return 0;
    }

    final db = await database;
    return await db.update(
      'recipes',
      {
        'is_saved': isSaved ? 1 : 0,
        'saved_at': isSaved ? now.toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<List<Recipe>> getSavedRecipes() async {
    if (kIsWeb) {
      final List<Recipe> saved = [];
      for (var pack in _webInMemoryPacks) {
        for (var recipe in pack.recipes) {
          if (recipe.isSaved) {
            saved.add(recipe);
          }
        }
      }
      saved.sort((a, b) {
        final aDate = a.savedAt ?? DateTime(0);
        final bDate = b.savedAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      return saved;
    }

    final db = await database;
    final recipesMaps = await db.query(
      'recipes',
      where: 'is_saved = 1',
      orderBy: 'saved_at DESC',
    );
    final List<Recipe> saved = [];
    for (var rMap in recipesMaps) {
      final recipeId = rMap['id'] as int;
      final ingredientsMaps = await db.query(
        'ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
      );
      final List<Ingredient> ingredients = ingredientsMaps.map((m) => Ingredient.fromMap(m)).toList();
      saved.add(Recipe.fromMap(rMap, ingredients));
    }
    return saved;
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await database;
    db.close();
  }

  // Pantry Items List (In-memory fallback for Web/testing)
  final List<String> _webInMemoryPantry = [];

  Future<List<String>> getPantryItems() async {
    if (kIsWeb) {
      return List.from(_webInMemoryPantry);
    }
    final db = await database;
    final maps = await db.query('pantry_items', orderBy: 'name ASC');
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<void> addPantryItem(String name) async {
    final cleanName = name.trim().toLowerCase();
    if (cleanName.isEmpty) return;

    if (kIsWeb) {
      if (!_webInMemoryPantry.contains(cleanName)) {
        _webInMemoryPantry.add(cleanName);
      }
      return;
    }
    final db = await database;
    await db.insert(
      'pantry_items',
      {'name': cleanName},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deletePantryItem(String name) async {
    final cleanName = name.trim().toLowerCase();
    if (kIsWeb) {
      _webInMemoryPantry.remove(cleanName);
      return;
    }
    final db = await database;
    await db.delete(
      'pantry_items',
      where: 'name = ?',
      whereArgs: [cleanName],
    );
  }
}
