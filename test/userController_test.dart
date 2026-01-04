import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/studySession.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:funlearn_client/data/userController.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late UserController controller;
  final path = 'userController_test.db';
  setUp(() async {
    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();
    final user = User();
    await dbHelper.insertUser(user);
    controller = UserController.getInstance(dbHelper);
  });
  tearDown(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });
  test(
    "getOrCreateUser returns existing user when users already exist",
    () async {
      final user = await controller.getOrCreateUser();
      expect(user, isNotNull);
      expect(user.userId, isNotNull);
    },
  );
  test("getOrCreateUser creates new user when no users exist", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    await dbHelper.deleteUser(user.userId);
    final emptyUsers = await dbHelper.getAllUsers();
    expect(emptyUsers.length, 0);
    final newUser = await controller.getOrCreateUser();
    expect(newUser, isNotNull);
    expect(newUser.userId, isNotNull);
    final newUsers = await dbHelper.getAllUsers();
    expect(newUsers.length, 1);
  });
  test("calculateStreak tests", () async {
    var returnValue = controller.calculateStreak(null, 0);
    expect(returnValue, 1);
    returnValue = controller.calculateStreak(
      DateTime.now().toUtc().subtract(const Duration(days: 2)),
      3,
    );
    expect(returnValue, 1);
    returnValue = controller.calculateStreak(
      DateTime.now().toUtc().subtract(const Duration(days: 1)),
      3,
    );
    expect(returnValue, 4);
    returnValue = controller.calculateStreak(DateTime.now().toUtc(), 3);
    expect(returnValue, 3);
  });
  test("calculateLevel", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final session = StudySession(
      timeStamp: DateTime.now().toUtc(),
      xp: 30,
      cardsLearnt: 2,
      userId: user.userId,
    );
    var (level, xpNeeded) = controller.calculateLevel(session, user);
    expect(level, 2);
    expect(xpNeeded, 50);
  });
  test("updateUserWithStudySession updates correctly", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final currentTime = DateTime.now().toUtc();
    final lastStudy = await controller.updateUserWithStudySession(
      StudySession(
        timeStamp: currentTime,
        xp: 30,
        cardsLearnt: 2,
        userId: user.userId,
      ),
    );
    expect(lastStudy, isNull);
    final updatedUser = await dbHelper.getUserById(user.userId);
    expect(updatedUser?.totalXP, 30);
    expect(updatedUser?.level, 2);
    expect(updatedUser?.totalCardsLearned, 2);
    expect(updatedUser?.currentStreak, 1);
    expect(updatedUser?.lastStudyDate?.millisecondsSinceEpoch, currentTime.millisecondsSinceEpoch);
  });
}
