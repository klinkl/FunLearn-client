
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:funlearn_client/data/models/friendRequest.dart';

import 'databaseHelper.dart';
import 'models/studySession.dart';
import 'models/user.dart';
import './serverApi/usersApi.dart';

class UserController extends ChangeNotifier {
  static UserController? _instance;
  final DatabaseHelper helper;
  final UsersApi usersApi;

  User? _currentUser;
  User? get currentUser => _currentUser;

  UserController._internal(this.helper, this.usersApi);

  static UserController getInstance(DatabaseHelper helper, UsersApi usersApi) {
    return _instance ??= UserController._internal(helper, usersApi);
  }
  static UserController getInstance_() {
    if (_instance == null) {
      throw StateError('UserController not initialized');
    }
    return _instance!;
  }
  Future<User> getOrCreateUser() async {
    final users = await helper.getAllUsers();

    // If local user exists -> try to get server version
    if (users.isNotEmpty) {
      final localUser = users.first;

      try {
        final remoteUser = await usersApi.getUserById(localUser.userId);
        await helper.upsertUser(remoteUser);
        _currentUser = remoteUser;
        notifyListeners();
        return remoteUser;
      } catch (_) {
        try {
          await usersApi.createUser(localUser);
        } catch (_) {}
        _currentUser = localUser;
        notifyListeners();
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

    _currentUser = newUser;
    notifyListeners();
    return newUser;
  }

  Future<void> updateUsername(String newName) async {
    final me = _currentUser;
    if (me == null) throw Exception('No current user');

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = User(
      username: trimmed,
      userId: me.userId,
      totalXP: me.totalXP,
      totalCardsLearned: me.totalCardsLearned,
      currentStreak: me.currentStreak,
      lastStudyDate: me.lastStudyDate,
      level: me.level,
      xpToNextLevel: me.xpToNextLevel,
      friends: me.friends,
    );

    await helper.upsertUser(updated);
    _currentUser = updated;
    notifyListeners();

    try {
      await usersApi.updateUser(updated);
    } catch (_) {}
  }

  int calculateStreak(DateTime? lastStudyDate, int oldStreak) {
    if (lastStudyDate == null) return 1;

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
    final newXP = user.totalXP + studySession.xp;
    final level = (newXP ~/ 25) + 1;
    final xpNeeded = 25 * level;
    return (level, xpNeeded);
  }

  Future<DateTime?> updateUserWithStudySession(
    StudySession studySession,
  ) async {
    final user = await helper.getUserById(studySession.userId);
    if (user == null) throw Exception('User not found locally');

    final (newLevel, xpToNextLevel) = calculateLevel(studySession, user);

    final updatedUser = User(
      username: user.username,
      userId: user.userId,
      currentStreak: calculateStreak(user.lastStudyDate, user.currentStreak),
      lastStudyDate: studySession.timeStamp,
      totalXP: user.totalXP + studySession.xp,
      totalCardsLearned: user.totalCardsLearned + studySession.cardsLearnt,
      level: newLevel,
      xpToNextLevel: xpToNextLevel,
      friends: user.friends,
    );

    await helper.upsertUser(updatedUser);

    if (_currentUser?.userId == updatedUser.userId) {
      _currentUser = updatedUser;
      notifyListeners();
    }

    return user.lastStudyDate;
  }

  Future<User?> refreshFromServer(String userId) async {
    try {
      final remoteUser = await usersApi.getUserById(userId);
      await helper.upsertUser(remoteUser);

      if (_currentUser?.userId == remoteUser.userId) {
        _currentUser = remoteUser;
        notifyListeners();
      }

      return remoteUser;
    } catch (_) {
      return null;
    }
  }

  Future<List<User>> fetchGlobalLeaderboard({bool forceRefresh = true}) async {
    if (forceRefresh) {
      try {
        final remoteUsers = await usersApi.getAllUsers();
        for (final user in remoteUsers) {
          await helper.upsertUser(user);
        }
        remoteUsers.sort((a, b) => b.totalXP.compareTo(a.totalXP));
        return remoteUsers;
      } catch (_) {
        final localUsers = await helper.getAllUsers();
        localUsers.sort((a, b) => b.totalXP.compareTo(a.totalXP));
        return localUsers;
      }
    }

    final localUsers = await helper.getAllUsers();
    localUsers.sort((a, b) => b.totalXP.compareTo(a.totalXP));
    return localUsers;
  }

  Future<List<User>> fetchFriendsLeaderboard(List<String> friendsIds) async {
    final global = await fetchGlobalLeaderboard();
    final set = friendsIds.toSet();

    final me = currentUser;
    if (me != null) set.add(me.userId);

    final friends = global.where((u) => set.contains(u.userId)).toList();
    friends.sort((a, b) => b.totalXP.compareTo(a.totalXP));
    return friends;
  }

  @visibleForTesting
  static void resetInstanceForTest() {
    _instance = null;
  }
  Future<void> sendFriendRequest(User userA, User userB) async {
    if (userA.userId == userB.userId){
      throw Exception('You cannot send a friend request to yourself.');
    }
    try {
        await usersApi.sendFriendRequest(FriendRequest(userA.userId, userB.userId, false));
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }
  Future<void> acceptFriendRequest(FriendRequest request) async {
    try {
      await usersApi.updateFriendRequest(
          FriendRequest(request.fromUser, request.toUser, true));
    }
    catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }
  Future<void> declineFriendRequest(FriendRequest request) async {
    try {
      await usersApi.deleteFriendRequest(request);
    }
    catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }
  Future<List<FriendRequest>?> getSent() async{
    try {
      final me = _currentUser ?? await getOrCreateUser();
      var users = await usersApi.getSent(me.userId);
      return users;
    }catch (e) {
      throw Exception('Failed to get friend requests: $e');
    }
  }
  Future<List<FriendRequest>?> getReceived() async{
    try {
      final me = _currentUser ?? await getOrCreateUser();
      var users = await usersApi.getReceived(me.userId);
      return users;
    }catch (e) {
      throw Exception('Failed to get friend requests: $e');
    }
  }
}
