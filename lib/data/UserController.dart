import 'databaseHelper.dart';
import 'models/user.dart';

class UserController {
  final DatabaseHelper helper;

  UserController(this.helper);

  Future<User> getOrCreateUser(DatabaseHelper helper) async {
    final users = await helper.getAllUsers();
    if (users.isNotEmpty) return users.first;

    final newUser = User(
      username: 'User',
      totalXP: 0,
      totalCardsLearned: 0,
      currentStreak: 0,
      lastStudyDate: null,
    );

    await helper.insertUser(newUser);

    return newUser;
  }
}
