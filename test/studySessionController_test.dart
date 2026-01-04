import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart';
import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:funlearn_client/data/studySessionController.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late StudySessionController controller;
  final path = 'studySessionController_test.db';
  setUp(() async {
    dbHelper = DatabaseHelper(dbPath: path);
    await dbHelper.resetDatabase();
    final user = User();
    await dbHelper.insertUser(user);
    controller = StudySessionController.getInstance(dbHelper);
    await controller.init();
  });
  tearDown(() async {
    await dbHelper.resetDatabase();
    await dbHelper.closeDatabase();
  });
  test("createSession works", () async {
    final users = await dbHelper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    var (lastStudy, session) = await controller.createSession(Rating.again);
    final updatedUser = await dbHelper.getUserById(user.userId);
    expect(updatedUser?.totalXP, controller.xpFromRating(Rating.again));
    expect(lastStudy, null);
    expect(session.xp, controller.xpFromRating(Rating.again));
    expect(session.cardsLearnt, 0);
    final sessions = await dbHelper.getStudySessionWithinTime(user.userId, DateTime.now().toUtc().subtract(const Duration(hours: 1)), DateTime.now().toUtc());
    expect(sessions.length, 1);
    (lastStudy, session) = await controller.createSession(Rating.easy);
    final updatedUser2 = await dbHelper.getUserById(user.userId);
    expect(updatedUser2?.totalXP, controller.xpFromRating(Rating.again) + controller.xpFromRating(Rating.easy));
    expect(session.xp, controller.xpFromRating(Rating.easy));
    expect(updatedUser2?.totalCardsLearned, controller.cardsLearnedFromRating(Rating.easy));
    final sessions2 = await dbHelper.getStudySessionWithinTime(user.userId, DateTime.now().toUtc().subtract(const Duration(hours: 1)), DateTime.now().toUtc());
    expect(sessions2.length, 2);

  });

}