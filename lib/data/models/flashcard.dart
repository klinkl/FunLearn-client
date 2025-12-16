import 'package:fsrs/fsrs.dart';

import '../databaseHelper.dart';

class Flashcard {
  int? cardId;
  int deckId;
  String front;
  String back;

  State state;
  int? step;
  double? stability;
  double? difficulty;
  DateTime due;
  DateTime? lastReview;

  Flashcard({
    this.cardId,
    required this.deckId,
    required this.front,
    required this.back,
    DateTime? due,
    this.state = State.learning,
    this.step,
    this.stability,
    this.difficulty,
    this.lastReview,
  }) : due = due ?? DateTime.now().toUtc() {
    if (state == State.learning && step == null) {
      step = 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'deckId': deckId,
      'front': front,
      'back': back,
      'state': state.index,
      'step': step,
      'stability': stability,
      'difficulty': difficulty,
      'due': due.millisecondsSinceEpoch,
      'lastReview': lastReview?.millisecondsSinceEpoch,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      cardId: map['cardId'] as int?,
      deckId: map['deckId'] as int,
      front: map['front'] as String,
      back: map['back'] as String,
      state: State.values[map['state'] ?? State.learning.index],
      step: map['step'],
      stability: (map['stability'])?.toDouble(),
      difficulty: (map['difficulty'])?.toDouble(),
      due: DateTime.fromMillisecondsSinceEpoch(
        map['due'] ?? DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ),
      lastReview: map['lastReview'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReview'], isUtc: true)
          : null,
    );
  }
  Card toFsrsCard(Flashcard card) {
    return Card(
      cardId: card.cardId ?? 0,
      state: card.state,
      step: card.step,
      stability: card.stability,
      difficulty: card.difficulty,
      due: card.due,
      lastReview: card.lastReview,
    );
  }
}
