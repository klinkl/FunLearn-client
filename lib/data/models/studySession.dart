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

  Map<String, dynamic> toJson() {
    return {
      'studySessionId': studySessionId,
      'timeStamp': timeStamp.toUtc().toIso8601String(),
      'xp': xp,
      'cardsLearnt': cardsLearnt,
      'userId': userId,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      studySessionId: json['studySessionId'],
      timeStamp: DateTime.parse(json['timestamp']).toUtc(),
      xp: json['xp'],
      cardsLearnt: json['cardsLearnt'],
      userId: json['userId'],
    );
  }
}
