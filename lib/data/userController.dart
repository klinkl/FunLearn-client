import 'databaseHelper.dart';
import 'models/studySession.dart';
import 'models/user.dart';
import './serverApi/apiClient.dart';
import './serverApi/usersApi.dart';

class UserController {
  static UserController? _instance;
  final DatabaseHelper helper;
  final UsersApi usersApi;

  UserController._internal(this.helper, this.usersApi);
  static UserController getInstance(DatabaseHelper helper, UsersApi usersApi) {
    return _instance ??= UserController._internal(helper, usersApi);
  }

  Future<User> getOrCreateUser() async {
    final users = await helper.getAllUsers();
    //if local user exist -> try to get server version
    if (users.isNotEmpty) {
      final localUser = users.first;

      try {
        final remoteUser = await usersApi.getUserById(localUser.userId);
        await helper.upsertUser(remoteUser);
        return remoteUser;
      } catch (e) {
        try {
          await usersApi.createUser(localUser);
        } catch (_) {}
        return localUser;
      }
    }

    final newUser = User(
      username: 'User',
      totalXP: 0,
      totalCardsLearned: 0,
      currentStreak: 0,
      lastStudyDate: null,
    );

    await helper.insertUser(newUser);

    // try to create it on the server
    try {
      await usersApi.createUser(newUser);
    } catch (_) {}

    return newUser;
  }

  int calculateStreak(DateTime? lastStudyDate, int oldStreak) {
    if (lastStudyDate == null) {
      return 1;
    }
    final last = DateTime(
      lastStudyDate.year,
      lastStudyDate.month,
      lastStudyDate.day,
    );
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);

    final difference = current.difference(last).inDays;
    if (difference == 1) return oldStreak + 1;
    if (difference > 1) return 1;
    return oldStreak;
  }

  (int, int) calculateLevel(StudySession studySession, User user) {
    final currentXP = user.totalXP;
    final newXP = currentXP + studySession.xp;
    int level = (newXP ~/ 25) + 1;
    int xpNeeded = 25 * level;
    return (level, xpNeeded);
  }

  Future<DateTime?> updateUserWithStudySession(
    StudySession studySession,
  ) async {
    final user = await helper.getUserById(studySession.userId);
    final (newLevel, xpTowardsNextLevel) = calculateLevel(studySession, user!);
    await helper.updateUser(
      User(
        username: user.username,
        userId: user.userId,
        currentStreak: calculateStreak(user.lastStudyDate, user.currentStreak),
        lastStudyDate: studySession.timeStamp,
        totalXP: user.totalXP + studySession.xp,
        totalCardsLearned: user.totalCardsLearned + studySession.cardsLearnt,
        level: newLevel,
        xpToNextLevel: xpTowardsNextLevel,
      ),
    );
    return user.lastStudyDate;
  }
}
