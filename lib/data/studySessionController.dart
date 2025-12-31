import 'package:fsrs/fsrs.dart';

import 'databaseHelper.dart';
import 'models/studySession.dart';

class StudySessionController {
  final DatabaseHelper helper;
  late final int userId;

  StudySessionController(this.helper);

  Future<void> init() async {
    final users = await helper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    userId = users.first.userId!;
  }

  int xpFromRating(Rating rating) {
    switch (rating) {
      case Rating.again:
        return 1;
      case Rating.hard:
        return 2;
      case Rating.good:
        return 3;
      case Rating.easy:
        return 6;
    }
  }

  int cardsLearnedFromRating(Rating rating) {
    switch (rating) {
      case Rating.again:
        return 0;
      case Rating.hard:
        return 0;
      case Rating.good:
        return 1;
      case Rating.easy:
        return 1;
    }
  }

  Future<void> createSession(Rating rating) async {
    final xp = xpFromRating(rating);
    final cardsLearnt = cardsLearnedFromRating(rating);
    final session = StudySession(
      userId: userId,
      xp: xp,
      cardsLearnt: cardsLearnt,
      timeStamp: DateTime.now().toUtc(),
    );
    await helper.insertStudySession(session);
  }
}
