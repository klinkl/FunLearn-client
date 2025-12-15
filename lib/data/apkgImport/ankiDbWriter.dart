import '../databaseHelper.dart';
import '../models/card.dart';
import '../models/deck.dart';

class AnkiDbWriter {
  final DatabaseHelper helper;

  AnkiDbWriter(this.helper);

  Future<void> save((List<Deck> deckList, List<Card> cardList) tuple) async {
    final (deckList, cardList) = tuple;
    if (deckList.isNotEmpty){
      for (var deck in deckList){
        var deckId = deck.deckId;
        final id = await helper.insertDeck(Deck(name: deck.name));
        for (var card in cardList){
          if (card.deckId == deckId){
            await helper.insertCard(
                Card(deckId: id, front: card.front, back: card.back)
            );
          }
        }
      }
    }
  }
}
