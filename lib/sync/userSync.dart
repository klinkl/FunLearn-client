import '../data/databaseHelper.dart';
import '../data/serverApi/usersApi.dart';

class UserSync {
  final UsersApi usersApi;
  final DatabaseHelper db;

  UserSync({required this.usersApi, required this.db});

  Future<void> pullAndSaveUser(String userId) async {
    final remoteUser = await usersApi.getUserById(userId);
    await db.upsertUser(remoteUser);
  }
}
