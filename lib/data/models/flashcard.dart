import 'package:fsrs/fsrs.dart';

import '../databaseHelper.dart';

class Flashcard {
  int? cardId;
  int deckId;
  String front;
  String back;
  bool isNew;
  State state;
  int? step;
  double? stability;
  double? difficulty;
  DateTime? due;
  DateTime? lastReview;

  Flashcard({
    this.cardId,
    required this.deckId,
    required this.front,
    required this.back,
    this.due,
    this.state = State.learning,
    this.step,
    this.stability,
    this.difficulty,
    this.lastReview,
    bool? isNew,
  }) : isNew = isNew ?? true
  {
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
      'due': due?.millisecondsSinceEpoch,
      'lastReview': lastReview?.millisecondsSinceEpoch,
      'isNew': isNew ? 1 : 0,
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
      isNew: map['isNew'] == 0 ? false : true
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
