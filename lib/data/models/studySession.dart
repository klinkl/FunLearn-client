import 'package:uuid/uuid.dart';

class StudySession {
  final String studySessionId;
  DateTime timeStamp;
  int xp;
  int cardsLearnt;
  final String userId;

  StudySession({
    String? studySessionId,
    required this.timeStamp,
    required this.xp,
    required this.cardsLearnt,
    required this.userId,
  }) : studySessionId = studySessionId ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'studySessionId': studySessionId,
      'timeStamp': timeStamp.millisecondsSinceEpoch,
      'xp': xp,
      'cardsLearnt': cardsLearnt,
      'userId': userId,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      studySessionId: map['studySessionId'],
      timeStamp: DateTime.fromMillisecondsSinceEpoch(
        map['timeStamp'] ?? DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ),
      xp: map['xp'] as int,
      cardsLearnt: map['cardsLearnt'] as int,
      userId: map['userId'],
    );
  }
}
