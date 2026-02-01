import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/friendRequest.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/models/modelQuest.dart';
import 'package:funlearn_client/data/studySessionController.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:funlearn_client/data/sync/syncService.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:funlearn_client/data/serverApi/studySessionApi.dart';
import 'package:funlearn_client/data/serverApi/usersApi.dart';
import 'package:funlearn_client/data/serverApi/questApi.dart';
import 'package:funlearn_client/data/service/batteryGate.dart';

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
  final Map<String, FriendRequest> _requests = {};
  void seed(User user) => _remote[user.userId] = user;

  String _reqKey(String fromUser, String toUser) => '$fromUser::$toUser';
  String _reqKeyFromReq(FriendRequest r) => _reqKey(r.fromUser, r.toUser);

  void seedRequest(FriendRequest r) => _requests[_reqKeyFromReq(r)] = r;

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

  @override
  Future<void> deleteFriendRequest(FriendRequest request) async {
    _requests.remove(_reqKeyFromReq(request));
  }

  @override
  Future<List<FriendRequest>> getReceived(String id) async {
    return _requests.values.where((r) => r.toUser == id).toList();
  }

  @override
  Future<List<FriendRequest>> getSent(String id) async {
    return _requests.values.where((r) => r.fromUser == id).toList();
  }

  @override
  Future<void> sendFriendRequest(FriendRequest request) async {
    final key = _reqKeyFromReq(request);
    _requests[key] = request;
  }

  @override
  Future<void> updateFriendRequest(FriendRequest request) async {
    final key = _reqKeyFromReq(request);
    if (!_requests.containsKey(key)) {
      throw Exception('Friend request not found');
    }
    _requests[key] = request;
  }
}

class FakeQuestsApi implements IQuestsApi {
  bool online = true;
  int getByUserCalls = 0;

  @override
  Future<List<ModelQuest>> getQuestsByUserId(String userId) async {
    if (!online) throw Exception('No connection');
    getByUserCalls += 1;
    return <ModelQuest>[];
  }

  @override
  Future<ModelQuest> getQuestById(String questId) async {
    if (!online) throw Exception('No connection');
    throw UnimplementedError();
  }

  @override
  Future<void> createQuest(ModelQuest quest) async {
    if (!online) throw Exception('No connection');
  }

  @override
  Future<void> updateQuest(ModelQuest quest) async {
    if (!online) throw Exception('No connection');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const path = 'syncService_test.db';

  late DatabaseHelper dbHelper;
  late FakeUsersApi fakeUsersApi;
  late FakeStudySessionApi fakeSessionApi;
  late FakeQuestsApi fakeQuestsApi;

  late UserController userController;
  late StudySessionController sessionController;
  late QuestController questController;

  late StreamController<ConnectivityResult> connectivityCtrl;
  late SyncService syncService;

  setUp(() async {
    await DatabaseHelper.resetInstanceForTest();
    StudySessionController.resetInstanceForTest();
    UserController.resetInstanceForTest();
    QuestController.resetInstanceForTest();

    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();

    final batteryGate = BatteryGate(criticalThreshold: 5);

    fakeUsersApi = FakeUsersApi();
    fakeSessionApi = FakeStudySessionApi();
    fakeQuestsApi = FakeQuestsApi();

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

    questController = QuestController.getInstance(dbHelper, fakeQuestsApi);
    questController.setUserIdForTest(user.userId);

    connectivityCtrl = StreamController<ConnectivityResult>.broadcast();

    syncService = SyncService(
      studySessionController: sessionController,
      questController: questController,
      dbHelper: dbHelper,
      batteryGate: batteryGate,
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

    await Future<void>.delayed(const Duration(milliseconds: 80));

    final pending2 = await dbHelper.getPendingStudySessions();
    expect(pending2.isEmpty, isTrue);

    expect(fakeSessionApi.received.length, 2);

    expect(fakeQuestsApi.getByUserCalls, greaterThanOrEqualTo(1));
  });
}
