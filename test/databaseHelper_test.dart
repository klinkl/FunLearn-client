import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funlearn_client/data/models/modelQuest.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/widgets/quest.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import 'package:funlearn_client/data/models/deck.dart';

void main() {
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  final path = 'databaseHelper_test.db';
  setUp(() async {
    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();
  });
  tearDown(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });

  group('Deck tests', () {
    test('Insert deck', () async {
      final id = await dbHelper.insertDeck(Deck(name: "Test Deck"));
      expect(id, isNonZero);
    });
    test('Get decks', () async {
      await dbHelper.insertDeck(Deck(name: "Test Deck A"));
      await dbHelper.insertDeck(Deck(name: "Test Deck B"));
      final List<Deck> decks = await dbHelper.getDecks();
      expect(decks.length, 2);
      expect(decks.first.name, "Test Deck A");
      expect(decks.last.name, "Test Deck B");
    });
    test('Get deck', () async {
      await dbHelper.insertDeck(Deck(name: "Test Deck A"));
      await dbHelper.insertDeck(Deck(name: "Test Deck B"));
      final deck = await dbHelper.getDeck(1);
      expect(deck?.name, "Test Deck A");
    });
    test('Update decks', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck A"));
      await dbHelper.updateDeck(Deck(deckId: 1, name: "Test Deck B"));
      final List<Deck> decks = await dbHelper.getDecks();
      expect(decks.length, 1);
      expect(decks.first.name, "Test Deck B");
    });
    test('Delete deck', () async {
      await dbHelper.insertDeck(Deck(name: "Test Deck A"));
      await dbHelper.insertDeck(Deck(name: "Test Deck B"));
      await dbHelper.deleteDeck(1);
      final List<Deck> decks = await dbHelper.getDecks();
      expect(decks.length, 1);
      expect(decks.first.name, "Test Deck B");
      expect(decks.first.deckId, 2);
    });
    test('Get non-existent deck', () async {
      final deck = await dbHelper.getDeck(999);
      expect(deck, null);
    });
    test('Inserting decks with same deckId', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck A"));
      try {
        await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck B"));
        fail(
          'Inserting a deck with a pre-existing deckId should throw an exception',
        );
      } catch (e) {
        expect(e, isA<DatabaseException>());
      }
    });
  });

  group('Card tests', () {
    test('Insert Card', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck A"));
      await dbHelper.insertCard(
        Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"),
      );
      final card = await dbHelper.getCard(1);
      expect(card?.back, "Back");
      expect(card?.front, "Front");
      expect(card?.cardId, 1);
    });
    test('Get Cards', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck A"));
      await dbHelper.insertCard(
        Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"),
      );
      await dbHelper.insertCard(
        Flashcard(cardId: 2, deckId: 1, front: "Front2", back: "Back2"),
      );
      final cards = await dbHelper.getCardsByDeck(1);
      expect(cards.length, 2);
      expect(cards.first.cardId, 1);
      expect(cards.first.deckId, 1);
      expect(cards.first.front, "Front");
      expect(cards.first.back, "Back");
      expect(cards.last.cardId, 2);
      expect(cards.last.deckId, 1);
      expect(cards.last.front, "Front2");
      expect(cards.last.back, "Back2");
    });
    test('Delete Card', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck A"));
      await dbHelper.insertCard(
        Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"),
      );
      await dbHelper.insertCard(
        Flashcard(cardId: 2, deckId: 1, front: "Front2", back: "Back2"),
      );
      await dbHelper.deleteCard(1);
      final cards = await dbHelper.getCardsByDeck(1);
      expect(cards.length, 1);
      expect(cards.first.front, "Front2");
    });
    test('Update Card', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck A"));
      await dbHelper.insertCard(
        Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"),
      );
      await dbHelper.updateCard(
        Flashcard(cardId: 1, deckId: 1, front: "New", back: "New"),
      );
      final card = await dbHelper.getCard(1);
      expect(card?.back, "New");
      expect(card?.front, "New");
    });
    test('Cascading card deletion on deck deletion', () async {
      final deckId = await dbHelper.insertDeck(
        Deck(deckId: 1, name: "Test Deck A"),
      );
      await dbHelper.insertCard(
        Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"),
      );
      await dbHelper.insertCard(
        Flashcard(cardId: 2, deckId: 1, front: "Front2", back: "Back2"),
      );
      await dbHelper.deleteDeck(deckId);
      final deletedDeck = await dbHelper.getDeck(deckId);
      expect(deletedDeck, isNull);
      final cards = await dbHelper.getCardsByDeck(deckId);
      expect(cards.length, 0);
    });
    test('Insert card with invalid deckId', () async {
      try {
        await dbHelper.insertCard(
          Flashcard(deckId: 999, front: "Invalid", back: "Invalid"),
        );
        fail(
          'Inserting a card with a non-existent deckId should throw an exception',
        );
      } catch (e) {
        expect(e, isA<DatabaseException>());
      }
    });
    test('Get cards for empty deck', () async {
      final deckId = await dbHelper.insertDeck(Deck(name: "Empty Deck"));
      expect(deckId, isNonZero);
      final cards = await dbHelper.getCardsByDeck(deckId);
      expect(cards, isEmpty);
    });
    test('Get new cards for deck', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "name"));
      await dbHelper.insertCard(
        Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple"),
      );
      final decks = await dbHelper.getNewCardsByDeck(1);
      expect(decks.length, 1);
    });
    test('Get new cards for deck with no new cards', () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "name"));
      await dbHelper.insertCard(
        Flashcard(
          cardId: 1,
          deckId: 1,
          front: "Test",
          back: "Apple",
          isNew: false,
        ),
      );
      final decks = await dbHelper.getNewCardsByDeck(1);
      expect(decks, isEmpty);
    });
    test("fetchDueCards works", () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "name"));
      await dbHelper.insertCard(
        Flashcard(
          cardId: 1,
          deckId: 1,
          front: "Test",
          back: "Apple",
          isNew: false,
          due: DateTime.now().toUtc(),
        ),
      );
      final decks = await dbHelper.fetchDueCards(1);
      expect(decks.length, 1);
    });
    test("fetchDueCards for no due cards", () async {
      await dbHelper.insertDeck(Deck(deckId: 1, name: "name"));
      await dbHelper.insertCard(
        Flashcard(
          cardId: 1,
          deckId: 1,
          front: "Test",
          back: "Apple",
          isNew: false,
          due: DateTime.now().toUtc().add(const Duration(hours: 2)),
        ),
      );
      final decks = await dbHelper.fetchDueCards(1);
      expect(decks.length, 0);
    });
  });
  group("StudySession tests", () {
    test("Insert study session", () async {
      final user = User();
      await dbHelper.insertUser(user);
      final row = await dbHelper.insertStudySession(
        StudySession(
          timeStamp: DateTime.now().toUtc(),
          xp: 5,
          cardsLearnt: 1,
          userId: user.userId,
        ),
      );
      expect(row, isNotNull);
    });
    test("Insert study session with no user", () async {
      try {
        final row = await dbHelper.insertStudySession(
          StudySession(
            timeStamp: DateTime.now().toUtc(),
            xp: 5,
            cardsLearnt: 1,
            userId: "ed15e150-8579-4da8-91ce-4173376c0aed",
          ),
        );
      } catch (e) {
        expect(e, isA<DatabaseException>());
      }
    });
    test("getStudySessionWithinTime works", () async {
      final user = User();
      await dbHelper.insertUser(user);
      final currentTime = DateTime.now().toUtc();
      final row = await dbHelper.insertStudySession(
        StudySession(
          timeStamp: currentTime.subtract(const Duration(hours: 1)),
          xp: 5,
          cardsLearnt: 1,
          userId: user.userId,
        ),
      );
      expect(row, isNotNull);

      final sessions = await dbHelper.getStudySessionWithinTime(
        user.userId,
        currentTime.subtract(const Duration(hours: 2)),
        currentTime,
      );
      expect(sessions.length, 1);
    });
    test(
      "getStudySessionWithinTime has no applicable study sessions",
      () async {
        final user = User();
        await dbHelper.insertUser(user);
        final currentTime = DateTime.now().toUtc();
        final row = await dbHelper.insertStudySession(
          StudySession(
            timeStamp: currentTime.subtract(const Duration(hours: 3)),
            xp: 5,
            cardsLearnt: 1,
            userId: user.userId,
          ),
        );
        expect(row, isNotNull);

        final sessions = await dbHelper.getStudySessionWithinTime(
          user.userId,
          currentTime.subtract(const Duration(hours: 2)),
          currentTime,
        );
        expect(sessions.length, 0);
      },
    );
  });
  group("User tests", () {
    test("insertUser works", () async {
      final row = await dbHelper.insertUser(User());
      expect(row, 1);
    });
    test("deleteUser works", () async {
      final user = User();
      await dbHelper.insertUser(user);
      final row = await dbHelper.deleteUser(user.userId);
      expect(row, 1);
    });
    test("deleteUser on non-existing user", () async {
      final row = await dbHelper.deleteUser(
        "ed15e150-8579-4da8-91ce-4173376c0aed",
      );
      expect(row, 0);
    });
    test("updateUser works", () async {
      final user = User();
      final row = await dbHelper.insertUser(user);
      await dbHelper.updateUser(
        User(
          userId: user.userId,
          username: user.username,
          totalCardsLearned: user.totalCardsLearned + 5,
          totalXP: 500,
          currentStreak: 20,
          lastStudyDate: DateTime.now().toUtc(),
        ),
      );
      final updatedUser = await dbHelper.getUserById(user.userId);
      expect(updatedUser?.totalXP, 500);
    });
    test("updateUser on non-existing user", () async {
      final row = await dbHelper.updateUser(
        User(userId: "ed15e150-8579-4da8-91ce-4173376c0aed"),
      );
      expect(row, 0);
    });
    test("getAllUsers works", () async {
      final user = User();
      final user2 = User();
      final row = await dbHelper.insertUser(user);
      final row2 = await dbHelper.insertUser(user2);
      final users = await dbHelper.getAllUsers();
      expect(users.length, 2);
    });
    test("getAllUsers for no users", () async {
      final users = await dbHelper.getAllUsers();
      expect(users.length, 0);
    });
    test("getUserById works", () async {
      final user = User();
      final row = await dbHelper.insertUser(user);
      final fetchedUser = await dbHelper.getUserById(user.userId);
      expect(fetchedUser?.userId, user.userId);
    });
    test("getUserById for non existing userId", () async {
      final fetchedUser = await dbHelper.getUserById(
        "ed15e150-8579-4da8-91ce-4173376c0aed",
      );
      expect(fetchedUser, isNull);
    });
  });
  group("ModelQuest tests", () {
    test("insertQuest works", () async {
      final row = await dbHelper.insertQuest(
        ModelQuest(
          userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
          questType: QuestType.XP,
          expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
          requestedValue: 100,
          friendsQuest: false,
        ),
      );
      expect(row, 1);
    });
    test("deleteQuest works", () async {
      final quest = ModelQuest(
        userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
      );
      await dbHelper.insertQuest(quest);
      final row = await dbHelper.deleteQuest(quest.questId);
      expect(row, 1);
    });
    test("deleteQuest for invalid quest", () async {
      final row = await dbHelper.deleteQuest(
        "ed15e150-8579-4da8-91ce-4173376c0aed",
      );
      expect(row, 0);
    });
    test("updateQuest works", () async {
      final quest = ModelQuest(
        userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
      );
      await dbHelper.insertQuest(quest);
      final row = await dbHelper.updateQuest(
        ModelQuest(
          userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
          questType: QuestType.XP,
          expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
          requestedValue: 100,
          currentValue: 56,
          friendsQuest: false,
          questId: quest.questId,
        ),
      );
      expect(row, 1);
      final updatedQuest = await dbHelper.getAllQuests();
      expect(updatedQuest.first.currentValue, 56);
    });
    test("updateQuest for invalid update", () async {
      final row = await dbHelper.updateQuest(
        ModelQuest(
          userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
          questType: QuestType.XP,
          expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
          requestedValue: 100,
          currentValue: 56,
          friendsQuest: false,
          questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
        ),
      );
      expect(row, 0);
    });
    test("getAllQuestsByUser works", () async {
      final quest = ModelQuest(
        userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
      );
      final quest2 = ModelQuest(
        userIds: ["82833217-03f9-41af-a8e3-dad172b4d9fe"],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
      );
      await dbHelper.insertQuest(quest);
      await dbHelper.insertQuest(quest2);
      final quests = await dbHelper.getAllQuestsByUser(
        "ed15e150-8579-4da8-91ce-4173376c0aed",
      );
      expect(quests.length, 1);
    });
    test("getAllQuestsByUser for invalid userId", () async {
      final quest = ModelQuest(
        userIds: ["82833217-03f9-41af-a8e3-dad172b4d9fe"],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
      );
      await dbHelper.insertQuest(quest);
      final quests = await dbHelper.getAllQuestsByUser(
        "ed15e150-8579-4da8-91ce-4173376c0aed",
      );
      expect(quests.length, 0);
    });
    test("getAllQuests works", () async {
      final quest = ModelQuest(
        userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
      );
      final quest2 = ModelQuest(
        userIds: ["82833217-03f9-41af-a8e3-dad172b4d9fe"],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
      );
      await dbHelper.insertQuest(quest);
      await dbHelper.insertQuest(quest2);
      final quests = await dbHelper.getAllQuests();
      expect(quests.length, 2);
    });
    test("getAllQuests for no quests", () async {
      final quests = await dbHelper.getAllQuests();
      expect(quests.length, 0);
    });
  });
}
