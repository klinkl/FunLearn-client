import '../databaseHelper.dart';

class Deck {
  int? deckId;
  String name;

  Deck({this.deckId, required this.name});

  Map<String, dynamic> toMap() {
    return {'deckId': deckId, 'name': name};
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      deckId: map['deckId'] as int?,
      name: map['name'] as String,
    );
  }
}

