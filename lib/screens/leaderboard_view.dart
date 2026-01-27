import 'package:flutter/material.dart';
import '../data/databaseHelper.dart';
import '../data/models/user.dart';
import '../theme/customColors.dart';
import '../widgets/user_info.dart';
import '../data/userController.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.userController,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final UserController userController;

  @override
  State<LeaderboardView> createState() => _LeaderBoardState();
}

class _LeaderBoardState extends State<LeaderboardView> {
  bool _world = false;
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);

    try {
      final users = _world
          ? await widget.userController.fetchGlobalLeaderboard()
          : await widget.userController.fetchFriendsLeaderboard(
              widget.userController.currentUser!.friends,
            );

      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _users = [];
        _loading = false;
      });
    }
  }

  void _onButtonTap() {
    setState(() {
      _world = !_world;
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
            ..._users.map((user) {
              return ListTile(
                title: Userinfo(
                  profilPicture: 'assets/images/default_pfp.png',
                  userName: user.username,
                  exp: user.totalXP,
                  expNextLevel: user.xpToNextLevel,
                  level: user.level,
                  streak: user.currentStreak,
                ),
              );
            }),
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
