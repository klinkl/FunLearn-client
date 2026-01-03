import 'package:funlearn_client/data/databaseHelper.dart';

import 'models/modelQuest.dart';
import 'models/studySession.dart';
import 'models/user.dart';

class QuestController {
  static QuestController? _instance;
  final DatabaseHelper helper;

  QuestController._internal(this.helper);

  static QuestController getInstance(DatabaseHelper helper) {
    return _instance ??= QuestController._internal(helper);
  }

  Future<List<ModelQuest>> getRelevantQuests() async {
    final users = await helper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final currentQuests = await helper.getAllQuestsByUser(user.userId!);
    // only see quests that havent expired or expired in the last 12 hours
    final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 12));
    return currentQuests.where((quest) {
      return quest.expiryDate.isAfter(cutoff);
    }).toList();
  }

  Future<void> createQuestsWhenOffline() async {
    final users = await helper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    final user = users.first;
    final currentQuests = await helper.getAllQuestsByUser(user.userId!);
    final currentTime = DateTime.now().toUtc();
    final allExpired = currentQuests.every(
      (quest) => quest.expiryDate.isBefore(currentTime),
    );
    //in future check if offline
    if (allExpired) {
      await helper.insertQuest(
        ModelQuest(
          userIds: [user.userId!],
          questType: QuestType.XP,
          startDate: currentTime,
          expiryDate: currentTime.add(const Duration(days: 2)),
          requestedValue: 100,
          friendsQuest: false,
        ),
      );
      await helper.insertQuest(
        ModelQuest(
          userIds: [user.userId!],
          questType: QuestType.CardsLearnt,
          startDate: currentTime,
          expiryDate: currentTime.add(const Duration(days: 2)),
          requestedValue: 20,
          friendsQuest: false,
        ),
      );
      await helper.insertQuest(
        ModelQuest(
          userIds: [user.userId!],
          questType: QuestType.Streak,
          startDate: currentTime,
          expiryDate: currentTime.add(const Duration(days: 7)),
          requestedValue: 3,
          friendsQuest: false,
        ),
      );
    }
  }

  Future<void> updateQuestsWithStudySession(
    StudySession studySession,
    DateTime? lastStudyDate,
  ) async {
    final quests = await helper.getAllQuestsByUser(studySession.userId);
    if (quests.isEmpty) return;
    for (var quest in quests) {
      if (quest.finished) continue;
      switch (quest.questType) {
        case QuestType.XP:
          var newValue = quest.currentValue + studySession.xp;
          var finished = false;
          if (newValue >= quest.requestedValue) {
            finished = true;
            newValue = quest.requestedValue;
          }
          await helper.updateQuest(
            ModelQuest(
              userIds: quest.userIds,
              questType: quest.questType,
              expiryDate: quest.expiryDate,
              startDate: quest.startDate,
              requestedValue: quest.requestedValue,
              friendsQuest: quest.friendsQuest,
              questId: quest.questId,
              currentValue: newValue,
              finished: finished,
            ),
          );
          break;
        case QuestType.CardsLearnt:
          var newValue = quest.currentValue + studySession.cardsLearnt;
          var finished = false;
          if (newValue >= quest.requestedValue) {
            finished = true;
            newValue = quest.requestedValue;
          }
          await helper.updateQuest(
            ModelQuest(
              userIds: quest.userIds,
              questType: quest.questType,
              expiryDate: quest.expiryDate,
              startDate: quest.startDate,
              requestedValue: quest.requestedValue,
              friendsQuest: quest.friendsQuest,
              questId: quest.questId,
              currentValue: newValue,
              finished: finished,
            ),
          );
          break;
        case QuestType.Streak:
          var newStreak = 0;
          if (lastStudyDate == null) {
            newStreak = 1;
          } else {
            final last = DateTime(
              lastStudyDate.year,
              lastStudyDate.month,
              lastStudyDate.day,
            );
            final today = DateTime.now();
            final current = DateTime(today.year, today.month, today.day);

            final difference = current.difference(last).inDays;
            if (difference == 1) newStreak = quest.currentValue + 1;
            if (difference > 1) newStreak = quest.currentValue;
            newStreak = quest.currentValue;
          }
          var finished = false;
          if (newStreak >= quest.requestedValue) {
            finished = true;
          }
          await helper.updateQuest(
            ModelQuest(
              userIds: quest.userIds,
              questType: quest.questType,
              expiryDate: quest.expiryDate,
              startDate: quest.startDate,
              requestedValue: quest.requestedValue,
              friendsQuest: quest.friendsQuest,
              questId: quest.questId,
              currentValue: newStreak,
              finished: finished,
            ),
          );
          break;
      }
    }
  }
}
