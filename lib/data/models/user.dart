import 'package:uuid/uuid.dart';

class User {
  String username;
  final String userId;
  int totalXP;
  int totalCardsLearned;
  int currentStreak;
  DateTime? lastStudyDate;
  int level;
  int xpToNextLevel;

  User({
    this.username = "User",
    String? userId,
    this.totalXP = 0,
    this.totalCardsLearned = 0,
    this.currentStreak = 0,
    this.lastStudyDate,
    this.level = 1,
    this.xpToNextLevel = 25,
  }): userId = userId ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'userId': userId,
      'totalXP': totalXP,
      'totalCardsLearned': totalCardsLearned,
      'currentStreak': currentStreak,
      'lastStudyDate': lastStudyDate?.millisecondsSinceEpoch,
      'level' : level,
      'xpToNextLevel': xpToNextLevel,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      userId: map['userId'],
      totalXP: map['totalXP'],
      totalCardsLearned: map['totalCardsLearned'],
      currentStreak: map['currentStreak'],
      level: map['level'],
      xpToNextLevel: map['xpToNextLevel'],
      lastStudyDate: map['lastStudyDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['lastStudyDate'],
              isUtc: true,
            )
          : null,
    );
  }
}
