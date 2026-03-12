import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes_v5.db'); // Versi baru untuk tabel users
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // Reset ke 1 atau naikkan jika sudah ada db lama
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. TABLE RECIPES
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        imageUrl TEXT,
        description TEXT NOT NULL,
        instructions TEXT NOT NULL,
        calories INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        rating REAL NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    // 2. TABLE FAVORITES
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_uid TEXT NOT NULL,
        recipe_id INTEGER NOT NULL,
        created_at TEXT,
        UNIQUE(user_uid, recipe_id)
      )
    ''');

    // 3. TABLE USERS (Fitur Baru)
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        created_at TEXT
      )
    ''');
  }

  // =================== USER MANAGEMENT ===================

  // Simpan user saat berhasil Signup
  Future<void> saveUser(String uid, String email) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'uid': uid,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Ambil total user yang terdaftar
  Future<int> getTotalUserCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // =================== FAVORITE ===================

  Future<void> addFavorite(String uid, int recipeId) async {
    final db = await database;
    final id = await db.insert(
      'favorites',
      {
        'user_uid': uid,
        'recipe_id': recipeId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    print("Hasil Insert Favorit ID: $id");
  }

  Future<void> removeFavorite(String uid, int recipeId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'user_uid = ? AND recipe_id = ?',
      whereArgs: [uid, recipeId],
    );
  }

  Future<bool> isFavorite(String uid, int recipeId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'user_uid = ? AND recipe_id = ?',
      whereArgs: [uid, recipeId],
    );
    return result.isNotEmpty;
  }

  Future<List<Recipe>> getFavoriteRecipes(String uid) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT r.*
      FROM recipes r
      INNER JOIN favorites f ON r.id = f.recipe_id
      WHERE f.user_uid = ?
      ORDER BY f.created_at DESC
    ''', [uid]);
    return result.map((e) => Recipe.fromJson(e)).toList();
  }

  // =================== CRUD RECIPES ===================

  Future<Recipe> create(Recipe recipe) async {
    final db = await database;
    final id = await db.insert('recipes', recipe.toJson()..remove('id'));
    return recipe.copy(id: id);
  }

  Future<int> update(Recipe recipeData) async {
    final db = await database;
    return await db.update(
      'recipes',
      recipeData.toJson(),
      where: 'id = ?',
      whereArgs: [recipeData.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    await db.delete('favorites', where: 'recipe_id = ?', whereArgs: [id]);
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recipe>> readAllRecipesPublic() async {
    final db = await database;
    final result = await db.query('recipes');
    return result.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<int>> getFavoriteRecipeIds(String uid) async {
    final db = await database;
    final result = await db.query('favorites', where: 'user_uid = ?', whereArgs: [uid]);
    return result.map((e) => e['recipe_id'] as int).toList();
  }

  Future<List<Recipe>> readAllRecipes(String uid) async {
    final db = await database;
    final result = await db.query('recipes', where: 'userId = ?', whereArgs: [uid]);
    return result.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<void> toggleFavoriteStatus(String uid, int recipeId, bool isFavorite) async {
    if (isFavorite) {
      await addFavorite(uid, recipeId);
    } else {
      await removeFavorite(uid, recipeId);
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}