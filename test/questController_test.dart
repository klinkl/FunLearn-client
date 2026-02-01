import 'package:flutter_test/flutter_test.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/modelQuest.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:funlearn_client/data/serverApi/questApi.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Fake API that simulates online/offline and holds "server" quests in memory.
class FakeQuestsApi implements IQuestsApi {
  bool online = true;

  final Map<String, List<ModelQuest>> _serverByUser = {};

  void reset() {
    online = true;
    _serverByUser.clear();
  }

  void seedServerQuests(String userId, List<ModelQuest> quests) {
    _serverByUser[userId] = List<ModelQuest>.from(quests);
  }

  List<ModelQuest> serverQuestsOf(String userId) =>
      List<ModelQuest>.from(_serverByUser[userId] ?? const []);

  @override
  Future<List<ModelQuest>> getQuestsByUserId(String userId) async {
    if (!online) throw Exception('No connection');
    return serverQuestsOf(userId);
  }

  @override
  Future<ModelQuest> getQuestById(String questId) async {
    if (!online) throw Exception('No connection');
    for (final entry in _serverByUser.entries) {
      final idx = entry.value.indexWhere((q) => q.questId == questId);
      if (idx != -1) return entry.value[idx];
    }
    throw Exception('Not found');
  }

  @override
  Future<void> createQuest(ModelQuest quest) async {
    if (!online) throw Exception('No connection');

    for (final uid in quest.userIds) {
      final list = _serverByUser.putIfAbsent(uid, () => []);
      list.add(quest);
    }
  }

  @override
  Future<void> updateQuest(ModelQuest quest) async {
    if (!online) throw Exception('No connection');

    for (final uid in quest.userIds) {
      final list = _serverByUser.putIfAbsent(uid, () => []);
      final idx = list.indexWhere((q) => q.questId == quest.questId);
      if (idx == -1) {
        list.add(quest);
      } else {
        list[idx] = quest;
      }
    }
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const path = 'questController_test.db';

  late DatabaseHelper dbHelper;
  late QuestController controller;
  late FakeQuestsApi fakeQuestsApi;
  late User user;

  setUp(() async {
    await DatabaseHelper.resetInstanceForTest();
    QuestController.resetInstanceForTest();

    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();

    fakeQuestsApi = FakeQuestsApi()..reset();

    user = User();
    await dbHelper.insertUser(user);

    controller = QuestController.getInstance(dbHelper, fakeQuestsApi);
    controller.setUserIdForTest(user.userId);
  });

  tearDown(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });

  test("init throws when no existing users", () async {
    await dbHelper.resetDatabase();

    QuestController.resetInstanceForTest();
    final c2 = QuestController.getInstance(dbHelper, fakeQuestsApi);

    expect(() async => c2.init(), throwsException);
  });

  test(
    "getRelevantQuests keeps active and recently-expired within 12h",
    () async {
      final now = DateTime.now().toUtc();

      final active = ModelQuest(
        userIds: [user.userId],
        questType: QuestType.XP,
        startDate: now,
        expiryDate: now.add(const Duration(days: 2)),
        requestedValue: 100,
        currentValue: 10,
        friendsQuest: false,
        questId: "q-active",
      );

      final expiredRecent = ModelQuest(
        userIds: [user.userId],
        questType: QuestType.XP,
        startDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.subtract(const Duration(hours: 2)),
        requestedValue: 100,
        currentValue: 10,
        friendsQuest: false,
        questId: "q-recent",
      );

      final expiredOld = ModelQuest(
        userIds: [user.userId],
        questType: QuestType.XP,
        startDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.subtract(const Duration(hours: 14)),
        requestedValue: 100,
        currentValue: 10,
        friendsQuest: false,
        questId: "q-old",
      );

      await dbHelper.insertQuest(active);
      await dbHelper.insertQuest(expiredRecent);
      await dbHelper.insertQuest(expiredOld);

      final quests = await controller.getRelevantQuests();
      expect(quests.map((q) => q.questId).toSet(), {"q-active", "q-recent"});
    },
  );

  test("getRelevantQuests empty when quests belong to another user", () async {
    final now = DateTime.now().toUtc();

    await dbHelper.insertQuest(
      ModelQuest(
        userIds: ["someone-else"],
        questType: QuestType.XP,
        startDate: now,
        expiryDate: now.add(const Duration(days: 2)),
        requestedValue: 100,
        currentValue: 10,
        friendsQuest: false,
        questId: "x",
      ),
    );

    final quests = await controller.getRelevantQuests();
    expect(quests, isEmpty);
  });

  // ----------------------------------------------------
  // OFFLINE QUEST CREATION (depends on server reachability)
  // ----------------------------------------------------

  test(
    "createQuestsWhenOffline creates 3 quests when offline and no existing quests",
    () async {
      fakeQuestsApi.online = false;

      final before = await controller.getRelevantQuests();
      await controller.createQuestsWhenOffline();
      final after = await controller.getRelevantQuests();

      expect(before, isEmpty);
      expect(after.length, 3);

      for (final q in after) {
        expect(q.origin, "client");
        expect(q.synced, false);
      }
    },
  );

