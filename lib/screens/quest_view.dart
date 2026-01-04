import 'package:flutter/material.dart';
import 'package:funlearn_client/data/models/modelQuest.dart';
import 'package:funlearn_client/data/questController.dart';
import '../data/databaseHelper.dart';
import '../theme/customColors.dart';
import '../widgets/quest.dart';

class QuestView extends StatefulWidget {
  const QuestView({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<QuestView> createState() => _QuestViewState();
}

class _QuestViewState extends State<QuestView> {
  List<ModelQuest> _quests = [];
  bool _loading = true;
  final QuestController questController = QuestController.getInstance(DatabaseHelper(dbPath: 'database.db'));
  @override
  void initState() {
    super.initState();
    _loadQuests();
  }
  Future<void> _loadQuests() async {
    await questController.createQuestsWhenOffline();
    final quests = await questController.getRelevantQuests();
    setState(() {
      _quests = quests;
      _loading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Center(
      child: ListView(
        children: [
          ListTile(title: Text('Friend Quests')),
          SizedBox(height: 12),
          ..._quests.map((quest) {
            return ListTile(
              title:  Quest(
                rarity: 1,
                quest: quest.questType.name,
                value: quest.currentValue,
                requestedValue: quest.requestedValue,
                finished: quest.finished,
                expiryDate: quest.expiryDate,
              ),
            );
          }),

          SizedBox(height: 12),
          ListTile(title: Text('Daily Quests')),
          SizedBox(height: 12),

        ],
      ),
    );
  }
}
