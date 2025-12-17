import 'package:funlearn_client/data/models/deck.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as databaseFactoryFfi;

import 'models/flashcard.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  final String dbPath;
  DatabaseHelper._internal(this.dbPath);

  static Database? _database;

  factory DatabaseHelper({required String dbPath}) {
    _instance ??= DatabaseHelper._internal(dbPath);
    return _instance!;
  }
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFolder = await getDatabasesPath();
    final path = join(dbFolder, dbPath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Deck(
        deckId INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
  CREATE TABLE Card(
    cardId INTEGER PRIMARY KEY AUTOINCREMENT,
    deckId INTEGER NOT NULL,
    front TEXT NOT NULL,
    back TEXT NOT NULL,
    --FSRS attributes
    state INTEGER,       
    step INTEGER,     
    stability REAL,      
    difficulty REAL,     
    due INTEGER,                   
    lastReview INTEGER,  
    FOREIGN KEY(deckId) REFERENCES Deck(deckId) ON DELETE CASCADE
  )
''');

  }
  Future<int> deleteCard(int cardId) async{
    final db = await _instance!.database;
    return await db.delete('Card',
        where: 'cardId = ?',
        whereArgs: [cardId]);
  }
  Future<int> updateCard(Flashcard card) async{
    final db = await _instance!.database;
    return await db.update('Card',
        card.toMap(),
        where: 'cardId = ?',
        whereArgs: [card.cardId]);
  }
  Future<int> insertCard(Flashcard card) async {
    final db = await _instance!.database;
    return await db.insert('Card', card.toMap());
  }

  Future<List<Flashcard>> getCardsByDeck(int deckId) async {
    final db = await _instance!.database;
    final maps = await db.query(
      'Card',
      where: 'deckId = ?',
      whereArgs: [deckId],
    );
    return List.generate(
      maps.length,
          (i) => Flashcard.fromMap(maps[i]),
    );
  }

  Future<int> insertDeck(Deck deck) async {
    final db = await _instance!.database;
    return await db.insert('Deck', deck.toMap());
  }

  Future<List<Deck>> getDecks() async {
    final db = await _instance!.database;
    final maps = await db.query('Deck');
    return maps.map((map) => Deck.fromMap(map)).toList();
  }
  Future<Deck?> getDeck(int deckId) async {
    final db = await _instance!.database;
    final deck = await db.query('Deck',
        where: 'deckId = ?',
        whereArgs: [deckId]);

    if (deck.isNotEmpty) {
      return Deck.fromMap(deck.first);
    } else {
      return null;
    }
  }
  Future<Flashcard?> getCard(int cardId) async {
    final db = await _instance!.database;
    final card = await db.query('Card',
        where: 'cardId = ?',
        whereArgs: [cardId]);

    if (card.isNotEmpty) {
      return Flashcard.fromMap(card.first);
    } else {
      return null;
    }
  }
  Future<int> deleteDeck(int deckId) async{
    final db = await _instance!.database;
    return await db.delete('Deck',
        where: 'deckId = ?',
        whereArgs: [deckId]);
  }
  Future<int> updateDeck(Deck deck) async{
    final db = await _instance!.database;
    return await db.update('Deck',
        deck.toMap(),
        where: 'deckId = ?',
        whereArgs: [deck.deckId]);
  }
  Future<void> resetDatabase() async {
    final dbFolder = await getDatabasesPath();
    final path = join(dbFolder, dbPath);

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    await deleteDatabase(path);

    _database = await _initDatabase();
  }
  Future<List<Flashcard>> fetchDueCards(int deckId) async {
    final db = await database;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final maps = await db.query(
      'Card',
      where: 'deckId = ? AND due <= ?',
      whereArgs: [deckId, now],
      orderBy: 'due ASC',
    );

    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }
  Future<void> closeDatabase() async{
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

}