  test("createQuestsWhenOffline does NOT create quests when online", () async {
    fakeQuestsApi.online = true;

    await controller.createQuestsWhenOffline();
    final after = await controller.getRelevantQuests();

    expect(after, isEmpty);
  });

  test(
    "createQuestsWhenOffline does NOT create if at least one quest is active (offline)",
    () async {
      fakeQuestsApi.online = false;

      final now = DateTime.now().toUtc();

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(hours: 2)),
          requestedValue: 100,
          currentValue: 0,
          friendsQuest: false,
          questId: "active1",
          origin: "server",
          synced: true,
        ),
      );

      final before = await controller.getRelevantQuests();
      await controller.createQuestsWhenOffline();
      final after = await controller.getRelevantQuests();

      expect(before.length, 1);
      expect(after.length, 1);
    },
  );

  test(
    "syncClientQuestsIfAny does nothing when there are no pending client quests",
    () async {
      fakeQuestsApi.online = true;

      await controller.syncClientQuestsIfAny();

      expect(fakeQuestsApi.serverQuestsOf(user.userId), isEmpty);
    },
  );

  test(
    "syncClientQuestsIfAny pushes pending client quests and marks them synced (online)",
    () async {
      fakeQuestsApi.online = false;
      await controller.createQuestsWhenOffline();

      final pendingBefore = await dbHelper.getPendingClientQuests(user.userId);
      expect(pendingBefore.length, 3);

      fakeQuestsApi.online = true;
      await controller.syncClientQuestsIfAny();

      final server = fakeQuestsApi.serverQuestsOf(user.userId);
      expect(server.length, 3);

      final pendingAfter = await dbHelper.getPendingClientQuests(user.userId);
      expect(pendingAfter, isEmpty);
    },
  );

  test("syncClientQuestsIfAny keeps pending quests when offline", () async {
    fakeQuestsApi.online = false;
    await controller.createQuestsWhenOffline();

    final pendingBefore = await dbHelper.getPendingClientQuests(user.userId);
    expect(pendingBefore.length, 3);

    await controller.syncClientQuestsIfAny();
    final pendingAfter = await dbHelper.getPendingClientQuests(user.userId);
    expect(pendingAfter.length, 3);
    expect(fakeQuestsApi.serverQuestsOf(user.userId), isEmpty);
  });
  test(
    "hasActiveClientQuests true if there is an active client quest not synced",
    () async {
      final now = DateTime.now().toUtc();

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          requestedValue: 100,
          currentValue: 0,
          friendsQuest: false,
          questId: "clientActive",
          origin: "client",
          synced: false,
          finished: false,
        ),
      );

      final blocked = await controller.hasActiveClientQuests();
      expect(blocked, true);
    },
  );

  test(
    "hasActiveClientQuests false if client quests are synced (even if active)",
    () async {
      final now = DateTime.now().toUtc();

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          requestedValue: 100,
          currentValue: 0,
          friendsQuest: false,
          questId: "clientActiveSynced",
          origin: "client",
          synced: true,
          finished: false,
        ),
      );

      final blocked = await controller.hasActiveClientQuests();
      expect(blocked, false);
    },
  );

  test(
    "refreshFromServer is blocked when there is an active unsynced client quest",
    () async {
      fakeQuestsApi.online = true;
      final now = DateTime.now().toUtc();

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          requestedValue: 100,
          currentValue: 0,
          friendsQuest: false,
          questId: "clientActiveUnsynced",
          origin: "client",
          synced: false,
          finished: false,
        ),
      );

      fakeQuestsApi.seedServerQuests(user.userId, [
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.Streak,
          startDate: now,
          expiryDate: now.add(const Duration(days: 7)),
          requestedValue: 3,
          currentValue: 0,
          friendsQuest: false,
          questId: "srv1",
          origin: "server",
          synced: true,
          finished: false,
        ),
      ]);

      await controller.refreshFromServer();

      final local = await dbHelper.getAllQuestsByUser(user.userId);
      expect(local.map((q) => q.questId).toSet(), {"clientActiveUnsynced"});
    },
  );

  test(
    "refreshFromServer replaces local quests with server quests when not blocked",
    () async {
      fakeQuestsApi.online = true;
      final now = DateTime.now().toUtc();

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.CardsLearnt,
          startDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          requestedValue: 20,
          currentValue: 5,
          friendsQuest: false,
          questId: "local1",
          origin: "server",
          synced: true,
          finished: false,
        ),
      );

      fakeQuestsApi.seedServerQuests(user.userId, [
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          requestedValue: 100,
          currentValue: 0,
          friendsQuest: false,
          questId: "srvA",
          origin: "server",
          synced: true,
          finished: false,
        ),
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.Streak,
          startDate: now,
          expiryDate: now.add(const Duration(days: 7)),
          requestedValue: 3,
          currentValue: 0,
          friendsQuest: false,
          questId: "srvB",
          origin: "server",
          synced: true,
          finished: false,
        ),
      ]);

      await controller.refreshFromServer();

      final localAfter = await dbHelper.getAllQuestsByUser(user.userId);
      expect(localAfter.map((q) => q.questId).toSet(), {"srvA", "srvB"});
    },
  );

  test(
    "refreshFromServer is allowed after syncing client quests (end-to-end)",
    () async {
      final now = DateTime.now().toUtc();

      fakeQuestsApi.online = false;
      await controller.createQuestsWhenOffline();

      expect(await controller.hasActiveClientQuests(), true);

      fakeQuestsApi.online = true;
      await controller.syncClientQuestsIfAny();

      expect(await controller.hasActiveClientQuests(), false);

      fakeQuestsApi.seedServerQuests(user.userId, [
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          requestedValue: 100,
          currentValue: 0,
          friendsQuest: false,
          questId: "srvFinal1",
          origin: "server",
          synced: true,
          finished: false,
        ),
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.CardsLearnt,
          startDate: now,
          expiryDate: now.add(const Duration(days: 2)),
          requestedValue: 20,
          currentValue: 0,
          friendsQuest: false,
          questId: "srvFinal2",
          origin: "server",
          synced: true,
          finished: false,
        ),
      ]);

      await controller.refreshFromServer();

      final localAfter = await dbHelper.getAllQuestsByUser(user.userId);
      expect(localAfter.map((q) => q.questId).toSet(), {
        "srvFinal1",
        "srvFinal2",
      });
    },
  );

  test(
    "updateQuestsWithStudySession does not update finished quests",
    () async {
      final now = DateTime.now().toUtc();

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(hours: 2)),
          requestedValue: 100,
          currentValue: 95,
          friendsQuest: false,
          questId: "q-finished",
          finished: true,
          origin: "server",
          synced: true,
        ),
      );

      await controller.updateQuestsWithStudySession(
        StudySession(
          timeStamp: now,
          xp: 10,
          cardsLearnt: 2,
          userId: user.userId,
          synced: false,
        ),
        now,
      );

      final quests = await controller.getRelevantQuests();
      final q = quests.firstWhere((x) => x.questId == "q-finished");
      expect(q.currentValue, 95);
    },
  );

  test(
    "updateQuestsWithStudySession updates only quests of the studySession user",
    () async {
      final now = DateTime.now().toUtc();
      await dbHelper.insertUser(User(userId: "other-user"));

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(hours: 2)),
          requestedValue: 100,
          currentValue: 95,
          friendsQuest: false,
          questId: "q-user1",
          finished: false,
          origin: "server",
          synced: true,
        ),
      );

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: ["other-user"],
          questType: QuestType.XP,
          startDate: now,
          expiryDate: now.add(const Duration(hours: 2)),
          requestedValue: 100,
          currentValue: 95,
          friendsQuest: false,
          questId: "q-user2",
          finished: false,
          origin: "server",
          synced: true,
        ),
      );

      await controller.updateQuestsWithStudySession(
        StudySession(
          timeStamp: now,
          xp: 6,
          cardsLearnt: 1,
          userId: user.userId,
          synced: false,
        ),
        now,
      );

      final quests = await controller.getRelevantQuests();
      final q1 = quests.firstWhere((q) => q.questId == "q-user1");
      expect(q1.currentValue, 100);
      expect(q1.finished, true);

      final otherUserQuests = await dbHelper.getAllQuestsByUser("other-user");
      final q2 = otherUserQuests.firstWhere((q) => q.questId == "q-user2");
      expect(q2.currentValue, 95);
    },
  );

  test(
    "updateQuestsWithStudySession increments CardsLearnt correctly",
    () async {
      final now = DateTime.now().toUtc();

      await dbHelper.insertQuest(
        ModelQuest(
          userIds: [user.userId],
          questType: QuestType.CardsLearnt,
          startDate: now,
          expiryDate: now.add(const Duration(hours: 2)),
          requestedValue: 100,
          currentValue: 95,
          friendsQuest: false,
          questId: "q-cards",
          finished: false,
          origin: "server",
          synced: true,
        ),
      );

      await controller.updateQuestsWithStudySession(
        StudySession(
          timeStamp: now,
          xp: 0,
          cardsLearnt: 2,
          userId: user.userId,
          synced: false,
        ),
        now,
      );

      var quests = await controller.getRelevantQuests();
      var q = quests.firstWhere((x) => x.questId == "q-cards");
      expect(q.currentValue, 97);
      expect(q.finished, false);

      await controller.updateQuestsWithStudySession(
        StudySession(
          timeStamp: now,
          xp: 0,
          cardsLearnt: 10,
          userId: user.userId,
          synced: false,
        ),
        now,
      );

      quests = await controller.getRelevantQuests();
      q = quests.firstWhere((x) => x.questId == "q-cards");
      expect(q.currentValue, 100);
      expect(q.finished, true);
    },
  );
}
