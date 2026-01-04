import 'package:flutter/material.dart';
import '../theme/customColors.dart';
import './progress_bar.dart';

class Userinfo extends StatelessWidget {
  final String profilPicture;
  final String userName;
  final int level;
  final int exp;
  final int expNextLevel;
  final int streak;

  const Userinfo({
    super.key,
    required this.profilPicture,
    required this.userName,
    required this.exp,
    required this.expNextLevel,
    required this.level,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 40, backgroundImage: AssetImage(profilPicture)),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                '$userName  |  level : $level',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              ProgressBar(
                progress: exp / expNextLevel,
                text: '$exp / $expNextLevel',
              ),
            ],
          ),
          Stack(
            children: [
              Image.asset('assets/images/streak.png', width: 50, height: 50),
              Positioned.fill(
                child: FractionalTranslation(
                  translation: const Offset(0, 0.25),
                  child: Center(
                    child: Text(
                      '$streak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.onSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
