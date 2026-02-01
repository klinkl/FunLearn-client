import 'package:funlearn_client/data/databaseHelper.dart';
import 'package:flutter/cupertino.dart';

import 'models/modelQuest.dart';
import 'models/studySession.dart';
import './serverApi/questApi.dart';

class QuestController {
  static QuestController? _instance;

  final DatabaseHelper helper;
  final IQuestsApi questsApi;

  late String userId;

  QuestController._internal(this.helper, this.questsApi);

  static QuestController getInstance(
    DatabaseHelper helper,
    IQuestsApi questApi,
  ) {
    return _instance ??= QuestController._internal(helper, questApi);
  }

  Future<void> init() async {
    final users = await helper.getAllUsers();
    if (users.isEmpty) throw Exception('No users found');
    userId = users.first.userId!;
  }

  Future<List<ModelQuest>> getRelevantQuests() async {
    final currentQuests = await helper.getAllQuestsByUser(userId);
    final cutoff = DateTime.now().toUtc().subtract(const Duration(hours: 12));
    return currentQuests
        .where((quest) => quest.expiryDate.isAfter(cutoff))
        .toList();
  }

  Future<bool> _canReachServer() async {
    try {
      await questsApi
          .getQuestsByUserId(userId)
          .timeout(const Duration(seconds: 2));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> createQuestsWhenOffline() async {
    final online = await _canReachServer();
    if (online) return;

    final currentQuests = await helper.getAllQuestsByUser(userId);
    final currentTime = DateTime.now().toUtc();

    final allExpired = currentQuests.every(
      (quest) => quest.expiryDate.isBefore(currentTime),
    );
    if (!allExpired) return;

    await helper.insertQuest(
      ModelQuest(
        userIds: [userId],
        questType: QuestType.XP,
        startDate: currentTime,
        expiryDate: currentTime.add(const Duration(days: 2)),
        requestedValue: 100,
        friendsQuest: false,
        origin: 'client',
        synced: false,
      ),
    );

    await helper.insertQuest(
      ModelQuest(
        userIds: [userId],
        questType: QuestType.CardsLearnt,
        startDate: currentTime,
        expiryDate: currentTime.add(const Duration(days: 2)),
        requestedValue: 20,
        friendsQuest: false,
        origin: 'client',
        synced: false,
      ),
    );

    await helper.insertQuest(
      ModelQuest(
        userIds: [userId],
        questType: QuestType.Streak,
        startDate: currentTime,
        expiryDate: currentTime.add(const Duration(days: 7)),
        requestedValue: 3,
        friendsQuest: false,
        origin: 'client',
        synced: false,
      ),
    );
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
              origin: quest.origin,
              synced: quest.synced,
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
              origin: quest.origin,
              synced: quest.synced,
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
            if (difference == 1) {
              newStreak = quest.currentValue + 1;
            } else if (difference > 1) {
              newStreak = 1;
            } else if (difference == 0) {
              newStreak = quest.currentValue;
            }
          }

          final finished = newStreak >= quest.requestedValue;

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
              origin: quest.origin,
              synced: quest.synced,
            ),
          );
          break;
      }
    }
  }

  Future<bool> hasActiveClientQuests() async {
    final nowUtc = DateTime.now().toUtc();
    final quests = await helper.getAllQuestsByUser(userId);

    return quests.any((q) {
      final isClient = q.origin == 'client';
      final isActive = !q.finished && q.expiryDate.isAfter(nowUtc);
      final notSyncedYet = q.synced == false;
      return isClient && isActive && notSyncedYet;
    });
  }

  Future<void> refreshFromServer() async {
    final blockRefresh = await hasActiveClientQuests();
    if (blockRefresh) return;

    final remoteQuests = await questsApi.getQuestsByUserId(userId);

    // Safe because we only allow refresh when there are no active UNSYNCED client quests.
    await helper.deleteQuestsByUser(userId);

    for (final q in remoteQuests) {
      await helper.upsertQuest(q);
    }
  }

  Future<void> syncClientQuestsIfAny() async {
    final pending = await helper.getPendingClientQuests(userId);
    if (pending.isEmpty) return;

    for (final q in pending) {
      try {
        await questsApi.createQuest(q);
        await helper.markQuestSynced(q.questId);
      } catch (_) {}
    }
  }

  @visibleForTesting
  void setUserIdForTest(String id) => userId = id;

  @visibleForTesting
  static void resetInstanceForTest() => _instance = null;
}
