import 'package:flutter/cupertino.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:funlearn_client/data/questController.dart';

import 'databaseHelper.dart';
import 'models/studySession.dart';

class StudySessionController {
  static StudySessionController? _instance;
  final DatabaseHelper helper;
  late String userId;
  late final UserController userController;
  StudySessionController._internal(this.helper);
  static StudySessionController getInstance(DatabaseHelper helper) {
    return _instance ??= StudySessionController._internal(helper);
  }
  Future<void> init() async {
    final users = await helper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    userId = users.first.userId!;
    userController = UserController.getInstance(helper);
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

  Future<(DateTime?, StudySession)> createSession(Rating rating) async {
    final xp = xpFromRating(rating);
    final cardsLearnt = cardsLearnedFromRating(rating);
    final session = StudySession(
      userId: userId,
      xp: xp,
      cardsLearnt: cardsLearnt,
      timeStamp: DateTime.now().toUtc(),
    );
    await helper.insertStudySession(session);
    final lastStudy = await userController.updateUserWithStudySession(session);
    return (lastStudy, session);
  }

  @visibleForTesting
  void setUserIdForTest(String id) {
    userId = id;
  }

}
