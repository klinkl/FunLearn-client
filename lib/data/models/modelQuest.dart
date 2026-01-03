import 'dart:convert';

import 'package:uuid/uuid.dart';

class ModelQuest {
  final String questId;
  List<int> userIds;
  QuestType questType;
  DateTime? startDate;
  DateTime expiryDate;
  int currentValue;
  int requestedValue;
  bool finished;
  bool friendsQuest;

  ModelQuest({
    String? questId,
    required this.userIds,
    required this.questType,
    DateTime? startDate,
    required this.expiryDate,
    this.currentValue = 0,
    required this.requestedValue,
    this.finished = false,
    required this.friendsQuest,
  }) : questId = questId ?? const Uuid().v4(),
       startDate = startDate ?? DateTime.now().toUtc();

  Map<String, dynamic> toMap() {
    return {
      'questId': questId,
      'userIds': jsonEncode(userIds),
      'questType': questType.name,
      'startDate': startDate?.millisecondsSinceEpoch,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'currentValue': currentValue,
      'requestedValue': requestedValue,
      'finished': finished? 1 : 0,
      'friendsQuest': friendsQuest? 1 : 0,
    };
  }

  factory ModelQuest.fromMap(Map<String, dynamic> map) {
    return ModelQuest(
      questId: map['questId'],
      userIds: List<int>.from(jsonDecode(map['userIds'])),
      questType: QuestType.values.byName(map['questType']),
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map['startDate'],
        isUtc: true,
      ),
      expiryDate: DateTime.fromMillisecondsSinceEpoch(
        map['expiryDate'],
        isUtc: true,
      ),
      currentValue: map['currentValue'] ?? 0,
      requestedValue: map['requestedValue'],
      finished: map['finished'] == 0 ? false : true,
      friendsQuest: map['friendsQuest'] == 0 ? false : true,
    );
  }
}

enum QuestType { XP, CardsLearnt }
