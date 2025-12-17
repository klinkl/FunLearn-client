import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Center(
      child: ListView(
        children: [
          ListTile(title: Text('Friend Quests')),
          SizedBox(height: 12),

          ListTile(
            title: Quest(
              rarity: 1,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: true,
            ),
          ),
          ListTile(
            title: Quest(
              rarity: 2,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: false,
            ),
          ),
          ListTile(
            title: Quest(
              rarity: 3,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: false,
            ),
          ),

          SizedBox(height: 12),
          ListTile(title: Text('Daily Quests')),
          SizedBox(height: 12),

          ListTile(
            title: Quest(
              rarity: 1,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: false,
            ),
          ),
          ListTile(
            title: Quest(
              rarity: 2,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: true,
            ),
          ),
          ListTile(
            title: Quest(
              rarity: 3,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: true,
            ),
          ),

          SizedBox(height: 12),
          ListTile(title: Text('Weekly Quests')),
          SizedBox(height: 12),

          ListTile(
            title: Quest(
              rarity: 1,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: false,
            ),
          ),
          ListTile(
            title: Quest(
              rarity: 2,
              quest: 'play everyday',
              value: 7,
              requestedValue: 7,
              finished: true,
            ),
          ),
          ListTile(
            title: Quest(
              rarity: 3,
              quest: 'finish 10 flashcards',
              value: 3,
              requestedValue: 10,
              finished: true,
            ),
          ),
        ],
      ),
    );
  }
}
