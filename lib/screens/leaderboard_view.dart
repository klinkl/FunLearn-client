import 'package:flutter/material.dart';
import '../theme/customColors.dart';
import '../widgets/user_info.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<LeaderboardView> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderboardView> {
  bool _world = false;

  void _onButtonTap() {
    setState(() {
      _world = !_world;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      body: Center(
        child: ListView(
          children: [
            if (_world)
              ListTile(
                title: Text(
                  'World Leaderboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              )
            else
              ListTile(
                title: Text(
                  'Friend Leaderboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ListTile(
              title: Userinfo(
                profilPicture: 'assets/images/default_pfp.png',
                userName: 'Romuald',
                exp: 26,
                expNextLevel: 250,
                level: 67,
                streak: 47,
              ),
            ),
            ListTile(
              title: Userinfo(
                profilPicture: 'assets/images/default_pfp.png',
                userName: 'Hans',
                exp: 75,
                expNextLevel: 250,
                level: 45,
                streak: 32,
              ),
            ),
            ListTile(
              title: Userinfo(
                profilPicture: 'assets/images/default_pfp.png',
                userName: 'Annett',
                exp: 168,
                expNextLevel: 250,
                level: 34,
                streak: 22,
              ),
            ),
            ListTile(
              title: Userinfo(
                profilPicture: 'assets/images/default_pfp.png',
                userName: 'Pablo',
                exp: 12,
                expNextLevel: 250,
                level: 12,
                streak: 12,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onButtonTap,
        backgroundColor: customColors.addButton,
        tooltip: _world ? 'World Leaderboard' : 'Friend Leaderboard',
        child: Icon(_world ? Icons.group : Icons.public),
      ),
    );
  }
}
