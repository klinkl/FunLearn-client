class StudySession {
  DateTime timeStamp;
  int xp;
  int cardsLearnt;
  int userId;

  StudySession({
    required this.timeStamp,
    required this.xp,
    required this.cardsLearnt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'timeStamp': timeStamp.millisecondsSinceEpoch,
      'xp': xp,
      'cardsLearnt': cardsLearnt,
      'userId': userId,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      timeStamp: DateTime.fromMillisecondsSinceEpoch(
        map['timeStamp'] ?? DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ),
      xp: map['xp'] as int,
      cardsLearnt: map['cardsLearnt'] as int,
      userId: map['userId'] as int,
    );
  }
}
