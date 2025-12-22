import 'dart:math';

import '../databaseHelper.dart';

class Deck {
  int? deckId;
  String name;

  //max amount of new cards per day
  int maxNewCards;
  DateTime? lastNewCardsRelease;

  Deck({
    this.deckId,
    required this.name,
    this.maxNewCards = 32,
    this.lastNewCardsRelease,
  });

  Map<String, dynamic> toMap() {
    return {
      'deckId': deckId,
      'name': name,
      'maxNewCards': maxNewCards,
      'lastNewCardsRelease': lastNewCardsRelease?.millisecondsSinceEpoch,
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      deckId: map['deckId'] as int?,
      name: map['name'] as String,
      maxNewCards: map['maxNewCards'] as int,
      lastNewCardsRelease: map['lastNewCardsRelease'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['lastNewCardsRelease'],
              isUtc: true,
            )
          : null,
    );
  }
}
