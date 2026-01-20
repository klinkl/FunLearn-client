import 'package:flutter_test/flutter_test.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:funlearn_client/data/serverApi/usersApi.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeUsersApi implements UsersApi {
  final Map<String, User> _remote = {};

  bool throwOnGet = false;
  bool throwOnCreate = false;
  bool throwOnUpdate = false;
  bool throwOnGetAll = false;

  void reset() {
    _remote.clear();
    throwOnGet = false;
    throwOnCreate = false;
    throwOnUpdate = false;
    throwOnGetAll = false;
  }

  void seedUser(User user) => _remote[user.userId] = user;

  @override
  Future<User> getUserById(String id) async {
    if (throwOnGet) throw Exception('Server down');
    final u = _remote[id];
    if (u == null) throw Exception('404');
    return u;
  }

  @override
  Future<List<User>> getAllUsers() async {
    if (throwOnGetAll) throw Exception('Server down');
    return _remote.values.toList();
  }

  @override
  Future<void> createUser(User user) async {
    if (throwOnCreate) throw Exception('Server down');
    _remote[user.userId] = user;
  }

  @override
  Future<void> updateUser(User user) async {
    if (throwOnUpdate) throw Exception('Server down');
    _remote[user.userId] = user;
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const path = 'userController_test.db';

  late DatabaseHelper dbHelper;
  late FakeUsersApi fakeUsersApi;
  late UserController controller;

  setUpAll(() async {
    dbHelper = DatabaseHelper(dbPath: path);
    fakeUsersApi = FakeUsersApi();

    controller = UserController.getInstance(dbHelper, fakeUsersApi);
  });

  setUp(() async {
    fakeUsersApi.reset();
    await dbHelper.resetDatabase();

    final user = User();
    await dbHelper.insertUser(user);

    fakeUsersApi.seedUser(user);
  });

  tearDownAll(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });

  test(
    "getOrCreateUser returns existing user when users already exist",
    () async {
      final user = await controller.getOrCreateUser();

      expect(user, isNotNull);
      expect(user.userId, isNotEmpty);

      final remote = await fakeUsersApi.getUserById(user.userId);
      expect(remote.userId, user.userId);
    },
  );

  test("getOrCreateUser creates new user when no users exist", () async {
    final users = await dbHelper.getAllUsers();
    for (final u in users) {
      await dbHelper.deleteUser(u.userId);
    }
    expect((await dbHelper.getAllUsers()).length, 0);

    final newUser = await controller.getOrCreateUser();
    expect(newUser.userId, isNotEmpty);

    final localUsers = await dbHelper.getAllUsers();
    expect(localUsers.length, 1);

    final remote = await fakeUsersApi.getUserById(newUser.userId);
    expect(remote.userId, newUser.userId);
  });

  test("calculateStreak tests", () async {
    var v = controller.calculateStreak(null, 0);
    expect(v, 1);

    v = controller.calculateStreak(
      DateTime.now().toUtc().subtract(const Duration(days: 2)),
      3,
    );
    expect(v, 1);

    v = controller.calculateStreak(
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
      3,
    );
    expect(v, 4);

    v = controller.calculateStreak(DateTime.now().toUtc(), 3);
    expect(v, 3);
  });

  test("calculateLevel", () async {
    final users = await dbHelper.getAllUsers();
    final user = users.first;

    final session = StudySession(
      timeStamp: DateTime.now().toUtc(),
      xp: 30,
      cardsLearnt: 2,
      userId: user.userId,
      synced: false,
    );

    final (level, xpNeeded) = controller.calculateLevel(session, user);
    expect(level, 2);
    expect(xpNeeded, 50);
  });

  test("updateUserWithStudySession updates local user correctly", () async {
    final user = (await dbHelper.getAllUsers()).first;
    final currentTime = DateTime.now().toUtc();

    final lastStudy = await controller.updateUserWithStudySession(
      StudySession(
        timeStamp: currentTime,
        xp: 30,
        cardsLearnt: 2,
        userId: user.userId,
        synced: false,
      ),
    );

    expect(lastStudy, isNull);

    final updatedUser = await dbHelper.getUserById(user.userId);
    expect(updatedUser?.totalXP, 30);
    expect(updatedUser?.level, 2);
    expect(updatedUser?.totalCardsLearned, 2);
    expect(updatedUser?.currentStreak, 1);
    expect(
      updatedUser?.lastStudyDate?.millisecondsSinceEpoch,
      currentTime.millisecondsSinceEpoch,
    );
  });

  test("refreshFromServer upserts remote user into local DB", () async {
    final localUser = (await dbHelper.getAllUsers()).first;

    final remoteUser = User(
      userId: localUser.userId,
      username: 'RemoteName',
      totalXP: 999,
      totalCardsLearned: 42,
      currentStreak: 7,
      lastStudyDate: DateTime.now().toUtc(),
      level: 40,
      xpToNextLevel: 1000,
    );
    fakeUsersApi.seedUser(remoteUser);

    final refreshed = await controller.refreshFromServer(localUser.userId);
    expect(refreshed, isNotNull);
    expect(refreshed!.username, 'RemoteName');

    final updatedLocal = await dbHelper.getUserById(localUser.userId);
    expect(updatedLocal?.username, 'RemoteName');
    expect(updatedLocal?.totalXP, 999);
  });
}
