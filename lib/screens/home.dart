import 'package:flutter/material.dart';
import 'package:funlearn_client/data/questController.dart';
import 'package:funlearn_client/data/userController.dart';
import 'learning_view.dart';
import 'cards_list_view.dart';
import 'quest_view.dart';
import 'leaderboard_view.dart';
import 'setting_view.dart';
import '../widgets/navigation_bar.dart';

import '../data/databaseHelper.dart';
import '../data/learningController.dart';

class HomeView extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DatabaseHelper dbHelper;
  final UserController userController;
  final LearningController learningController;
  final QuestController questController;

  const HomeView({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.dbHelper,
    required this.userController,
    required this.learningController,
    required this.questController,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CardsListView(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        dbHelper: widget.dbHelper,
        learningController: widget.learningController,
      ),
      QuestView(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        dbHelper: widget.dbHelper,
        questController: widget.questController,
      ),
      LeaderboardView(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        userController: widget.userController,
      ),
      SettingView(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        userController: widget.userController,
      ),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
