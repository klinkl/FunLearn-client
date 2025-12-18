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
    final deck = Deck(deckId: 1,name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    await dbHelper.insertDeck(deck);
    final index = await dbHelper.insertCard(card);
    await controller.reviewCard(card, Rating.good);
    final updatedCard = await dbHelper.getCard(1);
    expect(updatedCard?.lastReview, isNotNull);
  });
  test('returns first card when due cards exist', () async {
    final deck = Deck(deckId: 1,name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    await dbHelper.insertDeck(deck);
    final index = await dbHelper.insertCard(card);
    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNotNull);
  });
  test('returns null when no due cards exist', () async {
    final deck = Deck(deckId: 1,name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    await dbHelper.insertDeck(deck);
    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNull);
  });
  test('returns earliest due card when multiple cards are due', () async {
    final deck = Deck(deckId: 1,name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    final card2 = Flashcard(cardId: 2, deckId: 1, front: "Pear", back: "Test");
    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);
    await dbHelper.insertCard(card2);
    final nextCard = await controller.getNextCard(1);
    expect(nextCard?.toMap(), card.toMap());
  });
  test('does not return cards that are due in the future', () async {
    final deck = Deck(deckId: 1,name: "name");
    final time = DateTime.now().toUtc().millisecondsSinceEpoch + 100000;
    final utc = DateTime.fromMillisecondsSinceEpoch(time, isUtc: true);
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple", due: utc);
    await dbHelper.insertDeck(deck);
    await dbHelper.insertCard(card);
    final nextCard = await controller.getNextCard(1);
    expect(nextCard, isNull);
  });
  test('reviewCard updates card scheduling data for Rating.good', () async {
    final deck = Deck(deckId: 1,name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    await dbHelper.insertDeck(deck);
    final index = await dbHelper.insertCard(card);
    await controller.reviewCard(card, Rating.good);
    final updatedCard = await dbHelper.getCard(1);
    final difference = updatedCard!.due.millisecondsSinceEpoch -
        updatedCard!.lastReview!.millisecondsSinceEpoch;
    expect(difference, 600000);
  });
  test('reviewCard schedules card later for Rating.easy than Rating.good', () async {
    final deck = Deck(deckId: 1,name: "name");
    final card = Flashcard(cardId: 1, deckId: 1, front: "Test", back: "Apple");
    final card2 = Flashcard(cardId: 2, deckId: 1, front: "Pear", back: "Test");
    await dbHelper.insertDeck(deck);
    final index = await dbHelper.insertCard(card);
    await dbHelper.insertCard(card2);
    await controller.reviewCard(card2, Rating.again);
    await controller.reviewCard(card, Rating.good);
    final updatedCard = await dbHelper.getCard(1);
    final updatedCard2 = await dbHelper.getCard(2);
    expect(updatedCard2?.due.millisecondsSinceEpoch, lessThan(updatedCard!.due.millisecondsSinceEpoch));
  });
}