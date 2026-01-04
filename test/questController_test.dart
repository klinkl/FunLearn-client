import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/modelQuest.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late QuestController controller;
  final path = 'questController_test.db';
  setUp(() async {
    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();
    final user = User();
    await dbHelper.insertUser(user);
    controller = QuestController.getInstance(dbHelper);
  });
  tearDown(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });
  test("getRelevantQuests works", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final quest = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.XP,
      expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
      requestedValue: 100,
      currentValue: 56,
      friendsQuest: false,
      questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
    );
    final quest2 = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.XP,
      expiryDate: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      requestedValue: 100,
      currentValue: 56,
      friendsQuest: false,
      questId: "2610d0a6-961f-4de7-8f61-d36ba240ff1a",
    );
    final quest3 = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.XP,
      expiryDate: DateTime.now().toUtc().subtract(const Duration(hours: 14)),
      requestedValue: 100,
      currentValue: 56,
      friendsQuest: false,
      questId: "98ba9617-67f5-45ff-af29-6c46038605e1",
    );
    await dbHelper.insertQuest(quest);
    await dbHelper.insertQuest(quest2);
    await dbHelper.insertQuest(quest3);
    final quests = await controller.getRelevantQuests();
    expect(quests.length, 2);
  });
  test("getRelevantQuests for no existing users", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    await dbHelper.deleteUser(user.userId);
    try {
      final quests = await controller.getRelevantQuests();
    } catch (e) {
      expect(e, isA<Exception>());
    }
  });
  test("getRelevantQuests for user with no relevant quests", () async {
    final quest = ModelQuest(
      userIds: ["ed15e150-8579-4da8-91ce-4173376c0aed"],
      questType: QuestType.XP,
      expiryDate: DateTime.now().toUtc().add(const Duration(days: 2)),
      requestedValue: 100,
      currentValue: 56,
      friendsQuest: false,
      questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
    );
    await dbHelper.insertQuest(quest);
    final quests = await controller.getRelevantQuests();
    expect(quests, isEmpty);
  });
  test(
    "createQuestsWhenOffline creates quests when user has no existing quests",
    () async {
      final quests = await controller.getRelevantQuests();
      await controller.createQuestsWhenOffline();
      final quests2 = await controller.getRelevantQuests();
      expect(quests.length, 0);
      expect(quests2.length, 3);
    },
  );
  test(
    "createQuestsWhenOffline creates quests when all existing quests are expired",
    () async {
      final users = await dbHelper.getAllUsers();
      if (users.isEmpty) throw Exception('No users found');
      final user = users.first;
      final quest = ModelQuest(
        userIds: [user.userId],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        requestedValue: 100,
        currentValue: 56,
        friendsQuest: false,
        questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
      );
      await dbHelper.insertQuest(quest);
      final quests = await controller.getRelevantQuests();
      await controller.createQuestsWhenOffline();
      final quests2 = await controller.getRelevantQuests();
      expect(quests.length, 1);
      expect(quests2.length, 4);
    },
  );
  test(
    "createQuestsWhenOffline does not create quests when at least one quest is not expired",
    () async {
      final users = await dbHelper.getAllUsers();
      if (users.isEmpty) throw Exception('No users found');
      final user = users.first;
      final quest = ModelQuest(
        userIds: [user.userId],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
        requestedValue: 100,
        currentValue: 56,
        friendsQuest: false,
        questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
      );
      await dbHelper.insertQuest(quest);
      final quests = await controller.getRelevantQuests();
      await controller.createQuestsWhenOffline();
      final quests2 = await controller.getRelevantQuests();
      expect(quests.length, 1);
      expect(quests2.length, 1);
    },
  );
  test(
    "updateQuestsWithStudySession does not update finished quests",
    () async {
      final users = await dbHelper.getAllUsers();
      if (users.isEmpty) throw Exception('No users found');
      final user = users.first;
      final quest = ModelQuest(
        userIds: [user.userId],
        questType: QuestType.XP,
        expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
        requestedValue: 100,
        currentValue: 95,
        friendsQuest: false,
        questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
        finished: true,
      );
      await dbHelper.insertQuest(quest);
      await controller.updateQuestsWithStudySession(
        StudySession(
          timeStamp: DateTime.now().toUtc(),
          xp: 5,
          cardsLearnt: 2,
          userId: user.userId,
        ),
        DateTime.now().toUtc(),
      );
      final quests = await controller.getRelevantQuests();
      expect(quests.first.currentValue, 95);
    },
  );
  test("updateQuestsWithStudySession updates only quests belonging to study session user", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    await dbHelper.insertUser(User(userId: "94a2f1eb-558b-4a30-a343-f2b5ab7db3df"));
    final quest = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.XP,
      expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
      requestedValue: 100,
      currentValue: 95,
      friendsQuest: false,
      questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
      finished: false,
    );
    final quest2 = ModelQuest(
      userIds: ["94a2f1eb-558b-4a30-a343-f2b5ab7db3df"],
      questType: QuestType.XP,
      expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
      requestedValue: 100,
      currentValue: 95,
      friendsQuest: false,
      questId: "b50acb76-d7a6-4bea-a8c9-f213ed680f5d",
      finished: false,
    );
    await dbHelper.insertQuest(quest);
    await dbHelper.insertQuest(quest2);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      DateTime.now().toUtc(),
    );
    final quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 100);
    expect(quests.first.finished, true);
    final quests2 = await dbHelper.getAllQuestsByUser("94a2f1eb-558b-4a30-a343-f2b5ab7db3df");
    expect(quests2.first.currentValue, 95);
  });
  test("updateQuestsWithStudySession increments CardsLearnt correctly", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final quest = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.CardsLearnt,
      expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
      requestedValue: 100,
      currentValue: 95,
      friendsQuest: false,
      questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
      finished: false,
    );
    await dbHelper.insertQuest(quest);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      DateTime.now().toUtc(),
    );
    var quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 97);
    expect(quests.first.finished, false);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 4,
        userId: user.userId,
      ),
      DateTime.now().toUtc(),
    );
    quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 100);
    expect(quests.first.finished, true);
  }
  );
  test("updateQuestsWithStudySession streak completion test", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final quest = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.Streak,
      expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
      requestedValue: 3,
      currentValue: 0,
      friendsQuest: false,
      questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
      finished: false,
    );
    await dbHelper.insertQuest(quest);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      null,
    );
    var quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 1);
    expect(quests.first.finished, false);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 2);
    expect(quests.first.finished, false);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      DateTime.now().toUtc(),
    );
    quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 2);
    expect(quests.first.finished, false);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 3);
    expect(quests.first.finished, true);
  });
  test("updateQuestsWithStudySession streaks reset test", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final quest = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.Streak,
      expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
      requestedValue: 3,
      currentValue: 0,
      friendsQuest: false,
      questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
      finished: false,
    );
    await dbHelper.insertQuest(quest);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      null,
    );
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    var quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 2);
    expect(quests.first.finished, false);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      DateTime.now().toUtc().subtract(const Duration(days: 2)),
    );
    quests = await controller.getRelevantQuests();
    expect(quests.first.currentValue, 1);
    expect(quests.first.finished, false);
  });
  test("updateQuestsWithStudySession handles multiple quests of different types in one update", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final quest = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.Streak,
      expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
      requestedValue: 3,
      currentValue: 0,
      friendsQuest: false,
      questId: "ed15e150-8579-4da8-91ce-4173376c0aed",
      finished: false,
    );
    await dbHelper.insertQuest(quest);
    final quest2 = ModelQuest(
      userIds: [user.userId],
      questType: QuestType.CardsLearnt,
      expiryDate: DateTime.now().toUtc().add(const Duration(hours: 2)),
      requestedValue: 100,
      currentValue: 95,
      friendsQuest: false,
      questId: "b50acb76-d7a6-4bea-a8c9-f213ed680f5d",
      finished: false,
    );
    await dbHelper.insertQuest(quest2);
    await controller.updateQuestsWithStudySession(
      StudySession(
        timeStamp: DateTime.now().toUtc(),
        xp: 6,
        cardsLearnt: 2,
        userId: user.userId,
      ),
      null,
    );
    final quests = await controller.getRelevantQuests();
    expect(quests.length, 2);
    expect(quests.first.currentValue, 1);
    expect(quests.last.currentValue, 97);
  });
}
