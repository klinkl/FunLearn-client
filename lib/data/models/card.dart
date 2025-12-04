import '../databaseHelper.dart';

class Card {
  int? cardId;
  int deckId;
  String front;
  String back;

  Card({this.cardId, required this.deckId, required this.front, required this.back});

  Map<String, dynamic> toMap() {
    return {'cardId': cardId, 'deckId': deckId, 'front': front, 'back': back};
  }

  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      cardId: map['cardId'] as int?,
      deckId: map['deckId'] as int,
      front: map['front'] as String,
      back: map['back'] as String,
    );
  }
}


