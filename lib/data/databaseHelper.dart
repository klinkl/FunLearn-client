import 'package:flutter/cupertino.dart';
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE User ADD COLUMN friends TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE ModelQuest ADD COLUMN synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))",
          );
          await db.execute(
            "ALTER TABLE ModelQuest ADD COLUMN origin TEXT NOT NULL DEFAULT 'server'",
          );
        }
      },
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
    userId TEXT PRIMARY KEY,
    username TEXT NOT NULL DEFAULT 'User',
    totalXP INTEGER NOT NULL DEFAULT 0,
    totalCardsLearned INTEGER NOT NULL DEFAULT 0,
    currentStreak INTEGER NOT NULL DEFAULT 0,
    lastStudyDate INTEGER,
    level INTEGER NOT NULL DEFAULT 1,
    xpToNextLevel INTEGER NOT NULL DEFAULT 25,
    friends TEXT NOT NULL DEFAULT '[]'
);
''');
    await db.execute('''
    CREATE TABLE StudySession (
    studySessionId TEXT PRIMARY KEY,
    timeStamp INTEGER NOT NULL,
    userId TEXT NOT NULL,
    xp INTEGER NOT NULL,
    cardsLearnt INTEGER NOT NULL,
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1)),
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
    friendsQuest INTEGER CHECK (friendsQuest IN (0,1)),
    synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1)),
    origin TEXT NOT NULL DEFAULT 'server'
);
    ''');
  }

  /////////////////////////////// Study Session ////////////////////////////////

  Future<int> insertStudySession(StudySession studySession) async {
    final db = await _instance!.database;
    return await db.insert('StudySession', studySession.toMap());
  }

  Future<List<StudySession>> getStudySessionWithinTime(
    String userId,
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

  Future<List<StudySession>> getPendingStudySessions() async {
    final db = await _instance!.database;
    final maps = await db.query(
      'StudySession',
      where: 'synced = 0',
      orderBy: 'timeStamp ASC',
    );
    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  Future<int> markStudySessionSynced(String studySessionId) async {
    final db = await _instance!.database;
    return await db.update(
      'StudySession',
      {'synced': 1},
      where: 'studySessionId = ?',
      whereArgs: [studySessionId],
    );
  }

  //////////////////////////////// Quest ///////////////////////////////////////

  Future<List<ModelQuest>> getAllQuestsByUser(String userId) async {
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
    return await db.delete(
      'ModelQuest',
      where: 'questId = ?',
      whereArgs: [questId],
    );
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

  Future<int> upsertQuest(ModelQuest quest) async {
    final db = await _instance!.database;
    return await db.insert(
      'ModelQuest',
      quest.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteQuestsByUser(String userId) async {
    final db = await _instance!.database;
    return await db.rawDelete(
      '''
      DELETE FROM ModelQuest
      WHERE EXISTS (
        SELECT 1 FROM json_each(userIds) WHERE json_each.value = ?
      )
      ''',
      [userId],
    );
  }

  Future<List<ModelQuest>> getPendingClientQuests(String userId) async {
    final db = await _instance!.database;

    final maps = await db.rawQuery(
      '''
    SELECT * FROM ModelQuest
    WHERE origin = 'client' AND synced = 0
    AND EXISTS (
      SELECT 1 FROM json_each(userIds) WHERE json_each.value = ?
    )
    ''',
      [userId],
    );

    return maps.map((m) => ModelQuest.fromMap(m)).toList();
  }

  Future<int> markQuestSynced(String questId) async {
    final db = await _instance!.database;
    return db.update(
      'ModelQuest',
      {'synced': 1, 'origin': 'server'},
      where: 'questId = ?',
      whereArgs: [questId],
    );
  }

  Future<bool> hasActiveClientQuests(String userId, DateTime nowUtc) async {
    final quests = await getAllQuestsByUser(userId);
    return quests.any(
      (q) =>
          q.origin == 'client' &&
          q.synced == false &&
          !q.finished &&
          q.expiryDate.isAfter(nowUtc),
    );
  }

  //////////////////////////////// User ////////////////////////////////////////

  Future<User?> getUserById(String userId) async {
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

  Future<List<User>> getAllUsers() async {
    final db = await _instance!.database;
    final maps = await db.query('User');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> insertUser(User user) async {
    final db = await _instance!.database;
    return await db.insert('User', user.toMap());
  }

  Future<int> deleteUser(String userId) async {
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

  //insert user if it doesn't exist or update it
  Future<void> upsertUser(User user) async {
    final db = await _instance!.database;

    final insertedId = await db.insert(
      'User',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (insertedId == 0) {
      await db.update(
        'User',
        user.toMap(),
        where: 'userId = ?',
        whereArgs: [user.userId],
      );
    }
  }

  //////////////////////////////// Card/Deck ///////////////////////////////////

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

  //////////////////////////////// DataBase ////////////////////////////////////

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

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  @visibleForTesting
  static Future<void> resetInstanceForTest() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _instance = null;
  }
}
