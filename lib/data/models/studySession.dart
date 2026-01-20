import 'package:uuid/uuid.dart';

class StudySession {
  final String studySessionId;
  DateTime timeStamp;
  int xp;
  int cardsLearnt;
  final bool synced;
  final String userId;

  StudySession({
    String? studySessionId,
    required this.timeStamp,
    required this.xp,
    required this.cardsLearnt,
    this.synced = false,
    required this.userId,
  }) : studySessionId = studySessionId ?? const Uuid().v4();

  StudySession copyWith({bool? synced}) {
    return StudySession(
      studySessionId: studySessionId,
      timeStamp: timeStamp,
      xp: xp,
      cardsLearnt: cardsLearnt,
      synced: synced ?? this.synced,
      userId: userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studySessionId': studySessionId,
      'timeStamp': timeStamp.toUtc().millisecondsSinceEpoch,
      'xp': xp,
      'cardsLearnt': cardsLearnt,
      'synced': synced ? 1 : 0,
      'userId': userId,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      studySessionId: map['studySessionId'],
      timeStamp: DateTime.fromMillisecondsSinceEpoch(
        map['timeStamp'] as int,
        isUtc: true,
      ),
      xp: map['xp'] as int,
      cardsLearnt: map['cardsLearnt'] as int,
      synced: map['synced'] == 1,
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
      timeStamp: DateTime.parse(json['timeStamp']).toUtc(),
      xp: json['xp'],
      cardsLearnt: json['cardsLearnt'],
      userId: json['userId'],
    );
  }
}
