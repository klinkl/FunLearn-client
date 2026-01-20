import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/studySessionController.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:funlearn_client/data/serverApi/usersApi.dart';
import 'package:funlearn_client/data/serverApi/studySessionApi.dart';

class FakeStudySessionApi implements IStudySessionApi {
  bool throwOnCreate = false;
  final List<StudySession> received = [];

  void reset() {
    throwOnCreate = false;
    received.clear();
  }

  @override
  Future<void> createStudySession(StudySession session) async {
    if (throwOnCreate) throw Exception('Server down');
    received.add(session);
  }
}

class FakeUsersApi implements UsersApi {
  final Map<String, User> _remote = {};
  bool throwOnGet = false;

  void reset() {
    _remote.clear();
    throwOnGet = false;
  }

  void seedUser(User u) => _remote[u.userId] = u;

  @override
  Future<User> getUserById(String id) async {
    if (throwOnGet) throw Exception('Server down');
    final u = _remote[id];
    if (u == null) throw Exception('404');
    return u;
  }

  @override
  Future<List<User>> getAllUsers() async {
    return _remote.values.toList();
  }

  @override
  Future<void> createUser(User user) async {
    _remote[user.userId] = user;
  }

  @override
  Future<void> updateUser(User user) async {
    _remote[user.userId] = user;
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const path = 'studySessionController_test.db';

  late DatabaseHelper dbHelper;

  late FakeUsersApi fakeUsersApi;
  late UserController userController;

  late FakeStudySessionApi fakeStudySessionApi;
  late StudySessionController controller;

  setUp(() async {
    await DatabaseHelper.resetInstanceForTest();

    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();

    fakeUsersApi = FakeUsersApi()..reset();
    fakeStudySessionApi = FakeStudySessionApi()..reset();

    final user = User();
    await dbHelper.insertUser(user);
    fakeUsersApi.seedUser(user);

    UserController.resetInstanceForTest();
    StudySessionController.resetInstanceForTest();

    userController = UserController.getInstance(dbHelper, fakeUsersApi);

    controller = StudySessionController.getInstance(
      dbHelper,
      userController,
      fakeStudySessionApi,
    );

    controller.setUserIdForTest(user.userId);
  });

  test("createSession works (online) and marks session synced", () async {
    final user = (await dbHelper.getAllUsers()).first;

    final (lastStudy1, session1) = await controller.createSession(Rating.again);
    expect(lastStudy1, isNull);

    final updatedUser1 = await dbHelper.getUserById(user.userId);
    expect(updatedUser1?.totalXP, controller.xpFromRating(Rating.again));

    final sessions1 = await dbHelper.getStudySessionWithinTime(
      user.userId,
      DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      DateTime.now().toUtc().add(const Duration(seconds: 5)),
    );
    expect(sessions1.length, 1);
    expect(sessions1.first.synced, true);

    expect(fakeStudySessionApi.received.length, 1);
    expect(
      fakeStudySessionApi.received.first.studySessionId,
      session1.studySessionId,
    );

    final (_, session2) = await controller.createSession(Rating.easy);

    final updatedUser2 = await dbHelper.getUserById(user.userId);
    expect(
      updatedUser2?.totalXP,
      controller.xpFromRating(Rating.again) +
          controller.xpFromRating(Rating.easy),
    );
    expect(
      updatedUser2?.totalCardsLearned,
      controller.cardsLearnedFromRating(Rating.easy),
    );

    final sessions2 = await dbHelper.getStudySessionWithinTime(
      user.userId,
      DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      DateTime.now().toUtc().add(const Duration(seconds: 5)),
    );
    expect(sessions2.length, 2);
    expect(sessions2.every((s) => s.synced), true);

    expect(fakeStudySessionApi.received.length, 2);
    expect(
      fakeStudySessionApi.received.last.studySessionId,
      session2.studySessionId,
    );
  });

  test(
    "createSession works offline: keeps synced=false and does not crash",
    () async {
      final user = (await dbHelper.getAllUsers()).first;

      fakeStudySessionApi.throwOnCreate = true;

      await controller.createSession(Rating.good);

      final sessions = await dbHelper.getStudySessionWithinTime(
        user.userId,
        DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        DateTime.now().toUtc().add(const Duration(seconds: 5)),
      );
      expect(sessions.length, 1);
      expect(sessions.first.synced, false);

      expect(fakeStudySessionApi.received.length, 0);
    },
  );

  test("syncPendingSessions sends pending and marks them synced", () async {
    final user = (await dbHelper.getAllUsers()).first;

    final s1 = StudySession(
      userId: user.userId,
      xp: 3,
      cardsLearnt: 1,
      timeStamp: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
      synced: false,
    );
    final s2 = StudySession(
      userId: user.userId,
      xp: 2,
      cardsLearnt: 0,
      timeStamp: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      synced: false,
    );

    await dbHelper.insertStudySession(s1);
    await dbHelper.insertStudySession(s2);

    fakeStudySessionApi.throwOnCreate = false;

    await controller.syncPendingSessions();

    final pendingAfter = await dbHelper.getPendingStudySessions();
    expect(pendingAfter.isEmpty, true);

    expect(fakeStudySessionApi.received.length, 2);
  });
}
