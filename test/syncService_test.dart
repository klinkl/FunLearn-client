import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/studySessionController.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:funlearn_client/data/sync/syncService.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:funlearn_client/data/serverApi/studySessionApi.dart';
import 'package:funlearn_client/data/serverApi/usersApi.dart';

class FakeStudySessionApi implements IStudySessionApi {
  bool online = false;
  final List<StudySession> received = [];

  @override
  Future<void> createStudySession(StudySession session) async {
    if (!online) throw Exception('No connection');
    received.add(session);
  }
}

class FakeUsersApi implements UsersApi {
  final Map<String, User> _remote = {};

  void seed(User user) => _remote[user.userId] = user;

  @override
  Future<User> getUserById(String id) async {
    final u = _remote[id];
    if (u == null) throw Exception('404');
    return u;
  }

  @override
  Future<void> createUser(User user) async {
    _remote[user.userId] = user;
  }

  @override
  Future<void> updateUser(User user) async {
    _remote[user.userId] = user;
  }

  @override
  Future<List<User>> getAllUsers() async => _remote.values.toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const path = 'syncService_test.db';

  late DatabaseHelper dbHelper;
  late FakeUsersApi fakeUsersApi;
  late FakeStudySessionApi fakeSessionApi;
  late UserController userController;
  late StudySessionController sessionController;

  late StreamController<ConnectivityResult> connectivityCtrl;
  late SyncService syncService;

  setUp(() async {
    await DatabaseHelper.resetInstanceForTest();
    StudySessionController.resetInstanceForTest();
    UserController.resetInstanceForTest();

    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();

    fakeUsersApi = FakeUsersApi();
    fakeSessionApi = FakeStudySessionApi();

    final user = User();
    await dbHelper.insertUser(user);
    fakeUsersApi.seed(user);

    userController = UserController.getInstance(dbHelper, fakeUsersApi);

    sessionController = StudySessionController.getInstance(
      dbHelper,
      userController,
      fakeSessionApi,
    );
    sessionController.setUserIdForTest(user.userId);

    connectivityCtrl = StreamController<ConnectivityResult>.broadcast();

    syncService = SyncService(
      studySessionController: sessionController,
      connectivityStream: connectivityCtrl.stream,
    );
  });

  tearDown(() async {
    await syncService.dispose();
    await connectivityCtrl.close();
    await dbHelper.closeDatabase();
  });

  test("sync sends pending sessions when connection returns", () async {
    fakeSessionApi.online = false;

    await sessionController.createSession(Rating.good);
    await sessionController.createSession(Rating.easy);

    final pending1 = await dbHelper.getPendingStudySessions();
    expect(pending1.length, 2);
    expect(pending1.every((s) => s.synced == false), isTrue);

    await syncService.start();

    fakeSessionApi.online = true;
    connectivityCtrl.add(ConnectivityResult.wifi);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    final pending2 = await dbHelper.getPendingStudySessions();
    expect(pending2.isEmpty, isTrue);

    expect(fakeSessionApi.received.length, 2);
  });
}
