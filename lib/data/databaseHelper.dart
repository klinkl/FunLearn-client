import 'package:funlearn_client/data/models/deck.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as databaseFactoryFfi;

import 'models/card.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'database.db');

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
        FOREIGN KEY(deckId) REFERENCES Deck(deckId) ON DELETE CASCADE
      )
    ''');

  }
  Future<int> deleteCard(int cardId) async{
    final db = await _instance.database;
    return await db.delete('Card',
        where: 'cardId = ?',
        whereArgs: [cardId]);
  }
  Future<int> updateCard(Card card) async{
    final db = await _instance.database;
    return await db.update('Card',
        card.toMap(),
        where: 'cardId = ?',
        whereArgs: [card.cardId]);
  }
  Future<int> insertCard(Card card) async {
    final db = await _instance.database;
    return await db.insert('Card', card.toMap());
  }

  Future<List<Card>> getCardsByDeck(int deckId) async {
    final db = await _instance.database;
    final maps = await db.query('Card', where: 'deckId = ?', whereArgs: [deckId]);
    return List.generate(
      maps.length,
          (i) => Card(
        cardId: maps[i]['cardId'] as int,
        deckId: maps[i]['deckId'] as int,
        front: maps[i]['front'] as String,
        back: maps[i]['back'] as String,
      ),
    );
  }
  Future<int> insertDeck(Deck deck) async {
    final db = await _instance.database;
    return await db.insert('Deck', deck.toMap());
  }

  Future<List<Deck>> getDecks() async {
    final db = await _instance.database;
    final maps = await db.query('Deck');
    return maps.map((map) => Deck.fromMap(map)).toList();
  }
  Future<Deck?> getDeck(int deckId) async {
    final db = await _instance.database;
    final deck = await db.query('Deck',
        where: 'deckId = ?',
        whereArgs: [deckId]);

    if (deck.isNotEmpty) {
      return Deck.fromMap(deck.first);
    } else {
      return null;
    }
  }
  Future<Card?> getCard(int cardId) async {
    final db = await _instance.database;
    final card = await db.query('Card',
        where: 'cardId = ?',
        whereArgs: [cardId]);

    if (card.isNotEmpty) {
      return Card.fromMap(card.first);
    } else {
      return null;
    }
  }
  Future<int> deleteDeck(int deckId) async{
    final db = await _instance.database;
    return await db.delete('Deck',
        where: 'deckId = ?',
        whereArgs: [deckId]);
  }
  Future<int> updateDeck(Deck deck) async{
    final db = await _instance.database;
    return await db.update('Deck',
        deck.toMap(),
        where: 'deckId = ?',
        whereArgs: [deck.deckId]);
  }
}