import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import 'package:funlearn_client/data/models/deck.dart';

class LearningController {
  final DatabaseHelper helper;
  final scheduler = Scheduler( learningSteps: [
    Duration(minutes: 0),
    Duration(minutes: 10),
  ],);

  LearningController(this.helper);

  Future<Flashcard?> getNextCard(int deckId) async {
    final dueCards = await helper.fetchDueCards(deckId);
    return dueCards.isNotEmpty ? dueCards.first : null;
  }

  Future<void> reviewCard(Flashcard card, Rating rating) async {
    final result = scheduler.reviewCard(card.toFsrsCard(card), rating);
    final updatedCard = Flashcard(
      cardId: card.cardId,
      state: result.card.state,
      deckId: card.deckId,
      front: card.front,
      back: card.back,
      stability: result.card.stability,
      difficulty: result.card.difficulty,
      due: result.card.due,
      step: result.card.step,
      lastReview: result.card.lastReview,
    );
    final timeDelta = updatedCard.due.difference(DateTime.now());
    //print(updatedCard.toMap());
    //print(timeDelta);
    await helper.updateCard(updatedCard);
  }
}
