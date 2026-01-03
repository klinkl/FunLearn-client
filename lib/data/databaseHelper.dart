import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as databaseFactoryFfi;

import 'models/modelQuest.dart';
import 'models/flashcard.dart';
import 'models/user.dart';

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
        name TEXT NOT NULL,
        maxNewCards INTEGER,
        lastNewCardsRelease INTEGER
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
    isNew INTEGER CHECK (isNew IN (0,1)),
    FOREIGN KEY(deckId) REFERENCES Deck(deckId) ON DELETE CASCADE
  )
''');

    await db.execute('''
    CREATE TABLE User (
    userId INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL DEFAULT 'User',
    totalXP INTEGER NOT NULL DEFAULT 0,
    totalCardsLearned INTEGER NOT NULL DEFAULT 0,
    currentStreak INTEGER NOT NULL DEFAULT 0,
    lastStudyDate INTEGER,
    level INTEGER NOT NULL DEFAULT 1,
    xpToNextLevel INTEGER NOT NULL DEFAULT 25
);
''');
    await db.execute('''
    CREATE TABLE StudySession (
    timeStamp INTEGER NOT NULL,
    userId INTEGER NOT NULL,
    xp INTEGER NOT NULL,
    cardsLearnt INTEGER NOT NULL,
    PRIMARY KEY (timeStamp, userId),
    FOREIGN KEY (userId) REFERENCES User(userId) ON DELETE CASCADE
);
    ''');
    await db.execute('''
    CREATE TABLE ModelQuest (
    questId TEXT PRIMARY KEY,
    userIds TEXT NOT NULL,
    questType TEXT NOT NULL,
    startDate INTEGER NOT NULL,
    expiryDate INTEGER NOT NULL,
    currentValue INTEGER NOT NULL DEFAULT 0,
    requestedValue INTEGER NOT NULL,
    finished INTEGER CHECK (finished IN (0,1)),
    friendsQuest INTEGER CHECK (friendsQuest IN (0,1))
);
    ''');
  }

  Future<int> insertStudySession(StudySession studySession) async {
    final db = await _instance!.database;
    return await db.insert('StudySession', studySession.toMap());
  }

  Future<List<StudySession>> getStudySessionWithinTime(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _instance!.database;
    final startMs = start.toUtc().millisecondsSinceEpoch;
    final endMs = end.toUtc().millisecondsSinceEpoch;
    final maps = await db.query(
      'StudySession',
      where: 'userId = ? AND timeStamp BETWEEN ? AND ?',
      whereArgs: [userId, startMs, endMs],
      orderBy: 'timeStamp ASC',
    );

    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  Future<User?> getUserById(int userId) async {
    final db = await _instance!.database;
    final user = await db.query(
      'User',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (user.isNotEmpty) {
      return User.fromMap(user.first);
    } else {
      return null;
    }
  }

  Future<List<ModelQuest>> getAllQuestsByUser(int userId) async {
    final db = await _instance!.database;
    final maps = await db.rawQuery(
      '''
  SELECT * FROM ModelQuest
  WHERE EXISTS (
    SELECT 1 FROM json_each(userIds) WHERE json_each.value = ?
  )
  ''',
      [userId],
    );
    return maps.map((map) => ModelQuest.fromMap(map)).toList();
  }

  Future<List<ModelQuest>> getAllQuests() async {
    final db = await _instance!.database;
    final maps = await db.query('ModelQuest');
    return maps.map((map) => ModelQuest.fromMap(map)).toList();
  }

  Future<int> insertQuest(ModelQuest quest) async {
    final db = await _instance!.database;
    return await db.insert('ModelQuest', quest.toMap());
  }

  Future<int> deleteQuest(String questId) async {
    final db = await _instance!.database;
    return await db.delete('ModelQuest', where: 'questId = ?', whereArgs: [questId]);
  }

  Future<int> updateQuest(ModelQuest quest) async {
    final db = await _instance!.database;
    return await db.update(
      'ModelQuest',
      quest.toMap(),
      where: 'questId = ?',
      whereArgs: [quest.questId],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await _instance!.database;
    final maps = await db.query('User');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> insertUser(User user) async {
    final db = await _instance!.database;
    return await db.insert('User', user.toMap());
  }

  Future<int> deleteUser(int userId) async {
    final db = await _instance!.database;
    return await db.delete('User', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> updateUser(User user) async {
    final db = await _instance!.database;
    return await db.update(
      'User',
      user.toMap(),
      where: 'userId = ?',
      whereArgs: [user.userId],
    );
  }

  Future<int> deleteCard(int cardId) async {
    final db = await _instance!.database;
    return await db.delete('Card', where: 'cardId = ?', whereArgs: [cardId]);
  }

  Future<int> updateCard(Flashcard card) async {
    final db = await _instance!.database;
    return await db.update(
      'Card',
      card.toMap(),
      where: 'cardId = ?',
      whereArgs: [card.cardId],
    );
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
    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
  }

  Future<List<Flashcard>> getNewCardsByDeck(int deckId) async {
    final db = await _instance!.database;
    final maps = await db.query(
      'Card',
      where: 'deckId = ? AND isNew = 1',
      whereArgs: [deckId],
    );
    return List.generate(maps.length, (i) => Flashcard.fromMap(maps[i]));
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
    final deck = await db.query(
      'Deck',
      where: 'deckId = ?',
      whereArgs: [deckId],
    );

    if (deck.isNotEmpty) {
      return Deck.fromMap(deck.first);
    } else {
      return null;
    }
  }

  Future<Flashcard?> getCard(int cardId) async {
    final db = await _instance!.database;
    final card = await db.query(
      'Card',
      where: 'cardId = ?',
      whereArgs: [cardId],
    );

    if (card.isNotEmpty) {
      return Flashcard.fromMap(card.first);
    } else {
      return null;
    }
  }

  Future<int> deleteDeck(int deckId) async {
    final db = await _instance!.database;
    return await db.delete('Deck', where: 'deckId = ?', whereArgs: [deckId]);
  }

  Future<int> updateDeck(Deck deck) async {
    final db = await _instance!.database;
    return await db.update(
      'Deck',
      deck.toMap(),
      where: 'deckId = ?',
      whereArgs: [deck.deckId],
    );
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

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
