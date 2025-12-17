import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import 'package:funlearn_client/data/models/deck.dart';

void main() {
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper(dbPath: 'testDatabase.db');
    final db = await dbHelper.database;
    await db.delete('Card');
    await db.delete('Deck');
    //for auto-increment
    await db.execute("DELETE FROM sqlite_sequence WHERE name='Deck'");
    await db.execute("DELETE FROM sqlite_sequence WHERE name='Card'");
  });


  group('Deck tests', () {
    test('Insert deck', () async {
      final id = await dbHelper.insertDeck(Deck(name: "Test Deck"));
      expect(id, isNonZero);
    });
    test('Get decks', () async{
      await dbHelper.insertDeck(Deck(name: "Test Deck A"));
      await dbHelper.insertDeck(Deck(name: "Test Deck B"));
      final List<Deck> decks = await dbHelper.getDecks();
      expect(decks.length, 2);
      expect(decks.first.name, "Test Deck A");
      expect(decks.last.name, "Test Deck B");
    });
    test('Get deck', () async{
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
    test('Delete deck', () async{
      await dbHelper.insertDeck(Deck(name: "Test Deck A"));
      await dbHelper.insertDeck(Deck(name: "Test Deck B"));
      await dbHelper.deleteDeck(1);
      final List<Deck> decks = await dbHelper.getDecks();
      expect(decks.length, 1);
      expect(decks.first.name, "Test Deck B");
      expect(decks.first.deckId, 2);
    });
    test('Get non-existent deck', () async{
      final deck = await dbHelper.getDeck(999);
      expect(deck, null);
    });
    test('Inserting decks with same deckId', () async{
      await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck A"));
      try {
        await dbHelper.insertDeck(Deck(deckId: 1, name: "Test Deck B"));
        fail('Inserting a deck with a pre-existing deckId should throw an exception');
      } catch (e) {
        expect(e, isA<DatabaseException>());
      }
    });
  });

  group('Card tests', () {
    test('Insert Card', () async{
      await dbHelper.insertDeck(Deck(deckId: 1,name: "Test Deck A"));
      await dbHelper.insertCard(Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"));
      final card = await dbHelper.getCard(1);
      expect(card?.back, "Back");
      expect(card?.front, "Front");
      expect(card?.cardId, 1);
    });
    test('Get Cards', () async{
      await dbHelper.insertDeck(Deck(deckId: 1,name: "Test Deck A"));
      await dbHelper.insertCard(Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"));
      await dbHelper.insertCard(Flashcard(cardId: 2, deckId: 1, front: "Front2", back: "Back2"));
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
    test('Delete Card', () async{
      await dbHelper.insertDeck(Deck(deckId: 1,name: "Test Deck A"));
      await dbHelper.insertCard(Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"));
      await dbHelper.insertCard(Flashcard(cardId: 2, deckId: 1, front: "Front2", back: "Back2"));
      await dbHelper.deleteCard(1);
      final cards = await dbHelper.getCardsByDeck(1);
      expect(cards.length, 1);
      expect(cards.first.front, "Front2");
    });
    test('Update Card', ()async{
      await dbHelper.insertDeck(Deck(deckId: 1,name: "Test Deck A"));
      await dbHelper.insertCard(Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"));
      await dbHelper.updateCard(Flashcard(cardId: 1, deckId: 1, front: "New", back: "New"));
      final card = await dbHelper.getCard(1);
      expect(card?.back, "New");
      expect(card?.front, "New");
    });
    test('Cascading card deletion on deck deletion', () async{
      final deckId = await dbHelper.insertDeck(Deck(deckId: 1,name: "Test Deck A"));
      await dbHelper.insertCard(Flashcard(cardId: 1, deckId: 1, front: "Front", back: "Back"));
      await dbHelper.insertCard(Flashcard(cardId: 2, deckId: 1, front: "Front2", back: "Back2"));
      await dbHelper.deleteDeck(deckId);
      final deletedDeck = await dbHelper.getDeck(deckId);
      expect(deletedDeck, isNull);
      final cards = await dbHelper.getCardsByDeck(deckId);
      expect(cards.length, 0);
    });
    test('Insert card with invalid deckId', () async {
      try {
        await dbHelper.insertCard(Flashcard(deckId: 999, front: "Invalid", back: "Invalid"));
        fail('Inserting a card with a non-existent deckId should throw an exception');
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
  });
}
