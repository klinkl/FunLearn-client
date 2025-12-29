import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/learningController.dart';
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'apkgImport_test.dart';

void main() {
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late LearningController controller;
  final path = 'learningController_test.db';
  setUp(() async {
    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();
    controller = LearningController(DatabaseHelper(dbPath: path));
  });
  tearDown(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });
  test('updates card in database after review', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    await dbHelper.insertDeck(deck);
    final index = await dbHelper.insertCard(card);
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
      due: DateTime.now(),
    );
    await dbHelper.insertDeck(deck);
    final index = await dbHelper.insertCard(card);
    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNotNull);
  });
  test('returns null when no due cards exist', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    await dbHelper.insertDeck(deck);
    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNull);
  });
  test('returns earliest due card when multiple cards are due', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(
      cardId: 1,
      deckId: 1,
      front: "Test",
      back: "Apple",
      due: DateTime.now(),
    );
    final card2 = Flashcard(
      cardId: 2,
      deckId: 1,
      front: "Pear",
      back: "Test",
      due: DateTime.now(),
    );
    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);
    await dbHelper.insertCard(card2);
    final nextCard = await controller.getNextCard(1);
    expect(nextCard?.toMap(), card.toMap());
  });
  test('does not return cards that are due in the future', () async {
    final deck = Deck(deckId: 1, name: "name");
    final time = DateTime.now().toUtc().millisecondsSinceEpoch + 100000;
    final utc = DateTime.fromMillisecondsSinceEpoch(time, isUtc: true);
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
  test('reviewCard updates card scheduling data for Rating.good', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    await dbHelper.insertDeck(deck);
    final index = await dbHelper.insertCard(card);
    await controller.reviewCard(card, Rating.good);
    var updatedCard = await dbHelper.getCard(1);
    await controller.reviewCard(updatedCard!, Rating.good);
    updatedCard = await dbHelper.getCard(1);
    final difference =
        updatedCard!.due!.millisecondsSinceEpoch -
        updatedCard!.lastReview!.millisecondsSinceEpoch;
    expect(difference, greaterThan(0));
  });
  test(
    'reviewCard schedules card later for Rating.easy than Rating.good',
    () async {
      final deck = Deck(deckId: 1, name: "name");
      final card = Flashcard(
        cardId: 1,
        deckId: 1,
        front: "Test",
        back: "Apple",
      );
      final card2 = Flashcard(
        cardId: 2,
        deckId: 1,
        front: "Pear",
        back: "Test",
      );
      await dbHelper.insertDeck(deck);
      final index = await dbHelper.insertCard(card);
      await dbHelper.insertCard(card2);
      await controller.reviewCard(card2, Rating.again);
      await controller.reviewCard(card, Rating.good);
      final updatedCard = await dbHelper.getCard(1);
      final updatedCard2 = await dbHelper.getCard(2);
      expect(
        updatedCard2?.due?.millisecondsSinceEpoch,
        lessThan(updatedCard!.due!.millisecondsSinceEpoch),
      );
    },
  );
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
  test('scheduleNewCardsOnDemand only sets first x cards to due', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    final card2 = Flashcard(cardId: 2, deckId: 1, front: "Pear", back: "Test");
    final card3 = Flashcard(
      cardId: 3,
      deckId: 1,
      front: "Pineapple",
      back: "Test",
    );
    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);
    await dbHelper.insertCard(card2);
    await dbHelper.insertCard(card3);
    await controller.scheduleNewCardsOnDemand(1, 2);
    final cards = await dbHelper.fetchDueCards(1);
    expect(cards.length, 2);
    expect(cards.first.due, isNotNull);
    expect(cards.last.due, isNotNull);
  });
  test('scheduleNewCardsOnDemand amount > amount of cards in deck', () async {
    final deck = Deck(deckId: 1, name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    final card2 = Flashcard(cardId: 2, deckId: 1, front: "Pear", back: "Test");
    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);
    await dbHelper.insertCard(card2);
    //expect function to just take max size available
    await controller.scheduleNewCardsOnDemand(1, 3);
    final cards = await dbHelper.fetchDueCards(1);
    expect(cards.length, 2);
  });

  test('scheduleNewCards schedules up to maxNewCards', () async {
    final deck = Deck(deckId: 1, name: "name");
    await dbHelper.insertDeck(deck);
    for (int i = 0; i < 32; i++) {
      await dbHelper.insertCard(
        Flashcard(
          cardId: i,
          deckId: 1,
          front: "Test",
          back: "Apple",
          isNew: true,
        ),
      );
    }
    final cards = await dbHelper.fetchDueCards(1);
    expect(cards.length, 0);
    await controller.scheduleNewCards(1);
    final cards2 = await dbHelper.fetchDueCards(1);
    expect(cards2.length, 32);
  });

  test(
    'scheduleNewCards reduces scheduled count by already released new cards',
    () async {
      final deck = Deck(deckId: 1, name: "name");
      await dbHelper.insertDeck(deck);
      for (int i = 0; i < 16; i++) {
        await dbHelper.insertCard(
          Flashcard(
            cardId: i,
            deckId: 1,
            front: "Test",
            back: "Apple",
            isNew: false,
            due: DateTime.now(),
          ),
        );
      }
      for (int i = 16; i < 48; i++) {
        await dbHelper.insertCard(
          Flashcard(
            cardId: i,
            deckId: 1,
            front: "Test",
            back: "Apple",
            isNew: true,
          ),
        );
      }
      final cards = await dbHelper.fetchDueCards(1);
      expect(cards.length, 16);
      await controller.scheduleNewCards(1);
      final cards2 = await dbHelper.fetchDueCards(1);
      expect(cards2.length, 32);
    },
  );

  test(
    'scheduleNewCards does not schedule new cards when daily limit is reached',
    () async {
      final deck = Deck(deckId: 1, name: "name");
      await dbHelper.insertDeck(deck);
      for (int i = 0; i < 32; i++) {
        await dbHelper.insertCard(
          Flashcard(
            cardId: i,
            deckId: 1,
            front: "Test",
            back: "Apple",
            isNew: false,
            due: DateTime.now(),
          ),
        );
      }
      for (int i = 32; i < 64; i++) {
        await dbHelper.insertCard(
          Flashcard(
            cardId: i,
            deckId: 1,
            front: "Test",
            back: "Apple",
            isNew: true,
          ),
        );
        final cards = await dbHelper.fetchDueCards(1);
        expect(cards.length, 32);
        await controller.scheduleNewCards(1);
        final cards2 = await dbHelper.fetchDueCards(1);
        expect(cards.length, cards2.length);
      }
    },
  );
  test(
    'runDailyNewCardRelease schedules new cards when not run today',
    () async {
      final deck = Deck(deckId: 1, name: "name");
      await dbHelper.insertDeck(deck);
      for (int i = 0; i < 32; i++) {
        await dbHelper.insertCard(
          Flashcard(cardId: i, deckId: 1, front: "Test", back: "Apple"),
        );
      }
      final cards = await dbHelper.fetchDueCards(1);
      expect(cards.length, 0);
      await controller.runDailyNewCardRelease(1);
      final cards2 = await dbHelper.fetchDueCards(1);
      expect(cards2.length, 32);
      final dbDeck = await dbHelper.getDeck(1);
      expect(dbDeck?.lastNewCardsRelease, isNotNull);
    },
  );
  test(
    'runDailyNewCardRelease does not update deck when already run today',
    () async {
      final deck = Deck(
        deckId: 1,
        name: "name",
        lastNewCardsRelease: DateTime.now(),
      );
      await dbHelper.insertDeck(deck);
      for (int i = 0; i < 32; i++) {
        await dbHelper.insertCard(
          Flashcard(cardId: i, deckId: 1, front: "Test", back: "Apple"),
        );
      }
      final cards = await dbHelper.fetchDueCards(1);
      expect(cards.length, 0);
      await controller.runDailyNewCardRelease(1);
      final cards2 = await dbHelper.fetchDueCards(1);
      expect(cards2.length, 0);
    },
  );
}
