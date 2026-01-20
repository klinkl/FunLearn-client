import 'package:flutter/cupertino.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:funlearn_client/data/questController.dart';

import 'databaseHelper.dart';
import 'models/studySession.dart';
import './serverApi/studySessionApi.dart';

class StudySessionController {
  static StudySessionController? _instance;
  final DatabaseHelper helper;
  final UserController userController;
  final IStudySessionApi studySessionApi;

  late String userId;
  StudySessionController._internal(
    this.helper,
    this.userController,
    this.studySessionApi,
  );

  static StudySessionController getInstance(
    DatabaseHelper helper,
    UserController userController,
    IStudySessionApi studySessionApi,
  ) {
    return _instance ??= StudySessionController._internal(
      helper,
      userController,
      studySessionApi,
    );
  }

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

  Future<(DateTime?, StudySession)> createSession(Rating rating) async {
    final xp = xpFromRating(rating);
    final cardsLearnt = cardsLearnedFromRating(rating);

    final session = StudySession(
      userId: userId,
      xp: xp,
      cardsLearnt: cardsLearnt,
      timeStamp: DateTime.now().toUtc(),
      synced: false,
    );

    await helper.insertStudySession(session);

    try {
      await studySessionApi.createStudySession(session);
      await helper.markStudySessionSynced(session.studySessionId);
    } catch (_) {}

    final lastStudy = await userController.updateUserWithStudySession(session);
    return (lastStudy, session);
  }

  Future<void> syncPendingSessions() async {
    final pending = await helper.getPendingStudySessions();

    var syncedAny = false;

    for (final session in pending) {
      try {
        await studySessionApi.createStudySession(session);
        await helper.markStudySessionSynced(session.studySessionId);
        syncedAny = true;
      } catch (_) {
        break;
      }
    }

    if (syncedAny) {
      final stillPending = await helper.getPendingStudySessions();
      if (stillPending.isEmpty) {
        await userController.refreshFromServer(userId);
      }
    }
  }

  @visibleForTesting
  void setUserIdForTest(String id) {
    userId = id;
  }

  @visibleForTesting
  static void resetInstanceForTest() {
    _instance = null;
  }
}
