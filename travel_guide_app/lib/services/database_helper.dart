import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'attractions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT CHECK(role IN ('user', 'admin')) DEFAULT 'user'
      );
    ''');

    // Cities Table
    await db.execute('''
      CREATE TABLE cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      );
    ''');

    // Attractions Table
    await db.execute('''
      CREATE TABLE attractions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT,
        FOREIGN KEY(city_id) REFERENCES cities(id) ON DELETE CASCADE
      );
    ''');

    // Comments Table
    await db.execute('''
      CREATE TABLE comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attraction_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        comment_text TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(attraction_id) REFERENCES attractions(id) ON DELETE CASCADE,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      );
    ''');

    // Visited Table
    await db.execute('''
      CREATE TABLE visited (
        user_id INTEGER NOT NULL,
        attraction_id INTEGER NOT NULL,
        visited BOOLEAN NOT NULL DEFAULT 0,
        PRIMARY KEY (user_id, attraction_id),
        FOREIGN KEY(user_id) REFERENCES users(id),
        FOREIGN KEY(attraction_id) REFERENCES attractions(id)
      );
    ''');
  }

  // -----------------------
  // Users CRUD
  // -----------------------
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUserByUsername(String username) async {
    final db = await database;
    return await db.query('users', where: 'username = ?', whereArgs: [username]);
  }

  Future<List<Map<String, dynamic>>> getUserById(int userId) async {
    final db = await database;
    return await db.query('users', where: 'id = ?', whereArgs: [userId]);
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // -----------------------
  // Cities CRUD
  // -----------------------
  Future<int> insertCity(Map<String, dynamic> city) async {
    final db = await database;
    return await db.insert('cities', city);
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final db = await database;
    return await db.query('cities');
  }

  Future<int> updateCity(int cityId, Map<String, dynamic> updatedFields) async {
    final db = await database;
    return await db.update(
      'cities',
      updatedFields,
      where: 'id = ?',
      whereArgs: [cityId],
    );
  }

  Future<int> deleteCity(int cityId) async {
    final db = await database;
    return await db.delete('cities', where: 'id = ?', whereArgs: [cityId]);
  }

  // -----------------------
  // Attractions CRUD
  // -----------------------
  Future<int> insertAttraction(Map<String, dynamic> attraction) async {
    final db = await database;
    return await db.insert('attractions', attraction);
  }

  Future<List<Map<String, dynamic>>> getAttractionsByCity(int cityId) async {
    final db = await database;
    return await db.query('attractions', where: 'city_id = ?', whereArgs: [cityId]);
  }

  Future<int> updateAttraction(int attractionId, Map<String, dynamic> updatedFields) async {
    final db = await database;
    return await db.update(
      'attractions',
      updatedFields,
      where: 'id = ?',
      whereArgs: [attractionId],
    );
  }

  Future<int> deleteAttraction(int attractionId) async {
    final db = await database;
    return await db.delete('attractions', where: 'id = ?', whereArgs: [attractionId]);
  }

  // Get a single attraction by ID
  Future<List<Map<String, dynamic>>> getAttractionById(int attractionId) async {
    final db = await database;
    return await db.query('attractions', where: 'id = ?', whereArgs: [attractionId]);
  }

  // -----------------------
  // Comments CRUD
  // -----------------------
  Future<int> insertComment(Map<String, dynamic> comment) async {
    final db = await database;
    return await db.insert('comments', comment);
  }

  Future<List<Map<String, dynamic>>> getCommentsByAttraction(int attractionId) async {
    final db = await database;
    return await db.query(
      'comments',
      where: 'attraction_id = ?',
      whereArgs: [attractionId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> updateComment(int commentId, Map<String, dynamic> updatedFields) async {
    final db = await database;
    return await db.update(
      'comments',
      updatedFields,
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  Future<int> deleteComment(int commentId) async {
    final db = await database;
    return await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
  }

  // Get comment by ID
  Future<List<Map<String, dynamic>>> getCommentById(int commentId) async {
    final db = await database;
    return await db.query('comments', where: 'id = ?', whereArgs: [commentId]);
  }

  // -----------------------
  // Visited CRUD
  // -----------------------
  Future<int> setAttractionVisited(int userId, int attractionId, bool visited) async {
    final db = await database;
    // Check if record exists
    List<Map<String, dynamic>> existing = await db.query(
      'visited',
      where: 'user_id = ? AND attraction_id = ?',
      whereArgs: [userId, attractionId],
    );

    if (existing.isEmpty) {
      // Insert new record
      return await db.insert('visited', {
        'user_id': userId,
        'attraction_id': attractionId,
        'visited': visited ? 1 : 0,
      });
    } else {
      // Update existing record
      return await db.update(
        'visited',
        {'visited': visited ? 1 : 0},
        where: 'user_id = ? AND attraction_id = ?',
        whereArgs: [userId, attractionId],
      );
    }
  }

  Future<bool> isAttractionVisitedByUser(int userId, int attractionId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'visited',
      where: 'user_id = ? AND attraction_id = ? AND visited = 1',
      whereArgs: [userId, attractionId],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getVisitedAttractionsByUser(int userId) async {
    final db = await database;
    return await db.query(
      'visited',
      where: 'user_id = ? AND visited = 1',
      whereArgs: [userId],
    );
  }
}
