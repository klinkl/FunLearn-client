import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/learningController.dart';
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/studySessionController.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/serverApi/usersApi.dart';
import 'package:funlearn_client/data/serverApi/studySessionApi.dart';
import 'package:funlearn_client/data/serverApi/questApi.dart';
import 'package:funlearn_client/data/models/modelQuest.dart';

class FakeUsersApi implements UsersApi {
  final Map<String, User> _remote = {};
  bool throwOnGet = false;

  void reset() {
    _remote.clear();
    throwOnGet = false;
  }

  void seedUser(User u) => _remote[u.userId] = u;

  @override
  Future<User> getUserById(String id) async {
    if (throwOnGet) throw Exception('Server down');
    final u = _remote[id];
    if (u == null) throw Exception('404');
    return u;
  }

  @override
  Future<List<User>> getAllUsers() async => _remote.values.toList();

  @override
  Future<void> createUser(User user) async {
    _remote[user.userId] = user;
  }

  @override
  Future<void> updateUser(User user) async {
    _remote[user.userId] = user;
  }
}

class FakeStudySessionApi implements IStudySessionApi {
  bool throwOnCreate = false;
  final List<String> receivedIds = [];

  void reset() {
    throwOnCreate = false;
    receivedIds.clear();
  }

  @override
  Future<void> createStudySession(StudySession session) async {
    if (throwOnCreate) throw Exception('Server down');
    receivedIds.add(session.studySessionId ?? '');
  }
}

class FakeQuestsApi implements IQuestsApi {
  bool throwOnGet = false;

  void reset() {
    throwOnGet = false;
  }

  @override
  Future<List<ModelQuest>> getQuestsByUserId(String userId) async {
    if (throwOnGet) throw Exception('Server down');
    return <ModelQuest>[];
  }

  @override
  Future<ModelQuest> getQuestById(String questId) async {
    if (throwOnGet) throw Exception('Server down');
    throw Exception('Not implemented');
  }

  @override
  Future<void> createQuest(ModelQuest quest) async {
    if (throwOnGet) throw Exception('Server down');
  }

  @override
  Future<void> updateQuest(ModelQuest quest) async {
    if (throwOnGet) throw Exception('Server down');
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const path = 'learningController_test.db';

  late DatabaseHelper dbHelper;

  late FakeUsersApi fakeUsersApi;
  late FakeStudySessionApi fakeStudySessionApi;
  late FakeQuestsApi fakeQuestsApi;

  late UserController userController;
  late LearningController controller;

  setUp(() async {
    await DatabaseHelper.resetInstanceForTest();
    LearningController.resetInstanceForTest();
    StudySessionController.resetInstanceForTest();
    UserController.resetInstanceForTest();
    QuestController.resetInstanceForTest();

    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();

    fakeUsersApi = FakeUsersApi()..reset();
    fakeStudySessionApi = FakeStudySessionApi()..reset();
    fakeQuestsApi = FakeQuestsApi()..reset();

    final user = User();
    await dbHelper.insertUser(user);
    fakeUsersApi.seedUser(user);

    userController = UserController.getInstance(dbHelper, fakeUsersApi);

    controller = LearningController.getInstance(
      dbHelper,
      userController,
      fakeStudySessionApi,
      fakeQuestsApi,
    );
    await controller.init();

    final sessionController = StudySessionController.getInstance(
      dbHelper,
      userController,
      fakeStudySessionApi,
    );
    sessionController.setUserIdForTest(user.userId);
  });

  tearDown(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });

  test('updates card in database after review', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");

    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);

    await controller.reviewCard(card, Rating.good);

    final updatedCard = await dbHelper.getCard(1);
    expect(updatedCard?.lastReview, isNotNull);
  });

  test('returns first card when due cards exist', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(
      cardId: 1,
      deckId: 1,
      front: "Test",
      back: "Apple",
      due: DateTime.now().toUtc(),
    );

    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);

    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNotNull);
  });

  test('returns null when no due cards exist', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");

    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);

    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNull);
  });

  test('returns earliest due card when multiple cards are due', () async {
    final deck = Deck(deckId: 1, name: "name");
    final now = DateTime.now().toUtc();

    final card1 = Flashcard(
      cardId: 1,
      deckId: 1,
      front: "Test",
      back: "Apple",
      due: now,
    );
    final card2 = Flashcard(
      cardId: 2,
      deckId: 1,
      front: "Pear",
      back: "Test",
      due: now,
    );

    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card1);
    await dbHelper.insertCard(card2);

    final nextCard = await controller.getNextCard(1);
    expect(nextCard?.cardId, 1);
  });

  test('does not return cards that are due in the future', () async {
    final deck = Deck(deckId: 1, name: "name");
    final utc = DateTime.now().toUtc().add(const Duration(days: 1));

    final card = Flashcard(
      cardId: 1,
      deckId: 1,
      front: "Test",
      back: "Apple",
      due: utc,
    );

    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);

    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNull);
  });

  test('reviewCard updates scheduling data for Rating.good', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");

    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);

    await controller.reviewCard(card, Rating.good);
    var updatedCard = await dbHelper.getCard(1);

    await controller.reviewCard(updatedCard!, Rating.good);
    updatedCard = await dbHelper.getCard(1);

    final difference =
        updatedCard!.due!.millisecondsSinceEpoch -
        updatedCard.lastReview!.millisecondsSinceEpoch;

    expect(difference, greaterThan(0));
  });

  test('scheduleNewCardsOnDemand correctly changes due and isNew', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");

    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);

    await controller.scheduleNewCardsOnDemand(1, 1);

    final cards = await dbHelper.fetchDueCards(1);
    expect(cards.length, 1);
    expect(cards.first.due, isNotNull);
    expect(cards.first.isNew, false);
  });

  test(
    'runDailyNewCardRelease schedules new cards when not run today',
    () async {
      final deck = Deck(deckId: 1, name: "name", maxNewCards: 32);
      await dbHelper.insertDeck(deck);

      for (int i = 0; i < 32; i++) {
        await dbHelper.insertCard(
          Flashcard(cardId: i, deckId: 1, front: "Test", back: "Apple"),
        );
      }

      final cardsBefore = await dbHelper.fetchDueCards(1);
      expect(cardsBefore.length, 0);

      await controller.runDailyNewCardRelease(1);

      final cardsAfter = await dbHelper.fetchDueCards(1);
      expect(cardsAfter.length, 32);

      final dbDeck = await dbHelper.getDeck(1);
      expect(dbDeck?.lastNewCardsRelease, isNotNull);
    },
  );
}
