import 'package:funlearn_client/data/databaseHelper.dart';

import 'models/modelQuest.dart';
import 'models/studySession.dart';
import 'models/user.dart';

class QuestController {
  final DatabaseHelper helper;

  QuestController(this.helper);

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
    }
  }

  Future<void> updateQuestsWithStudySession(StudySession studySession) async {
    final quests = await helper.getAllQuestsByUser(studySession.userId);
    if (quests.isEmpty) return;
    for (var quest in quests) {
      if (quest.finished) return;
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
              currentValue: quest.currentValue + studySession.cardsLearnt,
              finished: finished,
            ),
          );
          break;
      }
    }
  }
}
