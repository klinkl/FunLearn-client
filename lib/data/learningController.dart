import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/flashcard.dart';
import 'package:funlearn_client/data/models/deck.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:funlearn_client/data/studySessionController.dart';

class LearningController {
  final DatabaseHelper helper;
  final scheduler = Scheduler(
    learningSteps: [Duration(milliseconds: 0), Duration(milliseconds: 0)],
    relearningSteps: [Duration(milliseconds: 0)],
  );
  late final StudySessionController studySessionController;
  late final QuestController questController;
  LearningController(this.helper) {
    studySessionController = StudySessionController(helper);
    studySessionController.init();
    questController = QuestController(helper);
    questController.createQuestsWhenOffline();
  }

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
      isNew: false,
    );
    final timeDelta = updatedCard.due?.difference(DateTime.now());
    //print(updatedCard.toMap());
    //print(timeDelta);
    await helper.updateCard(updatedCard);

    final session = await studySessionController.createSession(rating);

    await questController.updateQuestsWithStudySession(session);
  }

  Future<void> scheduleNewCardsOnDemand(int deckId, int amount) async {
    final deck = await helper.getDeck(deckId);
    if (deck == null) return;
    final unscheduledNewCards = await helper.getNewCardsByDeck(deckId);
    if (unscheduledNewCards.isEmpty) return;
    final cardsToRelease = unscheduledNewCards.take(amount);
    for (var card in cardsToRelease) {
      final updatedCard = Flashcard(
        cardId: card.cardId,
        state: card.state,
        stability: card.stability,
        difficulty: card.difficulty,
        isNew: false,
        due: DateTime.now(),
        lastReview: card.lastReview,
        deckId: card.deckId,
        front: card.front,
        back: card.back,
      );
      await helper.updateCard(updatedCard);
    }
  }

  Future<void> scheduleNewCards(int deckId) async {
    final deck = await helper.getDeck(deckId);
    if (deck == null) return;
    var newCards = deck.maxNewCards;
    final dueCards = await helper.fetchDueCards(deckId);
    final releasedNewCards = dueCards
        .where((c) => c.lastReview == null && c.due != null)
        .toList();
    if (releasedNewCards.isNotEmpty) {
      newCards = (newCards - releasedNewCards.length);
    }
    final unscheduledNewCards = await helper.getNewCardsByDeck(deckId);
    final cardsToRelease = unscheduledNewCards.take(newCards);
    for (var card in cardsToRelease) {
      final updatedCard = Flashcard(
        cardId: card.cardId,
        state: card.state,
        stability: card.stability,
        difficulty: card.difficulty,
        isNew: false,
        due: DateTime.now(),
        lastReview: card.lastReview,
        deckId: card.deckId,
        front: card.front,
        back: card.back,
      );
      await helper.updateCard(updatedCard);
    }
  }

  Future<void> runDailyNewCardRelease(int deckId) async {
    final deck = await helper.getDeck(deckId);
    if (deck == null) return;
    final now = DateTime.now();
    final last = deck.lastNewCardsRelease;
    final alreadyRanToday =
        last != null &&
            last.year == now.year &&
            last.month == now.month &&
            last.day == now.day;
    if (!alreadyRanToday) {
      await scheduleNewCards(deckId);
      await helper.updateDeck(
        Deck(
          deckId: deck.deckId,
          name: deck.name,
          lastNewCardsRelease: DateTime.now(),
          maxNewCards: deck.maxNewCards,
        ),
      );
    }
  }
}
