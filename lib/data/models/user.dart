class User {
  String username;
  int? userId;
  int totalXP;
  int totalCardsLearned;
  int currentStreak;
  DateTime? lastStudyDate;

  User({
    this.username = "User",
    this.userId,
    this.totalXP = 0,
    this.totalCardsLearned = 0,
    this.currentStreak = 0,
    this.lastStudyDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'userId': userId,
      'totalXP': totalXP,
      'totalCardsLearned': totalCardsLearned,
      'currentStreak': currentStreak,
      'lastStudyDate': lastStudyDate?.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      userId: map['userId'],
      totalXP: map['totalXP'],
      totalCardsLearned: map['totalCardsLearned'],
      currentStreak: map['currentStreak'],
      lastStudyDate: DateTime.fromMillisecondsSinceEpoch(
        map['lastStudyDate'] ?? DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ),
    );
  }
}
